extends TestSuite

func _texts(state: GameState) -> Array:
	var texts := state.moves().map(func(m: Move) -> String: return m.to_text())
	texts.sort()
	return texts

func test_one_move_per_option() -> void:
	var state := StandardSetup.from_fen("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1")
	var pawn_moves := _texts(state).filter(func(t: String) -> bool: return t.begins_with("b7"))
	check_eq(pawn_moves, ["b7-b8=B", "b7-b8=N", "b7-b8=Q", "b7-b8=R"], "Promotion choices")

func test_capture_promotion() -> void:
	var state := StandardSetup.from_fen("r3k3/1P6/8/8/8/8/8/4K3 w - - 0 1")
	var texts := _texts(state)
	check(texts.has("b7xa8=N"), "Capture and promote to knight")
	check(not texts.has("b7xa8"), "Must promote when capturing onto the last rank")

func test_promote_and_undo() -> void:
	var state := StandardSetup.from_fen("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1")
	var before := Fen.write(state)
	var move := state.find_move("b7-b8=Q")
	state.make_move(move)
	var queen := state.board.get_piece(Vector2i(1, 7))
	check_eq(queen.def.id, "queen", "Piece on b8")
	check_eq(queen.team, Piece.Team.WHITE, "Team on b8")
	check(state.is_in_check(), "New queen should check the black king")
	state.undo_move(move)
	check_eq(state.board.get_piece(Vector2i(1, 6)).def.id, "pawn", "Pawn back on b7")
	check_eq(Fen.write(state), before, "Position after undo")

func test_black_promotes_on_rank_1() -> void:
	var state := StandardSetup.from_fen("4k3/8/8/8/8/8/6p1/K7 b - - 0 1")
	check(_texts(state).has("g2-g1=Q"), "Black promotes on rank 1")

func test_no_options_means_no_promotion() -> void:
	# With an empty options list, the pawn just moves to the last rank.
	var state := StandardSetup.from_fen("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1")
	state.rules = GameRules.new()
	check(_texts(state).has("b7-b8"), "Plain move to b8")
