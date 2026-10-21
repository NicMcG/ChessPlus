class_name PieceGuideBoard
extends Control

## A small board (5 x 5, bigger only if a jump needs it) with one piece in the
## middle, showing how it moves (worked out by PieceGuide). The marks (Mac's
## design, Oct 2026):
##   dot = moves here                     line with an arrow = any square that way
##   empty circle = moves here, can't capture
##   dotted arrow = any square that way, can't capture
##   red X = must capture to move here    yellow dot = jumps here
##   yellow empty circle = jumps here, can't capture
##   yellow X = jumps here, must capture
## Squares it reaches only on its first move (the pawn's double step) aren't
## shown: the piece's Special Rule says so instead (Mac).

const LIGHT_SQUARE := Color("#F0D9B5")
const DARK_SQUARE := Color("#B58863")
const MARK := Color(0.1, 0.1, 0.1, 0.75)
const CAPTURE_MARK := Color("#D42A1F")
const JUMP_MARK := Color("#F5BE0B")

## The legend: kind -> text (Mac's wording), in his order. Every card shows all of it.
const LEGEND := {
	"both": "Moves or captures",
	"slide": "Slides",
	"move": "Moves, can't capture",
	"slide_move": "Slides, can't capture",
	"capture": "Captures only",
	"jump": "Jumps",
	"jump_move": "Jumps, can't capture",
	"jump_capture": "Jumps, captures only",
}

## The plain dot and arrow explain themselves, so the card's legend leaves them
## out (Mac, Oct 2026).
const NOT_IN_LEGEND: Array[String] = ["both", "slide"]

var def: PieceDef
var team := Piece.Team.WHITE

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func show_piece(p_def: PieceDef, p_team: Piece.Team) -> void:
	def = p_def
	team = p_team
	queue_redraw()

## The legend kinds this piece's picture uses, in LEGEND order (the card lists
## them all; tests use this to check each piece gets the right marks).
static func kinds_used(guide: Dictionary) -> Array[String]:
	var used := {}
	for flags in shown_squares(guide).values():
		used[_kind(flags)] = true
	for slide in guide.slides:
		used["slide" if slide[1] & PieceGuide.CAPTURE else "slide_move"] = true
	var kinds: Array[String] = []
	for kind in LEGEND:
		if used.has(kind):
			kinds.append(kind)
	return kinds

## The guide's squares that get a mark: all but the first-move-only ones.
static func shown_squares(guide: Dictionary) -> Dictionary:
	var shown := {}
	for offset in guide.squares:
		if guide.squares[offset] & PieceGuide.FIRST_MOVE == 0:
			shown[offset] = guide.squares[offset]
	return shown

## Which mark a square gets.
static func _kind(flags: int) -> String:
	var moves := flags & PieceGuide.MOVE != 0
	var captures := flags & PieceGuide.CAPTURE != 0
	var kind := "both" if moves and captures else ("move" if moves else "capture")
	if flags & PieceGuide.JUMP:
		return {"both": "jump", "move": "jump_move", "capture": "jump_capture"}[kind]
	return kind

## Draw the marker for one square, `rect`, with PieceGuide `flags`.
static func draw_square_marker(canvas: CanvasItem, rect: Rect2, flags: int) -> void:
	var c := rect.get_center()
	var s := rect.size.x
	match _kind(flags):
		"both":
			canvas.draw_circle(c, s * 0.18, MARK)
		"move":
			canvas.draw_arc(c, s * 0.16, 0, TAU, 24, MARK, s * 0.07, true)
		"capture":
			_draw_x(canvas, c, s * 0.17, CAPTURE_MARK, s * 0.09)
		"jump":
			canvas.draw_circle(c, s * 0.2, JUMP_MARK)
			canvas.draw_arc(c, s * 0.2, 0, TAU, 24, MARK, s * 0.04, true)
		"jump_move":
			# A yellow ring with a thin dark edge each side, so it shows on light squares.
			canvas.draw_arc(c, s * 0.17, 0, TAU, 24, MARK, s * 0.12, true)
			canvas.draw_arc(c, s * 0.17, 0, TAU, 24, JUMP_MARK, s * 0.065, true)
		"jump_capture":
			# A yellow X with a thin dark edge (the line ends too).
			_draw_x(canvas, c, s * 0.18, MARK, s * 0.14)
			_draw_x(canvas, c, s * 0.17, JUMP_MARK, s * 0.085)

## An X centred on `c`, its arms reaching `d` across and down each way.
static func _draw_x(canvas: CanvasItem, c: Vector2, d: float, color: Color, width: float) -> void:
	canvas.draw_line(c + Vector2(-d, -d), c + Vector2(d, d), color, width, true)
	canvas.draw_line(c + Vector2(-d, d), c + Vector2(d, -d), color, width, true)

## Draw a slide: a line from `from` to `to` ending in an arrowhead. Dotted if the
## piece can't capture along it.
static func draw_slide(canvas: CanvasItem, from: Vector2, to: Vector2, can_capture: bool, square_size: float) -> void:
	var width := square_size * 0.08
	var direction := (to - from).normalized()
	var tip_back := to - direction * square_size * 0.28
	if can_capture:
		canvas.draw_line(from, tip_back, MARK, width, true)
	else:
		# Round dots, evenly spaced, the last one just before the arrowhead.
		var length := from.distance_to(tip_back)
		var gap := square_size * 0.2
		var count := maxi(1, roundi(length / gap))
		for i in range(count):
			canvas.draw_circle(tip_back - direction * (gap * 0.6 + length * i / count), width * 0.7, MARK)
	var side := direction.orthogonal() * square_size * 0.16
	canvas.draw_colored_polygon(PackedVector2Array([to, tip_back + side, tip_back - side]), MARK)

## A legend icon for `kind` in `rect`, drawn on a light square.
static func draw_legend_icon(canvas: CanvasItem, rect: Rect2, kind: String) -> void:
	canvas.draw_rect(rect, LIGHT_SQUARE)
	var flags := {
		"both": PieceGuide.MOVE | PieceGuide.CAPTURE,
		"move": PieceGuide.MOVE,
		"capture": PieceGuide.CAPTURE,
		"jump": PieceGuide.MOVE | PieceGuide.CAPTURE | PieceGuide.JUMP,
		"jump_move": PieceGuide.MOVE | PieceGuide.JUMP,
		"jump_capture": PieceGuide.CAPTURE | PieceGuide.JUMP,
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
	var shown := shown_squares(guide)
	for offset in shown:
		var cell := Vector2(radius + offset.x, radius + offset.y * forward)
		draw_square_marker(self, Rect2(origin + cell * s, Vector2(s, s)), shown[offset])
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
