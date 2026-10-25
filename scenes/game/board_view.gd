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
## A square marked with a right-click (like chess.com's red squares).
const MARK_TINT := Color(0.92, 0.27, 0.2, 0.75)
const TARGET_MARK := Color(0.1, 0.1, 0.1, 0.25)
const HOVER_TINT := Color(1, 1, 1, 0.3)
## Targets for a special ability (Crack Shot) are ringed in gold.
const ABILITY_MARK := Color(0.95, 0.7, 0.1, 0.9)
## The see-through arrows players draw with the right mouse button, and the
## rings round the squares they right-click.
const ARROW_COLOR := Color(0.1, 0.55, 0.15, 0.6)
## Plusfish's best move, shown when looking over a finished game (blue, so it
## can't be mistaken for a player's own green arrow).
const HINT_ARROW_COLOR := Color(0.15, 0.45, 0.85, 0.6)
## The disc behind the piece a suggested move promotes to or brings back (pale,
## so black and white pieces both show; the rim is the hint arrow's blue).
const HINT_BADGE_COLOR := Color(0.85, 0.91, 1.0, 0.95)
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
## Set from the Animation speed setting (apply_settings); tests set it directly.
@export var move_time := BASE_MOVE_TIME
const BASE_MOVE_TIME := 0.22
## The board helpers (UserSettings.BOARD_HELPERS) that are switched on.
var helpers := {"coordinates": true, "move_dots": true, "last_move": true, "ability_glow": true}
## Settings' "Reduce flashing and shaking".
var reduce_effects := false

## Take the visual settings from UserSettings (when the board is made, and
## again when Settings change them during a game).
func apply_settings() -> void:
	move_time = BASE_MOVE_TIME * UserSettings.ANIMATION_SPEEDS[UserSettings.animation_speed()]
	for helper in UserSettings.BOARD_HELPERS:
		helpers[helper] = UserSettings.board_helper(helper)
	reduce_effects = UserSettings.reduce_effects()
	queue_redraw()
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
## A capture that more than one Jester could take: one move per Jester, until
## the player taps the Jester they want to take the hit (Mac: the attacking
## player chooses). Gold rings close in on those Jesters meanwhile; a tap
## anywhere else calls the capture off. Empty the rest of the time.
var jester_choices: Array[Move] = []

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
## Squares ringed in green by right-clicking them (PC), for planning.
var highlights: Array[Vector2i] = []
## Plusfish's suggestion: [from square, to square], or empty for none. Set by
## the game screen after it shows a position (show_game clears it).
var hint_arrow: Array = []:
	set(value):
		hint_arrow = value
		queue_redraw()
## The piece Plusfish's suggestion promotes to or brings back (Raise Dead):
## {"square", "def", "team", "ring"}, or empty for none. Drawn as a small blue
## badge with the piece's picture in the square's top-right corner; "ring" also
## circles the square (Raise Dead has no arrow). Cleared with hint_arrow.
var hint_piece: Dictionary = {}:
	set(value):
		hint_piece = value
		queue_redraw()
## Where the right button went down (NO_SQUARE when it isn't held).
var _arrow_start := Board.NO_SQUARE
var _arrow_pointer := Vector2.ZERO
## When the right button went down, and whether holding it still can still open
## the piece's card (only on a piece, and not once the pointer leaves its square).

## Plain white silhouettes of piece pictures (for flashes), made when first needed.
static var _silhouettes := {}

func _ready() -> void:
	# Smooth edges when the piece images are shrunk to fit the squares.
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	apply_settings()

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
	# A new move (or a different position) clears the arrows and rings.
	arrows.clear()
	highlights.clear()
	hint_arrow = []
	hint_piece = {}
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

## Squares whose piece is swelling and shrinking back (a Parapet or Squire
## stopping a move): square -> seconds so far.
var _pulses := {}
const PULSE_TIME := 0.35

func pulse(square: Vector2i) -> void:
	_pulses[square] = 0.0
	queue_redraw()

## How much bigger the piece on `square` is drawn now (1 = normal).
func pulse_scale(square: Vector2i) -> float:
	if not _pulses.has(square):
		return 1.0
	return 1.0 + 0.22 * sin(PI * clampf(_pulses[square] / PULSE_TIME, 0.0, 1.0))

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
	if not jester_choices.is_empty():
		var picked: Array[Move] = []
		picked.assign(jester_choices.filter(func(m: Move) -> bool: return m.decoy_square == square))
		jester_choices.clear()
		queue_redraw()
		if not picked.is_empty():
			_choose(picked)
			return true
		# Not one of the Jesters: the capture is called off, and the tap does
		# whatever it would have done.
	if _try_move_to(square):
		return true
	var piece := state.board.get_piece(square)
	if piece and piece.team == state.side_to_move and square != _selected:
		_select(square)
	else:
		# Somewhere the selected piece can't go: it shakes "no", with a buzz. If
		# a Parapet or a Squire is what stops it, that piece swells for a moment
		# instead, with a thock like hitting a wall (Mac).
		if _selected != Board.NO_SQUARE and square != _selected and not aiming:
			_start_shake(_selected)
			var stopped_by := MoveGenerator.blocker(state, _selected, square)
			if stopped_by != Board.NO_SQUARE:
				pulse(stopped_by)
				sound_cue.emit(GameSounds.Sound.BLOCKED)
			else:
				sound_cue.emit(GameSounds.Sound.ILLEGAL)
		_clear_selection()
	queue_redraw()
	return false

