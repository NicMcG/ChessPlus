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
## The selected piece changed (NO_SQUARE: nothing selected now). The game screen
## uses it to show the selected piece's special ability button.
signal selection_changed(square: Vector2i)
## An animation has reached the moment a sound belongs to (a GameSounds.Sound).
signal sound_cue(sound: int)
## The move's animation (and check shake) has finished.
signal animation_finished

const LIGHT_SQUARE := Color("#F0D9B5")
const DARK_SQUARE := Color("#B58863")
const SELECTED_TINT := Color(0.95, 0.85, 0.2, 0.55)
const LAST_MOVE_TINT := Color(0.95, 0.85, 0.2, 0.3)
const CHECK_TINT := Color(0.9, 0.15, 0.1, 0.6)
const TARGET_MARK := Color(0.1, 0.1, 0.1, 0.25)
const HOVER_TINT := Color(1, 1, 1, 0.3)
## Targets for a special ability (Crack Shot) are ringed in gold.
const ABILITY_MARK := Color(0.95, 0.7, 0.1, 0.9)
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
@export var move_time := 0.22
## Black's side at the bottom (the board turned round; pieces still upright).
## Set when this player is Black, online or against the bot.
var flipped := false:
	set(value):
		flipped = value
		queue_redraw()

var state: GameState
## False while the practice bot is thinking, so the player can't move.
var input_enabled := true
var _selected := Board.NO_SQUARE
var _selected_moves: Array[Move] = []
## The selected piece's special-ability moves. They aren't offered by normal
## taps: only after aim_ability() (the ability button).
var _ability_moves: Array[Move] = []
## True while choosing a target for an ability: only its targets are offered.
var aiming := false

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
## The move being animated (see MoveAnimation), or null.
var _animation: MoveAnimation
## The square whose piece is shaking "no" (an illegal tap), and for how long.
var _shake_square := Board.NO_SQUARE
var _shake_elapsed := 0.0
## The player just dropped a dragged piece: its move slams down instead of sliding.
var _dropped := false
## Kings in check (while the game goes on): they keep trembling a little.
var _check_squares: Array[Vector2i] = []
## Squares whose pieces aren't drawn (the checkmated king while it turns to dust).
var hidden_squares: Array[Vector2i] = []

# Arrows (PC): drag with the right mouse button from one square to another.
## Each arrow is [from square, to square].
var arrows: Array = []
## Where the right button went down (NO_SQUARE when it isn't held).
var _arrow_start := Board.NO_SQUARE
var _arrow_pointer := Vector2.ZERO

## Plain white silhouettes of piece pictures (for flashes), made when first needed.
static var _silhouettes := {}

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
	_animation = null
	hidden_squares.clear()
	_check_squares.clear()
	if state and state.outcome() == GameState.Outcome.NONE and state.is_in_check():
		_check_squares = MoveAnimation.royal_squares(state, state.side_to_move)
	_shake_square = Board.NO_SQUARE
	# A new move (or a different position) clears the arrows.
	arrows.clear()
	_arrow_start = Board.NO_SQUARE
	queue_redraw()

## Redraw after `move` was made, and animate it (see MoveAnimation): slides,
## hops, slams (if the player dragged it there), captures being knocked off and
## so on, with sound_cue telling the game screen when each sound plays.
func show_move(move: Move) -> void:
	var dropped := _dropped
	_dropped = false
	refresh()
	_start_animation(MoveAnimation.for_move(move, state, dropped, _speed()))

## Redraw after `moves` were undone (most recent first): each piece slides back
## and captured pieces fade back in.
func show_undo(moves: Array[Move]) -> void:
	refresh()
	_start_animation(MoveAnimation.for_undo(moves, state, _speed()))

## How fast animations play: move_time is how long a plain slide takes.
func _speed() -> float:
	return move_time / MoveAnimation.SLIDE if move_time > 0 else 1.0

## Animations switched off (move_time 0): just play the sounds.
func _start_animation(animation: MoveAnimation) -> void:
	if move_time <= 0:
		for sound: int in animation.all_sounds():
			sound_cue.emit(sound)
		animation_finished.emit()
		return
	_animation = animation
	advance_animation(0.0)

## The animation playing now, or null (for tests).
func current_animation() -> MoveAnimation:
	return _animation

