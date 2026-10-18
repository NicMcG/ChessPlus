extends Control

## The game screen: connects the board view, the text around it and the buttons
## to a GameState. Either two players share the device (pass and play), or one
## player plays the practice bot.

## Pressed "Menu". Only shown if something is listening (the main scene).
signal menu_requested

## If set, games start from this FEN position instead of the standard one. Any
## piece in res://data/pieces/ can appear in it (e.g. "E"/"e" for elephants).
@export var start_fen := ""

## If both are set (by the main scene, before the screen opens), games are
## played with these armies, and "New game" replays them.
var white_army: Army
var black_army: Army

## The bot's side (Piece.Team), or -1 when two people are playing. Set by the
## main scene, with the bot's level, before the screen opens.
var bot_team := -1
var bot_level := PracticeBot.Level.MEDIUM
## Frames to wait before the bot thinks, so the screen can show the player's move
## and "Bot is thinking..." first (thinking freezes the screen briefly). Tests use 0.
var bot_delay_frames := 2
var bot: PracticeBot
## True from the moment it's the bot's turn until it has moved.
var bot_thinking := false
## Counts bot turns, so a turn that was overtaken (New game, Menu) is dropped.
var _bot_turn_id := 0
## A saved game to continue instead of starting a new one (set by the main scene).
var resume: SavedGame
var sounds: GameSounds

@onready var board_view: BoardView = %BoardView
@onready var status_label: Label = %Status
@onready var moves_label: Label = %Moves
@onready var new_game_button: Button = %NewGame
@onready var undo_button: Button = %Undo
@onready var menu_button: Button = %Menu
@onready var promotion_overlay: ColorRect = %PromotionOverlay
@onready var promotion_choices: HBoxContainer = %PromotionChoices
@onready var _layout: VBoxContainer = $Margin/Layout
@onready var _board_area: Control = $Margin/Layout/BoardArea
@onready var _moves_scroll: Control = $Margin/Layout/MovesScroll
@onready var _buttons: Control = $Margin/Layout/Buttons
## On wide screens: the board on the left, `_side` (status, moves, buttons) on the right.
var _wide_box: HBoxContainer
var _side: VBoxContainer
var wide := false

var state: GameState

## Shown where the move list goes, until the first move.
const TIP := "Tip: hold any piece to see how it moves."

func _ready() -> void:
	sounds = GameSounds.new()
	add_child(sounds)
	_build_wide_layout()
	resized.connect(fit_layout)
	fit_layout()
	board_view.move_chosen.connect(play)
	board_view.choice_needed.connect(_ask_which_move)
	board_view.info_requested.connect(func(piece: Piece) -> void:
		PieceInfo.open(self, piece.def, piece.team))
	new_game_button.pressed.connect(new_game)
	undo_button.pressed.connect(undo)
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	menu_button.visible = not menu_requested.get_connections().is_empty()
	promotion_overlay.gui_input.connect(_on_overlay_input)
	if is_bot_game():
		bot = PracticeBot.new(bot_level)
	if resume:
		_continue_saved_game(resume)
	else:
		new_game()

func new_game() -> void:
	if white_army and black_army:
		state = ArmySetup.create_game(white_army, black_army, StandardSetup.create_rules())
	elif start_fen.is_empty():
		state = StandardSetup.create_game()
	else:
		state = Fen.parse(start_fen, PieceCatalog.all_defs(), StandardSetup.create_rules())
	_show_new_state()

## The side-by-side layout for wide screens, unused (hidden) until needed.
func _build_wide_layout() -> void:
	_wide_box = HBoxContainer.new()
	_wide_box.add_theme_constant_override("separation", 24)
	_wide_box.hide()
	_layout.get_parent().add_child(_wide_box)
	_side = VBoxContainer.new()
	_side.custom_minimum_size.x = 620
	_side.add_theme_constant_override("separation", 12)
	_wide_box.add_child(_side)
	_board_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL

## Put the board beside the rest on a wide screen, above it on a tall one.
func fit_layout() -> void:
	var now_wide := ScreenShape.is_wide(size)
	if now_wide == wide:
		return
	wide = now_wide
	if wide:
		ScreenShape.move_to([_board_area], _wide_box)
		_wide_box.move_child(_board_area, 0)
		ScreenShape.move_to([status_label, _moves_scroll, _buttons], _side)
	else:
		ScreenShape.move_to([status_label, _board_area, _moves_scroll, _buttons], _layout)
	_layout.visible = not wide
	_wide_box.visible = wide

func is_bot_game() -> bool:
	return bot_team >= 0

## Make a move (it must be legal) and update everything on screen.
func play(move: Move) -> void:
	state.make_move(move)
	board_view.show_move(move)
	sounds.play_for_move(state, move)
	_update_text()
	_save_progress()
	_start_bot_turn_if_needed()