## The pointer went down at `pos` (a mouse press or a finger touching the screen).
## Holding still opens the piece's card only for a finger (`touch`): with a
## mouse, the piece card's button (middle click unless changed) does that instead.
func pointer_down(pos: Vector2, touch := true) -> void:
	# A left click clears the arrows and rings, as on chess websites.
	clear_drawings()
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
	# Kings in check tremble, aiming rings close in and sleeping pieces' "Zz"
	# bobs: keep redrawing.
	if not _check_squares.is_empty() or aiming or not jester_choices.is_empty() or (state and state.frozen_piece()) or _any_vampire_aura():
		queue_redraw()

## True if a Vampire has its shield (its aura pulses, so keep redrawing).
func _any_vampire_aura() -> bool:
	if state == null:
		return false
	for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
		for piece: Piece in state.board.pieces_of(team).values():
			if piece.gained_shield:
				return true
	return false

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
	for square: Vector2i in _pulses.keys():
		_pulses[square] += delta
		if _pulses[square] >= PULSE_TIME:
			_pulses.erase(square)
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
## down: a right-click, which marks the square red (or takes the mark off).
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
	elif end == start:
		if highlights.has(start):
			highlights.erase(start)
		else:
			highlights.append(start)
	queue_redraw()

## A right-click at `pos`.
func right_click(pos: Vector2) -> void:
	right_down(pos)
	right_up(pos)

## A middle click at `pos` (PC, Mac): on a piece, asks for its info card.
func middle_click(pos: Vector2) -> void:
	if state == null:
		return
	var square := _square_at(pos)
	var piece := state.board.get_piece(square) if square != Board.NO_SQUARE else null
	if piece:
		_clear_selection()
		queue_redraw()
		info_requested.emit(piece)

## Take away every arrow and ring the player has drawn.
func clear_drawings() -> void:
	if arrows.is_empty() and highlights.is_empty():
		return
	arrows.clear()
	highlights.clear()
	queue_redraw()

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

## Which mouse button does what comes from Settings (MouseBinds; by default
## left = select and move, right = mark squares and draw arrows, middle = the
## piece card). A finger's touch arrives as a pretend ("emulated") left click,
## and always selects and moves.
func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and MouseBinds.can_use(button.button_index):
		var emulated := button.device == InputEvent.DEVICE_ID_EMULATION
		var action := "move" if emulated else MouseBinds.action_for(button.button_index)
		match action:
			"move":
				if button.pressed:
					pointer_down(button.position, emulated or DisplayServer.is_touchscreen_available())
				else:
					pointer_up(button.position)
			"mark":
				if button.pressed:
					right_down(button.position)
				else:
					right_up(button.position)
			"piece_card":
				if button.pressed:
					middle_click(button.position)
		if action != "":
			accept_event()
	var motion := event as InputEventMouseMotion
	if motion:
		pointer_move(motion.position)
		if _arrow_start != Board.NO_SQUARE:
			_arrow_pointer = motion.position
			queue_redraw()

## If the selected piece can move to `square`, choose that move and return true.
func _try_move_to(square: Vector2i) -> bool:
	if (_selected == Board.NO_SQUARE and not aiming) or square == Board.NO_SQUARE or not _can_play():
		return false
	var choices: Array[Move] = []
	choices.assign(_selected_moves.filter(func(m: Move) -> bool: return m.to == square))
	if choices.is_empty():
		return false
	var from := _selected
	_clear_selection()
	queue_redraw()
	if choices.any(func(m: Move) -> bool: return m.decoy_choice):
		# More than one Jester could take this hit: the player taps which.
		jester_choices = choices
		_jester_attacker = from
		return true
	_choose(choices)
	return true

## Where the attacker stands while the player chooses a Jester (it stays tinted).
var _jester_attacker := Board.NO_SQUARE

## Play the move, or ask which one if there are several (promotions, Raise Dead).
func _choose(choices: Array[Move]) -> void:
	if choices.size() == 1:
		move_chosen.emit(choices[0])
	else:
		choice_needed.emit(choices)

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

## Choose where an ability is used when no piece on the board is selected (a
## lost Ghost's Haunt): only `moves`' squares can be tapped, until another square
## is. `marked`: ring them in gold (Haunt doesn't: any empty square will do).
func aim_moves(moves: Array[Move], marked := true) -> void:
	_clear_selection()
	aiming = true
	_aim_unmarked = not marked
	_selected_moves.assign(moves)
	queue_redraw()

## Aiming without gold rings on the targets (see aim_moves).
var _aim_unmarked := false

## Choose a target for the selected piece's ability: from now on only the
## ability's targets are shown and can be tapped (until the selection changes).
func aim_ability() -> void:
	if _selected == Board.NO_SQUARE or _ability_moves.is_empty():
		return
	aiming = true
	_aim_unmarked = false
	_selected_moves.assign(_ability_moves)
	queue_redraw()