## True while a move is still being animated.
func is_animating() -> bool:
	return _animation != null

func _start_shake(square: Vector2i) -> void:
	_shake_square = square
	_shake_elapsed = 0.0
	queue_redraw()

## The image for a piece, or null if there isn't one (it's then drawn as a letter).
func texture_for(def: PieceDef, team: Piece.Team) -> Texture2D:
	return PieceArt.texture_for(def, team, piece_style)

## Where a square is on screen, in global coordinates.
func square_screen_rect(square: Vector2i) -> Rect2:
	var rect := _square_rect(square)
	return Rect2(get_global_transform() * rect.position, rect.size * get_global_transform().get_scale())

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
	_dropped = false
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
		_dropped = true
		if not _try_move_to(_square_at(pos)):
			_dropped = false
		queue_redraw()
	elif _pressed_selected:
		_clear_selection()
		queue_redraw()

func _process(delta: float) -> void:
	check_long_press(Time.get_ticks_msec())
	advance_animation(delta)
	if not _check_squares.is_empty():
		queue_redraw()

## The kings in check now (empty when nobody is), which tremble on the board.
func check_squares() -> Array[Vector2i]:
	return _check_squares

## A small nervous jitter (in squares) for a king in check.
static func tremble(seconds: float) -> Vector2:
	return Vector2(sin(seconds * 53.0) + 0.6 * sin(seconds * 31.0), 0.5 * sin(seconds * 41.0)) * 0.012

## Move the animations on by `delta` seconds (tests call this to skip ahead).
func advance_animation(delta: float) -> void:
	if _animation:
		for sound: int in _animation.advance(delta):
			sound_cue.emit(sound)
		if _animation.is_done():
			_animation = null
			animation_finished.emit()
		queue_redraw()
	if _shake_square != Board.NO_SQUARE:
		_shake_elapsed += delta
		if _shake_elapsed >= SHAKE_TIME:
			_shake_square = Board.NO_SQUARE
		queue_redraw()

## True while the piece on `square` is shaking (for tests).
func is_shaking(square: Vector2i) -> bool:
	return _shake_square == square or (_animation != null and _animation.shake_squares().has(square))

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
	aiming = false
	var piece_moves := state.moves().filter(func(m: Move) -> bool: return m.from == square)
	_selected_moves.assign(piece_moves.filter(func(m: Move) -> bool: return m.ability == PieceDef.Ability.NONE))
	_ability_moves.assign(piece_moves.filter(func(m: Move) -> bool: return m.ability != PieceDef.Ability.NONE))
	selection_changed.emit(square)

## The selected square, or NO_SQUARE.
func selected_square() -> Vector2i:
	return _selected

## The selected piece's special-ability moves (empty if it has none to use).
func selected_ability_moves() -> Array[Move]:
	return _ability_moves

## Choose a target for the selected piece's ability: from now on only the
## ability's targets are shown and can be tapped (until the selection changes).
func aim_ability() -> void:
	if _selected == Board.NO_SQUARE or _ability_moves.is_empty():
		return
	aiming = true
	_selected_moves.assign(_ability_moves)
	queue_redraw()

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
	# Pieces the animation is moving are drawn where it says, not on their squares.
	var poses := {}
	var shaking := {}
	var extras := []
	if _animation:
		for piece: Piece in _animation.tracks:
			poses[piece] = _animation.pose(piece)
		shaking = _animation.shake_squares()
		extras = _animation.active_extras()
	_draw_extras(extras, true)
	for rank in range(board.height):
		for file in range(board.width):
			var square := Vector2i(file, rank)
			var piece := board.get_piece(square)
			# While dragging, the piece follows the pointer instead of its square.
			if piece == null or (_dragging and square == _selected) or poses.has(piece) or square in hidden_squares:
				continue
			var rect := _square_rect(square)
			if square == _shake_square:
				rect.position.x += _shake_offset(rect.size.x)
			if shaking.has(square):
				rect.position.x += MoveAnimation.shake_offset(shaking[square]) * rect.size.x
			if square in _check_squares:
				rect.position += tremble(Time.get_ticks_msec() / 1000.0) * rect.size.x
			_draw_piece(piece, rect)
	# Moving pieces last, so they pass over the others.
	for piece: Piece in poses:
		if poses[piece].visible:
			_draw_posed(piece, poses[piece])
	_draw_extras(extras, false)
	# On top of the pieces, so a piece on an edge square doesn't hide its label.
	_draw_coordinates()
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

