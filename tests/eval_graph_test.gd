extends TestSuite

## The eval graph after a game and the mistakes and blunders marked from it:
## MoveQuality's judging, EvalGraph's drawing scale and taps, and the game
## screen showing both once the game is over (Plusfish's answers handed in).

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func _result(ply: int, cp: int, best := "", mate: Variant = null, outcome := "none") -> Dictionary:
	return {"ply": ply, "cp": cp, "mate": mate, "outcome": outcome, "best": best, "best_san": best}

func _finish() -> void:
	PlusfishLink.enabled = false
	PlusfishLink.pretend_available = false

# --- MoveQuality -------------------------------------------------------------------------

func test_chances_from_scores() -> void:
	check_eq(MoveQuality.white_chances(_result(0, 0)), 0.0, "Level = even chances")
	var up := MoveQuality.white_chances(_result(0, 300))
	check(up > 0.4 and up < 0.6, "+3 is a good lead, not a win: %s" % up)
	check(MoveQuality.white_chances(_result(0, -300)) < -0.4, "Black's lead is negative")
	check(MoveQuality.white_chances(_result(0, 5000)) > 0.99, "A huge lead is nearly a win")
	check_eq(MoveQuality.white_chances(_result(0, 19995, "", 3)), 1.0, "White mates: a win")
	check_eq(MoveQuality.white_chances(_result(0, -19997, "", -2)), -1.0, "Black mates: a loss")
	check_eq(MoveQuality.white_chances(_result(0, -20000, "", 0, "checkmate")), -1.0, "White checkmated")
	check_eq(MoveQuality.white_chances(_result(0, 0, "", null, "stalemate")), 0.0, "A draw")

func test_judging_one_move() -> void:
	var white := Piece.Team.WHITE
	var black := Piece.Team.BLACK
	check_eq(MoveQuality.judge(_result(0, 30), _result(1, 10), white), MoveQuality.Mark.NONE, "A small loss is fine")
	check_eq(MoveQuality.judge(_result(0, 0), _result(1, -150), white), MoveQuality.Mark.MISTAKE, "Level to -1.5: a mistake")
	check_eq(MoveQuality.judge(_result(0, 100), _result(1, -300), white), MoveQuality.Mark.BLUNDER, "+1 to -3: a blunder")
	check_eq(MoveQuality.judge(_result(0, 900), _result(1, 600), white), MoveQuality.Mark.NONE,
			"+9 to +6 is still winning: not a mistake")
	check_eq(MoveQuality.judge(_result(0, 200), _result(1, -19998, "", -1), white), MoveQuality.Mark.BLUNDER,
			"Allowing mate is a blunder")
	check_eq(MoveQuality.judge(_result(0, 800), _result(1, 0, "", null, "stalemate"), white), MoveQuality.Mark.BLUNDER,
			"Stalemating from a winning position is a blunder")
	check_eq(MoveQuality.judge(_result(0, 100), _result(1, -300), black), MoveQuality.Mark.NONE,
			"The same swing is good for Black")
	check_eq(MoveQuality.judge(_result(0, -100), _result(1, 300), black), MoveQuality.Mark.BLUNDER,
			"Black throwing the game away")
	check_eq(MoveQuality.judge(_result(0, 19998, "", 1), _result(1, -10), white), MoveQuality.Mark.BLUNDER,
			"Missing a mate and ending up level")

func test_marks_for_a_game() -> void:
	var results := {
		0: _result(0, 20, "e2-e4"),
		1: _result(1, 30, "e7-e5"),
		2: _result(2, 300, "d2-d4"),   # Black's move lost a lot
		3: _result(3, -200, "g8-f6"),  # White's move threw it all away
		# Ply 4 not evaluated yet.
		5: _result(5, -900, ""),
	}
	var moves := ["e2-e4", "f7-f6", "d1-h5", "g8-f6", "a7-a6"]
	var movers := [Piece.Team.WHITE, Piece.Team.BLACK, Piece.Team.WHITE, Piece.Team.BLACK, Piece.Team.WHITE]
	var marks := MoveQuality.marks(results, moves, movers)
	check(not marks.has(1), "Playing the engine's own move is never marked")
	check_eq(marks.get(2), MoveQuality.Mark.BLUNDER, "Black's second move (ply 2)")
	check_eq(marks.get(3), MoveQuality.Mark.BLUNDER, "White's move to ply 3")
	check(not marks.has(4) and not marks.has(5), "Not judged until both positions are known")
	check_eq(MoveQuality.sign_of(MoveQuality.Mark.MISTAKE), "?", "Mistake sign")
	check_eq(MoveQuality.sign_of(MoveQuality.Mark.BLUNDER), "??", "Blunder sign")

# --- EvalGraph ---------------------------------------------------------------------------