func _draw() -> void:
	if state == null:
		return
	var board := state.board
	# A soft shadow under the board lifts it off the background.
	draw_style_box(_board_shadow(), Rect2(_origin(), Vector2(board.width, board.height) * _square_size()))
	for rank in range(board.height):
		for file in range(board.width):
			var square := Vector2i(file, rank)
			draw_rect(_square_rect(square), LIGHT_SQUARE if (file + rank) % 2 == 1 else DARK_SQUARE)
	if not state.history.is_empty():
		var last: Move = state.history.back()
		if helpers.last_move:
			draw_rect(_square_rect(last.from), LAST_MOVE_TINT)
			draw_rect(_square_rect(last.to), LAST_MOVE_TINT)
	if _selected != Board.NO_SQUARE:
		draw_rect(_square_rect(_selected), SELECTED_TINT)
	# Squares marked red with a right-click, for planning (Mac).
	for square in highlights:
		draw_rect(_square_rect(square), MARK_TINT)
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
	# The check's flash makes the king's red border flare (see _draw_check_border).
	_check_flash = 0.0
	for extra: Dictionary in extras:
		if extra.kind == "red_flash":
			var t: float = extra.t
			if not reduce_effects:
				_check_flash = maxf(_check_flash, absf(sin(t * TAU)) * (1.0 - 0.4 * t))
	_draw_extras(extras, 0)
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
			if square in _check_squares and not reduce_effects:
				rect.position += tremble(Time.get_ticks_msec() / 1000.0) * rect.size.x
			if _pulses.has(square):
				var grow := pulse_scale(square)
				rect = Rect2(rect.get_center() - rect.size * grow / 2, rect.size * grow)
			# Choosing a target for its ability: a flickering aura of fire in its
			# ability's colours (Mac).
			if aiming and square == _selected:
				_draw_power_aura(rect, piece.def.ability_gradient())
			if piece.gained_shield:
				_draw_vampire_aura(piece, rect)
			_draw_piece(piece, rect)
			if piece == state.frozen_piece():
				_draw_asleep(rect)
	# Behind the moving pieces but over the others (the Full Moon's moon).
	_draw_extras(extras, 1)
	# Moving pieces last, so they pass over the others.
	for piece: Piece in poses:
		if poses[piece].visible:
			_draw_posed(piece, poses[piece])
	_draw_extras(extras, 2)
	# On top of the pieces, so a piece on an edge square doesn't hide its label.
	if helpers.coordinates:
		_draw_coordinates()
	# Where the chosen piece can go (Board helpers: Move dots); an ability's
	# targets always show while aiming, as they're needed to use it.
	if not (aiming and _aim_unmarked) and (helpers.move_dots or aiming):
		for move in _selected_moves:
			_draw_target(move)
	# Choosing which Jester takes the hit: the attacker stays tinted and gold
	# rings close in on each Jester that could (always shown: they're needed).
	if not jester_choices.is_empty():
		if _jester_attacker != Board.NO_SQUARE:
			draw_rect(_square_rect(_jester_attacker), SELECTED_TINT)
		for move in jester_choices:
			_draw_closing_rings(_square_rect(move.decoy_square))
	if hint_arrow.size() == 2 and hint_arrow[0] != hint_arrow[1]:
		_draw_arrow(square_center(hint_arrow[0]), square_center(hint_arrow[1]), HINT_ARROW_COLOR)
	if not hint_piece.is_empty():
		_draw_hint_piece(hint_piece)
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

## The badge for hint_piece: the piece's picture on a pale disc with a blue rim
## in the square's top-right corner (clear of the coordinates), plus a ring
## round the square if asked for.
func _draw_hint_piece(hint: Dictionary) -> void:
	var rect := _square_rect(hint["square"])
	var s := rect.size.x
	if hint.get("ring", false):
		draw_arc(rect.get_center(), s * 0.45, 0.0, TAU, 48, HINT_ARROW_COLOR, s * 0.07, true)
	var radius := s * 0.28
	var center := rect.position + Vector2(s - radius - s * 0.01, radius + s * 0.01)
	draw_circle(center, radius, HINT_BADGE_COLOR)
	draw_arc(center, radius, 0.0, TAU, 32, HINT_ARROW_COLOR.lerp(Color(0.15, 0.45, 0.85), 0.7), maxf(1.5, s * 0.035), true)
	var picture := radius * 1.75
	var def: PieceDef = hint["def"]
	_draw_piece(Piece.new(def, hint["team"]), Rect2(center - Vector2(picture, picture) / 2, Vector2(picture, picture)), 1.0, Color(0, 0, 0), def)

## A see-through arrow from the middle of one square to the middle of another,
## drawn as one shape (so the overlapping parts don't look darker).
func _draw_arrow(from: Vector2, to: Vector2, color := ARROW_COLOR) -> void:
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
	draw_colored_polygon(points, color)

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
	var font := UiStyle.font(UiStyle.SEMIBOLD)
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
func _piece_texture(piece: Piece, as_def: PieceDef = null, intact := false) -> Texture2D:
	if as_def:
		return texture_for(as_def, piece.team)
	var texture: Texture2D = null
	if piece.def.has_shield() and piece.shield_broken and not intact:
		texture = PieceArt.texture_for(piece.def, piece.team, piece_style, "wounded")
	if texture == null:
		texture = texture_for(piece.def, piece.team)
	return texture

## A piece whose special ability hasn't been used yet (it glows, so both
## players can see which pieces can still use theirs), whether or not it has
## moved yet (an ability needs a move first, Mac, Oct 2026).
static func has_ability_ready(piece: Piece) -> bool:
	return piece.has_unused_ability()

## A faint glow around the edge of a piece in its ability's colours: its
## silhouette drawn slightly offset all the way round, behind it.
func _draw_ability_glow(texture: Texture2D, rect: Rect2, colors: PackedColorArray, alpha: float) -> void:
	var outline := silhouette(texture)
	var reach := rect.size.x * 0.035
	for i in 12:
		var offset := Vector2.from_angle(TAU * i / 12.0) * reach
		var color := colors[0].lerp(colors[1], 0.5 + 0.5 * sin(TAU * i / 12.0)).lerp(Color.WHITE, 0.25)
		draw_texture_rect(outline, Rect2(rect.position + offset, rect.size), false, Color(color, 0.22 * alpha))

