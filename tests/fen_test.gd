extends TestSuite

const KIWIPETE := "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"

func _parse(text: String) -> GameState:
	return StandardSetup.from_fen(text)

func _check_round_trip(text: String) -> void:
	var state := _parse(text)
	check(state != null, "Should parse: " + text)
	if state:
		check_eq(Fen.write(state), text, "Round trip")

func test_start_matches_standard_setup() -> void:
	var state := _parse(Fen.STANDARD_START)
	check_eq(state.board.to_text(), StandardSetup.create_board().to_text(), "Board from FEN")
	check_eq(state.side_to_move, Piece.Team.WHITE, "Side to move")

func test_round_trips() -> void:
	_check_round_trip(Fen.STANDARD_START)
	_check_round_trip(KIWIPETE)
	_check_round_trip("rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2")
	_check_round_trip("r3k2r/8/8/8/8/8/8/R3K2R b Kq - 5 40")
	_check_round_trip("4k3/8/8/8/8/8/8/4K3 w - - 0 1")

func test_castling_rights_set_moved_flags() -> void:
	var board := _parse("r3k2r/8/8/8/8/8/8/R3K2R w Kq - 0 1").board
	check(not board.get_piece(Vector2i(4, 0)).has_moved, "White king unmoved")
	check(not board.get_piece(Vector2i(7, 0)).has_moved, "h1 rook unmoved (K)")
	check(board.get_piece(Vector2i(0, 0)).has_moved, "a1 rook moved (no Q)")
	check(not board.get_piece(Vector2i(0, 7)).has_moved, "a8 rook unmoved (q)")
	check(board.get_piece(Vector2i(7, 7)).has_moved, "h8 rook moved (no k)")

func test_pawns_on_start_rank_are_unmoved() -> void:
	var board := _parse("rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2").board
	check(not board.get_piece(Vector2i(3, 1)).has_moved, "d2 pawn unmoved")
	check(board.get_piece(Vector2i(4, 3)).has_moved, "e4 pawn moved")
	check(board.get_piece(Vector2i(4, 4)).has_moved, "e5 pawn moved")

func test_en_passant_square() -> void:
	var state := _parse("rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2")
	check_eq(state.en_passant_squares, [Vector2i(4, 5)] as Array[Vector2i], "En passant square")
	check_eq(state.en_passant_victim, Vector2i(4, 4), "Pawn that can be taken")

func test_move_number_counts_black_moves() -> void:
	var state := _parse(Fen.STANDARD_START)
	var e4 := state.find_move("e2-e4")
	state.make_move(e4)
	check_eq(state.fullmove_number, 1, "After 1. e4")
	var e5 := state.find_move("e7-e5")
	state.make_move(e5)
	check_eq(state.fullmove_number, 2, "After 1... e5")
	state.undo_move(e5)
	state.undo_move(e4)
	check_eq(Fen.write(state), Fen.STANDARD_START, "After undoing both")
