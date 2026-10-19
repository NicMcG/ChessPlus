extends TestSuite

## The eval bar for looking over a finished game: EvalBar's scale and text,
## the request PlusfishLink sends, the game screen showing it only once the
## game is over, and (when Plusfish has been built) the real engine.

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func _frames(count: int) -> void:
	for i in count:
		await (Engine.get_main_loop() as SceneTree).process_frame

func _play_all(game: Node, moves: Array) -> void:
	for san in moves:
		game.play(Notation.find_move(game.state, san))

const FOOLS_MATE := ["f3", "e5", "g4", "Qh4#"]

func _open_game() -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	_root().add_child(game)
	game.board_view.move_time = 0.0
	return game

func _finish() -> void:
	PlusfishLink.enabled = false
	PlusfishLink.pretend_available = false

# --- EvalBar -------------------------------------------------------------------------

func test_bar_scale_and_text() -> void:
	var bar := EvalBar.new()
	check_eq(bar.score_text(), "...", "Unknown until evaluated")
	check_eq(bar.target(), 0.5, "Unknown sits in the middle")
	bar.set_score(0, null)
	check_eq(bar.score_text(), "0.0", "Level")
	check_eq(bar.target(), 0.5, "Level = half")
	bar.set_score(300, null)
	check_eq(bar.score_text(), "+3.0", "White better")
	check(bar.target() > 0.75 and bar.target() < 0.96, "Mostly White's: %s" % bar.target())
	bar.set_score(-150, null)
	check_eq(bar.score_text(), "-1.5", "Black better")
	check(bar.target() < 0.5, "Mostly Black's")
	bar.set_score(5000, null)
	check_eq(bar.target(), 0.96, "Never quite full without a mate")
	bar.set_score(19995, 3)
	check_eq(bar.score_text(), "M3", "White mates in 3")
	check_eq(bar.target(), 1.0, "Mate fills it")
	bar.set_score(-19997, -2)
	check_eq(bar.score_text(), "M2", "Black mates in 2")
	check_eq(bar.target(), 0.0, "Black's mate empties it")
	bar.set_score(-20000, 0, "0-1")
	check_eq(bar.score_text(), "0-1", "Game over shows the result")
	bar.set_score(0, null, "1/2-1/2")
	check_eq(bar.score_text(), "½", "Draw")
	bar.free()

# --- The request ----------------------------------------------------------------------

func test_request_describes_the_game() -> void:
	var start := ArmySetup.create_game(StandardSetup.army(), StandardSetup.army(), StandardSetup.create_rules())
	var request := PlusfishLink.request_for(start, ["e2-e4", "e7-e5"])
	var ids: Array = request["pieces"].map(func(p: Dictionary) -> String: return p["id"])
	for def in PieceCatalog.all_defs():
		check(ids.has(def.id), "Sends piece type " + def.id)
	check_eq(request["board"].size(), 32, "Every piece on the board")
	check(request["board"].has(["king", Piece.Team.BLACK, 4, 7, false, false, false, false]), "Black's king on e8, unmoved")
	check_eq(request["moves"], ["e2-e4", "e7-e5"], "The moves")
	check_eq(request["promo"].size(), 4, "Promotion choices from the armies")
	var pawn: Dictionary = request["pieces"][ids.find("pawn")]
	check_eq(pawn["rules"][0]["first_move_max_steps"], 2, "Move rules go with it")
	# JSON can carry it (no Godot-only values inside).
	check(JSON.parse_string(JSON.stringify(request)) is Dictionary, "Turns into JSON")

func test_request_mirrors_black_armies_as_the_game_does() -> void:
	var army := Army.new()
	army.place(load("res://data/pieces/king.tres"), Vector2i(4, 0))
	army.place(load("res://data/pieces/rook.tres"), Vector2i(0, 0))
	var start := ArmySetup.create_game(army, army, StandardSetup.create_rules())
	var board: Array = PlusfishLink.request_for(start, [])["board"]
	check(board.has(["rook", Piece.Team.BLACK, 7, 7, false, false, false, false]), "Black's rook where the game put it (h8)")

## A start with the new pieces' state: a Vampire's gained shield, a lost Ghost
## that can still Haunt, and a Werewolf (whose wolf form goes along too).
func _new_pieces_start() -> GameState:
	var start := Fen.parse("4k3/8/8/3v+4/8/8/(WW)7/4K2(BD) w - - 0 1", PieceCatalog.all_defs(), StandardSetup.create_rules())
	start.lost[Piece.Team.WHITE].append(Piece.new(load("res://data/pieces/ghost.tres"), Piece.Team.WHITE))
	return start

func test_request_carries_the_new_rules() -> void:
	var request := PlusfishLink.request_for(_new_pieces_start(), ["@e4"])
	var pieces := {}
	for p: Dictionary in request["pieces"]:
		pieces[p["id"]] = p
	check(pieces.has("werewolf_wolf"), "The wolf form is sent with the Werewolf")
	check_eq(pieces["werewolf"]["transforms_into"], "werewolf_wolf", "And linked to it")
	check_eq(pieces["parapet"]["blocks_jumps"], true, "The Parapet blocks jumps")
	check_eq(pieces["vampire"]["shield_on_capture"], true, "The Vampire gains shields")
	check_eq(pieces["squire"]["protects"], ["knight"], "The Squire protects knights")
	check_eq(pieces["jester"]["decoy"], true, "The Jester takes hits")
	check(request["board"].has(["vampire", Piece.Team.BLACK, 3, 4, false, false, false, true]), "The Vampire's gained shield")
	check_eq(request["lost"], [["ghost", Piece.Team.WHITE, false]], "The lost Ghost, Haunt unused")
	check(JSON.parse_string(JSON.stringify(request)) is Dictionary, "Turns into JSON")

