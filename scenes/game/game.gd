extends Control

## The game screen: connects the board view, the text around it and the buttons
## to a GameState. Either two players share the device (pass and play), or one
## player plays the practice bot.

## Pressed "Menu". Only shown if something is listening (the main scene).
signal menu_requested
## Online: both players are in the rematch; the main scene opens it.
signal rematch_ready(session: OnlineSession)

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
## The bot always takes at least this long (seconds) over a move, so its replies
## don't land instantly. Not in tests (bot_delay_frames = 0).
var bot_min_seconds := 2.0
## Counts down the rest of that time. A child of this screen, so if the screen
## closes while it runs, the bot's turn is simply dropped.
var _bot_timer: Timer
## True from the moment it's the bot's turn until it has moved.
var bot_thinking := false
## Counts bot turns, so a turn that was overtaken (New game, Menu) is dropped.
var _bot_turn_id := 0
## A saved game to continue instead of starting a new one (set by the main scene).
var resume: SavedGame
## An online game (set by the main scene before the screen opens): the session
## that talks to the server. Null for games on this device.
var online: OnlineSession
## Both players' clocks, in a timed online game.
var clock_label: Label
## Resigning needs a second tap: when the first tap was (or -1).
var _resign_tapped_ms := -1
## True while this player's move is on its way to the server.
var _sending := false
var _claiming_timeout := false
## The result screen shown when a game ends.
var game_over_panel: GameOverPanel
## Saved armies, for choosing one for a rematch.
var library: ArmyLibrary
## Online extras: chat, draw offers, rematches.
var chat_panel: ChatPanel
var chat_button: Button
var draw_button: Button
## "Your opponent offers a draw" with Accept / Decline.
var offer_bar: HBoxContainer
## Was the game over at the last update (so the result shows once)?
var _was_over := false
## Chat messages already read.
var _chat_seen := 0
## The rematch this player set up (its code), if any.
var _my_rematch_code := ""
var sounds: GameSounds

@onready var board_view: BoardView = %BoardView
@onready var status_label: Label = %Status
@onready var move_list: MoveList = %Moves
@onready var play_from_here_button: Button = %PlayFromHere
## Shown while a piece with an unused special ability is selected.
@onready var ability_button: Button = %Ability
@onready var new_game_button: Button = %NewGame
@onready var undo_button: Button = %Undo
@onready var menu_button: Button = %Menu
@onready var promotion_overlay: ColorRect = %PromotionOverlay
@onready var promotion_choices: HBoxContainer = %PromotionChoices
@onready var _layout: VBoxContainer = $Margin/Layout
@onready var _board_area: Control = $Margin/Layout/BoardArea
@onready var _moves_scroll: ScrollContainer = $Margin/Layout/MovesScroll
@onready var _buttons: Control = $Margin/Layout/Buttons
## On wide screens: the board on the left, `_side` (status, moves, buttons) on the right.
var _wide_box: HBoxContainer
var _side: VBoxContainer
var wide := false

## Looking back: the number of moves played in the position being shown, or -1
## when showing the game as it is now. Looking back never changes the game.
var viewing := -1
## The position being looked at (a separate copy of the game).
var _view_state: GameState

var state: GameState

## Shown where the move list goes, until the first move.
var TIP := tip_text(DisplayServer.is_touchscreen_available())

## Phones: hold a piece. PC: right-click it.
static func tip_text(touchscreen: bool) -> String:
	return "Tip: %s any piece to see how it moves." % ("hold" if touchscreen else "right-click")

