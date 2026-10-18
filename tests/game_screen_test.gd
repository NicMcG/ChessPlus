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
	check(not game.board_view.input_enabled, "No moving while looking back")
	check(game.status_label.text == "Viewing 1. e4", "Status says so")
	var viewed_box: StyleBoxFlat = game.move_list.buttons[0].get_theme_stylebox("normal")
	check_eq(viewed_box.bg_color, MoveList.VIEWED_BG, "Viewed move highlighted")
	check(not game.play_from_here_button.visible, "Play from here is only for bot games")
	game.view_move(3)
	check_eq(game.viewing, -1, "Tapping the last move returns to the game")
	check(game.board_view.state == game.state, "Board shows the game again")
	check(game.board_view.input_enabled, "Moving allowed again")
	game.free()

func test_black_move_name() -> void:
	var game := _open()
	for san in ["e4", "e5", "Nf3"]:
		_play(game, san)
	game.view_move(2)
	check(game.status_label.text == "Viewing 1... e5", "Black's move: 1... e5")
	game.free()

func test_play_from_here_against_the_bot() -> void:
	var game := _open_bot_game(Piece.Team.BLACK)
	_play(game, "e4")
	_play(game, "d4")
	check_eq(game.state.history.size(), 4, "Two moves each")
	game.view_move(2)
	check(game.play_from_here_button.visible, "Button shown while looking back")
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
