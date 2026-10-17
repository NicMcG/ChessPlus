extends TestSuite

func test_turn_alternates() -> void:
	var state := GameState.new(StandardSetup.create_board())
	check_eq(state.side_to_move, Piece.Team.WHITE, "First turn")
	state.make_move(state.find_move("e2-e4"))
	check_eq(state.side_to_move, Piece.Team.BLACK, "After e4")

func test_make_and_undo_restores_start() -> void:
	var state := GameState.new(StandardSetup.create_board())
	var start_text := state.board.to_text()
	var e4 := state.find_move("e2-e4")
	state.make_move(e4)
	var e5 := state.find_move("e7-e5")
	state.make_move(e5)
	print(state.board.to_text())
	check(state.board.get_piece(Vector2i(4, 3)).has_moved, "Pawn on e4 should be marked moved")
	check(state.board.is_empty(Vector2i(4, 1)), "e2 should be empty")
	state.undo_move(e5)
	state.undo_move(e4)
	check_eq(state.board.to_text(), start_text, "Board after undoing both")
	check_eq(state.side_to_move, Piece.Team.WHITE, "Turn after undoing both")
	check(not state.board.get_piece(Vector2i(4, 1)).has_moved, "Pawn back on e2 should be unmoved")
	check(not state.board.get_piece(Vector2i(4, 6)).has_moved, "Pawn back on e7 should be unmoved")

func test_capture_and_undo() -> void:
	var state := GameState.new(StandardSetup.create_board())
	state.make_move(state.find_move("e2-e4"))
	state.make_move(state.find_move("d7-d5"))
	var before := state.board.to_text()
	var exd5 := state.find_move("e4xd5")
	check(exd5 != null, "e4xd5 should be available")
	check_eq(exd5.captured.team, Piece.Team.BLACK, "Captured piece's team")
	state.make_move(exd5)
	check_eq(state.board.get_piece(Vector2i(3, 4)).team, Piece.Team.WHITE, "d5 after capture")
	state.undo_move(exd5)
	check_eq(state.board.to_text(), before, "Board after undoing the capture")