func _ready() -> void:
	sounds = GameSounds.new()
	add_child(sounds)
	clock_label = Label.new()
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.add_theme_font_size_override("font_size", 32)
	clock_label.hide()
	_layout.add_child(clock_label)
	_layout.move_child(clock_label, status_label.get_index() + 1)
	_build_offer_bar()
	PieceInfo.prepare(self)
	game_over_panel = GameOverPanel.new()
	game_over_panel.chosen.connect(_on_game_over_action)
	add_child(game_over_panel)
	if library == null:
		library = ArmyLibrary.new()
	_bot_timer = Timer.new()
	_bot_timer.one_shot = true
	add_child(_bot_timer)
	_build_wide_layout()
	resized.connect(fit_layout)
	fit_layout()
	board_view.move_chosen.connect(play)
	board_view.choice_needed.connect(_ask_which_move)
	board_view.info_requested.connect(func(piece: Piece) -> void:
		PieceInfo.open(self, piece.def, piece.team))
	new_game_button.pressed.connect(new_game)
	undo_button.pressed.connect(undo)
	play_from_here_button.pressed.connect(play_from_here)
	for color in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		ability_button.add_theme_color_override(color, Color.WHITE)
	ability_button.pressed.connect(use_ability)
	board_view.selection_changed.connect(_on_selection_changed)
	move_list.move_tapped.connect(view_move)
	menu_button.pressed.connect(func() -> void: menu_requested.emit())
	menu_button.visible = not menu_requested.get_connections().is_empty()
	promotion_overlay.gui_input.connect(_on_overlay_input)
	if is_bot_game():
		bot = PracticeBot.new(bot_level)
	if online:
		_start_online()
		return
	if resume:
		_continue_saved_game(resume)
	else:
		new_game()

func new_game() -> void:
	state = _create_start_state()
	_show_new_state()

## The game's starting position: from the armies, start_fen, or standard chess.
func _create_start_state() -> GameState:
	if white_army and black_army:
		return ArmySetup.create_game(white_army, black_army, StandardSetup.create_rules())
	if start_fen.is_empty():
		return StandardSetup.create_game()
	return Fen.parse(start_fen, PieceCatalog.all_defs(), StandardSetup.create_rules())

## Show the position after the first `moves_played` moves, without changing the
## game. The latest position (or anything past it) goes back to the game itself.
func view_move(moves_played: int) -> void:
	if moves_played < 0 or moves_played >= state.history.size():
		back_to_game()
		return
	# Replay the moves on a fresh copy of the starting position.
	var copy := _create_start_state()
	for i in moves_played:
		var move := copy.find_move(state.history[i].to_text())
		if move == null:
			back_to_game()
			return
		copy.make_move(move)
	viewing = moves_played
	_view_state = copy
	board_view.show_game(copy)
	_update_input()
	_update_text()

## Stop looking back and show the game as it is now.
func back_to_game() -> void:
	if viewing < 0:
		return
	viewing = -1
	_view_state = null
	board_view.show_game(state)
	_update_input()
	_update_text()

## Against the bot: take the game back to the position being looked at, and
## carry on from there.
func play_from_here() -> void:
	if viewing < 0 or bot_thinking:
		return
	var target := viewing
	back_to_game()
	while state.history.size() > target:
		state.undo_move(state.history.back())
	board_view.refresh()
	sounds.play(GameSounds.Sound.MOVE)
	_update_text()
	_save_progress()
	_start_bot_turn_if_needed()

## The board takes moves only when showing the game now, it's not the bot's turn,
## and (online) it's this player's turn.
func _update_input() -> void:
	board_view.input_enabled = viewing < 0 and not bot_thinking and _my_online_turn()

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
		ScreenShape.move_to([status_label, clock_label, _moves_scroll, offer_bar, ability_button, play_from_here_button, _buttons], _side)
	else:
		ScreenShape.move_to([status_label, clock_label, _board_area, _moves_scroll, offer_bar, ability_button, play_from_here_button, _buttons], _layout)
	_layout.visible = not wide
	_wide_box.visible = wide

func is_bot_game() -> bool:
	return bot_team >= 0

## Make a move (it must be legal) and update everything on screen. Online, this
## player's moves are sent to the server (`from_server` = it came from there).
func play(move: Move, from_server := false) -> void:
	state.make_move(move)
	# While looking back, the board keeps showing the old position.
	if viewing < 0:
		board_view.show_move(move)
	sounds.play_for_move(state, move)
	_update_text()
	_save_progress()
	_start_bot_turn_if_needed()
	if online and not from_server:
		_send_online_moves()

## Take back the last move (also after the game has ended). Against the bot it
## takes back the bot's reply too, so it's your turn again.
func undo() -> void:
	if not _can_undo():
		return
	back_to_game()
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
	_play_bot_move(bot.choose_move(state))

