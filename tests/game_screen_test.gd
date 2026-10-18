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
	check_eq(game.moves_label.text, "1. e4", "Move list after undo")
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
	check_eq(game.moves_label.text, game.TIP, "Tip instead of an empty move list")
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
