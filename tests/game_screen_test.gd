extends TestSuite

## Checks the game screen (game.tscn) by loading it into the running scene tree.

func _open() -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	return game

func _play(game: Node, san: String) -> void:
	var move := Notation.find_move(game.state, san)
	check(move != null, "Should be legal: " + san)
	if move:
		game.play(move)

func test_undo_takes_back_one_move() -> void:
	var game := _open()
	check(game.undo_button.disabled, "Undo is off at the start")
	_play(game, "e4")
	_play(game, "e5")
	check(not game.undo_button.disabled, "Undo is on after moves")
	game.undo()
	check_eq(game.state.history.size(), 1, "One move left")
	check_eq(game.move_list.lines(), PackedStringArray(["1. e4"]), "Move list after undo")
	check_eq(game.status_label.text, "Black to move", "Status after undo")
	game.undo()
	check_eq(Fen.write(game.state), Fen.STANDARD_START, "Back to the start")
	check(game.undo_button.disabled, "Undo is off again")
	game.free()

func test_undo_after_checkmate_resumes_play() -> void:
	var game := _open()
	for san in ["f3", "e5", "g4", "Qh4#"]:
		_play(game, san)
	check_eq(game.status_label.text, "Checkmate! Black wins", "Status at mate")
	game.undo()
	check_eq(game.status_label.text, "Black to move", "Status after undoing the mate")
	game.free()

func test_new_game_resets() -> void:
	var game := _open()
	_play(game, "e4")
	game.new_game()
	check_eq(game.state.history.size(), 0, "No moves")
	check(game.move_list._tip.visible and game.move_list._tip.text == game.TIP, "Tip instead of an empty move list")
	check(game.move_list.buttons.is_empty(), "No moves listed")
	game.free()

# --- Against the practice bot ------------------------------------------------------
# bot_delay_frames = 0 makes the bot move straight away, so tests don't wait.

func _open_bot_game(bot_team: Piece.Team, level := PracticeBot.Level.EASY) -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.white_army = StandardSetup.army()
	game.black_army = StandardSetup.army()
	game.bot_team = bot_team
	game.bot_level = level
	game.bot_delay_frames = 0
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	return game

func test_bot_replies_to_your_move() -> void:
	var game := _open_bot_game(Piece.Team.BLACK)
	check_eq(game.status_label.text, "Your move", "You start as White")
	check(game.board_view.input_enabled, "Board open for you")
	_play(game, "e4")
	check_eq(game.state.history.size(), 2, "Bot answered")
	check_eq(game.state.side_to_move, Piece.Team.WHITE, "Your turn again")
	check(game.board_view.input_enabled, "Board open again")
	check_eq(game.status_label.text, "Your move", "Status")
	game.free()

func test_bot_moves_first_when_you_play_black() -> void:
	var game := _open_bot_game(Piece.Team.WHITE)
	check_eq(game.state.history.size(), 1, "Bot played White's first move")
	check_eq(game.state.side_to_move, Piece.Team.BLACK, "Now you, as Black")
	check(game.undo_button.disabled, "Nothing of yours to undo yet")
	game.free()

func test_undo_against_the_bot_takes_back_both_moves() -> void:
	var game := _open_bot_game(Piece.Team.BLACK)
	_play(game, "e4")
	check(not game.undo_button.disabled, "Undo available")
	game.undo()
	check_eq(game.state.history.size(), 0, "Your move and the bot's reply are gone")
	check_eq(Fen.write(game.state), Fen.STANDARD_START, "Back to the start")
	game.free()

func test_checkmate_message_against_the_bot() -> void:
	var game := _open_bot_game(Piece.Team.BLACK)
	game.state = StandardSetup.from_fen("rnbqkbnr/ppppp2p/5p2/6p1/4P3/8/PPPP1PPP/RNBQKBNR w KQkq - 0 3")
	game.board_view.show_game(game.state)
	_play(game, "Qh5#")
	check_eq(game.status_label.text, "Checkmate! You win", "You won")
	game.free()