func _play_bot_move(move: Move) -> void:
	bot_thinking = false
	_update_input()
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
	# Your own army at the bottom: online, or against the bot. (Two players
	# sharing a device keep White at the bottom.)
	var black_player := online.my_team == Piece.Team.BLACK if online else bot_team == Piece.Team.WHITE
	board_view.flipped = black_player
	promotion_overlay.hide()
	bot_thinking = false
	viewing = -1
	_view_state = null
	board_view.show_game(state)
	_update_text()
	_save_progress()
	_start_bot_turn_if_needed()

## Save the game so it can be continued after the app closes; once it's over,
## remove the save so the menu stops offering to continue it. Only games started
## from armies (from the menu) are saved.
func _save_progress() -> void:
	# Online games are kept on the server instead.
	if online or white_army == null or black_army == null:
		return
	if state.outcome() != GameState.Outcome.NONE:
		SavedGame.delete_saved()
	else:
		SavedGame.from_state(state, white_army, black_army, bot_team, bot_level).save()

## If it's the bot's turn: block the board, say it's thinking, then let it move.
func _start_bot_turn_if_needed() -> void:
	if not is_bot_game() or state.side_to_move != bot_team or state.outcome() != GameState.Outcome.NONE:
		_update_input()
		return
	bot_thinking = true
	_update_input()
	_update_text()
	_bot_turn_id += 1
	var turn_id := _bot_turn_id
	for i in bot_delay_frames:
		await get_tree().process_frame
	# Let the player's move finish sliding first: thinking freezes the screen.
	while bot_delay_frames > 0 and board_view.is_animating() and turn_id == _bot_turn_id:
		await get_tree().process_frame
	# Dropped if a new game (or another turn) started while we waited.
	if turn_id != _bot_turn_id or not bot_thinking:
		return
	var started := Time.get_ticks_msec()
	var move := bot.choose_move(state)
	# Fast answers wait until the bot has "thought" for bot_min_seconds.
	var wait := bot_min_seconds - (Time.get_ticks_msec() - started) / 1000.0
	if bot_delay_frames > 0 and wait > 0:
		_bot_timer.start(wait)
		await _bot_timer.timeout
	if turn_id == _bot_turn_id and bot_thinking:
		_play_bot_move(move)

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
		# The piece it would become (promotion) or bring back (Raise Dead).
		if move.promotion:
			button.icon = board_view.texture_for(move.promotion, move.piece.team)
		elif move.raised:
			button.icon = board_view.texture_for(move.raised.def, move.piece.team)
			if button.icon == null:
				button.text = move.raised.def.display_name
		if button.icon == null and button.text == "":
			button.text = Notation.san(state, move)
		button.expand_icon = true
		button.custom_minimum_size = Vector2(120, 120)
		button.pressed.connect(func() -> void:
			promotion_overlay.hide()
			play(move))
		promotion_choices.add_child(button)
	promotion_overlay.show()

## A piece was selected (or the selection cleared): offer its special ability,
## if it has one it can use now.
func _on_selection_changed(_square: Vector2i) -> void:
	var moves := board_view.selected_ability_moves()
	ability_button.visible = not moves.is_empty()
	if not moves.is_empty():
		var def: PieceDef = moves[0].piece.def
		ability_button.text = def.ability_name
		_style_ability_button(def.ability_gradient())
	else:
		_update_text()

## The ability button gets the piece's gradient: lighter under the mouse,
## darker while pressed.
func _style_ability_button(colors: PackedColorArray) -> void:
	var style := GradientStyleBox.new(colors, 12, 16, 8)
	ability_button.add_theme_stylebox_override("normal", style)
	ability_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	ability_button.add_theme_stylebox_override("hover", style.shaded(0.15))
	ability_button.add_theme_stylebox_override("pressed", style.shaded(-0.2))

## The ability button: Crack Shot asks which piece to shoot (on the board);
## Raise Dead asks which lost piece to bring back (a picker, like promotion).
func use_ability() -> void:
	var moves := board_view.selected_ability_moves()
	if moves.is_empty():
		return
	var piece := moves[0].piece
	if piece.def.ability == PieceDef.Ability.RAISE_DEAD:
		_ask_which_move(moves)
	else:
		board_view.aim_ability()
		status_label.text = "%s: choose a target" % piece.def.ability_name