func test_graph_scale_and_taps() -> void:
	var graph := EvalGraph.new()
	graph.custom_minimum_size = Vector2.ZERO
	graph.size = Vector2(212, 100)
	graph.show_game(4, {0: 0.0, 4: 1.0}, {}, 4, false)
	check_eq(graph.x_for(0), EvalGraph.DOT_RADIUS, "The start at the left")
	check_eq(graph.x_for(4), 212 - EvalGraph.DOT_RADIUS, "The end at the right")
	for ply in 5:
		check_eq(graph.ply_at(graph.x_for(ply)), ply, "Tapping ply %d's place finds it" % ply)
	check_eq(graph.ply_at(-50), 0, "Left of the graph = the start")
	check_eq(graph.ply_at(500), 4, "Right of it = the end")
	check_eq(graph.y_for(0.0), 50.0, "Even = the middle")
	check_eq(graph.y_for(1.0), 0.0, "White winning reaches the top")
	check_eq(graph.y_for(-1.0), 100.0, "Black winning: none of it")
	graph.flipped = true
	check_eq(graph.y_for(1.0), 100.0, "Turned round: White's end at the top, so it fills down")
	var chosen := []
	graph.ply_chosen.connect(func(ply: int) -> void: chosen.append(ply))
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = Vector2(graph.x_for(1), 50)
	graph._gui_input(press)
	var drag := InputEventMouseMotion.new()
	drag.button_mask = MOUSE_BUTTON_MASK_LEFT
	drag.position = Vector2(graph.x_for(1) + 2, 50)
	graph._gui_input(drag)
	drag = drag.duplicate()
	drag.position = Vector2(graph.x_for(3), 50)
	graph._gui_input(drag)
	check_eq(chosen, [1, 3], "A tap and a drag choose positions (each once)")
	graph.free()

# --- The game screen ---------------------------------------------------------------------

const FOOLS_MATE := ["f3", "e5", "g4", "Qh4#"]

func _fools_mate_game() -> Node:
	PlusfishLink.enabled = true
	PlusfishLink.pretend_available = true
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	_root().add_child(game)
	game.board_view.move_time = 0.0
	return game

func _hand_in(game: Node, result: Dictionary) -> void:
	game.plusfish.results[int(result["ply"])] = result
	game._on_evaluated(int(result["ply"]), result)

func test_graph_and_marks_after_the_game() -> void:
	var game := _fools_mate_game()
	for san in ["f3", "e5"]:
		game.play(Notation.find_move(game.state, san))
	check(not game.eval_graph.visible, "No graph during the game")
	for san in ["g4", "Qh4#"]:
		game.play(Notation.find_move(game.state, san))
	check(game.eval_graph.visible, "Graph once the game is over")
	check_eq(game.eval_graph.plies, 4, "Covers all four moves")
	check(game.eval_graph.chances.is_empty(), "Nothing evaluated yet")
	_hand_in(game, _result(4, -20000, "", 0, "checkmate"))
	_hand_in(game, _result(3, -19999, "d8-h4", -1))
	_hand_in(game, _result(2, -60, "d2-d4"))
	_hand_in(game, _result(1, -40, "e7-e5"))
	_hand_in(game, _result(0, 20, "e2-e4"))
	check_eq(game.eval_graph.chances.size(), 5, "Every position on the graph")
	check_eq(game.eval_graph.chances[4], -1.0, "Ends with Black's win")
	check_eq(game.move_marks, {3: MoveQuality.Mark.BLUNDER}, "g4 (allowing mate) is the only blunder")
	check_eq(game.eval_graph.marks, game.move_marks, "Marked on the graph")
	check_eq(game.move_list.mark_signs(), PackedStringArray(["", "", "??", ""]), "And in the move list")
	check_eq(game.move_list.lines(), PackedStringArray(["1. f3 e5", "2. g4 Qh4#"]), "The moves' text is unchanged")
	# Tapping the graph shows that position.
	game.eval_graph.ply_chosen.emit(3)
	check_eq(game.viewing, 3, "Graph tap: looking at the position after g4")
	check_eq(game.eval_graph.current, 3, "The graph marks where you're looking")
	check(game.status_label.text.contains("Blunder"), "Status says so: " + game.status_label.text)
	check(game.status_label.text.ends_with("best: d8-h4"), "Best move still shown: " + game.status_label.text)
	game.view_move(2)
	check(not game.status_label.text.contains("Blunder"), "Not on other moves: " + game.status_label.text)
	game.eval_graph.ply_chosen.emit(4)
	check_eq(game.viewing, -1, "The last position is the game itself")
	# Undo: the game is on again, graph and marks gone.
	game.undo()
	check(not game.eval_graph.visible, "Undo hides the graph")
	check(game.move_marks.is_empty(), "And the marks")
	check_eq(game.move_list.mark_signs(), PackedStringArray(["", "", ""]), "Move list unmarked")
	game.free()
	_finish()

func test_marks_appear_as_answers_come() -> void:
	var game := _fools_mate_game()
	for san in FOOLS_MATE:
		game.play(Notation.find_move(game.state, san))
	game.view_move(3)
	_hand_in(game, _result(3, -19999, "d8-h4", -1))
	check(not game.status_label.text.contains("Blunder"), "Can't judge g4 without the position before it")
	_hand_in(game, _result(2, -60, "d2-d4"))
	check(game.status_label.text.contains("Blunder"), "Judged once it comes: " + game.status_label.text)
	check_eq(game.move_list.mark_signs()[2], "??", "Move list too")
	game.free()
	_finish()

func test_no_graph_without_plusfish() -> void:
	PlusfishLink.enabled = false
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	_root().add_child(game)
	game.board_view.move_time = 0.0
	for san in FOOLS_MATE:
		game.play(Notation.find_move(game.state, san))
	check(not game.eval_graph.visible, "No Plusfish, no graph")
	game.free()
	_finish()

func test_graph_follows_the_board_round() -> void:
	var game := _fools_mate_game()
	game.board_view.flipped = true
	for san in FOOLS_MATE:
		game.play(Notation.find_move(game.state, san))
	check(game.eval_graph.flipped, "White's end at the top when Black is at the bottom")
	game.free()
	_finish()