## How strongly the king's check border is flaring now (0 = steady).
var _check_flash := 0.0
const CHECK_BORDER := Color(0.9, 0.08, 0.06)

func _is_checked_king(piece: Piece) -> bool:
	for square in _check_squares:
		if state.board.get_piece(square) == piece:
			return true
	return false

## A king in check gets a solid red border round its outline (Mac: instead of
## a red square), flaring wider and glowing as the check flashes.
func _draw_check_border(texture: Texture2D, rect: Rect2, alpha: float) -> void:
	var outline := silhouette(texture)
	var reach := rect.size.x * (0.038 + 0.025 * _check_flash)
	if _check_flash > 0.01:
		for i in 16:
			var glow := Vector2.from_angle(TAU * i / 16.0) * reach * 2.2
			draw_texture_rect(outline, Rect2(rect.position + glow, rect.size), false, Color(CHECK_BORDER, 0.25 * _check_flash * alpha))
	for i in 16:
		var offset := Vector2.from_angle(TAU * i / 16.0) * reach
		draw_texture_rect(outline, Rect2(rect.position + offset, rect.size), false, Color(CHECK_BORDER, alpha))

## A white silhouette of `texture` (same shape, every pixel white).
static func silhouette(texture: Texture2D) -> Texture2D:
	if not _silhouettes.has(texture):
		var image := texture.get_image()
		if image.is_compressed():
			image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		# Every pixel's colour made white, its see-through-ness kept: brightness 0
		# makes it black, then contrast -1 turns black into white. Done by Godot
		# itself, it's much quicker than going pixel by pixel in GDScript, which
		# held up the first frame each new piece glowed or flashed (worst on phones).
		image.adjust_bcs(0.0, -1.0, 1.0)
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

## A Vampire's shield (Mac): a deep dark red aura round it, slowly pulsing,
## gone once the shield is broken.
func _draw_vampire_aura(piece: Piece, rect: Rect2) -> void:
	var texture := _piece_texture(piece)
	if texture == null:
		return
	var pulse_amount := 0.8 + 0.2 * sin(Time.get_ticks_msec() / 1000.0 * 3.0)
	var center := rect.get_center() + Vector2(0, rect.size.y * 0.05)
	var s := rect.size.x
	# A soft dark red haze behind it, and its outline glowing deep red.
	for ring in 4:
		draw_circle(center, s * (0.55 - 0.1 * ring) * (0.95 + 0.08 * pulse_amount), Color(0.4, 0.0, 0.04, 0.16 * pulse_amount))
	var dark_red := PackedColorArray([Color(0.5, 0.0, 0.05), Color(0.8, 0.05, 0.12)])
	_draw_ability_glow(texture, rect.grow(s * 0.06), dark_red, pulse_amount)
	_draw_ability_glow(texture, rect.grow(s * 0.02), dark_red, pulse_amount)

## While a piece's ability is being aimed (Mac): an anime power aura round it,
## smoke in the ability's colours streaming up off it and drifting away, with a
## sparkle twinkling now and then.
func _draw_power_aura(rect: Rect2, colors: PackedColorArray) -> void:
	var s := rect.size.x
	var seconds := Time.get_ticks_msec() / 1000.0
	var center := rect.get_center()
	var bright: Color = colors[colors.size() - 1]
	draw_circle(center, s * 0.55, Color(bright, 0.12 + 0.05 * sin(seconds * 4.0)))
	# Wisps rise from round the piece, swell and fade as they float up.
	for i in 16:
		var k := fposmod(seconds * 0.55 + i / 16.0, 1.0)
		var side := (fposmod(i * 0.618, 1.0) - 0.5) * 0.9
		var drift := sin(seconds * 1.7 + i * 2.3) * s * 0.08 * k
		var pos := Vector2(center.x + side * s + drift, rect.position.y + s * (0.85 - 1.15 * k))
		var color: Color = colors[0].lerp(bright, fposmod(i * 0.37, 1.0))
		draw_circle(pos, s * (0.1 + 0.14 * k), Color(color, 0.32 * sin(PI * k)))
	# Now and then, a sparkle.
	for i in 4:
		var phase := fposmod(seconds * 0.7 + i * 0.29, 1.0)
		if phase > 0.25:
			continue
		var twinkle := sin(PI * phase / 0.25)
		var spot := Vector2(fposmod(i * 0.73 + floorf(seconds * 0.7 + i * 0.29) * 0.37, 1.0) - 0.5, fposmod(i * 0.41 + floorf(seconds * 0.7 + i * 0.29) * 0.53, 1.0) - 0.6)
		_draw_star(center + spot * s * 1.2, s * 0.11 * twinkle, Color(bright.lerp(Color.WHITE, 0.7), twinkle))

## A music note (a quaver): a filled oval head with a stem and a flag.
func _draw_note(at: Vector2, height: float, color: Color) -> void:
	var outline := Color(0.3, 0.15, 0.0, color.a)
	var head := at + Vector2(-height * 0.2, height * 0.35)
	var stem_top := head + Vector2(height * 0.2, -height * 0.8)
	for pass_color: Color in [outline, color]:
		var grow := height * 0.06 if pass_color == outline else 0.0
		draw_set_transform(head, -0.4, Vector2(1.35, 1.0))
		draw_circle(Vector2.ZERO, height * 0.17 + grow, pass_color)
		draw_set_transform(Vector2.ZERO)
		draw_line(head + Vector2(height * 0.2, 0), stem_top, pass_color, height * 0.09 + grow * 2)
		draw_line(stem_top, stem_top + Vector2(height * 0.25, height * 0.25), pass_color, height * 0.09 + grow * 2)

