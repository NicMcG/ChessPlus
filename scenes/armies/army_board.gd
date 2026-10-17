class_name ArmyBoard
extends Control

## The army's starting rows, drawn while it's being built. Shows the pieces and
## reports which square was tapped; the army builder decides what that does.
## Squares are (file, row) counted from the owner's edge: row 0 is the back row,
## drawn at the bottom like White's side of the real board.

signal square_tapped(square: Vector2i)

const LIGHT_SQUARE := Color("#F0D9B5")
const DARK_SQUARE := Color("#B58863")
const HIGHLIGHT_TINT := Color(0.95, 0.85, 0.2, 0.45)

var army: Army
var columns := 8
var rows := 2
## Squares to tint, e.g. where the selected piece is allowed to go.
var highlighted: Array[Vector2i] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func show_army(p_army: Army) -> void:
	army = p_army
	queue_redraw()

## The middle of a square on screen.
func square_center(square: Vector2i) -> Vector2:
	return _square_rect(square).get_center()

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var square := _square_at(click.position)
		if square != Board.NO_SQUARE:
			square_tapped.emit(square)
		accept_event()

func _draw() -> void:
	for row in range(rows):
		for file in range(columns):
			var square := Vector2i(file, row)
			# Same colours as the real board: a1 (file 0, row 0) is dark.
			draw_rect(_square_rect(square), LIGHT_SQUARE if (file + row) % 2 == 1 else DARK_SQUARE)
			if highlighted.has(square):
				draw_rect(_square_rect(square), HIGHLIGHT_TINT)
	if army == null:
		return
	for piece in army.pieces:
		var texture := PieceArt.texture_for(piece.def, Piece.Team.WHITE)
		if texture:
			draw_texture_rect(texture, _square_rect(piece.square), false)

func _square_size() -> float:
	return minf(size.x / columns, size.y / rows)

func _origin() -> Vector2:
	return (size - Vector2(columns, rows) * _square_size()) / 2

func _square_rect(square: Vector2i) -> Rect2:
	var s := _square_size()
	return Rect2(_origin() + Vector2(square.x, rows - 1 - square.y) * s, Vector2(s, s))

func _square_at(pos: Vector2) -> Vector2i:
	if _square_size() <= 0:
		return Board.NO_SQUARE
	var cell := ((pos - _origin()) / _square_size()).floor()
	var square := Vector2i(int(cell.x), rows - 1 - int(cell.y))
	if square.x < 0 or square.x >= columns or square.y < 0 or square.y >= rows:
		return Board.NO_SQUARE
	return square