# --- The game screen --------------------------------------------------------------------

func test_bar_during_the_game_only_when_chosen() -> void:
	PlusfishLink.enabled = true
	PlusfishLink.pretend_available = true
	var game := _open_game()
	game.eval_bar_on = true
	_play_all(game, ["e4"])
	check(game.eval_bar.visible, "Chosen: shown during the game")
	game.plusfish.results[1] = {"ply": 1, "cp": 30, "mate": null, "outcome": "none", "best": "e7-e5", "best_san": "e5"}
	game._on_evaluated(1, game.plusfish.results[1])
	check(game.eval_bar.known, "Shows the score")
	check(game.board_view.hint_arrow.is_empty(), "But no best-move arrow while the game is on")
	game.free()
	PlusfishLink.pretend_available = false
	PlusfishLink.enabled = false

func test_bar_only_after_the_game() -> void:
	PlusfishLink.enabled = true
	PlusfishLink.pretend_available = true
	var game := _open_game()
	_play_all(game, ["f3", "e5"])
	check(not game.eval_bar.visible, "No bar during the game")
	game.view_move(1)
	check(not game.eval_bar.visible, "Not even when looking back mid-game")
	game.back_to_game()
	_play_all(game, ["g4", "Qh4#"])
	check(game.eval_bar.visible, "Bar once it's over")
	check(game._board_area.ratio > 1.0, "Board area widens for it")
	check(not game.eval_bar.known, "Waiting for Plusfish")
	# Hand in Plusfish's answers (the real engine is tested below).
	game.plusfish.results[4] = {"ply": 4, "cp": -20000, "mate": 0, "outcome": "checkmate", "best": "", "best_san": ""}
	game._on_evaluated(4, game.plusfish.results[4])
	check(game.eval_bar.known, "Final position known")
	check_eq(game.eval_bar.score_text(), "0-1", "Shows the result")
	game.view_move(3)
	check(not game.eval_bar.known, "Earlier position not known yet")
	game.plusfish.results[3] = {"ply": 3, "cp": -19999, "mate": -1, "outcome": "none", "best": "d8-h4", "best_san": "Qh4#"}
	game._on_evaluated(3, game.plusfish.results[3])
	check_eq(game.eval_bar.score_text(), "M1", "Mate in one for Black")
	check_eq(game.board_view.hint_arrow, [Vector2i(3, 7), Vector2i(7, 3)], "Best move arrow d8-h4")
	check(game.status_label.text.ends_with("best: Qh4#"), "Status names the best move: " + game.status_label.text)
	game.undo()
	check(not game.eval_bar.visible, "Undo: game on again, bar gone")
	check_eq(game.board_view.hint_arrow, [], "Arrow gone too")
	game.free()
	_finish()

func test_bar_follows_the_board_round() -> void:
	PlusfishLink.enabled = true
	PlusfishLink.pretend_available = true
	var game := _open_game()
	game.board_view.flipped = true
	_play_all(game, FOOLS_MATE)
	check(game.eval_bar.flipped, "White's end at the top when Black is at the bottom")
	game.free()
	_finish()

# --- The real engine (only if Plusfish has been built) -------------------------------------

func test_real_engine_finds_the_mate() -> void:
	if PlusfishLink.program_path() == "" or OS.has_feature("web"):
		print("    (Plusfish not built: cargo build --release in engine/plusfish to run this test)")
		return
	PlusfishLink.enabled = true
	var game := _open_game()
	game.plusfish.desktop_nodes = 20000
	_play_all(game, FOOLS_MATE)
	# Wait (up to ~20 s) for every position.
	for i in 2000:
		if game.plusfish.results.size() == 5:
			break
		await _frames(1)
		OS.delay_msec(10)
	check_eq(game.plusfish.results.size(), 5, "All five positions evaluated")
	var before_mate: Dictionary = game.plusfish.results.get(3, {})
	check_eq(before_mate.get("best"), "d8-h4", "Plusfish finds Qh4#")
	check_eq(before_mate.get("mate"), -1.0, "Black mates in 1")
	var start: Dictionary = game.plusfish.results.get(0, {})
	check(absi(int(start.get("cp", 999))) < 100, "Start position about level: %s" % start.get("cp"))
	check_eq(game.plusfish.results.get(4, {}).get("outcome"), "checkmate", "Final position is mate")
	game.view_move(3)
	check(game.eval_bar.known and game.eval_bar.score_text() == "M1", "Bar shows the mate")
	game.free()
	_finish()

func test_real_engine_follows_the_new_abilities() -> void:
	if PlusfishLink.program_path() == "" or OS.has_feature("web"):
		print("    (Plusfish not built: cargo build --release in engine/plusfish to run this test)")
		return
	# Haunt, a capture of the Ghost by the shielded Vampire, Full Moon, then
	# Song of Slumber: Plusfish must replay every one to evaluate each position.
	var start := _new_pieces_start()
	var moves := ["@e4", "d5xe4", "a2!", "e8-d8", "h1~e4"]
	var replay := _new_pieces_start()
	for text: String in moves:
		var move := replay.find_move(text)
		check(move != null, "The game allows " + text)
		replay.make_move(move)
	var link := PlusfishLink.new()
	_root().add_child(link)
	link.desktop_nodes = 5000
	link.analyse(start, moves)
	for i in 2000:
		if link.results.size() == moves.size() + 1:
			break
		await _frames(1)
		OS.delay_msec(10)
	check_eq(link.results.size(), moves.size() + 1, "Every position evaluated")
	check(str(link.results.get(0, {}).get("best", "")) != "", "A best move at the start")
	link.free()