## A piece put to sleep by Song of Slumber (it can't move this turn): a "Zz" in
## the top-right corner of its square, in the Bard's gold, gently bobbing.
func _draw_asleep(rect: Rect2) -> void:
	var s := rect.size.x
	var font := UiStyle.bold()
	var bob := sin(Time.get_ticks_msec() / 1000.0 * 2.5) * s * 0.025
	for i in 2:
		var size_px := int(s * (0.34 if i == 0 else 0.25))
		var at := rect.position + Vector2(s * (0.56 + 0.2 * i), s * (0.36 - 0.15 * i) + bob * (1 - 2 * i))
		draw_string_outline(font, at, "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, maxi(2, int(s * 0.035)), Color(0.25, 0.12, 0.0))
		draw_string(font, at, "Z", HORIZONTAL_ALIGNMENT_LEFT, -1, size_px, Color(1.0, 0.82, 0.35))

## Draw a piece the animation is moving: `pose` is from MoveAnimation.pose.
## It's scaled and turned about the middle of its bottom edge, so a slam
## squashes it down onto the board and a knocked piece tips over.
func _draw_posed(piece: Piece, pose: Dictionary) -> void:
	var s := _square_size()
	var lift: float = pose.lift
	var bottom := _point(pose.pos) + Vector2(0, s / 2 - lift * s)
	# A pose can show the piece as another type ("as_def": a Werewolf still a
	# Werewolf while it turns into a wolf).
	var as_def: PieceDef = pose.get("as_def")
	var intact: bool = pose.get("intact", false)
	var texture := _piece_texture(piece, as_def, intact)
	var shadow: float = pose.shadow
	if shadow > 0 and texture:
		# A soft shadow left on the board below a piece lifted towards the player.
		var ground := Rect2(_point(pose.pos) - Vector2(s, s) / 2 + Vector2(s, s) * 0.05 * shadow, Vector2(s, s))
		draw_texture_rect(silhouette(texture), ground, false, Color(0, 0, 0, 0.3 * shadow))
	draw_set_transform(bottom, pose.angle, pose.scale)
	var sunk: float = pose.sunk
	if sunk > 0 and texture:
		# Going down into the board: only the part still above it shows.
		var showing := 1.0 - sunk
		var source := Rect2(Vector2.ZERO, texture.get_size() * Vector2(1, showing))
		draw_texture_rect_region(texture, Rect2(-s / 2, -s * showing, s, s * showing), source, Color(1, 1, 1, pose.alpha))
	elif sunk < 1.0:
		var flash: float = pose.flash
		# White at first, turning red as it fades.
		var flash_color: Color = pose.get("flash_color", Color.WHITE.lerp(Color(1, 0.15, 0.1), 1.0 - flash))
		if intact and piece.def.shield_on_capture:
			_draw_vampire_aura(piece, Rect2(-s / 2, -s, s, s))
		_draw_piece(piece, Rect2(-s / 2, -s, s, s), pose.alpha, flash_color * flash, as_def, intact)
	draw_set_transform(Vector2.ZERO)

## Draw the animation's extras: `under` = the ones that go below the pieces
## (dust, red flash), otherwise the ones on top (cannonball, arrow, smoke, light).
func _draw_extras(extras: Array, layer: int) -> void:
	var s := _square_size()
	for extra: Dictionary in extras:
		var t: float = extra.t
		var kind: String = extra.kind
		var its_layer := 0 if kind in ["dust", "red_flash", "rising_smoke"] else (1 if kind in ["moon", "blood"] else 2)
		if layer != its_layer:
			continue
		match kind:
			"speed_lines":
				# Anime dash lines streaking along the path, fading behind.
				var from := _point(extra.from)
				var to := _point(extra.to)
				var along := (to - from).normalized()
				var side := Vector2(-along.y, along.x)
				var fade := 1.0 - t
				for i in 7:
					var offset := (i - 3) * s * 0.13
					var head := from.lerp(to, minf(1.0, t * 1.4 + 0.1 * (i % 3)))
					var tail := head - along * s * (0.8 + 0.3 * (i % 2))
					draw_line(tail + side * offset, head + side * offset, Color(1, 1, 1, 0.75 * fade), maxf(1.5, s * 0.025))
			"confetti":
				# A burst of paper confetti that flutters down.
				var center := _point(extra.at)
				var colours := [Color("#e74c3c"), Color("#f1c40f"), Color("#2ecc71"), Color("#3498db"), Color("#9b59b6"), Color("#ff8fd0")]
				for i in 26:
					var angle := TAU * i / 26.0 + i * 0.37
					var speed := s * (0.9 + 0.6 * fposmod(i * 0.618, 1.0))
					var pos := center + Vector2.from_angle(angle) * speed * MoveAnimation.ease_out(t) + Vector2(0, s * 1.2 * t * t)
					var spin := t * 12.0 + i
					var size_px := Vector2(s * 0.09, s * 0.05)
					draw_set_transform(pos, spin, Vector2(1, absf(cos(spin * 1.3))))
					draw_rect(Rect2(-size_px / 2, size_px), Color(colours[i % colours.size()], 1.0 - smoothstep(0.7, 1.0, t)))
					draw_set_transform(Vector2.ZERO)
			"blood":
				# A light spray of blood droplets, and a small splash that fades.
				var center := _point(extra.at)
				var fade := 1.0 - smoothstep(0.5, 1.0, t)
				draw_circle(center + Vector2(0, s * 0.38), s * 0.14 * MoveAnimation.ease_out(minf(1.0, t * 3.0)), Color(0.55, 0.0, 0.05, 0.35 * fade))
				for i in 14:
					var angle := -PI * (0.05 + 0.9 * i / 13.0)
					var reach := s * (0.5 + 0.3 * fposmod(i * 0.7, 1.0)) * MoveAnimation.ease_out(t)
					var drop := center + Vector2.from_angle(angle) * reach + Vector2(0, s * 0.7 * t * t)
					draw_circle(drop, s * (0.018 + 0.012 * (i % 3)), Color(0.72, 0.02, 0.06, fade))
			"moon":
				# A huge full moon, behind the rising Werewolf.
				var center := _point(extra.at) - Vector2(0, s * 0.55)
				var alpha := smoothstep(0.0, 0.2, t) * (1.0 - smoothstep(0.85, 1.0, t))
				var r := s * 1.35
				draw_circle(center, r * 1.25, Color(0.85, 0.9, 1.0, 0.18 * alpha))
				draw_circle(center, r, Color(0.96, 0.95, 0.86, 0.92 * alpha))
				for crater: Array in [[Vector2(-0.35, -0.25), 0.22], [Vector2(0.3, 0.1), 0.16], [Vector2(-0.1, 0.4), 0.12], [Vector2(0.4, -0.4), 0.09], [Vector2(-0.45, 0.2), 0.08]]:
					draw_circle(center + (crater[0] as Vector2) * r, r * float(crater[1]), Color(0.82, 0.82, 0.75, 0.7 * alpha))
			"rising_smoke":
				# White-blue smoke rising up out of the square, wisp after wisp.
				var color: Color = extra.color
				var base := _point(extra.at) + Vector2(0, s * 0.45)
				for i in 12:
					var k := fposmod(t * 1.6 + i / 12.0, 1.0)
					if t * 1.6 + i / 12.0 < 1.0 and k > t * 3.0:
						continue
					var x := base.x + s * 0.32 * sin(i * 2.1 + k * 4.0)
					var puff := Vector2(x, base.y - s * 1.3 * k)
					draw_circle(puff, s * (0.08 + 0.2 * k), Color(color, 0.5 * sin(PI * k) * (1.0 - smoothstep(0.8, 1.0, t))))
			"lightning":
				# A jagged bolt striking the square from the top of the board,
				# flashing twice.
				var strike := _point(extra.at)
				var top := Vector2(strike.x + s * 0.6, _origin().y - s * 0.2)
				var flash := (1.0 - t) * (1.0 if reduce_effects else 0.6 + 0.4 * absf(sin(t * TAU * 2.0)))
				var points := PackedVector2Array([top])
				var pieces := 8
				for i in range(1, pieces):
					var k := float(i) / pieces
					var zig := s * 0.35 * (1.0 if i % 2 == 0 else -1.0) * (1.0 - k)
					points.append(top.lerp(strike, k) + Vector2(zig, 0))
				points.append(strike)
				var color: Color = extra.get("color", Color(0.9, 0.85, 1.0))
				draw_polyline(points, Color(color, 0.7 * flash), maxf(8, s * 0.3), true)
				draw_polyline(points, Color(1, 1, 1, flash), maxf(4, s * 0.11), true)
				draw_circle(strike, s * 0.5 * flash, Color(color, 0.4 * flash))
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
				pass  # Drawn as the king's border flaring (_check_flash).
			"light":
				var center := _point(extra.at) - Vector2(0, s * extra.get("lift", 0.0))
				var r: float = s * extra.get("size", 1.0)
				var fade := 1.0 - t
				# Golden by default (promotion); an ability's glow has its own colour.
				var glow: Color = extra.get("color", Color(1, 0.95, 0.6))
				draw_circle(center, r * (0.25 + 0.55 * t), Color(glow.lerp(Color.WHITE, 0.5), 0.35 * fade))
				draw_circle(center, r * (0.15 + 0.3 * t), Color(glow.lerp(Color.WHITE, 0.75), 0.6 * fade))
				for ray in 8:
					var direction := Vector2.from_angle(TAU * ray / 8.0 + t)
					draw_line(center + direction * r * 0.2, center + direction * r * (0.35 + 0.45 * t), Color(glow, 0.8 * fade), maxf(2, r * 0.04))
			"notes":
				# Golden music notes drifting from the Bard to its target, bobbing.
				for i in 3:
					var k := clampf(t * 1.4 - i * 0.2, 0.0, 1.0)
					if k <= 0.0 or k >= 1.0:
						continue
					var pos := _point((extra.from as Vector2).lerp(extra.to, k)) \
							+ Vector2(0, -s * (0.25 + 0.12 * sin(k * TAU * 1.5 + i)))
					_draw_note(pos, s * 0.34, Color(1.0, 0.82, 0.3, sin(PI * k)))
			"impact_frame":
				# An anime impact frame: for an instant the board goes stark white,
				# with black lines bursting out from the hit. Not with Reduce
				# flashing and shaking.
				if reduce_effects:
					continue
				var center := _point(extra.at)
				var strength := 1.0 - t
				var board_rect := Rect2(_origin(), Vector2(state.board.width, state.board.height) * s)
				draw_rect(board_rect, Color(1, 1, 1, 0.75 * strength))
				for i in 18:
					var direction := Vector2.from_angle(TAU * i / 18.0 + 0.2)
					var inner := s * (0.35 + 0.15 * (i % 3))
					var outer := s * (2.5 + 1.0 * (i % 2))
					draw_line(center + direction * inner, center + direction * outer, Color(0, 0, 0, 0.85 * strength), maxf(2, s * (0.08 - 0.02 * (i % 3))))
			"swirl":
				# Streaks of light whirling round the rising piece, faster and faster.
				var center := _point(extra.at) - Vector2(0, s * extra.get("lift", 0.5) * smoothstep(0.0, 0.6, t))
				var spin := 10.0 * t * t
				var fade := sin(PI * t)
				for i in 3:
					var start_angle := spin + TAU * i / 3.0
					draw_arc(center, s * (0.6 - 0.08 * i), start_angle, start_angle + 1.6, 16, Color(1, 0.95, 0.7, 0.8 * fade), maxf(2, s * 0.05))
					draw_arc(center, s * (0.6 - 0.08 * i), start_angle + 1.6, start_angle + 2.2, 8, Color(1, 1, 1, 0.5 * fade), maxf(1, s * 0.025))
			"energy":
				# Specks of light streaming up into the piece from round its square.
				var target := _point(extra.at) - Vector2(0, s * 0.5)
				for i in 14:
					var k := fposmod(t * 2.2 + i / 14.0, 1.0)
					var angle := TAU * i / 14.0 + i * 0.9
					var from := target + Vector2.from_angle(angle) * s * 1.1 + Vector2(0, s * 0.4)
					var pos := from.lerp(target, k * k)
					draw_circle(pos, s * 0.03 * (1.0 - k * 0.5), Color(1, 0.95, 0.75, sin(PI * k) * (1.0 - smoothstep(0.85, 1.0, t))))
			"shockwave":
				# A ring of light bursting outwards.
				var center := _point(extra.at) - Vector2(0, s * extra.get("lift", 0.0))
				var radius := s * (0.3 + 1.6 * MoveAnimation.ease_out(t))
				draw_arc(center, radius, 0, TAU, 48, Color(1, 0.97, 0.8, 0.85 * (1.0 - t)), maxf(2, s * 0.12 * (1.0 - t)))
				draw_arc(center, radius * 0.8, 0, TAU, 40, Color(1, 1, 1, 0.5 * (1.0 - t)), maxf(1, s * 0.04 * (1.0 - t)))
			"sparkles":
				# Little four-pointed stars twinkling round a rising piece.
				var center := _point(extra.at) - Vector2(0, s * 0.45 * smoothstep(0.0, 0.4, t))
				for i in 10:
					var angle := TAU * i / 10.0 + t * 3.0
					var radius := s * (0.55 + 0.25 * sin(i * 1.7 + t * 9.0))
					var twinkle := absf(sin(t * 14.0 + i * 2.1)) * sin(PI * t)
					_draw_star(center + Vector2.from_angle(angle) * radius, s * 0.09 * twinkle, Color(1, 0.95, 0.7, twinkle))
			"slash":
				# A white streak across the passed pawn.
				var center := _point(extra.at)
				var along := (_point(extra.at + (extra.dir as Vector2)) - center).normalized()
				var reach := s * 0.6 * MoveAnimation.ease_out(minf(1.0, t * 2.0))
				var fade := 1.0 - smoothstep(0.4, 1.0, t)
				draw_line(center - along * s * 0.6, center - along * s * 0.6 + along * reach * 2.0, Color(1, 1, 1, 0.9 * fade), maxf(3, s * 0.07))
				draw_line(center - along * s * 0.5, center - along * s * 0.5 + along * reach * 1.6, Color(1, 0.85, 0.5, 0.6 * fade), maxf(2, s * 0.03))
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

## A small four-pointed star (a sparkle).
func _draw_star(center: Vector2, radius: float, color: Color) -> void:
	if radius < 0.5:
		return
	var thin := radius * 0.28
	draw_colored_polygon(PackedVector2Array([
		center + Vector2(0, -radius), center + Vector2(thin, -thin), center + Vector2(radius, 0), center + Vector2(thin, thin),
		center + Vector2(0, radius), center + Vector2(-thin, thin), center + Vector2(-radius, 0), center + Vector2(-thin, -thin),
	]), color)

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
	# A streak of light all the way back to the Archer (Mac), in the ability's
	# colour round a white core, fading away just after the arrow strikes.
	const STREAK_FADE := 0.4
	if extra.has("trail") and since_hit < STREAK_FADE:
		var glow: Color = extra.trail
		var fade := 1.0 - clampf(since_hit / STREAK_FADE, 0.0, 1.0)
		var start := from + direction * s * 0.3
		var length := start.distance_to(tail)
		var steps := 10
		for i in steps:
			# Brightest at the arrow, dimmer back towards the Archer.
			var k := float(i) / steps
			var a := tail - direction * length * k
			var b := tail - direction * length * (k + 1.0 / steps)
			var strength := (1.0 - k * 0.6) * fade
			var narrow := 1.0 - k * 0.5
			draw_line(a, b, Color(glow, 0.22 * strength), maxf(5, s * 0.4 * narrow))
			draw_line(a, b, Color(glow.lerp(Color.WHITE, 0.2), 0.75 * strength), maxf(3, s * 0.2 * narrow))
			draw_line(a, b, Color(1, 1, 1, strength), maxf(2, s * 0.07 * narrow))
	# A glowing trail in the ability's colour behind the arrow in flight (Mac).
	if since_hit < 0 and extra.has("trail"):
		var trail: Color = extra.trail
		var length := minf(from.distance_to(tail), s * 2.2)
		for i in 6:
			var k := float(i) / 6.0
			var a := tail - direction * length * k
			var b := tail - direction * length * (k + 1.0 / 6.0)
			draw_line(a, b, Color(trail.lerp(Color.WHITE, 0.3), 0.75 * (1.0 - k)), maxf(2, s * (0.12 - 0.015 * i)))
	draw_line(tail, tip - direction * s * 0.12, Color(0.45, 0.3, 0.15, alpha), maxf(2, s * 0.05))
	draw_colored_polygon(PackedVector2Array([tip, tip - direction * s * 0.2 + side * s * 0.08, tip - direction * s * 0.2 - side * s * 0.08]), Color(0.3, 0.3, 0.32, alpha))
	for fletch in [-1.0, 1.0]:
		draw_line(tail + direction * s * 0.15, tail + side * fletch * s * 0.08, Color(0.85, 0.2, 0.15, alpha), maxf(2, s * 0.04))

## `flash`: a colour the piece flashes (its strength is how bright it is).
func _draw_piece(piece: Piece, rect: Rect2, alpha := 1.0, flash := Color(0, 0, 0), as_def: PieceDef = null, intact := false) -> void:
	var texture := _piece_texture(piece, as_def, intact)
	if texture and _is_checked_king(piece):
		_draw_check_border(texture, rect, alpha)
	if texture:
		if has_ability_ready(piece) and as_def == null and helpers.ability_glow:
			_draw_ability_glow(texture, rect, piece.def.glow_gradient(), alpha)
		draw_texture_rect(texture, rect, false, Color(1, 1, 1, alpha))
		var strength := maxf(flash.r, maxf(flash.g, flash.b))
		if strength > 0.01:
			# The flash: the piece's outline filled with the colour, over it.
			draw_texture_rect(silhouette(texture), rect, false, Color(flash / strength, strength * alpha))
		return
	# No image for this piece yet: draw its letter(s) instead, outlined so they
	# show on both square colours.
	var font := UiStyle.bold()
	var font_size := int(rect.size.y * (0.6 if (as_def if as_def else piece.def).symbol.length() == 1 else 0.45))
	if font_size <= 0:
		return  # The board has no size yet.
	var color := Color.WHITE if piece.team == Piece.Team.WHITE else Color.BLACK
	var outline := Color.BLACK if piece.team == Piece.Team.WHITE else Color.WHITE
	color.a = alpha
	outline.a = alpha
	var baseline := Vector2(rect.position.x, rect.position.y + rect.size.y * 0.5 + font_size * 0.36)
	var symbol := (as_def if as_def else piece.def).symbol.to_upper()
	draw_string_outline(font, baseline, symbol, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, maxi(2, int(rect.size.y * 0.04)), outline)
	draw_string(font, baseline, symbol, HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, font_size, color)

## A dot on an empty square, a ring around a piece that can be captured.
func _draw_target(move: Move) -> void:
	var rect := _square_rect(move.to)
	var center := rect.get_center()
	if aiming:
		_draw_closing_rings(rect)
		return
	if move.is_capture() and not state.board.is_empty(move.to):
		draw_arc(center, rect.size.x * 0.45, 0, TAU, 32, TARGET_MARK, rect.size.x * 0.08, true)
	else:
		draw_circle(center, rect.size.x * 0.16, TARGET_MARK)

## Gold rings that close in on the square `rect` (Mac's design, for an
## ability's targets): each fades in large, then shrinks and fades away as the
## next one fades in.
func _draw_closing_rings(rect: Rect2) -> void:
	var center := rect.get_center()
	var seconds := Time.get_ticks_msec() / 1000.0
	for ring in 2:
		var t := fmod(seconds * 0.8 + ring * 0.5, 1.0)
		var alpha := smoothstep(0.0, 0.2, t) * (1.0 - t)
		var radius := rect.size.x * lerpf(0.62, 0.12, t)
		draw_arc(center, radius, 0, TAU, 40, Color(ABILITY_MARK, ABILITY_MARK.a * alpha), rect.size.x * 0.08, true)

func _square_size() -> float:
	return minf(size.x / state.board.width, size.y / state.board.height)

## Where the board's top-left corner is inside this control.
var _shadow: StyleBoxFlat

func _board_shadow() -> StyleBoxFlat:
	if _shadow == null:
		_shadow = StyleBoxFlat.new()
		_shadow.bg_color = DARK_SQUARE
		_shadow.shadow_color = Color(0, 0, 0, 0.45)
		_shadow.shadow_size = 22
		_shadow.shadow_offset = Vector2(0, 8)
	return _shadow

func board_origin() -> Vector2:
	return _origin() if state else Vector2.ZERO

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

## Let go of the chosen piece (the Cancel selection shortcut), also when aiming
## an ability.
func cancel_selection() -> void:
	_clear_selection()
	queue_redraw()

func _clear_selection() -> void:
	var had_selection := _selected != Board.NO_SQUARE or aiming
	_selected = Board.NO_SQUARE
	_selected_moves.clear()
	_ability_moves.clear()
	aiming = false
	jester_choices.clear()
	if had_selection:
		selection_changed.emit(Board.NO_SQUARE)