## Tapping outside the choices cancels.
func _on_overlay_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed:
		promotion_overlay.hide()

func _update_text() -> void:
	var mover := "White" if state.side_to_move == Piece.Team.WHITE else "Black"
	var other := "Black" if state.side_to_move == Piece.Team.WHITE else "White"
	if online:
		var my_turn := state.side_to_move == online.my_team
		mover = "You" if my_turn else "Your opponent"
		other = "Your opponent" if my_turn else "You"
	elif is_bot_game():
		var bots_turn := state.side_to_move == bot_team
		mover = "Bot" if bots_turn else "You"
		other = "You" if bots_turn else "The bot"
	match state.outcome():
		GameState.Outcome.NONE:
			if online:
				var mine := state.side_to_move == online.my_team
				status_label.text = ("Your move" if mine else "Your opponent's move") + (" - check!" if state.is_in_check() else "")
			elif is_bot_game():
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
	if online and _online_ending() != "":
		status_label.text = _online_ending()
	if viewing >= 0:
		status_label.text = "Viewing %s" % _move_name(viewing - 1)
	var result := state.result_text()
	if online and result == "*":
		result = _online_result_text()
	move_list.show_moves(Notation.numbered_moves(state), "" if result == "*" else result, viewing, TIP)
	# Keep the latest move in sight (not while looking back at an older one).
	if viewing < 0:
		_scroll_moves_to_end.call_deferred()
	undo_button.disabled = not _can_undo()
	play_from_here_button.visible = is_bot_game() and viewing >= 0
	play_from_here_button.disabled = bot_thinking
	if online:
		_update_online_controls()
	_update_game_over()

# --- The result screen ----------------------------------------------------------

func is_over() -> bool:
	if state.outcome() != GameState.Outcome.NONE:
		return true
	return online != null and online.status() in [OnlineSession.FINISHED, OnlineSession.CANCELLED]

## Show the result once, when the game ends; hide it if the game is back on
## (e.g. the last move was undone).
func _update_game_over() -> void:
	var over := is_over()
	if over and not _was_over and viewing < 0:
		show_game_over()
	elif not over:
		game_over_panel.hide()
	_was_over = over

func show_game_over() -> void:
	var texts := result_texts()
	var buttons := []
	if online:
		buttons.append(["rematch", "Rematch"])
	elif is_bot_game():
		buttons.append(["again", "Play again"])
	else:
		buttons.append(["again", "New game"])
	buttons.append(["board", "View board"])
	if menu_button.visible:
		buttons.append(["menu", "Menu"])
	game_over_panel.show_result(texts[0], texts[1], buttons)
	if online and _opponent_wants_rematch():
		_show_rematch_offer()

## The headline and the line under it, e.g. ["Checkmate!", "You win!"].
func result_texts() -> Array:
	var me := _my_team()
	if online:
		var code := online.result_code()
		if online.status() == OnlineSession.CANCELLED:
			return ["Game cancelled", ""]
		if code == "draw_agreed":
			return ["Draw", "Agreed by both players"]
		if code.ends_with("_resigned") or code.ends_with("_timeout"):
			var loser := Piece.Team.WHITE if code.begins_with("white") else Piece.Team.BLACK
			var you_lost := loser == me
			if code.ends_with("_resigned"):
				return ["You resigned" if you_lost else "Your opponent resigned", "You lose" if you_lost else "You win!"]
			return ["Out of time", "You ran out of time" if you_lost else "Your opponent ran out of time - you win!"]
	match state.outcome():
		GameState.Outcome.CHECKMATE:
			# The side to move has been checkmated.
			var winner := Piece.other_team(state.side_to_move)
			if me == -1:
				return ["Checkmate!", "%s wins" % ("White" if winner == Piece.Team.WHITE else "Black")]
			if winner == me:
				return ["Checkmate!", "You win!"]
			return ["Checkmate!", "The bot wins" if is_bot_game() else "You lose"]
		GameState.Outcome.STALEMATE:
			return ["Draw", "Stalemate: no legal moves, but not in check"]
		GameState.Outcome.FIFTY_MOVES:
			return ["Draw", "50 moves each without a capture or pawn move"]
		GameState.Outcome.REPETITION:
			return ["Draw", "The same position three times"]
		GameState.Outcome.INSUFFICIENT_MATERIAL:
			return ["Draw", "Checkmate is impossible"]
	return ["Game over", ""]

