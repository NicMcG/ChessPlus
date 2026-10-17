extends TestSuite

func test_starting_position() -> void:
	var board := StandardSetup.create_board()
	print(board.to_text())
	check_eq(board.get_piece(Vector2i(4, 0)).def.id, "king", "Piece on e1")
	check_eq(board.get_piece(Vector2i(4, 0)).team, Piece.Team.WHITE, "Team on e1")
	check_eq(board.get_piece(Vector2i(3, 7)).def.id, "queen", "Piece on d8")
	check_eq(board.get_piece(Vector2i(3, 7)).team, Piece.Team.BLACK, "Team on d8")
	check(board.is_empty(Vector2i(4, 3)), "e4 should be empty")

func test_square_names() -> void:
	check_eq(Board.square_name(Vector2i(0, 0)), "a1", "(0, 0)")
	check_eq(Board.square_name(Vector2i(4, 3)), "e4", "(4, 3)")
	check_eq(Board.square_name(Vector2i(7, 7)), "h8", "(7, 7)")

func test_off_board_is_null() -> void:
	var board := StandardSetup.create_board()
	check(board.get_piece(Vector2i(-1, 0)) == null, "(-1, 0) should be null")
	check(board.get_piece(Vector2i(8, 8)) == null, "(8, 8) should be null")
