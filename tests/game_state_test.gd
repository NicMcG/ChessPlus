extends TestSuite

func test_turn_alternates() -> void:
	var state := StandardSetup.create_game()
	check_eq(state.side_to_move, Piece.Team.WHITE, "First turn")
	state.make_move(state.find_move("e2-e4"))
	check_eq(state.side_to_move, Piece.Team.BLACK, "After e4")

func test_make_and_undo_restores_start() -> void:
	var state := StandardSetup.create_game()
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
	var state := StandardSetup.create_game()
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

## The board's per-team piece lists (used for speed) must always match the squares.
func _check_piece_lists(state: GameState, when: String) -> void:
	for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
		var scanned := {}
		for rank in range(state.board.height):
			for file in range(state.board.width):
				var piece := state.board.get_piece(Vector2i(file, rank))
				if piece and piece.team == team:
					scanned[Vector2i(file, rank)] = piece
		check_eq(state.board.pieces_of(team), scanned, "%s: team %d" % [when, team])

func test_piece_lists_after_one_move() -> void:
	var state := StandardSetup.from_fen(PerftTest.KIWIPETE)
	for move in state.moves():
		state.make_move(move)
		_check_piece_lists(state, Notation.move_list(state))
		state.undo_move(move)
	_check_piece_lists(state, "After undoing everything")

func slow_test_piece_lists_stay_in_step() -> void:
	# Kiwipete has captures, castling, en passant and promotions within two moves.
	var state := StandardSetup.from_fen(PerftTest.KIWIPETE)
	_check_piece_lists(state, "Start")
	for first in state.moves():
		state.make_move(first)
		for second in state.moves():
			state.make_move(second)
			_check_piece_lists(state, Notation.move_list(state))
			state.undo_move(second)
		state.undo_move(first)
	_check_piece_lists(state, "After undoing everything")

func test_piece_lists_with_shields() -> void:
	var state := Fen.parse("k7/8/8/3(pd)4/8/8/8/3R3K w - - 0 1", PieceCatalog.all_defs(), StandardSetup.create_rules())
	var hit := Notation.find_move(state, "Rxd5*")
	state.make_move(hit)
	_check_piece_lists(state, "After the shield break")
	state.undo_move(hit)
	_check_piece_lists(state, "After undo")