## This player's side: online or against the bot. -1 for two players on one device.
func _my_team() -> int:
	if online:
		return online.my_team
	if is_bot_game():
		return Piece.other_team(bot_team)
	return -1

func _on_game_over_action(action: String) -> void:
	match action:
		"again":
			new_game()
		"board":
			game_over_panel.hide()
		"menu":
			menu_requested.emit()
		"rematch":
			start_rematch()

# --- Online extras: draw offers, chat, rematch ------------------------------------

func _build_offer_bar() -> void:
	offer_bar = HBoxContainer.new()
	offer_bar.add_theme_constant_override("separation", 10)
	offer_bar.hide()
	var label := Label.new()
	label.name = "Text"
	label.text = "Your opponent offers a draw"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	offer_bar.add_child(label)
	for entry in [["Accept", true], ["Decline", false]]:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[0]
		button.custom_minimum_size = Vector2(150, 70)
		var accept: bool = entry[1]
		button.pressed.connect(func() -> void: answer_draw(accept))
		offer_bar.add_child(button)
	_layout.add_child(offer_bar)
	_layout.move_child(offer_bar, _buttons.get_index())

## The extra buttons and chat window, for online games.
func _build_online_extras() -> void:
	chat_button = Button.new()
	chat_button.text = "Chat"
	chat_button.custom_minimum_size = Vector2(0, 80)
	chat_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chat_button.pressed.connect(open_chat)
	_buttons.add_child(chat_button)
	_buttons.move_child(chat_button, new_game_button.get_index())
	draw_button = Button.new()
	draw_button.text = "Draw"
	draw_button.custom_minimum_size = Vector2(0, 80)
	draw_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draw_button.pressed.connect(offer_draw)
	_buttons.add_child(draw_button)
	_buttons.move_child(draw_button, new_game_button.get_index())
	chat_panel = ChatPanel.new()
	chat_panel.send_requested.connect(send_chat)
	add_child(chat_panel)

func _update_online_controls() -> void:
	var playing := online.status() == OnlineSession.PLAYING
	var theirs := OnlineSession.team_key(Piece.other_team(online.my_team))
	draw_button.visible = playing
	draw_button.disabled = online.draw_offer() != "" or _sending
	draw_button.text = "Draw offered" if online.draw_offer() == OnlineSession.team_key(online.my_team) else "Draw"
	offer_bar.visible = playing and online.draw_offer() == theirs
	new_game_button.text = "Results" if is_over() else "Resign"
	var unread := online.chat().size() - _chat_seen
	chat_button.text = "Chat (%d)" % unread if unread > 0 else "Chat"
	if chat_panel.visible:
		_refresh_chat()

func offer_draw() -> void:
	if online == null or online.status() != OnlineSession.PLAYING or online.draw_offer() != "":
		return
	draw_button.disabled = true
	await online.offer_draw()
	_after_online_change()

func answer_draw(accept: bool) -> void:
	await online.answer_draw(accept)
	_after_online_change()

func open_chat() -> void:
	_refresh_chat()
	chat_panel.show()
	_update_online_controls()

func send_chat(text: String) -> void:
	await online.post_chat(text)
	_refresh_chat()
	_update_online_controls()

func _refresh_chat() -> void:
	_chat_seen = online.chat().size()
	chat_panel.show_messages(online.chat(), OnlineSession.team_key(online.my_team))

func _opponent_wants_rematch() -> bool:
	return online.rematch_code() != "" and online.rematch_code() != _my_rematch_code

func _show_rematch_offer() -> void:
	if not game_over_panel.visible:
		show_game_over()
		return
	game_over_panel.set_note("Your opponent wants a rematch!")
	var button := game_over_panel.button("rematch")
	if button:
		button.text = "Accept rematch"

