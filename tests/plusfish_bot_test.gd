extends TestSuite

## The Plusfish bot level: against it, the game screen asks the Plusfish engine
## (res://engine/plusfish/) for the bot's moves, and the Hard bot plays instead
## wherever Plusfish can't. The tests with the real engine skip if it isn't built.

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func _frames(count: int) -> void:
	for i in count:
		await (Engine.get_main_loop() as SceneTree).process_frame

func _finish() -> void:
	PlusfishLink.enabled = false
	PlusfishLink.pretend_available = false

func _engine_missing() -> bool:
	if PlusfishLink.program_path() == "" or OS.has_feature("web"):
		print("    (Plusfish not built: cargo build --release in engine/plusfish to run this test)")
		return true
	return false

func _open_plusfish_game(bot_team := Piece.Team.BLACK) -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.white_army = StandardSetup.army()
	game.black_army = StandardSetup.army()
	game.bot_team = bot_team
	game.bot_level = PracticeBot.Level.PLUSFISH
	game.bot_delay_frames = 0
	game.bot_min_seconds = 0.0
	_root().add_child(game)
	game.board_view.move_time = 0.0
	return game

func _play(game: Node, san: String) -> void:
	game.play(Notation.find_move(game.state, san))

## Waits (up to `seconds`) until the game has `count` moves.
func _wait_for_moves(game: Node, count: int, seconds: float) -> void:
	var give_up := Time.get_ticks_msec() + int(seconds * 1000.0)
	while game.state.history.size() < count and Time.get_ticks_msec() < give_up:
		await _frames(1)
		OS.delay_msec(10)

func test_plusfish_is_a_level() -> void:
	check_eq(PracticeBot.LEVEL_NAMES[PracticeBot.Level.PLUSFISH], "Plusfish", "Listed as Plusfish")
	check(PracticeBot.SETTINGS.has(PracticeBot.Level.PLUSFISH), "Has settings for when the Hard bot stands in")

func test_match_setup_offers_plusfish_only_where_it_runs() -> void:
	var setup: Node = load("res://scenes/menu/match_setup.tscn").instantiate()
	setup.library = ArmyLibrary.new("user://test_armies/")
	_root().add_child(setup)
	check_eq(setup.level_pick.item_count, 4, "Four levels")
	check_eq(setup.level_pick.get_item_text(PracticeBot.Level.PLUSFISH), "Plusfish", "Plusfish last")
	check(setup.level_pick.is_item_disabled(PracticeBot.Level.PLUSFISH), "Off when Plusfish can't run")
	PlusfishLink.enabled = true
	PlusfishLink.pretend_available = true
	setup.update_plusfish_choice()
	check(not setup.level_pick.is_item_disabled(PracticeBot.Level.PLUSFISH), "On once it can")
	var started := []
	setup.start_requested.connect(func(_w: Army, _b: Army, bot_team: int, level: int) -> void: started.append([bot_team, level]))
	setup.opponent_pick.select(setup.PRACTICE_BOT)
	setup.level_pick.select(PracticeBot.Level.PLUSFISH)
	setup.side_pick.select(setup.SIDE_WHITE)
	setup.start()
	check_eq(started, [[Piece.Team.BLACK, PracticeBot.Level.PLUSFISH]], "Starts a Plusfish game")
	setup.free()
	_finish()

func test_hard_bot_plays_where_plusfish_cant() -> void:
	var game := _open_plusfish_game()
	_play(game, "e4")
	check_eq(game.state.history.size(), 2, "The Hard bot answered at once")
	check(game.last_notice.contains("Hard bot"), "Says the Hard bot is playing: " + game.last_notice)
	game.free()

func test_plusfish_move_or_the_hard_bots() -> void:
	var game := _open_plusfish_game()
	check_eq(game.engine_move_or_fallback("e2-e4").to_text(), "e2-e4", "Plays Plusfish's move")
	for best in ["", "z9-z9"]:
		var move: Move = game.engine_move_or_fallback(best)
		check(move != null and game.state.find_move(move.to_text()) != null, "A legal move instead of '%s'" % best)
	game.free()

func test_plusfish_plays_its_best_move() -> void:
	if _engine_missing():
		return
	PlusfishLink.enabled = true
	var game := _open_plusfish_game()
	game.bot_engine.desktop_nodes = 20000
	_play(game, "e4")
	check(game.bot_thinking, "Thinking while Plusfish searches")
	check(not game.board_view.input_enabled, "Board closed meanwhile")
	await _wait_for_moves(game, 2, 20.0)
	check_eq(game.state.history.size(), 2, "Plusfish answered")
	var found: Dictionary = game.bot_engine.results.get(1, {})
	check_eq(game.state.history[1].to_text(), found.get("best", "?"), "Played Plusfish's best move")
	check(game.board_view.input_enabled, "Your turn again")
	check(game.last_notice == "", "No note about the Hard bot")
	game.free()
	_finish()

func test_plusfish_moves_first_as_white() -> void:
	if _engine_missing():
		return
	PlusfishLink.enabled = true
	var game := _open_plusfish_game(Piece.Team.WHITE)
	game.bot_engine.desktop_nodes = 20000
	await _wait_for_moves(game, 1, 20.0)
	check_eq(game.state.history.size(), 1, "Plusfish opened")
	check_eq(game.state.side_to_move, Piece.Team.BLACK, "Your turn")
	game.free()
	_finish()

func test_closing_the_screen_while_plusfish_thinks() -> void:
	if _engine_missing():
		return
	PlusfishLink.enabled = true
	var game := _open_plusfish_game()
	_play(game, "e4")
	check(game.bot_thinking, "Plusfish is thinking")
	game.free()
	# The waiting turn must end quietly (errors would fail this test).
	await _frames(10)
	_finish()