func test_match_setup_with_the_bot() -> void:
	var setup: Node = load("res://scenes/menu/match_setup.tscn").instantiate()
	setup.library = ArmyLibrary.new("user://test_armies/")
	(Engine.get_main_loop() as SceneTree).root.add_child(setup)
	check(not setup.bot_options.visible, "Bot options hidden for two players")
	setup.opponent_pick.select(1)
	setup.opponent_pick.item_selected.emit(1)
	check(setup.bot_options.visible, "Bot options shown")
	check_eq(setup.first_label.text, "Your army", "First list is yours")
	var started := []
	setup.start_requested.connect(func(_w: Army, _b: Army, bot_team: int, level: int) -> void: started.append([bot_team, level]))
	setup.level_pick.select(PracticeBot.Level.HARD)
	setup.side_pick.select(0)  # You play White
	setup.start()
	setup.side_pick.select(1)  # You play Black
	setup.start()
	check_eq(started, [[Piece.Team.BLACK, PracticeBot.Level.HARD], [Piece.Team.WHITE, PracticeBot.Level.HARD]], "Bot takes the other side")
	setup.side_pick.select(2)  # Random
	setup.rng.seed = 1
	var sides := {}
	for i in 20:
		started.clear()
		setup.start()
		sides[started[0][0]] = true
	check_eq(sides.size(), 2, "Random gives both sides")
	setup.free()

func test_bot_takes_its_time() -> void:
	var game := _open_bot_game(Piece.Team.BLACK)
	game.bot_delay_frames = 1
	game.bot_min_seconds = 0.4
	var started := Time.get_ticks_msec()
	_play(game, "e4")
	check_eq(game.state.history.size(), 1, "Not answered straight away")
	while game.state.history.size() < 2 and Time.get_ticks_msec() - started < 5000:
		await (Engine.get_main_loop() as SceneTree).process_frame
	check_eq(game.state.history.size(), 2, "Answered in the end")
	check(Time.get_ticks_msec() - started >= 400, "After at least the minimum time")
	game.free()

# --- Looking back through the moves ------------------------------------------------

func test_one_turn_per_line() -> void:
	var game := _open()
	for san in ["e4", "e5", "Nf3"]:
		_play(game, san)
	check_eq(game.move_list.lines(), PackedStringArray(["1. e4 e5", "2. Nf3"]), "One line per turn")
	check_eq(game.move_list.buttons.size(), 3, "A button per move")
	var first_row: HBoxContainer = game.move_list.buttons[0].get_child(0)
	check(first_row.get_child(0).get_child(0) is TextureRect, "Starts with the pawn's picture")
	check_eq(first_row.get_child(1).text, "e4", "Then the square")
	game.move_list.buttons[0].pressed.emit()
	check_eq(game.viewing, 1, "Tapping a move looks back at it")
	game.free()

func test_black_moving_first_leaves_whites_cell_empty() -> void:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.start_fen = "4k3/8/8/8/8/8/4P3/4K3 b - - 0 1"
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	_play(game, "Kd7")
	_play(game, "e4")
	check_eq(game.move_list.lines(), PackedStringArray(["1... Kd7", "2. e4"]), "Black first")
	game.free()

func test_looking_back_leaves_the_game_alone() -> void:
	var game := _open()
	for san in ["e4", "e5", "Nf3"]:
		_play(game, san)
	var now := Fen.write(game.state)
	game.view_move(1)
	check_eq(game.viewing, 1, "Looking at the position after 1. e4")
	check_eq(Fen.write(game.board_view.state), "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1", "Board shows it")
	check_eq(Fen.write(game.state), now, "The game itself is unchanged")
	check(not game.board_view.input_enabled, "Two players: no moves while looking back during the game (Mac)")
	check(game.status_label.text == "Viewing White's move 1", "Status says so")
	var viewed_box: StyleBoxFlat = game.move_list.buttons[0].get_theme_stylebox("normal")
	check_eq(viewed_box.bg_color, MoveList.VIEWED_BG, "Viewed move highlighted")
	check(not game.play_from_here_button.visible, "Play from here is only for bot games")
	game.view_move(3)
	check_eq(game.viewing, -1, "Tapping the last move returns to the game")
	check(game.board_view.state == game.state, "Board shows the game again")
	check(game.board_view.input_enabled, "Moving allowed again")
	game.free()

