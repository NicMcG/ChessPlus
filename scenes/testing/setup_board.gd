class_name SetupBoard
extends Control

## The board in Testing mode's setup screen: shows a TestingPosition and says
## which square was tapped (the setup screen decides what that does). Pieces can
## be dragged from the tray onto a square, or from one square to another.

signal square_tapped(square: Vector2i)
## Right-clicked (PC): the setup screen removes the piece there.
signal square_right_clicked(square: Vector2i)
## A piece type was dragged from the tray and dropped on a square.
signal piece_dropped(def: PieceDef, square: Vector2i)
## A piece on the board was dragged to another square.
signal piece_moved(from: Vector2i, to: Vector2i)

const LIGHT_SQUARE := Color("#F0D9B5")
const DARK_SQUARE := Color("#B58863")

var position_shown: TestingPosition

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func show_position(p_position: TestingPosition) -> void:
	position_shown = p_position
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_RIGHT:
		var square := square_at(click.position)
		if square != Board.NO_SQUARE:
			square_right_clicked.emit(square)
		accept_event()
	elif click and not click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		# On release, so that pressing on a piece and dragging it moves it instead.
		var square := square_at(click.position)
		if square != Board.NO_SQUARE:
			square_tapped.emit(square)
		accept_event()

## Dragging a piece on the board picks it up (to drop on another square).
func _get_drag_data(at_position: Vector2) -> Variant:
	var square := square_at(at_position)
	if position_shown == null or square == Board.NO_SQUARE or position_shown.get_at(square).is_empty():
		return null
	var entry: Array = position_shown.get_at(square)
	var preview := TextureRect.new()
	preview.texture = PieceArt.texture_for(entry[0], entry[1])
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2.ONE * _square_size()
	preview.position = -preview.size / 2
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	return {"board_square": square}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and (data.has("tray_piece") or data.has("board_square")) \
			and square_at(at_position) != Board.NO_SQUARE

func _drop_data(at_position: Vector2, data: Variant) -> void:
	var square := square_at(at_position)
	if data.has("tray_piece"):
		piece_dropped.emit(data["tray_piece"], square)
	elif data["board_square"] != square:
		piece_moved.emit(data["board_square"], square)

func _draw() -> void:
	# Nothing to draw before the board has a size.
	if position_shown == null or _square_size() < 4:
		return
	var font := UiStyle.font(UiStyle.SEMIBOLD)
	var s := _square_size()
	for rank in range(position_shown.height):
		for file in range(position_shown.width):
			var square := Vector2i(file, rank)
			var light := (file + rank) % 2 == 1
			var rect := _square_rect(square)
			draw_rect(rect, LIGHT_SQUARE if light else DARK_SQUARE)
			# Coordinates in the opposite square colour, as on the game board.
			var label_color := DARK_SQUARE if light else LIGHT_SQUARE
			var font_size := int(s * 0.2)
			if file == 0:
				draw_string(font, rect.position + Vector2(s * 0.05, s * 0.22), str(rank + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)
			if rank == 0:
				draw_string(font, rect.position + Vector2(s * 0.78, s * 0.95), Board.FILE_LETTERS[file], HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, label_color)
			var entry := position_shown.get_at(square)
			if entry.is_empty():
				continue
			var texture := PieceArt.texture_for(entry[0], entry[1])
			if texture:
				draw_texture_rect(texture, rect, false)
			else:
				var def: PieceDef = entry[0]
				draw_string(font, rect.position + Vector2(0, s * 0.62), def.symbol, HORIZONTAL_ALIGNMENT_CENTER, s, int(s * 0.45),
						Color.WHITE if entry[1] == Piece.Team.WHITE else Color.BLACK)

func _square_size() -> float:
	if position_shown == null:
		return 0.0
	return minf(size.x / position_shown.width, size.y / position_shown.height)

func _origin() -> Vector2:
	return (size - Vector2(position_shown.width, position_shown.height) * _square_size()) / 2

## White at the bottom: rank 0 is the bottom row.
func _square_rect(square: Vector2i) -> Rect2:
	var s := _square_size()
	return Rect2(_origin() + Vector2(square.x * s, (position_shown.height - 1 - square.y) * s), Vector2(s, s))

func square_at(point: Vector2) -> Vector2i:
	if position_shown == null:
		return Board.NO_SQUARE
	var s := _square_size()
	var local := point - _origin()
	var square := Vector2i(floori(local.x / s), position_shown.height - 1 - floori(local.y / s))
	if square.x < 0 or square.y < 0 or square.x >= position_shown.width or square.y >= position_shown.height:
		return Board.NO_SQUARE
	return square

## The middle of a square, in this control's coordinates (for tests).
func square_center(square: Vector2i) -> Vector2:
	return _square_rect(square).get_center()
