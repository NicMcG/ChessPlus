extends TestSuite

## Side lines (Nicholas's fork, Oct 2026): moves made on the board while looking
## back go into a side line beside the game, never into the game itself; the
## move list shows them under the turn they branch from; Plusfish follows the
## line on the board; and the Top moves list names its best moves.

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func _frames(count: int) -> void:
	for i in count:
		await (Engine.get_main_loop() as SceneTree).process_frame

func _open() -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	_root().add_child(game)
	game.board_view.move_time = 0.0
	return game

func _play_all(game: Node, moves: Array) -> void:
	for san: String in moves:
		var move := Notation.find_move(game.state, san)
		check(move != null, "Should be legal: " + san)
		game.play(move)

## A move on the board, in the position it shows (as a tap or drag would).
func _choose(game: Node, san: String) -> void:
	var move := Notation.find_move(game.board_view.state, san)
	check(move != null, "Should be legal on the board: " + san)
	if move:
		game.choose(move)

func _finish() -> void:
	PlusfishLink.enabled = false
	PlusfishLink.pretend_available = false

const OPENING := ["e4", "e5", "Nf3", "Nc6"]

func test_a_move_while_looking_back_starts_a_side_line() -> void:
	var game := _open()
	_play_all(game, OPENING)
	var now := Fen.write(game.state)
	game.view_move(2)
	check(game.board_view.input_enabled, "The board takes moves while looking back")
	_choose(game, "d4")
	check_eq(Fen.write(game.state), now, "The game itself is unchanged")
	check_eq(game.state.history.size(), 4, "...and has its four moves")
	check_eq(game.side_lines.size(), 1, "A side line")
	check_eq(game.side_lines[0]["from"], 2, "Leaving the game after 1. e4 e5")
	check_eq(game.side_lines[0]["moves"], ["d2-d4"], "With the move tried")
	check_eq(game.line_index, 0, "Shown on the board")
	check_eq(game.shown_ply(), 3, "Three moves into it")
	check_eq(Fen.write(game.board_view.state), "rnbqkbnr/pppp1ppp/8/4p3/3PP3/8/PPP2PPP/RNBQKBNR b KQkq d3 0 2", "Board shows 1. e4 e5 2. d4")
	check_eq(game.status_label.text, "Side line: White's move 2", "Status says so")
	_choose(game, "exd4")
	check_eq(game.side_lines.size(), 1, "Carrying on from its last move: the same side line")
	check_eq(game.side_lines[0]["moves"], ["d2-d4", "e5xd4"], "...one move longer")
	check_eq(game.line_ply, 2, "Showing its newest move")
	check_eq(game.status_label.text, "Side line: Black's move 2", "Status follows")
	check_eq(game.move_list.side_line_text(0), "2. d4 exd4", "In the move list")
	check_eq(game.move_list.lines(), PackedStringArray(["1. e4 e5", "2. Nf3 Nc6"]), "The game's moves as before")
	game.free()

func test_the_games_own_move_steps_along_it() -> void:
	var game := _open()
	_play_all(game, OPENING)
	game.view_move(2)
	_choose(game, "Nf3")
	check(game.side_lines.is_empty(), "Playing the game's own move makes no side line")
	check_eq(game.viewing, 3, "...it steps forward along the game")
	check_eq(Fen.write(game.board_view.state), Fen.write(game._replay(3, [])), "Board after 2. Nf3")
	_choose(game, "Nc6")
	check_eq(game.viewing, -1, "The game's last move: back to the game now")
	check(game.board_view.state == game.state, "Board shows the game itself")
	game.free()

