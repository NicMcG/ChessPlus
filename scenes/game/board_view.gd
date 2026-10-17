class_name BoardView
extends Control

## Draws a game's board and pieces, and turns taps into moves.
## It never decides what's legal: it asks the GameState for its legal moves and
## only lets you pick from those. Phone taps arrive as mouse clicks, so one input
## path works on both PC and mobile.

## The player picked a move.
signal move_chosen(move: Move)
## The tap matched several moves between the same two squares (the promotion
## choices), so someone has to ask which one.
signal choice_needed(moves: Array[Move])

const LIGHT_SQUARE := Color("#F0D9B5")
const DARK_SQUARE := Color("#B58863")
const SELECTED_TINT := Color(0.95, 0.85, 0.2, 0.55)
const LAST_MOVE_TINT := Color(0.95, 0.85, 0.2, 0.3)
const CHECK_TINT := Color(0.9, 0.15, 0.1, 0.6)
const TARGET_MARK := Color(0.1, 0.1, 0.1, 0.25)

## Which folder in res://art/pieces/ the piece images come from.
@export var piece_style := "classic"

var state: GameState
var _selected := Board.NO_SQUARE
var _selected_moves: Array[Move] = []
var _textures := {}  # Image path -> Texture2D (or null if there's no image).

## Start showing a game.
func show_game(p_state: GameState) -> void:
	state = p_state
	refresh()

## Redraw after the game has changed (a move was made).
func refresh() -> void:
	_clear_selection()
	queue_redraw()

## The image for a piece, or null if there isn't one (it's then drawn as a letter).
func texture_for(def: PieceDef, team: Piece.Team) -> Texture2D:
	var team_name := "white" if team == Piece.Team.WHITE else "black"
	var path := "res://art/pieces/%s/%s_%s.svg" % [piece_style, team_name, def.id]
	if not _textures.has(path):
		_textures[path] = load(path) if ResourceLoader.exists(path) else null
	return _textures[path]

## What happens when a square is tapped. Public so tests and tools can tap too.
func tap(square: Vector2i) -> void:
	if state == null or state.outcome() != GameState.Outcome.NONE:
		return
	if _selected != Board.NO_SQUARE:
		var choices: Array[Move] = []
		choices.assign(_selected_moves.filter(func(m: Move) -> bool: return m.to == square))
		if not choices.is_empty():
			_clear_selection()
			queue_redraw()
			if choices.size() == 1:
				move_chosen.emit(choices[0])
			else:
				choice_needed.emit(choices)
			return
	var piece := state.board.get_piece(square)
	if piece and piece.team == state.side_to_move and square != _selected:
		_selected = square
		_selected_moves.assign(state.moves().filter(func(m: Move) -> bool: return m.from == square))
	else:
		_clear_selection()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		var square := _square_at(click.position)
		if square != Board.NO_SQUARE:
			tap(square)
		accept_event()

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
	for rank in range(board.height):
		for file in range(board.width):
			var piece := board.get_piece(Vector2i(file, rank))
			if piece:
				_draw_piece(piece, _square_rect(Vector2i(file, rank)))
	for move in _selected_moves:
		_draw_target(move)

func _draw_piece(piece: Piece, rect: Rect2) -> void:
	var texture := texture_for(piece.def, piece.team)
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
	if state == null:
		return Board.NO_SQUARE
	var cell := ((pos - _origin()) / _square_size()).floor()
	var square := Vector2i(int(cell.x), state.board.height - 1 - int(cell.y))
	return square if state.board.in_bounds(square) else Board.NO_SQUARE

func _royal_squares(team: Piece.Team) -> Array[Vector2i]:
	var squares: Array[Vector2i] = []
	for rank in range(state.board.height):
		for file in range(state.board.width):
			var piece := state.board.get_piece(Vector2i(file, rank))
			if piece and piece.team == team and piece.def.is_royal:
				squares.append(Vector2i(file, rank))
	return squares

func _clear_selection() -> void:
	_selected = Board.NO_SQUARE
	_selected_moves.clear()
