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
## The see-through arrows players draw with the right mouse button.
const ARROW_COLOR := Color(0.1, 0.55, 0.15, 0.6)
## How far (in pixels) the pointer must move while held before it counts as a drag.
const DRAG_THRESHOLD := 10.0
## A dragged piece is drawn this much bigger, so a finger doesn't hide it.
const DRAG_SCALE := 1.3
## Holding still on a piece this long (milliseconds) opens its info card.
const LONG_PRESS_MS := 450
## How long (seconds) a piece shakes when you tap somewhere it can't go.
const SHAKE_TIME := 0.3

## Which folder in res://art/pieces/ the piece images come from.
@export var piece_style := "standard"
## How long (seconds) a move takes to slide across the board. 0 = no animation.
@export var move_time := 0.18

var state: GameState
## False while the practice bot is thinking, so the player can't move.
var input_enabled := true
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

# Animation. The game state has always already changed: these only change where
# and how pieces are drawn for a moment afterwards.
## Pieces sliding: piece -> [square it's drawn leaving, square it's going to].
var _slides := {}
## Pieces fading: [piece, square, fading in?]. Captured pieces fade out; when a
## capture is undone, the piece fades back in.
var _fades: Array = []
## Seconds since the slide started (it's over once this reaches move_time).
var _move_elapsed := 0.0
## The square whose piece is shaking, and for how long it has been.
var _shake_square := Board.NO_SQUARE
var _shake_elapsed := 0.0
## The player just dropped a dragged piece, so its move needs no slide.
var _skip_next_slide := false

# Arrows (PC): drag with the right mouse button from one square to another.
## Each arrow is [from square, to square].
var arrows: Array = []
## Where the right button went down (NO_SQUARE when it isn't held).
var _arrow_start := Board.NO_SQUARE
var _arrow_pointer := Vector2.ZERO

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
	_slides.clear()
	_fades.clear()
	_shake_square = Board.NO_SQUARE
	# A new move (or a different position) clears the arrows.
	arrows.clear()
	_arrow_start = Board.NO_SQUARE
	queue_redraw()

## Redraw after `move` was made, sliding the piece there (and the castling
## partner too) and fading out what it captured. Not if the piece was dragged
## there: it's already in place.
func show_move(move: Move) -> void:
	var skip := _skip_next_slide
	_skip_next_slide = false
	refresh()
	if move_time <= 0:
		return
	var landed := move.lands_on()
	var moved := state.board.get_piece(landed)  # A promoted piece is a new Piece.
	if moved and landed != move.from and not skip:
		_slides[moved] = [move.from, landed]
	if move.partner:
		_slides[move.partner] = [move.partner_from, move.partner_to]
	if move.captured:
		_fades.append([move.captured, move.capture_square, false])
	if move.breaks_shield():
		_start_shake(move.to)
	_move_elapsed = 0.0

## Redraw after `moves` were undone (most recent first): each piece slides back
## and captured pieces fade back in.
func show_undo(moves: Array[Move]) -> void:
	refresh()
	if move_time <= 0:
		return
	for move in moves:
		var piece := state.board.get_piece(move.from)
		if piece:
			_add_slide_back(piece, move.lands_on(), move.from)
		if move.partner:
			_add_slide_back(move.partner, move.partner_to, move.partner_from)
		if move.captured:
			_fades.append([move.captured, move.capture_square, true])
	_move_elapsed = 0.0

## True while pieces are still sliding or fading.
func is_animating() -> bool:
	return not (_slides.is_empty() and _fades.is_empty())

## The piece may already be sliding back from a later move: keep where it's
## drawn leaving from and only change where it ends up.
func _add_slide_back(piece: Piece, leaving: Vector2i, going_to: Vector2i) -> void:
	if leaving == going_to:
		return
	if _slides.has(piece):
		_slides[piece][1] = going_to
	else:
		_slides[piece] = [leaving, going_to]

func _start_shake(square: Vector2i) -> void:
	_shake_square = square
	_shake_elapsed = 0.0
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
		# Somewhere the selected piece can't go: it shakes "no".
		if _selected != Board.NO_SQUARE and square != _selected:
			_start_shake(_selected)
		_clear_selection()
	queue_redraw()
	return false

## The pointer went down at `pos` (a mouse press or a finger touching the screen).
## Holding still opens the piece's card only for a finger (`touch`): with a
## mouse, right-clicking does that instead.
func pointer_down(pos: Vector2, touch := true) -> void:
	_pressed = true
	_dragging = false
	_skip_next_slide = false
	_press_pos = pos
	_pointer_pos = pos
	var square := _square_at(pos)
	_pressed_selected = square != Board.NO_SQUARE and square == _selected
	_press_time = Time.get_ticks_msec()
	_long_press_possible = touch and state != null and not state.board.is_empty(square) if square != Board.NO_SQUARE else false
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
		_skip_next_slide = true
		if not _try_move_to(_square_at(pos)):
			_skip_next_slide = false
		queue_redraw()
	elif _pressed_selected:
		_clear_selection()
		queue_redraw()

func _process(delta: float) -> void:
	check_long_press(Time.get_ticks_msec())
	advance_animation(delta)

## Move the animations on by `delta` seconds (tests call this to skip ahead).
func advance_animation(delta: float) -> void:
	if is_animating():
		_move_elapsed += delta
		if _move_elapsed >= move_time:
			_slides.clear()
			_fades.clear()
		queue_redraw()
	if _shake_square != Board.NO_SQUARE:
		_shake_elapsed += delta
		if _shake_elapsed >= SHAKE_TIME:
			_shake_square = Board.NO_SQUARE
		queue_redraw()