## Rematch: accepting the opponent's rematch means choosing an army; setting one
## up means choosing an army and a side (White, Black or Random, Mac's design),
## then waiting for them. The time limit stays the same.
func start_rematch() -> void:
	var accepting := _opponent_wants_rematch()
	var picker := ArmyPicker.new(library, "Your army for the rematch", not accepting)
	picker.chosen.connect(_rematch_with)
	add_child(picker)

func _rematch_with(army: Army, side := OnlineSession.SIDE_RANDOM) -> void:
	var button := game_over_panel.button("rematch")
	if button:
		button.disabled = true
	if _opponent_wants_rematch():
		await _join_rematch(online.rematch_code(), army)
		return
	game_over_panel.set_note("Setting up the rematch...")
	var next := _new_session()
	var created := await next.create_game(army, side, int(online.row.get("time_ms", 0)))
	if not created.ok:
		_rematch_failed(next, "Couldn't set up a rematch: " + created.error)
		return
	var claimed := await online.claim_rematch(next.code)
	if claimed.ok and not claimed.rows.is_empty():
		_my_rematch_code = next.code
		game_over_panel.set_note("Waiting for your opponent to accept the rematch...")
		next.changed.connect(func(_row: Dictionary) -> void:
			if next.status() == OnlineSession.PLAYING:
				_go_to_rematch(next))
		next.start_polling()
		return
	# The opponent set one up at the same moment: join theirs instead.
	await next.cancel()
	next.queue_free()
	await online.poll()
	if online.rematch_code() != "":
		await _join_rematch(online.rematch_code(), army)
	else:
		_rematch_failed(null, "Couldn't set up a rematch.")

func _join_rematch(rematch_code: String, army: Army) -> void:
	game_over_panel.set_note("Joining the rematch...")
	var next := _new_session()
	var joined := await next.join_game(rematch_code, army)
	if not joined.ok:
		_rematch_failed(next, joined.error)
		return
	_go_to_rematch(next)

func _new_session() -> OnlineSession:
	var next := OnlineSession.new(online.backend.duplicate(), online.player_id)
	next.poll_seconds = online.poll_seconds
	add_child(next)
	return next

func _rematch_failed(next: OnlineSession, message: String) -> void:
	if next:
		next.queue_free()
	game_over_panel.set_note(message)
	var button := game_over_panel.button("rematch")
	if button:
		button.disabled = false

func _go_to_rematch(next: OnlineSession) -> void:
	next.stop_polling()
	rematch_ready.emit(next)

# --- Online games ---------------------------------------------------------------

## Set the screen up for an online game: the position from the server, this
## player's side, the clocks, and Resign instead of Undo / New game.
func _start_online() -> void:
	if online.get_parent() != self:
		add_child(online)
	white_army = online.army(Piece.Team.WHITE)
	black_army = online.army(Piece.Team.BLACK)
	state = online.create_state(StandardSetup.create_rules())
	if state == null:
		state = _create_start_state()
	undo_button.hide()
	new_game_button.text = "Resign"
	new_game_button.pressed.disconnect(new_game)
	new_game_button.pressed.connect(resign)
	clock_label.visible = online.timed()
	_build_online_extras()
	online.changed.connect(_on_online_changed)
	online.start_polling()
	if online.status() == OnlineSession.PLAYING:
		UserSettings.set_online_game(online.code, online.player_id)
	else:
		UserSettings.set_online_game("")
	_show_new_state()

func _my_online_turn() -> bool:
	if online == null:
		return true
	return online.status() == OnlineSession.PLAYING and state.side_to_move == online.my_team and not _sending

## Send the moves so far after this player's move. If the connection fails, keep
## trying until the server has it.
func _send_online_moves() -> void:
	_sending = true
	_update_input()
	var moves := state.history.map(func(m: Move) -> String: return m.to_text())
	var finished := state.outcome() != GameState.Outcome.NONE
	var result := await online.send_moves(moves, finished)
	while not result.ok and is_inside_tree():
		status_label.text = "Connection problem - trying again..."
		await get_tree().create_timer(3.0).timeout
		result = await online.send_moves(moves, finished)
	_sending = false
	if not is_inside_tree():
		return
	# The server had something newer (e.g. the opponent resigned): catch up.
	if result.rows.is_empty():
		await online.poll()
	_after_online_change()

