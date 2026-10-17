extends TestSuite

func _parse(text: String) -> GameState:
	return Fen.parse(text, StandardSetup.piece_defs())

func _texts(moves: Array[Move]) -> Array:
	var texts := moves.map(func(m: Move) -> String: return m.to_text())
	texts.sort()
	return texts

func test_pinned_piece_cannot_move() -> void:
	# The bishop on e2 is pinned to its king by the rook on e7.
	var state := _parse("4k3/4r3/8/8/8/8/4B3/4K3 w - - 0 1")
	check_eq(_texts(state.moves()), ["e1-d1", "e1-d2", "e1-f1", "e1-f2"], "Only king moves")

func test_must_get_out_of_check() -> void:
	# The queen on d2 checks the king. It can take the queen or step to f1.
	var state := _parse("4k3/8/8/8/8/8/3q4/4K3 w - - 0 1")
	check(state.is_in_check(), "White should be in check")
	check_eq(_texts(state.moves()), ["e1-f1", "e1xd2"], "Escapes")

func test_checkmate_has_no_moves() -> void:
	# Fool's mate: 1. f3 e5 2. g4 Qh4#
	var state := _parse("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
	check(state.is_in_check(), "White should be in check")
	check_eq(state.moves().size(), 0, "Moves when checkmated")

func test_stalemate_has_no_moves() -> void:
	var state := _parse("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
	check(not state.is_in_check(), "Black should not be in check")
	check_eq(state.moves().size(), 0, "Moves when stalemated")

func test_knight_check() -> void:
	check(_parse("4k3/8/8/8/8/5n2/8/4K3 w - - 0 1").is_in_check(), "Knight on f3 checks e1")

func test_pawns_attack_forward_only() -> void:
	check(_parse("4k3/8/8/8/8/8/3p4/4K3 w - - 0 1").is_in_check(), "Black pawn d2 checks e1")
	check(not _parse("4k3/8/8/8/8/3p4/8/4K3 w - - 0 1").is_in_check(), "Black pawn d3 doesn't check e1")
	check(_parse("4k3/3P4/8/8/8/8/8/4K3 b - - 0 1").is_in_check(), "White pawn d7 checks e8")
	check(not _parse("4k3/8/8/8/8/8/8/3PK3 w - - 0 1").is_in_check(), "Own pawn doesn't check")

func test_pawn_forward_move_is_not_an_attack() -> void:
	# A pawn moving straight ahead can't capture, so e3 is safe from the e4 pawn.
	var board := _parse("4k3/8/8/8/4p3/8/8/4K3 w - - 0 1").board
	check(not MoveGenerator.is_attacked(board, Vector2i(4, 2), Piece.Team.BLACK), "e3 not attacked by e4 pawn")
	check(MoveGenerator.is_attacked(board, Vector2i(3, 2), Piece.Team.BLACK), "d3 attacked by e4 pawn")

func test_sliders_are_blocked() -> void:
	var board := _parse("4k3/8/8/8/8/8/8/r2PK3 w - - 0 1").board
	check(not MoveGenerator.is_attacked(board, Vector2i(4, 0), Piece.Team.BLACK), "Rook blocked by d1 pawn")
	check(MoveGenerator.is_attacked(board, Vector2i(3, 0), Piece.Team.BLACK), "Rook attacks the d1 pawn")