## Take back the last move (also after the game has ended). Against the bot it
## takes back the bot's reply too, so it's your turn again.
func undo() -> void:
	if not _can_undo():
		return
	var undone: Array[Move] = [state.history.back()]
	state.undo_move(undone[0])
	if is_bot_game() and state.side_to_move == bot_team and not state.history.is_empty():
		undone.append(state.history.back())
		state.undo_move(undone[1])
	promotion_overlay.hide()
	board_view.show_undo(undone)
	sounds.play(GameSounds.Sound.MOVE)
	_update_text()
	_save_progress()
	_start_bot_turn_if_needed()

## The bot plays its move now. Normally called by _start_bot_turn_if_needed
## (after a short wait); tests call it directly.
func make_bot_move() -> void:
	var move := bot.choose_move(state)
	bot_thinking = false
	board_view.input_enabled = true
	if move:
		play(move)
	else:
		_update_text()

## Pick up a saved game where it left off. If it can't be rebuilt (for example
## the rules changed since), start a new game with the same armies instead.
func _continue_saved_game(saved: SavedGame) -> void:
	var rebuilt := saved.create_state(StandardSetup.create_rules())
	if rebuilt == null:
		new_game()
		return
	state = rebuilt
	_show_new_state()

## Show `state` from scratch (after a new game or continuing a saved one).
func _show_new_state() -> void:
	promotion_overlay.hide()
	bot_thinking = false
	board_view.show_game(state)
	_update_text()
	_save_progress()
	_start_bot_turn_if_needed()

## Save the game so it can be continued after the app closes; once it's over,
## remove the save so the menu stops offering to continue it. Only games started
## from armies (from the menu) are saved.
func _save_progress() -> void:
	if white_army == null or black_army == null:
		return
	if state.outcome() != GameState.Outcome.NONE:
		SavedGame.delete_saved()
	else:
		SavedGame.from_state(state, white_army, black_army, bot_team, bot_level).save()

## If it's the bot's turn: block the board, say it's thinking, then let it move.
func _start_bot_turn_if_needed() -> void:
	if not is_bot_game() or state.side_to_move != bot_team or state.outcome() != GameState.Outcome.NONE:
		board_view.input_enabled = true
		return
	board_view.input_enabled = false
	bot_thinking = true
	_update_text()
	_bot_turn_id += 1
	var turn_id := _bot_turn_id
	for i in bot_delay_frames:
		await get_tree().process_frame
	# Let the player's move finish sliding first: thinking freezes the screen.
	while bot_delay_frames > 0 and board_view.is_animating() and turn_id == _bot_turn_id:
		await get_tree().process_frame
	# Dropped if a new game (or another turn) started while we waited.
	if turn_id == _bot_turn_id and bot_thinking:
		make_bot_move()

## Undo is possible if there's a move to take back that you made (against the
## bot) or any move at all (two players), and the bot isn't thinking.
func _can_undo() -> bool:
	if bot_thinking:
		return false
	if is_bot_game():
		return state.history.any(func(m: Move) -> bool: return m.piece.team != bot_team)
	return not state.history.is_empty()

## Several moves go between the same two squares: the promotion choices.
## Show a button with each new piece's picture.
func _ask_which_move(moves: Array[Move]) -> void:
	for child in promotion_choices.get_children():
		child.queue_free()
	for move in moves:
		var button := Button.new()
		button.icon = board_view.texture_for(move.promotion, move.piece.team) if move.promotion else null
		if button.icon == null:
			button.text = Notation.san(state, move)
		button.expand_icon = true
		button.custom_minimum_size = Vector2(120, 120)
		button.pressed.connect(func() -> void:
			promotion_overlay.hide()
			play(move))
		promotion_choices.add_child(button)
	promotion_overlay.show()

## Tapping outside the choices cancels.
func _on_overlay_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed:
		promotion_overlay.hide()

func _update_text() -> void:
	var mover := "White" if state.side_to_move == Piece.Team.WHITE else "Black"
	var other := "Black" if state.side_to_move == Piece.Team.WHITE else "White"
	if is_bot_game():
		var bots_turn := state.side_to_move == bot_team
		mover = "Bot" if bots_turn else "You"
		other = "You" if bots_turn else "The bot"
	match state.outcome():
		GameState.Outcome.NONE:
			if is_bot_game():
				status_label.text = "Bot is thinking..." if bot_thinking else "Your move" + (" - check!" if state.is_in_check() else "")
			else:
				status_label.text = mover + " to move" + (" - check!" if state.is_in_check() else "")
		GameState.Outcome.CHECKMATE:
			status_label.text = "Checkmate! %s %s" % [other, "win" if other == "You" else "wins"]
		GameState.Outcome.STALEMATE:
			status_label.text = "Draw by stalemate"
		GameState.Outcome.FIFTY_MOVES:
			status_label.text = "Draw by the 50-move rule"
		GameState.Outcome.REPETITION:
			status_label.text = "Draw by repetition"
		GameState.Outcome.INSUFFICIENT_MATERIAL:
			status_label.text = "Draw: checkmate is impossible"
	moves_label.text = Notation.move_list(state)
	if state.history.is_empty():
		moves_label.text = TIP
	undo_button.disabled = not _can_undo()