## Something changed on the server: play any new moves from the opponent.
func _on_online_changed(_row: Dictionary) -> void:
	var server_moves := online.moves()
	for i in range(state.history.size(), server_moves.size()):
		var move := state.find_move(str(server_moves[i]))
		if move == null:
			status_label.text = "This game is out of step with the server."
			return
		play(move, true)
	_after_online_change()

func _after_online_change() -> void:
	# Keep checking the server after the game ends too, for rematch offers.
	if online.status() != OnlineSession.PLAYING:
		UserSettings.set_online_game("")
	_update_text()
	_update_input()
	if is_over() and _opponent_wants_rematch():
		_show_rematch_offer()

## Resign this online game (the first tap asks for a second one).
func resign() -> void:
	if online == null:
		return
	# After the game, this button shows the result screen again.
	if is_over():
		show_game_over()
		return
	if online.status() != OnlineSession.PLAYING:
		return
	var now := Time.get_ticks_msec()
	if _resign_tapped_ms < 0 or now - _resign_tapped_ms > 3000:
		_resign_tapped_ms = now
		new_game_button.text = "Tap again to resign"
		get_tree().create_timer(3.0).timeout.connect(func() -> void:
			if is_instance_valid(new_game_button):
				new_game_button.text = "Resign")
		return
	_resign_tapped_ms = -1
	new_game_button.text = "Resign"
	await online.resign()
	_after_online_change()

func _process(_delta: float) -> void:
	if online == null or not online.timed():
		return
	var now := Time.get_ticks_msec()
	var white := _clock_text(online.clock_ms(Piece.Team.WHITE, now))
	var black := _clock_text(online.clock_ms(Piece.Team.BLACK, now))
	var you := " (you)"
	clock_label.text = "White %s%s      Black %s%s" % [white, you if online.my_team == Piece.Team.WHITE else "",
			black, you if online.my_team == Piece.Team.BLACK else ""]
	# A clock that has run out ends the game (claimed by whoever notices first).
	if not _claiming_timeout and online.out_of_time(online.side_to_move(), now):
		_claim_timeout(online.side_to_move())

func _claim_timeout(team: Piece.Team) -> void:
	_claiming_timeout = true
	await online.claim_timeout(team)
	_claiming_timeout = false
	_after_online_change()

## "4:05", never below "0:00".
static func _clock_text(ms: int) -> String:
	var seconds := maxi(0, ceili(ms / 1000.0))
	return "%d:%02d" % [seconds / 60, seconds % 60]

## How a finished online game ended, if not on the board: "" otherwise.
func _online_ending() -> String:
	if online.status() == OnlineSession.CANCELLED:
		return "This game was cancelled"
	var code := online.result_code()
	if online.status() != OnlineSession.FINISHED or code == "board" or code == "":
		return ""
	var losing_team := Piece.Team.WHITE if code.begins_with("white") else Piece.Team.BLACK
	var you_lost := losing_team == online.my_team
	if code.ends_with("resigned"):
		return "You resigned" if you_lost else "Your opponent resigned - you win!"
	return "You ran out of time" if you_lost else "Your opponent ran out of time - you win!"

## "1-0" / "0-1" for a game that ended by resigning or time, else "*".
func _online_result_text() -> String:
	var code := online.result_code()
	if online.status() != OnlineSession.FINISHED or code == "board" or code == "":
		return "*"
	return "0-1" if code.begins_with("white") else "1-0"

func _scroll_moves_to_end() -> void:
	if is_inside_tree():
		_moves_scroll.scroll_vertical = int(_moves_scroll.get_v_scroll_bar().max_value)

## Which move `index` (0 = the first) was, e.g. "White's move 12".
func _move_name(index: int) -> String:
	var move: Move = state.history[index]
	var side := "White" if move.piece.team == Piece.Team.WHITE else "Black"
	# Count White's and Black's moves up to this one.
	var number := 0
	for i in range(index + 1):
		if state.history[i].piece.team == move.piece.team:
			number += 1
	return "%s's move %d" % [side, number]