func test_back_and_forward_while_looking_back() -> void:
	var game := _open()
	for san in ["e4", "e5", "Nf3"]:
		_play(game, san)
	check(not game.view_nav.visible, "No Back / Forward while showing the game now")
	game.view_move(2)
	check(game.view_nav.visible, "Back / Forward shown while looking back")
	game.step_back_button.pressed.emit()
	check_eq(game.viewing, 1, "Back: one move earlier")
	check(game.status_label.text == "Viewing White's move 1", "Status follows")
	game.step_back()
	check_eq(game.viewing, 0, "Back again: the start")
	check(game.status_label.text == "Viewing the start", "Status says so")
	check_eq(Fen.write(game.board_view.state), Fen.STANDARD_START, "Board shows the start")
	check(game.step_back_button.disabled, "Nothing before the start")
	game.step_back()
	check_eq(game.viewing, 0, "Back does nothing at the start")
	game.step_forward_button.pressed.emit()
	check_eq(game.viewing, 1, "Forward: one move later")
	check(not game.step_back_button.disabled, "Back works again")
	game.step_forward()
	check_eq(game.viewing, 2, "Forward again")
	game.step_forward()
	check_eq(game.viewing, -1, "Forward from the second-to-last move: the game now")
	check(not game.view_nav.visible, "Buttons hidden again")
	check(game.board_view.input_enabled, "Moving allowed again")
	game.free()

func test_stepping_keeps_the_viewed_move_in_sight() -> void:
	var game := _open()
	# A long game of random (but always the same) moves.
	var random := RandomNumberGenerator.new()
	random.seed = 7
	while game.state.history.size() < 24 and not game.is_over():
		var moves: Array = game.state.moves()
		game.play(moves[random.randi() % moves.size()])
	check_eq(game.state.history.size(), 24, "24 moves played")
	var tree := Engine.get_main_loop() as SceneTree
	var scroll: ScrollContainer = game.move_list.get_parent()
	game.view_move(3)
	game.step_back()
	for i in 3:
		await tree.process_frame
	check_eq(scroll.scroll_vertical, 0, "Stepping back to an early move scrolls up to it")
	game.view_move(21)
	game.step_forward()
	for i in 3:
		await tree.process_frame
	check(scroll.scroll_vertical > 0, "Stepping forward to a late move scrolls down to it")
	game.free()

func test_black_move_name() -> void:
	var game := _open()
	for san in ["e4", "e5", "Nf3"]:
		_play(game, san)
	game.view_move(2)
	check(game.status_label.text == "Viewing Black's move 1", "Black's first move")
	game.free()

func test_play_from_here_against_the_bot() -> void:
	var game := _open_bot_game(Piece.Team.BLACK)
	_play(game, "e4")
	_play(game, "d4")
	check_eq(game.state.history.size(), 4, "Two moves each")
	game.view_move(2)
	check(game.play_from_here_button.visible, "Button shown while looking back")
	check(game.step_back_button.visible and game.step_forward_button.visible, "Between Back and Forward")
	game.play_from_here()
	check_eq(game.viewing, -1, "Back to the game")
	check_eq(game.state.history.size(), 2, "Game taken back to that position")
	check_eq(game.state.history[0].to_text(), "e2-e4", "Starting with e4")
	check(not game.play_from_here_button.visible, "Button hidden again")
	game.free()

func test_undo_while_looking_back_returns_first() -> void:
	var game := _open()
	for san in ["e4", "e5"]:
		_play(game, san)
	game.view_move(1)
	game.undo()
	check_eq(game.viewing, -1, "Back to the game")
	check_eq(game.state.history.size(), 1, "And one move undone")
	check(game.board_view.state == game.state, "Board shows the game")
	game.free()

# --- Special abilities ---------------------------------------------------------------

func _open_fen(fen: String) -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.start_fen = fen
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	return game

