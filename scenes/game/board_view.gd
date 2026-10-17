class_name BoardView
extends Control

## Draws a game's board and pieces, and turns taps and drags into moves.
## It never decides what's legal: it asks the GameState for its legal moves and
## only lets you pick from those. Phone touches arrive as mouse events, so one
## input path works on both PC and mobile.
##
## Two ways to move: tap a piece then tap a square, or drag the piece there.

## The player picked a move.
signal move_chosen(move: Move)
## The player's choice matched several moves between the same two squares (the
## promotion choices), so someone has to ask which one.
signal choice_needed(moves: Array[Move])
## The player held a finger (or the mouse) on a piece: show its info card.
signal info_requested(piece: Piece)

const LIGHT_SQUARE := Color("#F0D9B5")
const DARK_SQUARE := Color("#B58863")
const SELECTED_TINT := Color(0.95, 0.85, 0.2, 0.55)
const LAST_MOVE_TINT := Color(0.95, 0.85, 0.2, 0.3)
const CHECK_TINT := Color(0.9, 0.15, 0.1, 0.6)
const TARGET_MARK := Color(0.1, 0.1, 0.1, 0.25)
const HOVER_TINT := Color(1, 1, 1, 0.3)
## How far (in pixels) the pointer must move while held before it counts as a drag.
const DRAG_THRESHOLD := 10.0
## A dragged piece is drawn this much bigger, so a finger doesn't hide it.
const DRAG_SCALE := 1.3
## Holding still on a piece this long (milliseconds) opens its info card.
const LONG_PRESS_MS := 450

## Which folder in res://art/pieces/ the piece images come from.
@export var piece_style := "standard"

var state: GameState
var _selected := Board.NO_SQUARE
var _selected_moves: Array[Move] = []

# Pointer (mouse or finger) state.
var _pressed := false
var _press_pos := Vector2.ZERO
var _pointer_pos := Vector2.ZERO
var _dragging := false
## The press landed on the piece that was already selected. If it's released
## without dragging, that deselects it.
var _pressed_selected := false
## When the press started, and whether it can still turn into a long press (it
## can't once it has made a move or wandered off the square).
var _press_time := 0
var _long_press_possible := false

func _ready() -> void:
	# Smooth edges when the piece images are shrunk to fit the squares.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

## Start showing a game.
func show_game(p_state: GameState) -> void:
	state = p_state
	refresh()

## Redraw after the game has changed (a move was made or undone).
func refresh() -> void:
	_clear_selection()
	_dragging = false
	_pressed = false
	queue_redraw()

## The image for a piece, or null if there isn't one (it's then drawn as a letter).
func texture_for(def: PieceDef, team: Piece.Team) -> Texture2D:
	return PieceArt.texture_for(def, team, piece_style)

## The middle of a square on screen.
func square_center(square: Vector2i) -> Vector2:
	return _square_rect(square).get_center()

## Tap a square: select a piece, or move the selected piece there. Returns true
## if the tap chose a move. Public so tests and tools can tap too.
func tap(square: Vector2i) -> bool:
	if not _can_play():
		return false
	if _try_move_to(square):
		return true
	var piece := state.board.get_piece(square)
	if piece and piece.team == state.side_to_move and square != _selected:
		_select(square)
	else:
		_clear_selection()
	queue_redraw()
	return false

## The pointer went down at `pos` (a mouse press or a finger touching the screen).
func pointer_down(pos: Vector2) -> void:
	_pressed = true
	_dragging = false
	_press_pos = pos
	_pointer_pos = pos
	var square := _square_at(pos)
	_pressed_selected = square != Board.NO_SQUARE and square == _selected
	_press_time = Time.get_ticks_msec()
	_long_press_possible = state != null and not state.board.is_empty(square) if square != Board.NO_SQUARE else false
	if not _pressed_selected and square != Board.NO_SQUARE:
		if tap(square):
			_long_press_possible = false

## The pointer moved to `pos`.
func pointer_move(pos: Vector2) -> void:
	if not _pressed:
		return
	_pointer_pos = pos
	if _press_pos.distance_to(pos) > DRAG_THRESHOLD:
		_long_press_possible = false
	if not _dragging and _selected != Board.NO_SQUARE and _square_at(_press_pos) == _selected:
		_dragging = _press_pos.distance_to(pos) > DRAG_THRESHOLD
	if _dragging:
		queue_redraw()

## The pointer was released at `pos`.
func pointer_up(pos: Vector2) -> void:
	if not _pressed:
		return
	_pressed = false
	if _dragging:
		_dragging = false
		# Dropped on a legal square: move. Anywhere else: the piece goes back
		# and stays selected.
		_try_move_to(_square_at(pos))
		queue_redraw()
	elif _pressed_selected:
		_clear_selection()
		queue_redraw()

func _process(_delta: float) -> void:
	check_long_press(Time.get_ticks_msec())

## If the pointer has been held still on a piece long enough, ask for its info
## card and cancel the press (so letting go doesn't also select or move).
## `now_ms` is passed in so tests can pretend time has passed.
func check_long_press(now_ms: int) -> void:
	if not _pressed or _dragging or not _long_press_possible:
		return
	if now_ms - _press_time < LONG_PRESS_MS:
		return
	var piece := state.board.get_piece(_square_at(_press_pos))
	_pressed = false
	_long_press_possible = false
	_clear_selection()
	queue_redraw()
	if piece:
		info_requested.emit(piece)