## The squares along the bottom and left edges as they're shown, with the text
## each gets: [square, "a"] for the file letters along the bottom row, [square,
## "1"] for the rank numbers up the left column. They follow the flip.
func edge_labels() -> Array:
	var board := state.board
	var bottom_rank := board.height - 1 if flipped else 0
	var left_file := board.width - 1 if flipped else 0
	var labels := []
	for file in range(board.width):
		labels.append([Vector2i(file, bottom_rank), Board.FILE_LETTERS[file]])
	for rank in range(board.height):
		labels.append([Vector2i(left_file, rank), str(rank + 1)])
	return labels

## Draw the file letters (bottom-right of the bottom row's squares) and rank
## numbers (top-left of the left column's), each in the other square colour,
## over the pieces.
func _draw_coordinates() -> void:
	var s := _square_size()
	var font_size := int(s * 0.24)
	if font_size < 6:
		return
	var font := ThemeDB.fallback_font
	for label: Array in edge_labels():
		var square: Vector2i = label[0]
		var text: String = label[1]
		var rect := _square_rect(square)
		var light := (square.x + square.y) % 2 == 1
		var color := DARK_SQUARE if light else LIGHT_SQUARE
		if text.is_valid_int():
			var top_left := rect.position + Vector2(s * 0.06, s * 0.06 + font_size * 0.8)
			draw_string(font, top_left, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
		else:
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
			var bottom_right := rect.end - Vector2(width + s * 0.06, s * 0.07)
			draw_string(font, bottom_right, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)

## Sideways wobble that dies away.
func _shake_offset(square_size: float) -> float:
	var t := _shake_elapsed / SHAKE_TIME
	return sin(t * TAU * 3) * square_size * 0.08 * (1.0 - t)

## The picture for this piece now (a Paladin whose shield broke has its own).
func _piece_texture(piece: Piece) -> Texture2D:
	var texture: Texture2D = null
	if piece.def.has_shield() and piece.shield_broken:
		texture = PieceArt.texture_for(piece.def, piece.team, piece_style, "wounded")
	if texture == null:
		texture = texture_for(piece.def, piece.team)
	return texture

## A white silhouette of `texture` (same shape, every pixel white).
static func silhouette(texture: Texture2D) -> Texture2D:
	if not _silhouettes.has(texture):
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		for y in image.get_height():
			for x in image.get_width():
				image.set_pixel(x, y, Color(1, 1, 1, image.get_pixel(x, y).a))
		image.generate_mipmaps()
		_silhouettes[texture] = ImageTexture.create_from_image(image)
	return _silhouettes[texture]

static func clear_cache() -> void:
	_silhouettes.clear()

## The middle of a square on screen, for a position in squares that can be
## between squares (animations).
func _point(pos: Vector2) -> Vector2:
	var s := _square_size()
	var column := state.board.width - 1 - pos.x if flipped else pos.x
	var row := pos.y if flipped else state.board.height - 1 - pos.y
	return _origin() + Vector2(column + 0.5, row + 0.5) * s

## Draw a piece the animation is moving: `pose` is from MoveAnimation.pose.
## It's scaled and turned about the middle of its bottom edge, so a slam
## squashes it down onto the board and a knocked piece tips over.
func _draw_posed(piece: Piece, pose: Dictionary) -> void:
	var s := _square_size()
	var lift: float = pose.lift
	var bottom := _point(pose.pos) + Vector2(0, s / 2 - lift * s)
	draw_set_transform(bottom, pose.angle, pose.scale)
	var texture := _piece_texture(piece)
	var sunk: float = pose.sunk
	if sunk > 0 and texture:
		# Going down into the board: only the part still above it shows.
		var showing := 1.0 - sunk
		var source := Rect2(Vector2.ZERO, texture.get_size() * Vector2(1, showing))
		draw_texture_rect_region(texture, Rect2(-s / 2, -s * showing, s, s * showing), source, Color(1, 1, 1, pose.alpha))
	elif sunk < 1.0:
		var flash: float = pose.flash
		# White at first, turning red as it fades.
		var flash_color := Color.WHITE.lerp(Color(1, 0.15, 0.1), 1.0 - flash)
		_draw_piece(piece, Rect2(-s / 2, -s, s, s), pose.alpha, flash_color * flash)
	draw_set_transform(Vector2.ZERO)

## Draw the animation's extras: `under` = the ones that go below the pieces
## (dust, red flash), otherwise the ones on top (cannonball, arrow, smoke, light).
func _draw_extras(extras: Array, under: bool) -> void:
	var s := _square_size()
	for extra: Dictionary in extras:
		var t: float = extra.t
		var kind: String = extra.kind
		if under != (kind in ["dust", "red_flash"]):
			continue
		match kind:
			"impact":
				# A quick ring and sparks where the pieces collide.
				var center := _point(extra.at)
				var fade := 1.0 - t
				draw_arc(center, s * (0.1 + 0.45 * t), 0, TAU, 24, Color(1, 0.95, 0.8, 0.8 * fade), maxf(2, s * 0.05 * fade))
				for spark in 8:
					var direction := Vector2.from_angle(TAU * spark / 8.0 + 0.3)
					var reach := s * (0.15 + 0.5 * MoveAnimation.ease_out(t))
					draw_line(center + direction * reach * 0.6, center + direction * reach, Color(1, 0.8, 0.3, fade), maxf(2, s * 0.035))
			"dust":
				var base := _point(extra.at) + Vector2(0, s * 0.42)
				for i in 6:
					var side := -1.0 if i % 2 == 0 else 1.0
					var reach := (0.18 + 0.07 * i) * MoveAnimation.ease_out(t)
					var puff := base + Vector2(side * reach * s, -s * (0.02 + 0.03 * (i % 3)) * t)
					draw_circle(puff, s * (0.05 + 0.07 * t), Color(0.86, 0.79, 0.66, 0.7 * (1.0 - t)))
			"red_flash":
				var rect := Rect2(_point(extra.at) - Vector2(s, s) / 2, Vector2(s, s))
				draw_rect(rect, Color(1, 0.1, 0.05, 0.55 * absf(sin(t * TAU)) * (1.0 - 0.4 * t)))
			"light":
				var center := _point(extra.at)
				var fade := 1.0 - t
				draw_circle(center, s * (0.25 + 0.55 * t), Color(1, 0.97, 0.75, 0.35 * fade))
				draw_circle(center, s * (0.15 + 0.3 * t), Color(1, 1, 0.9, 0.6 * fade))
				for ray in 8:
					var direction := Vector2.from_angle(TAU * ray / 8.0 + t)
					draw_line(center + direction * s * 0.2, center + direction * s * (0.35 + 0.45 * t), Color(1, 0.95, 0.6, 0.8 * fade), maxf(2, s * 0.04))
			"ball":
				if t < 1.0:
					var from := _point(extra.from)
					var to := _point(extra.to)
					var height := s * 0.7 + 0.15 * from.distance_to(to)
					var center := from.lerp(to, t) - Vector2(0, 4 * height * t * (1.0 - t))
					draw_circle(center, s * 0.12, Color(0.12, 0.12, 0.13))
					draw_circle(center - Vector2(s, s) * 0.035, s * 0.04, Color(0.5, 0.5, 0.55))
			"smoke":
				var center := _point(extra.at)
				var puff_size: float = extra.size
				var color: Color = extra.color
				for i in 7:
					var direction := Vector2.from_angle(TAU * i / 7.0 + 0.4)
					var puff := center + direction * s * puff_size * 0.5 * MoveAnimation.ease_out(t) - Vector2(0, s * 0.25 * t)
					draw_circle(puff, s * puff_size * (0.3 + 0.35 * t), Color(color, 0.55 * (1.0 - t)))
			"arrow":
				_draw_flying_arrow(extra)

## Crack Shot's arrow: in flight it flies point-first from the Archer to the
## target; then it stays stuck in the target (moving and fading with it), or,
## if it only broke a shield, drops away.
func _draw_flying_arrow(extra: Dictionary) -> void:
	var s := _square_size()
	var from := _point(extra.from)
	var to := _point(extra.to)
	var direction := (to - from).normalized()
	# The point goes in past the middle of the target (impaled).
	var tip := to + direction * s * 0.15
	var alpha := 1.0
	var since_hit: float = _animation.time - extra.end
	if since_hit < 0:
		tip = from.lerp(tip, extra.t)
	elif extra.stuck_to:
		var pose: Variant = _animation.pose(extra.stuck_to)
		if pose == null or not pose.visible:
			return
		var sunk: float = pose.sunk
		tip = _point(pose.pos) + direction * s * 0.15 + Vector2(0, sunk * s)
		alpha = pose.alpha * (1.0 - sunk)
	else:
		var fall := clampf(since_hit / maxf(extra.until - extra.end, 0.001), 0.0, 1.0)
		tip += Vector2(0, s * 0.4 * fall * fall)
		alpha = 1.0 - fall
	var tail := tip - direction * s * 0.8
	var side := Vector2(-direction.y, direction.x)
	draw_line(tail, tip - direction * s * 0.12, Color(0.45, 0.3, 0.15, alpha), maxf(2, s * 0.05))
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * s * 0.2 + side * s * 0.08, tip - direction * s * 0.2 - side * s * 0.08]), Color(0.3, 0.3, 0.32, alpha))
	for fletch in [-1.0, 1.0]:
		draw_line(tail + direction * s * 0.15, tail + side * fletch * s * 0.08, Color(0.85, 0.2, 0.15, alpha), maxf(2, s * 0.04))