func test_ability_button_and_crack_shot() -> void:
	var game := _open_fen("4k3/8/8/8/8/2n5/8/A3K3 w - - 0 1")
	check(not game.ability_button.visible, "No button before selecting")
	game.board_view.tap(Board.parse_square("a1"))
	check(game.ability_button.visible, "Button shows for the Archer")
	check_eq(game.ability_button.text, "CRACK SHOT", "Named after the ability, in capitals")
	game.use_ability()
	check(game.board_view.aiming, "Choosing a target")
	check_eq(game.status_label.text, "Crack Shot: choose a target", "Status asks for a target")
	game.board_view.tap(Board.parse_square("c3"))
	check_eq(game.state.history.size(), 1, "Shot taken")
	check_eq(game.state.history[0].ability, PieceDef.Ability.CRACK_SHOT, "As a Crack Shot")
	check(game.state.board.get_piece(Board.parse_square("a1")) != null, "Archer stayed")
	check(not game.ability_button.visible, "Button hidden afterwards")
	game.free()

func test_tapping_a_target_normally_is_a_normal_capture() -> void:
	var game := _open_fen("4k3/8/8/8/8/2n5/8/A3K3 w - - 0 1")
	game.board_view.tap(Board.parse_square("a1"))
	game.board_view.tap(Board.parse_square("c3"))
	check_eq(game.state.history.size(), 1, "Moved")
	check_eq(game.state.history[0].ability, PieceDef.Ability.NONE, "An ordinary capture")
	check(game.state.board.get_piece(Board.parse_square("c3")).def.id == "archer", "Archer moved to c3")
	game.free()

func test_used_ability_button_and_ordinary_piece() -> void:
	var game := _open_fen("4k3/8/8/8/8/2n5/8/A^3K3 w - - 0 1")
	game.board_view.tap(Board.parse_square("a1"))
	check(game.ability_button.visible, "A used ability still shows its button")
	game.use_ability()
	check_eq(game.last_notice, "Crack Shot has already been used.", "Says it's used up")
	check_eq(game.state.history.size(), 0, "Nothing played")
	game.board_view.tap(Board.parse_square("e1"))
	check(not game.ability_button.visible, "The king has no ability")
	game.free()

func test_ability_that_cant_be_used_now() -> void:
	# Nothing in range to shoot: the button shows (darkened) and says so.
	var game := _open_fen("4k3/7p/8/8/8/8/8/A3K3 w - - 0 1")
	game.board_view.tap(Board.parse_square("a1"))
	check(game.ability_button.visible, "Button still shows")
	game.use_ability()
	check_eq(game.last_notice, "This ability can't be used right now.", "Says it can't be used now")
	check(not game.board_view.aiming, "Not aiming")
	game.free()

func test_raise_dead_picker() -> void:
	var game := _open_fen("3k4/8/8/8/8/8/3(NC)4/4K3 w - - 0 1")
	game.state.lost[Piece.Team.WHITE].append(Piece.new(load("res://data/pieces/queen.tres"), Piece.Team.WHITE))
	game.board_view.tap(Board.parse_square("d2"))
	check_eq(game.ability_button.text, "RAISE DEAD", "Raise Dead button")
	game.use_ability()
	check(game.promotion_overlay.visible, "Picker shown")
	check_eq(game.promotion_choices.get_child_count(), 1, "One lost piece to choose")
	(game.promotion_choices.get_child(0) as Button).pressed.emit()
	check_eq(game.state.board.get_piece(Board.parse_square("d2")).def.id, "queen", "Queen raised")
	game.free()

func test_playing_black_against_the_bot_flips_the_board() -> void:
	var as_black := _open_bot_game(Piece.Team.WHITE)
	check(as_black.board_view.flipped, "You play Black: Black at the bottom")
	as_black.free()
	var as_white := _open_bot_game(Piece.Team.BLACK)
	check(not as_white.board_view.flipped, "You play White: White at the bottom")
	as_white.free()
	var two_players := _open()
	check(not two_players.board_view.flipped, "Two players on one device: White at the bottom")
	two_players.free()

# --- Redo and New game ---------------------------------------------------------------

