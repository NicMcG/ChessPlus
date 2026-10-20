class_name PieceGuideBoard
extends Control

## A small board (5 x 5, bigger only if a jump needs it) with one piece in the
## middle, showing how it moves (worked out by PieceGuide):
##   filled circle = moves or captures    empty circle = moves only
##   red X = captures only                pale = first move only
##   yellow circle = jumps there          arrow line = moves any distance that way
##   dashed arrow line = moves any distance that way, but can't capture that way

const LIGHT_SQUARE := Color("#F0D9B5")
const DARK_SQUARE := Color("#B58863")
const MARK := Color(0.1, 0.1, 0.1, 0.75)
const FIRST_MOVE_MARK := Color(0.1, 0.1, 0.1, 0.35)
const CAPTURE_MARK := Color("#D42A1F")
const JUMP_MARK := Color("#F5BE0B")

## Legend entries: kind -> text. Only the kinds a piece uses are listed.
const LEGEND := {
	"both": "Moves or captures here",
	"move": "Moves here (can't capture)",
	"capture": "Captures here only",
	"first": "Only on its first move",
	"jump": "Jumps here",
	"slide": "Moves any distance this way",
	"slide_move": "Moves any distance this way (can't capture)",
}

var def: PieceDef
var team := Piece.Team.WHITE

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func show_piece(p_def: PieceDef, p_team: Piece.Team) -> void:
	def = p_def
	team = p_team
	queue_redraw()

## The legend kinds this piece's picture uses, in LEGEND order.
static func legend_kinds(guide: Dictionary) -> Array[String]:
	var used := {}
	for flags in guide.squares.values():
		used[_kind(flags)] = true
	for slide in guide.slides:
		used["slide" if slide[1] & PieceGuide.CAPTURE else "slide_move"] = true
	var kinds: Array[String] = []
	for kind in LEGEND:
		if used.has(kind):
			kinds.append(kind)
	return kinds

static func _kind(flags: int) -> String:
	if flags & PieceGuide.FIRST_MOVE:
		return "first"
	if flags & PieceGuide.JUMP:
		return "jump"
	var moves := flags & PieceGuide.MOVE != 0
	var captures := flags & PieceGuide.CAPTURE != 0
	if moves and captures:
		return "both"
	return "move" if moves else "capture"

## Draw the marker for one square, `rect`, with PieceGuide `flags`.
static func draw_square_marker(canvas: CanvasItem, rect: Rect2, flags: int) -> void:
	var color := FIRST_MOVE_MARK if flags & PieceGuide.FIRST_MOVE else MARK
	var c := rect.get_center()
	var s := rect.size.x
	match _kind(flags):
		"jump":
			canvas.draw_circle(c, s * 0.2, JUMP_MARK)
			canvas.draw_arc(c, s * 0.2, 0, TAU, 24, MARK, s * 0.04, true)
		"both":
			canvas.draw_circle(c, s * 0.18, color)
		"capture":
			var d := s * 0.17
			canvas.draw_line(c + Vector2(-d, -d), c + Vector2(d, d), CAPTURE_MARK, s * 0.09, true)
			canvas.draw_line(c + Vector2(-d, d), c + Vector2(d, -d), CAPTURE_MARK, s * 0.09, true)
		_:  # "move" and "first": an empty circle
			canvas.draw_arc(c, s * 0.16, 0, TAU, 24, color, s * 0.07, true)

## Draw a slide: a line from `from` to `to` ending in an arrowhead. Dashed if the
## piece can't capture along it.
static func draw_slide(canvas: CanvasItem, from: Vector2, to: Vector2, can_capture: bool, square_size: float) -> void:
	var width := square_size * 0.08
	var direction := (to - from).normalized()
	var tip_back := to - direction * square_size * 0.28
	if can_capture:
		canvas.draw_line(from, tip_back, MARK, width, true)
	else:
		canvas.draw_dashed_line(from, tip_back, MARK, width, square_size * 0.16, true, true)
	var side := direction.orthogonal() * square_size * 0.16
	canvas.draw_colored_polygon(PackedVector2Array([to, tip_back + side, tip_back - side]), MARK)

## A legend icon for `kind` in `rect`, drawn on a light square.
static func draw_legend_icon(canvas: CanvasItem, rect: Rect2, kind: String) -> void:
	canvas.draw_rect(rect, LIGHT_SQUARE)
	var flags := {
		"both": PieceGuide.MOVE | PieceGuide.CAPTURE,
		"move": PieceGuide.MOVE,
		"capture": PieceGuide.CAPTURE,
		"first": PieceGuide.MOVE | PieceGuide.FIRST_MOVE,
		"jump": PieceGuide.MOVE | PieceGuide.CAPTURE | PieceGuide.JUMP,
	}
	if flags.has(kind):
		draw_square_marker(canvas, rect, flags[kind])
		return
	var s := rect.size.x
	var y := rect.get_center().y
	draw_slide(canvas, Vector2(rect.position.x + s * 0.12, y), Vector2(rect.end.x - s * 0.08, y), kind == "slide", s * 0.8)

func _draw() -> void:
	if def == null:
		return
	var guide := PieceGuide.guide(def)
	var radius: int = guide.radius
	var cells := radius * 2 + 1
	var s := minf(size.x, size.y) / cells
	var origin := (size - Vector2(cells, cells) * s) / 2
	for row in range(cells):
		for col in range(cells):
			# The piece sits on a light square: its picture reads best there.
			var color := LIGHT_SQUARE if (col + row) % 2 == 0 else DARK_SQUARE
			draw_rect(Rect2(origin + Vector2(col, row) * s, Vector2(s, s)), color)
	# Forward is always up the screen, for both colours (Mac).
	var forward := -1
	var center := origin + Vector2(radius + 0.5, radius + 0.5) * s
	for slide in guide.slides:
		var dir: Vector2i = slide[0]
		var screen_dir := Vector2(dir.x, dir.y * forward)
		var steps := float(radius) / maxi(absi(dir.x), absi(dir.y))
		# From the edge of the square before its first step (the piece's own square,
		# or the jump mark for a leaping slide).
		var first_step: int = slide[2]
		var start := center + screen_dir * s * (first_step - 1) + screen_dir.normalized() * s * 0.5
		draw_slide(self, start, center + screen_dir * s * steps, slide[1] & PieceGuide.CAPTURE != 0, s)
	for offset in guide.squares:
		var cell := Vector2(radius + offset.x, radius + offset.y * forward)
		draw_square_marker(self, Rect2(origin + cell * s, Vector2(s, s)), guide.squares[offset])
	var texture := PieceArt.texture_for(def, team)
	var piece_rect := Rect2(origin + Vector2(radius, radius) * s, Vector2(s, s))
	if texture:
		draw_texture_rect(texture, piece_rect, false)
	else:
		# No picture yet: its letter(s), in the team's colour with an outline.
		var font := get_theme_default_font()
		var font_size := int(s * (0.55 if def.symbol.length() == 1 else 0.4))
		var baseline := Vector2(piece_rect.position.x, piece_rect.position.y + s * 0.5 + font_size * 0.35)
		var fill := Color.WHITE if team == Piece.Team.WHITE else Color.BLACK
		draw_string_outline(font, baseline, def.symbol, HORIZONTAL_ALIGNMENT_CENTER, s, font_size, maxi(2, int(s * 0.06)), Color.BLACK if team == Piece.Team.WHITE else Color.WHITE)
		draw_string(font, baseline, def.symbol, HORIZONTAL_ALIGNMENT_CENTER, s, font_size, fill)
