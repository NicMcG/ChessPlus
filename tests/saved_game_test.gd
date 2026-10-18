extends TestSuite

## Saving a game in progress and continuing it later. The test runner points
## SavedGame at a test file, so the player's real saved game is never touched.

func _open_game(resume: SavedGame = null) -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.white_army = StandardSetup.army()
	game.black_army = StandardSetup.army()
	game.bot_delay_frames = 0
	game.resume = resume
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	return game

func _play(game: Node, san: String) -> void:
	var move := Notation.find_move(game.state, san)
	check(move != null, "Should be legal: " + san)
	if move:
		game.play(move)

func test_round_trip() -> void:
	SavedGame.delete_saved()
	var state := ArmySetup.create_game(StandardSetup.army(), StandardSetup.army(), StandardSetup.create_rules())
	for san in ["e4", "e5", "Nf3"]:
		state.make_move(Notation.find_move(state, san))
	var saved := SavedGame.from_state(state, StandardSetup.army(), StandardSetup.army(), Piece.Team.BLACK, PracticeBot.Level.HARD)
	check_eq(saved.save(), OK, "Saved")
	var loaded := SavedGame.load_saved()
	check(loaded != null, "Loaded")
	if loaded == null:
		return
	check_eq(loaded.bot_team, Piece.Team.BLACK, "Bot side")
	check_eq(loaded.bot_level, PracticeBot.Level.HARD, "Bot level")
	var rebuilt := loaded.create_state(StandardSetup.create_rules())
	check(rebuilt != null, "Rebuilt")
	if rebuilt:
		check_eq(Fen.write(rebuilt), Fen.write(state), "Same position")
		check_eq(Notation.move_list(rebuilt), "1. e4 e5 2. Nf3", "Same moves")
	SavedGame.delete_saved()
	check(SavedGame.load_saved() == null, "Gone after deleting")

func test_broken_file_is_ignored() -> void:
	var file := FileAccess.open(SavedGame.save_path, FileAccess.WRITE)
	file.store_string("not json at all")
	file.close()
	check(SavedGame.load_saved() == null, "Unreadable save gives nothing")
	SavedGame.delete_saved()

func test_unknown_piece_is_ignored() -> void:
	var file := FileAccess.open(SavedGame.save_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"white": {"name": "", "pieces": [["dragon", 0, 0]]}, "black": {"pieces": []}}))
	file.close()
	check(SavedGame.load_saved() == null, "A piece type that no longer exists gives nothing")
	SavedGame.delete_saved()

func test_game_screen_saves_every_move() -> void:
	SavedGame.delete_saved()
	var game := _open_game()
	_play(game, "e4")
	_play(game, "e5")
	var saved := SavedGame.load_saved()
	check(saved != null and saved.moves.size() == 2, "Two moves saved")
	game.undo()
	saved = SavedGame.load_saved()
	check(saved != null and saved.moves.size() == 1, "Undo is saved too")
	game.free()

func test_finished_game_is_not_offered() -> void:
	SavedGame.delete_saved()
	var game := _open_game()
	for san in ["f3", "e5", "g4", "Qh4#"]:
		_play(game, san)
	check(SavedGame.load_saved() == null, "Save removed at checkmate")
	game.free()

func test_continue_where_you_left_off() -> void:
	SavedGame.delete_saved()
	var game := _open_game()
	for san in ["d4", "d5", "c4"]:
		_play(game, san)
	game.free()
	var resumed := _open_game(SavedGame.load_saved())
	check_eq(Notation.move_list(resumed.state), "1. d4 d5 2. c4", "Same moves after continuing")
	check_eq(resumed.status_label.text, "Black to move", "Black's turn")
	resumed.free()
	SavedGame.delete_saved()

func test_menu_offers_continue_only_with_a_save() -> void:
	SavedGame.delete_saved()
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(main)
	check(not main.screen.get_node("%Continue").visible, "No Continue button without a save")
	main.start_game(StandardSetup.army(), StandardSetup.army(), Piece.Team.BLACK, PracticeBot.Level.EASY)
	main.screen.bot_delay_frames = 0
	_play(main.screen, "e4")
	var played: int = main.screen.state.history.size()  # e4, plus the bot's reply.
	main.show_main_menu()
	check(main.screen.get_node("%Continue").visible, "Continue button with a save")
	main.continue_game()
	check_eq(main.screen.bot_team, Piece.Team.BLACK, "Still against the bot")
	check_eq(main.screen.state.history.size(), played, "Moves restored")
	check_eq(main.screen.state.history[0].to_text(), "e2-e4", "Starting with e4")
	main.free()
	SavedGame.delete_saved()
