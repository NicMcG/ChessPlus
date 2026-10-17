extends TestSuite

const BOTH_SIDES := "r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1"

func _parse(text: String) -> GameState:
	return StandardSetup.from_fen(text)

func _texts(state: GameState) -> Array:
	return state.moves().map(func(m: Move) -> String: return m.to_text())

func test_both_sides_available() -> void:
	var texts := _texts(_parse(BOTH_SIDES))
	check(texts.has("e1-g1"), "White kingside")
	check(texts.has("e1-c1"), "White queenside")
	texts = _texts(_parse(BOTH_SIDES.replace(" w ", " b ")))
	check(texts.has("e8-g8"), "Black kingside")
	check(texts.has("e8-c8"), "Black queenside")

func test_castling_moves_the_rook_and_undoes() -> void:
	var state := _parse(BOTH_SIDES)
	var castle := state.find_move("e1-g1")
	state.make_move(castle)
	check_eq(state.board.get_piece(Vector2i(6, 0)).def.id, "king", "King on g1")
	check_eq(state.board.get_piece(Vector2i(5, 0)).def.id, "rook", "Rook on f1")
	check(state.board.is_empty(Vector2i(7, 0)), "h1 empty")
	check_eq(Fen.write(state), "r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1", "FEN after O-O")
	state.undo_move(castle)
	check_eq(Fen.write(state), BOTH_SIDES, "FEN after undo")
	castle = state.find_move("e1-c1")
	state.make_move(castle)
	check_eq(Fen.write(state), "r3k2r/8/8/8/8/8/8/2KR3R b kq - 1 1", "FEN after O-O-O")

func test_not_out_of_check() -> void:
	var texts := _texts(_parse("4k3/4r3/8/8/8/8/8/R3K2R w KQ - 0 1"))
	check(not texts.has("e1-g1") and not texts.has("e1-c1"), "No castling while in check")

func test_not_through_check() -> void:
	# The f8 rook attacks f1, which the king would cross.
	var texts := _texts(_parse("4kr2/8/8/8/8/8/8/R3K2R w KQ - 0 1"))
	check(not texts.has("e1-g1"), "No kingside castling across f1")
	check(texts.has("e1-c1"), "Queenside still fine")

func test_not_into_check() -> void:
	var texts := _texts(_parse("4k1r1/8/8/8/8/8/8/R3K2R w KQ - 0 1"))
	check(not texts.has("e1-g1"), "No castling onto attacked g1")

func test_attacked_b1_is_fine() -> void:
	# On the queenside the king never crosses b1, only the rook does.
	check(_texts(_parse("1r2k3/8/8/8/8/8/8/R3K2R w KQ - 0 1")).has("e1-c1"), "Queenside with b1 attacked")

func test_blocked() -> void:
	var texts := _texts(_parse("4k3/8/8/8/8/8/8/RN2K1NR w KQ - 0 1"))
	check(not texts.has("e1-c1"), "Knight on b1 blocks queenside")
	check(not texts.has("e1-g1"), "Knight on g1 blocks kingside")

func test_rights_lost_after_moving() -> void:
	var state := _parse(BOTH_SIDES)
	state.make_move(state.find_move("h1-h2"))
	check_eq(Fen.write(state).split(" ")[2], "Qkq", "Rights after the h1 rook moves")
	state.make_move(state.find_move("e8-d8"))
	check_eq(Fen.write(state).split(" ")[2], "Q", "Rights after the black king moves")
	state.make_move(state.find_move("h2-h1"))
	state.make_move(state.find_move("d8-e8"))
	var texts := _texts(state)
	check(not texts.has("e1-g1"), "Rook went back, but has moved: no kingside")
	check(texts.has("e1-c1"), "Queenside still allowed")

func test_captured_rook_loses_right() -> void:
	var state := _parse("r3k2r/8/8/8/8/8/6b1/R3K2R b KQkq - 0 1")
	state.make_move(state.find_move("g2xh1"))
	check_eq(Fen.write(state).split(" ")[2], "Qkq", "Rights after h1 rook is taken")