func test_trying_another_path() -> void:
	var game := _open()
	_play_all(game, OPENING)
	game.view_move(2)
	_choose(game, "d4")
	_choose(game, "exd4")
	game.step_back()
	check_eq(game.line_ply, 1, "Back: one move earlier in the side line")
	_choose(game, "d6")
	check_eq(game.side_lines.size(), 2, "Another move there: a second side line, the first kept")
	check_eq(game.side_lines[1]["moves"], ["d2-d4", "d7-d6"], "Starting the same way")
	check_eq(game.line_index, 1, "The new one is shown")
	game.view_side_line(0, 1)
	_choose(game, "exd4")
	check_eq(game.side_lines.size(), 2, "A side line's own next move makes no new one")
	check_eq([game.line_index, game.line_ply], [0, 2], "...it steps along it")
	game.view_move(2)
	_choose(game, "d4")
	check_eq(game.side_lines.size(), 2, "Same from the game: d4 follows the first side line")
	check_eq([game.line_index, game.line_ply], [0, 1], "...to its first move")
	game.step_back()
	check_eq([game.line_index, game.viewing], [-1, 2], "Back from its first move: the game, where it left")
	game.free()

func test_back_and_forward_in_a_side_line() -> void:
	var game := _open()
	_play_all(game, OPENING)
	game.view_move(2)
	_choose(game, "d4")
	_choose(game, "exd4")
	check(game.view_nav.visible, "Back / Forward shown")
	check(game.step_forward_button.disabled, "No Forward from a side line's last move")
	game.step_back_button.pressed.emit()
	check(not game.step_forward_button.disabled, "Forward again once back")
	game.step_forward_button.pressed.emit()
	check_eq(game.line_ply, 2, "Forward along the side line")
	game.back_to_game()
	check_eq(game.line_index, -1, "Back to the game")
	check(game.board_view.state == game.state, "Board shows the game")
	check_eq(game.side_lines.size(), 1, "The side line stays in the list")
	game.free()

func test_side_lines_in_the_move_list() -> void:
	var game := _open()
	_play_all(game, OPENING)
	game.view_move(1)
	_choose(game, "c5")
	game.view_move(3)
	_choose(game, "d6")
	check_eq(game.move_list.side_line_text(0), "1... c5", "Black's side line starts with a numbered dots")
	check_eq(game.move_list.side_line_text(1), "2... d6", "Second side line")
	# Each box sits under the turn it branches from: the first after turn 1.
	var body: Array = game.move_list._body.get_children()
	var kinds: Array = body.map(func(node: Node) -> String: return "grid" if node is GridContainer else "line")
	check_eq(kinds, ["grid", "line", "grid", "line", "grid"], "Boxes between the turns")
	var viewed: Button = game.move_list.side_buttons[1][0]
	check(game.move_list.viewed_button == viewed, "The side line's move being looked at is highlighted")
	game.move_list.line_tapped.emit(0, 1)
	check_eq([game.line_index, game.line_ply, game.viewing], [0, 1, 1], "Tapping a side line's move shows it")
	game.move_list.remove_button(1).pressed.emit()
	check_eq(game.side_lines.size(), 1, "x removes a side line")
	check_eq(game.line_index, 0, "The one shown is still shown")
	game.move_list.remove_button(0).pressed.emit()
	check(game.side_lines.is_empty(), "Removed too")
	check_eq([game.line_index, game.viewing], [-1, 1], "Its board goes back to where it left the game")
	game.free()

func test_taking_back_the_game_drops_side_lines_past_it() -> void:
	var game := _open()
	_play_all(game, OPENING)
	game.view_move(1)
	_choose(game, "c5")
	game.view_move(3)
	_choose(game, "d6")
	game.undo()
	game.undo()
	check_eq(game.state.history.size(), 2, "Two moves taken back")
	check_eq(game.side_lines.size(), 1, "The side line from after them is gone")
	check_eq(game.side_lines[0]["from"], 1, "The earlier one stays")
	game.new_game()
	check(game.side_lines.is_empty(), "A new game has none")
	game.free()

func test_from_the_end_of_a_finished_game() -> void:
	var game := _open()
	_play_all(game, ["e4", "e5"])
	game.resign_local()
	game.resign_local()
	check(game.is_over(), "Resigned")
	check(game.board_view.input_enabled, "The board still takes moves")
	_choose(game, "Nf3")
	check_eq(game.state.history.size(), 2, "The game is unchanged")
	check_eq(game.side_lines.size(), 1, "A side line from its last position")
	check_eq(game.side_lines[0]["from"], 2, "...after its two moves")
	check_eq(game.move_list.side_line_text(0), "2. Nf3", "In the list")
	game.step_back()
	check_eq(game.viewing, -1, "Back from its first move: the game now")
	game.free()

