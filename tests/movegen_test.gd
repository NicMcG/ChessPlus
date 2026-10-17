extends TestSuite

func _texts(moves: Array[Move]) -> Array:
	return moves.map(func(m: Move) -> String: return m.to_text())

func test_white_has_20_opening_moves() -> void:
	var state := StandardSetup.create_game()
	check_eq(state.moves().size(), 20, "White moves")

func test_black_has_20_opening_moves() -> void:
	var state := StandardSetup.create_game()
	state.side_to_move = Piece.Team.BLACK
	var texts := _texts(state.moves())
	check_eq(texts.size(), 20, "Black moves")
	# Black's pawns must move down the board.
	check(texts.has("e7-e5"), "Black should have e7-e5")
	check(not texts.has("e7-e8"), "Black pawn moved the wrong way")