func test_redo_plays_undone_moves_again() -> void:
	var game := _open()
	_play(game, "e4")
	_play(game, "e5")
	check(game.redo_button.disabled, "Nothing to redo yet")
	game.undo()
	game.undo()
	check_eq(game.state.history.size(), 0, "Both taken back")
	check(not game.redo_button.disabled, "Redo available")
	game.redo()
	check_eq(game.state.history.size(), 1, "One move back")
	check_eq(game.state.history[0].to_text(), "e2-e4", "The first move first")
	game.redo()
	check_eq(game.state.history[1].to_text(), "e7-e5", "Then the second")
	check(game.redo_button.disabled, "Nothing left to redo")
	game.undo()
	_play(game, "c5")
	check(game.redo_moves.is_empty(), "A new move clears what could be redone")
	game.free()
	SavedGame.delete_saved()

func test_redo_against_the_bot_replays_both_moves() -> void:
	var game := _open_bot_game(Piece.Team.BLACK)
	_play(game, "e4")
	if game.state.history.size() < 2:
		game.make_bot_move()
	check_eq(game.state.history.size(), 2, "You and the bot moved")
	var reply: String = game.state.history[1].to_text()
	game.undo()
	check_eq(game.state.history.size(), 0, "Both taken back")
	game.redo()
	check_eq(game.state.history.size(), 2, "Both played again")
	check_eq(game.state.history[1].to_text(), reply, "The bot's same reply")
	check(not game.bot_thinking, "The bot doesn't think again")
	game.free()
	SavedGame.delete_saved()

func test_new_game_asks_first() -> void:
	var game := _open()
	game.ask_new_game()
	check(game.new_game_confirm == null, "Nothing played: no need to ask")
	_play(game, "e4")
	game.ask_new_game()
	check(game.new_game_confirm != null and game.new_game_confirm.visible, "Asks if you're sure")
	check_eq(game.state.history.size(), 1, "Game untouched until you say yes")
	game.new_game_confirm.confirmed.emit()
	check_eq(game.state.history.size(), 0, "New game after yes")
	game.free()
	SavedGame.delete_saved()

func test_dragging_the_move_list_scrolls_without_choosing_a_move() -> void:
	var game := _open()
	for san in ["e4", "e5", "Nf3", "Nc6", "Bc4", "Bc5", "c3", "Nf6", "d4", "exd4", "cxd4", "Bb4+", "Nc3", "Nxe4", "O-O", "Bxc3", "d5", "Bf6", "Re1", "Ne7", "Rxe4", "d6", "Bg5", "Bxg5", "Nxg5", "h6"]:
		_play(game, san)
	await (Engine.get_main_loop() as SceneTree).process_frame
	var tapped := []
	game.move_list.move_tapped.connect(func(n: int) -> void: tapped.append(n))
	var button: Button = game.move_list.buttons[3]
	check_eq(button.mouse_filter, Control.MOUSE_FILTER_PASS, "Drags pass through to the list")
	var scroll: ScrollContainer = game.move_list.get_parent()
	scroll.scroll_vertical = 0
	button.button_down.emit()
	scroll.scroll_vertical = 60
	button.pressed.emit()
	check(tapped.is_empty(), "A press that scrolled isn't a tap")
	button.button_down.emit()
	button.pressed.emit()
	check_eq(tapped, [4], "A plain tap still picks the move")
	game.free()

func test_king_in_check_trembles() -> void:
	var game := _open_fen("4k3/8/8/8/8/8/8/4K2R w - - 0 1")
	_play(game, "Rh8+")
	var king := Board.parse_square("e8")
	check_eq(game.board_view.check_squares(), [king] as Array[Vector2i], "The king in check trembles")
	_play(game, "Ke7")
	check(game.board_view.check_squares().is_empty(), "Out of check: still")
	game.free()

func test_captured_pieces_and_material() -> void:
	var game := _open_fen("4k3/8/8/3p4/4P3/8/8/R3K3 w - - 0 1")
	_play(game, "exd5")
	check_eq(game.captured_bottom.pieces.size(), 1, "White captured one piece")
	check_eq(game.captured_bottom.pieces[0].def.id, "pawn", "A pawn")
	check_eq(game.captured_bottom.advantage_text(), "+5.5", "White is 5.5 ahead (rook 4.5 + pawn against nothing; Rook 4.5 since Oct 2026)")
	check_eq(game.captured_top.pieces.size(), 0, "Black captured nothing")
	check_eq(game.captured_top.advantage_text(), "", "Black isn't ahead")
	game.free()