## True while the piece on `square` is shaking (for tests).
func is_shaking(square: Vector2i) -> bool:
	return _shake_square == square

## The right mouse button went down (PC): maybe the start of an arrow.
func right_down(pos: Vector2) -> void:
	if state == null or _dragging:
		return
	_arrow_start = _square_at(pos)
	_arrow_pointer = pos

## The right mouse button came up. Dragged to another square: add an arrow
## there (or remove it, if that arrow is already drawn). Released where it went
## down: a plain right-click, which clears the arrows and, on a piece, asks for
## its info card.
func right_up(pos: Vector2) -> void:
	if state == null or _arrow_start == Board.NO_SQUARE:
		_arrow_start = Board.NO_SQUARE
		return
	var start := _arrow_start
	var end := _square_at(pos)
	_arrow_start = Board.NO_SQUARE
	if end != Board.NO_SQUARE and end != start:
		var arrow := [start, end]
		if arrows.has(arrow):
			arrows.erase(arrow)
		else:
			arrows.append(arrow)
	else:
		arrows.clear()
		var piece := state.board.get_piece(start)
		if piece and end == start:
			_clear_selection()
			info_requested.emit(piece)
	queue_redraw()

## A plain right-click at `pos`.
func right_click(pos: Vector2) -> void:
	right_down(pos)
	right_up(pos)

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
	if button and button.button_index == MOUSE_BUTTON_RIGHT:
		if button.pressed:
			right_down(button.position)
		else:
			right_up(button.position)
		accept_event()
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			# A finger's touch arrives as a pretend ("emulated") mouse click.
			var touch := button.device == InputEvent.DEVICE_ID_EMULATION or DisplayServer.is_touchscreen_available()
			pointer_down(button.position, touch)
		else:
			pointer_up(button.position)
		accept_event()
	var motion := event as InputEventMouseMotion
	if motion:
		pointer_move(motion.position)
		if _arrow_start != Board.NO_SQUARE:
			_arrow_pointer = motion.position
			queue_redraw()

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
	return input_enabled and state != null and state.outcome() == GameState.Outcome.NONE

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
	var progress := _ease(clampf(_move_elapsed / move_time, 0.0, 1.0)) if move_time > 0 else 1.0
	for fade: Array in _fades:
		if not _slides.has(fade[0]):
			_draw_piece(fade[0], _square_rect(fade[1]), progress if fade[2] else 1.0 - progress)
	for rank in range(board.height):
		for file in range(board.width):
			var square := Vector2i(file, rank)
			var piece := board.get_piece(square)
			# While dragging, the piece follows the pointer instead of its square.
			# Sliding and fading pieces are drawn separately.
			if piece and not (_dragging and square == _selected) and not _slides.has(piece) \
					and not _fades.any(func(f: Array) -> bool: return f[0] == piece):
				var rect := _square_rect(square)
				if square == _shake_square:
					rect.position.x += _shake_offset(rect.size.x)
				_draw_piece(piece, rect)
	# Sliding pieces last, so they pass over the others.
	for piece: Piece in _slides:
		var from_rect := _square_rect(_slides[piece][0])
		var to_rect := _square_rect(_slides[piece][1])
		_draw_piece(piece, Rect2(from_rect.position.lerp(to_rect.position, progress), to_rect.size))
	for move in _selected_moves:
		_draw_target(move)
	for arrow: Array in arrows:
		_draw_arrow(square_center(arrow[0]), square_center(arrow[1]))
	# The arrow being drawn right now follows the pointer to the square under it.
	if _arrow_start != Board.NO_SQUARE:
		var hover := _square_at(_arrow_pointer)
		if hover != Board.NO_SQUARE and hover != _arrow_start:
			_draw_arrow(square_center(_arrow_start), square_center(hover))
	if _dragging:
		var size_px := _square_size() * DRAG_SCALE
		var rect := Rect2(_pointer_pos - Vector2(size_px, size_px) / 2, Vector2(size_px, size_px))
		_draw_piece(board.get_piece(_selected), rect)

## A see-through arrow from the middle of one square to the middle of another,
## drawn as one shape (so the overlapping parts don't look darker).
func _draw_arrow(from: Vector2, to: Vector2) -> void:
	var s := _square_size()
	var direction := (to - from).normalized()
	var side := Vector2(-direction.y, direction.x)
	var start := from + direction * s * 0.25
	var head_length := s * 0.4
	var neck := to - direction * head_length
	var shaft := s * 0.09  # Half the shaft's width.
	var head := s * 0.25  # Half the head's width.
	var points := PackedVector2Array([
		start + side * shaft, neck + side * shaft, neck + side * head, to,
		neck - side * head, neck - side * shaft, start - side * shaft,
	])
	draw_colored_polygon(points, ARROW_COLOR)

## Starts fast and slows down as it arrives.
static func _ease(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3)

## Sideways wobble that dies away.
func _shake_offset(square_size: float) -> float:
	var t := _shake_elapsed / SHAKE_TIME
	return sin(t * TAU * 3) * square_size * 0.08 * (1.0 - t)

func _draw_piece(piece: Piece, rect: Rect2, alpha := 1.0) -> void:
	var texture: Texture2D = null
	if piece.def.has_shield() and piece.shield_broken:
		texture = PieceArt.texture_for(piece.def, piece.team, piece_style, "wounded")
	if texture == null:
		texture = texture_for(piece.def, piece.team)
	if texture:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))
		return
	# No image for this piece yet: draw its letter instead.
	var font := ThemeDB.fallback_font
	var font_size := int(rect.size.y * 0.6)
	var color := Color.WHITE if piece.team == Piece.Team.WHITE else Color.BLACK
	color.a = alpha
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