func test_play_from_here_takes_the_side_line() -> void:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.white_army = StandardSetup.army()
	game.black_army = StandardSetup.army()
	game.bot_team = Piece.Team.BLACK
	game.bot_level = PracticeBot.Level.EASY
	game.bot_delay_frames = 0
	_root().add_child(game)
	game.board_view.move_time = 0.0
	game.play(Notation.find_move(game.state, "e4"))
	await _frames(2)
	check_eq(game.state.history.size(), 2, "The bot answered")
	game.view_move(0)
	_choose(game, "d4")
	_choose(game, "d5")
	check(game.play_from_here_button.visible, "Play from here in a side line")
	game.play_from_here()
	check_eq(game.state.history.map(func(m: Move) -> String: return m.to_text()), ["d2-d4", "d7-d5"], "The side line is now the game")
	check(game.side_lines.is_empty(), "...and no longer a side line")
	check_eq(game.viewing, -1, "Showing the game now")
	game.free()
	SavedGame.delete_saved()

# --- Plusfish and the Top moves list ---------------------------------------------------------

func _testing_game() -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.testing_position = TestingPosition.standard()
	_root().add_child(game)
	game.board_view.move_time = 0.0
	return game

func _lines(entries: Array) -> Array:
	var lines := []
	for entry: Array in entries:
		lines.append({"move": entry[0], "san": entry[1], "cp": entry[2], "mate": null})
	return lines

func test_plusfish_follows_the_side_line() -> void:
	PlusfishLink.enabled = true
	PlusfishLink.pretend_available = true
	var game := _testing_game()
	_play_all(game, ["e4", "e5"])
	game.view_move(1)
	_choose(game, "c5")
	check_eq(game.shown_line_moves(), ["e2-e4", "c7-c5"], "The line on the board")
	check_eq(game.plusfish._moves_so_far, ["e2-e4", "c7-c5"], "Plusfish is given it")
	check(game.plusfish._need_lines.has(2), "Asked for the top moves of the position shown")
	game.plusfish.results[2] = {"ply": 2, "cp": 20, "mate": null, "outcome": "none", "best": "g1-f3", "best_san": "Nf3",
			"lines": _lines([["g1-f3", "Nf3", 20], ["b1-c3", "Nc3", 10], ["c2-c3", "c3", -5]])}
	game._on_evaluated(2, game.plusfish.results[2])
	check_eq(game.board_view.hint_arrow, [Vector2i(6, 0), Vector2i(5, 2)], "Best move arrow in the side line")
	check(game.eval_bar.known, "And the bar")
	game.view_move(1)
	check_eq(game.plusfish._moves_so_far, ["e2-e4", "e7-e5"], "Back on the game: Plusfish follows it")
	game.free()
	_finish()

func test_top_moves_list() -> void:
	PlusfishLink.enabled = true
	PlusfishLink.pretend_available = true
	var game := _testing_game()
	_play_all(game, ["e4"])
	check(game._top_row.visible, "Testing mode: the Top moves list is there")
	check(game.top_moves_button.disabled, "Nothing to choose until Plusfish answers")
	game.plusfish.results[1] = {"ply": 1, "cp": 30, "mate": null, "outcome": "none", "best": "e7-e5", "best_san": "e5",
			"lines": _lines([["e7-e5", "e5", 30], ["c7-c5", "c5", 45], ["e7-e6", "e6", 60]])}
	game._on_evaluated(1, game.plusfish.results[1])
	check(not game.top_moves_button.disabled, "Answered: it opens")
	check_eq(game.top_moves_button.item_count, 3, "Three moves")
	check_eq(game.top_moves_button.get_item_text(0), "Best: e5  (+0.3)", "The best")
	check_eq(game.top_moves_button.get_item_text(1), "2nd: c5  (+0.5)", "The second best")
	check_eq(game.top_moves_button.get_item_text(2), "3rd: e6  (+0.6)", "The third best")
	check(not game.status_label.text.contains("best:"), "The list names the best move, not the status line")
	check_eq(game.board_view.hint_arrow, [Vector2i(4, 6), Vector2i(4, 4)], "Arrow for the best move")
	game.top_moves_button.item_selected.emit(1)
	check_eq(game.board_view.hint_arrow, [Vector2i(2, 6), Vector2i(2, 4)], "Choosing the second: its arrow")
	check_eq(game.top_moves_button.selected, 1, "...and it stays chosen")
	game._on_evaluated(1, game.plusfish.results[1])
	check_eq(game.board_view.hint_arrow, [Vector2i(2, 6), Vector2i(2, 4)], "...through updates")
	_play_all(game, ["e5"])
	check_eq(game.top_moves_button.selected, 0, "A new position starts on the best again")
	game.free()
	_finish()