## `flash`: a colour the piece flashes (its strength is how bright it is).
func _draw_piece(piece: Piece, rect: Rect2, alpha := 1.0, flash := Color(0, 0, 0)) -> void:
	var texture := _piece_texture(piece)
	if texture:
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))
		var strength := maxf(flash.r, maxf(flash.g, flash.b))
		if strength > 0.01:
			# The flash: the piece's outline filled with the colour, over it.
			draw_texture_rect(silhouette(texture), rect, false, Color(flash / strength, strength * alpha))
		return
	# No image for this piece yet: draw its letter(s) instead, outlined so they
	# show on both square colours.
	var font := ThemeDB.fallback_font
	var font_size := int(rect.size.y * (0.6 if piece.def.symbol.length() == 1 else 0.45))
	if font_size <= 0:
		return  # The board has no size yet.
	var color := Color.WHITE if piece.team == Piece.Team.WHITE else Color.BLACK
	var outline := Color.BLACK if piece.team == Piece.Team.WHITE else Color.WHITE
	color.a = alpha
	outline.a = alpha
	var baseline := Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5 + font_size * 0.36)
	var symbol := piece.def.symbol.to_upper()
	draw_string_outline(font, baseline, symbol, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, maxi(2, int(rect.size.y * 0.04)), outline)
	draw_string(font, baseline, symbol, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)

