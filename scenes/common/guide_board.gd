class_name PieceGuideBoard
extends Control

## A small board with one piece in the middle and a marker on every square it can
## reach (worked out by PieceGuide). Part of the piece info card.

const LIGHT_SQUARE := Color("#F0D9B5")
const DARK_SQUARE := Color("#B58863")
const MARK := Color(0.1, 0.1, 0.1, 0.6)
const FIRST_MOVE_MARK := Color(0.1, 0.1, 0.1, 0.28)
const HOP_MARK := Color(0.82, 0.16, 0.1, 0.9)
## Squares shown on each side of the piece (4 gives a 9 x 9 board).
const RADIUS := 4

var def: PieceDef
var team := Piece.Team.WHITE

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func show_piece(p_def: PieceDef, p_team: Piece.Team) -> void:
	def = p_def
	team = p_team
	queue_redraw()

## Draw the marker for `flags` (PieceGuide flags) in the square `rect`:
## filled dot = moves or captures; small hollow circle = moves only;
## big ring = captures only; pale = first move only; red ring = captures by hopping.
static func draw_marker(canvas: CanvasItem, rect: Rect2, flags: int) -> void:
	var center := rect.get_center()
	var s := rect.size.x
	var color := FIRST_MOVE_MARK if flags & PieceGuide.FIRST_MOVE else MARK
	var moves := flags & PieceGuide.MOVE != 0
	var captures := flags & PieceGuide.CAPTURE != 0
	if moves and captures:
		canvas.draw_circle(center, s * 0.18, color)
	elif moves:
		canvas.draw_arc(center, s * 0.15, 0, TAU, 24, color, s * 0.07, true)
	elif captures:
		canvas.draw_arc(center, s * 0.38, 0, TAU, 32, color, s * 0.08, true)
	if flags & PieceGuide.HOP_CAPTURE:
		canvas.draw_arc(center, s * 0.38, 0, TAU, 32, HOP_MARK, s * 0.08, true)

func _draw() -> void:
	var cells := RADIUS * 2 + 1
	var s := minf(size.x, size.y) / cells
	var origin := (size - Vector2(cells, cells) * s) / 2
	for row in range(cells):
		for col in range(cells):
			# Same colouring as the real board around a piece on a dark square.
			var color := DARK_SQUARE if (col + row) % 2 == 0 else LIGHT_SQUARE
			draw_rect(Rect2(origin + Vector2(col, row) * s, Vector2(s, s)), color)
	if def == null:
		return
	# Forward is up the screen for White and down for Black, as on the real board.
	var forward := -1 if team == Piece.Team.WHITE else 1
	var marks := PieceGuide.pattern(def, RADIUS)
	for offset in marks:
		var cell := Vector2(RADIUS + offset.x, RADIUS + offset.y * forward)
		draw_marker(self, Rect2(origin + cell * s, Vector2(s, s)), marks[offset])
	var texture := PieceArt.texture_for(def, team)
	if texture:
		draw_texture_rect(texture, Rect2(origin + Vector2(RADIUS, RADIUS) * s, Vector2(s, s)), false)