func test_top_moves_hidden_where_the_best_move_is() -> void:
	PlusfishLink.enabled = true
	PlusfishLink.pretend_available = true
	var game := _open()
	game.eval_bar_on = true
	_play_all(game, ["e4"])
	check(not game._top_row.visible, "Two players during the game: no Top moves")
	game.free()
	_finish()

func test_scores_as_the_bar_writes_them() -> void:
	var screen: GDScript = load("res://scenes/game/game.gd")
	check_eq(screen.score_text(42, null), "+0.4", "White better")
	check_eq(screen.score_text(-120, null), "-1.2", "Black better")
	check_eq(screen.score_text(3, null), "0.0", "Level")
	check_eq(screen.score_text(19995, 3), "M3", "White mates")
	check_eq(screen.score_text(-19997, -2), "-M2", "Black mates")

# --- PlusfishLink: asking for the top moves --------------------------------------------------

func test_top_moves_are_asked_for_the_position_shown_only() -> void:
	var link := PlusfishLink.new()
	link.analyse(StandardSetup.create_game(), ["e2-e4", "e7-e5"])
	link.results[2] = {"ply": 2, "cp": 30, "best": "g1-f3", "asked": 150000}
	check(link._answered(2), "An answer is enough while the top moves aren't wanted")
	link.prioritise(2, true)
	check(not link._answered(2), "Not once they are: searched again")
	check_eq(link._queue.front(), 2, "...first")
	link._task_lines = true
	check(link._request_text(2, 300000, 3).ends_with('"plies":[2],"nodes":300000,"multipv":3}'), "Asking for three")
	link.results[2]["lines"] = []
	check(link._answered(2), "An answer with them is enough")
	link.free()

func test_answers_with_top_moves_are_kept() -> void:
	var link := PlusfishLink.new()
	var start := StandardSetup.create_game()
	link.analyse_live(start, ["e2-e4"])
	var key: String = link._line_keys[1]
	link._on_answer('{"ply":1,"cp":30,"best":"e7-e5","lines":[]}', 1, key, 300000)
	link._on_answer('{"ply":1,"cp":35,"best":"c7-c5"}', 1, key, 400000)
	check(link.cache[key].has("lines"), "An answer without the top moves (the bot's) doesn't replace one with them")
	link.free()

func test_real_engine_lists_the_top_moves() -> void:
	if PlusfishLink.program_path() == "" or OS.has_feature("web"):
		print("    (Plusfish not built: cargo build --release in engine/plusfish to run this test)")
		return
	PlusfishLink.enabled = true
	var game := _testing_game()
	game.plusfish.desktop_nodes = 20000
	_play_all(game, ["e4", "e5"])
	for i in 2000:
		if game.top_moves_button.item_count == 3:
			break
		await _frames(1)
		OS.delay_msec(10)
	check_eq(game.top_moves_button.item_count, 3, "Three top moves")
	var lines: Array = game.plusfish.results.get(2, {}).get("lines", [])
	check_eq(lines.size(), 3, "Plusfish listed three")
	if lines.size() == 3:
		check(int(lines[0]["cp"]) >= int(lines[1]["cp"]) and int(lines[1]["cp"]) >= int(lines[2]["cp"]), "Best first (White to move)")
		check_eq(lines[0]["move"], game.plusfish.results[2]["best"], "The first is the best move")
		var distinct := {}
		for line: Dictionary in lines:
			distinct[line["move"]] = true
		check_eq(distinct.size(), 3, "Three different moves")
	game.free()
	_finish()