## A dot on an empty square, a ring around a piece that can be captured.
func _draw_target(move: Move) -> void:
	var rect := _square_rect(move.to)
	var center := rect.get_center()
	if aiming:
		draw_arc(center, rect.size.x * 0.45, 0, TAU, 32, ABILITY_MARK, rect.size.x * 0.1, true)
		return
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

## Where a square is drawn: White's side at the bottom, or Black's if flipped.
func _square_rect(square: Vector2i) -> Rect2:
	var s := _square_size()
	var column := state.board.width - 1 - square.x if flipped else square.x
	var row := square.y if flipped else state.board.height - 1 - square.y
	return Rect2(_origin() + Vector2(column * s, row * s), Vector2(s, s))

func _square_at(pos: Vector2) -> Vector2i:
	if state == null or _square_size() <= 0:
		return Board.NO_SQUARE
	var cell := ((pos - _origin()) / _square_size()).floor()
	var square := Vector2i(int(cell.x), state.board.height - 1 - int(cell.y))
	if flipped:
		square = Vector2i(state.board.width - 1 - int(cell.x), int(cell.y))
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
	var had_selection := _selected != Board.NO_SQUARE
	_selected = Board.NO_SQUARE
	_selected_moves.clear()
	_ability_moves.clear()
	aiming = false
	if had_selection:
		selection_changed.emit(Board.NO_SQUARE)