func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			pointer_down(button.position)
		else:
			pointer_up(button.position)
		accept_event()
	var motion := event as InputEventMouseMotion
	if motion:
		pointer_move(motion.position)

## If the selected piece can move to `square`, choose that move and return true.
func _try_move_to(square: Vector2i) -> bool:
	if _selected == Board.NO_SQUARE or square == Board.NO_SQUARE or not _can_play():
		return false
	var choices: Array[Move] = []
	choices.assign(_selected_moves.filter(func(m: Move) -> bool: return m.to == square))
	if choices.is_empty():
		return false
	_clear_selection()
	queue_redraw()
	if choices.size() == 1:
		move_chosen.emit(choices[0])
	else:
		choice_needed.emit(choices)
	return true

func _can_play() -> bool:
	return state != null and state.outcome() == GameState.Outcome.NONE

func _select(square: Vector2i) -> void:
	_selected = square
	_selected_moves.assign(state.moves().filter(func(m: Move) -> bool: return m.from == square))

func _draw() -> void:
	if state == null:
		return
	var board := state.board
	for rank in range(board.height):
		for file in range(board.width):
			var square := Vector2i(file, rank)
			draw_rect(_square_rect(square), LIGHT_SQUARE if (file + rank) % 2 == 1 else DARK_SQUARE)
	if not state.history.is_empty():
		var last: Move = state.history.back()
		draw_rect(_square_rect(last.from), LAST_MOVE_TINT)
		draw_rect(_square_rect(last.to), LAST_MOVE_TINT)
	if _selected != Board.NO_SQUARE:
		draw_rect(_square_rect(_selected), SELECTED_TINT)
	if state.is_in_check():
		for square in _royal_squares(state.side_to_move):
			draw_rect(_square_rect(square), CHECK_TINT)
	if _dragging:
		var hover := _square_at(_pointer_pos)
		if _selected_moves.any(func(m: Move) -> bool: return m.to == hover):
			draw_rect(_square_rect(hover), HOVER_TINT)
	for rank in range(board.height):
		for file in range(board.width):
			var square := Vector2i(file, rank)
			var piece := board.get_piece(square)
			# While dragging, the piece follows the pointer instead of its square.
			if piece and not (_dragging and square == _selected):
				_draw_piece(piece, _square_rect(square))
	for move in _selected_moves:
		_draw_target(move)
	if _dragging:
		var size_px := _square_size() * DRAG_SCALE
		var rect := Rect2(_pointer_pos - Vector2(size_px, size_px) / 2, Vector2(size_px, size_px))
		_draw_piece(board.get_piece(_selected), rect)

func _draw_piece(piece: Piece, rect: Rect2) -> void:
	var texture: Texture2D = null
	if piece.def.has_shield() and piece.shield_broken:
		texture = PieceArt.texture_for(piece.def, piece.team, piece_style, "wounded")
	if texture == null:
		texture = texture_for(piece.def, piece.team)
	if texture:
		draw_texture_rect(texture, rect, false)
		return
	# No image for this piece yet: draw its letter instead.
	var font := ThemeDB.fallback_font
	var font_size := int(rect.size.y * 0.6)
	var color := Color.WHITE if piece.team == Piece.Team.WHITE else Color.BLACK
	var baseline := Vector2(rect.position.x, rect.position.y + rect.size.y * 0.72)
	draw_string(font, baseline, piece.def.symbol.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)

## A dot on an empty square, a ring around a piece that can be captured.
func _draw_target(move: Move) -> void:
	var rect := _square_rect(move.to)
	var center := rect.get_center()
	if move.is_capture() and not state.board.is_empty(move.to):
		draw_arc(center, rect.size.x * 0.45, 0, TAU, 32, TARGET_MARK, rect.size.x * 0.08, true)
	else:
		draw_circle(center, rect.size.x * 0.16, TARGET_MARK)

func _square_size() -> float:
	return minf(size.x / state.board.width, size.y / state.board.height)

## Top-left corner of the board, so it's centred in this control.
func _origin() -> Vector2:
	var board_size := Vector2(state.board.width, state.board.height) * _square_size()
	return (size - board_size) / 2

## Where a square is drawn. White's side is at the bottom.
func _square_rect(square: Vector2i) -> Rect2:
	var s := _square_size()
	var row := state.board.height - 1 - square.y
	return Rect2(_origin() + Vector2(square.x * s, row * s), Vector2(s, s))

func _square_at(pos: Vector2) -> Vector2i:
	if state == null or _square_size() <= 0:
		return Board.NO_SQUARE
	var cell := ((pos - _origin()) / _square_size()).floor()
	var square := Vector2i(int(cell.x), state.board.height - 1 - int(cell.y))
	return square if state.board.in_bounds(square) else Board.NO_SQUARE

func _royal_squares(team: Piece.Team) -> Array[Vector2i]:
	var squares: Array[Vector2i] = []
	for rank in range(state.board.height):
		for file in range(state.board.width):
			var piece := state.board.get_piece(Vector2i(file, rank))
			if piece and piece.team == team and piece.def.is_king_type():
				squares.append(Vector2i(file, rank))
	return squares

func _clear_selection() -> void:
	_selected = Board.NO_SQUARE
	_selected_moves.clear()
