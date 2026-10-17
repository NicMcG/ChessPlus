extends TestSuite

func _parse(text: String) -> GameState:
	return Fen.parse(text, StandardSetup.piece_defs())

func _texts(state: GameState) -> Array:
	return state.moves().map(func(m: Move) -> String: return m.to_text())

func test_double_step_sets_en_passant_square() -> void:
	var state := _parse(Fen.STANDARD_START)
	state.make_move(state.find_move("e2-e4"))
	check_eq(state.en_passant_squares, [Vector2i(4, 2)] as Array[Vector2i], "Square skipped by e4")
	check_eq(state.en_passant_victim, Vector2i(4, 3), "Pawn that can be taken")
	state.make_move(state.find_move("g8-f6"))
	check(state.en_passant_squares.is_empty(), "En passant chance gone after one move")

func test_single_step_sets_nothing() -> void:
	var state := _parse(Fen.STANDARD_START)
	state.make_move(state.find_move("e2-e3"))
	check(state.en_passant_squares.is_empty(), "No en passant after e3")
	state.make_move(state.find_move("b8-c6"))
	state.make_move(state.find_move("g1-f3"))
	check(state.en_passant_squares.is_empty(), "No en passant after a knight move")

func test_capture_removes_the_passed_pawn() -> void:
	# Black has just played f7-f5 next to White's e5 pawn.
	var state := _parse("rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3")
	var before := Fen.write(state)
	var capture := state.find_move("e5xf6")
	check(capture != null, "e5xf6 en passant should be available")
	check(state.find_move("e5xd6") == null, "d5 pawn didn't just move, so no e5xd6")
	if capture == null:
		return
	state.make_move(capture)
	check(state.board.is_empty(Vector2i(5, 4)), "f5 pawn should be gone")
	check_eq(state.board.get_piece(Vector2i(5, 5)).team, Piece.Team.WHITE, "White pawn on f6")
	state.undo_move(capture)
	check_eq(Fen.write(state), before, "Position after undo")

func test_black_captures_en_passant() -> void:
	var state := _parse("rnbqkbnr/ppp1pppp/8/8/2Pp4/8/PP1PPPPP/RNBQKBNR b KQkq c3 0 2")
	check(_texts(state).has("d4xc3"), "Black should have d4xc3 en passant")

func test_en_passant_cannot_expose_king() -> void:
	# Taking en passant would clear both pawns off rank 5, letting the rook hit the king.
	var state := _parse("8/8/8/K2pP2r/8/8/8/7k w - d6 0 1")
	check(not _texts(state).has("e5xd6"), "e5xd6 would leave the king in check")
