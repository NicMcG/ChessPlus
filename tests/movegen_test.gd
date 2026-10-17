extends TestSuite

func test_white_has_20_opening_moves() -> void:
	var board := StandardSetup.create_board()
	check_eq(MoveGenerator.pseudo_legal_moves(board, Piece.Team.WHITE).size(), 20, "White moves")

func test_black_has_20_opening_moves() -> void:
	var board := StandardSetup.create_board()
	var moves := MoveGenerator.pseudo_legal_moves(board, Piece.Team.BLACK)
	check_eq(moves.size(), 20, "Black moves")
	# Black's pawns must move down the board.
	var texts := moves.map(func(m: Move) -> String: return m.to_text())
	check(texts.has("e7-e5"), "Black should have e7-e5")
	check(not texts.has("e7-e8"), "Black pawn moved the wrong way")
