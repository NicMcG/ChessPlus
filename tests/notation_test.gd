extends TestSuite

## The SAN of every legal move, sorted.
func _all_san(state: GameState) -> Array:
	var texts := state.moves().map(func(m: Move) -> String: return Notation.san(state, m))
	texts.sort()
	return texts

func _san_of(state: GameState, test_text: String) -> String:
	var move := state.find_move(test_text)
	check(move != null, "Move should be available: " + test_text)
	return Notation.san(state, move) if move else ""

func _play(state: GameState, sans: Array) -> void:
	for text in sans:
		var move := Notation.find_move(state, text)
		check(move != null, "Move should be available: " + text)
		if move == null:
			return
		state.make_move(move)

func test_opening_moves() -> void:
	var texts := _all_san(StandardSetup.create_game())
	check(texts.has("e4"), "Pawns have no letter")
	check(texts.has("Nf3"), "Knight move")
	check_eq(texts.size(), 20, "One SAN per move")

func test_pawn_capture_uses_file() -> void:
	var state := StandardSetup.create_game()
	_play(state, ["e4", "d5"])
	check_eq(_san_of(state, "e4xd5"), "exd5", "Pawn capture")

func test_disambiguation() -> void:
	var knights := StandardSetup.from_fen("4k3/8/8/8/8/8/8/1N2KN2 w - - 0 1")
	check_eq(_san_of(knights, "b1-d2"), "Nbd2", "By file")
	check_eq(_san_of(knights, "f1-d2"), "Nfd2", "By file")
	var rooks := StandardSetup.from_fen("4k3/8/8/8/8/R7/8/R3K3 w - - 0 1")
	check_eq(_san_of(rooks, "a1-a2"), "R1a2", "By rank")
	check_eq(_san_of(rooks, "a3-a2"), "R3a2", "By rank")
	var queens := StandardSetup.from_fen("4k3/8/8/8/8/Q7/8/Q1Q1K3 w - - 0 1")
	check_eq(_san_of(queens, "a1-b2"), "Qa1b2", "By file and rank")
	check_eq(_san_of(queens, "c1-b2"), "Qcb2", "By file")
	check_eq(_san_of(queens, "a3-b2"), "Q3b2", "By rank")

func test_pinned_piece_needs_no_disambiguation() -> void:
	# The e2 knight is pinned, so only the b1 knight can really go to c3.
	var state := StandardSetup.from_fen("4k3/4r3/8/8/8/8/4N3/1N2K3 w - - 0 1")
	check_eq(_san_of(state, "b1-c3"), "Nc3", "No disambiguation")

func test_castling() -> void:
	var state := StandardSetup.from_fen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	check_eq(_san_of(state, "e1-g1"), "O-O", "Kingside")
	check_eq(_san_of(state, "e1-c1"), "O-O-O", "Queenside")

func test_promotion_and_check() -> void:
	var state := StandardSetup.from_fen("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1")
	check_eq(_san_of(state, "b7-b8=Q"), "b8=Q+", "Promotion with check")
	check_eq(_san_of(state, "b7-b8=N"), "b8=N", "Underpromotion")

func test_checkmate_mark() -> void:
	var state := StandardSetup.create_game()
	_play(state, ["f3", "e5", "g4"])
	check_eq(_san_of(state, "d8-h4"), "Qh4#", "Checkmate")

func test_en_passant() -> void:
	var state := StandardSetup.from_fen("rnbqkbnr/ppp1p1pp/8/3pPp2/8/8/PPPP1PPP/RNBQKBNR w KQkq f6 0 3")
	check_eq(_san_of(state, "e5xf6"), "exf6", "En passant")

func test_move_list() -> void:
	var state := StandardSetup.create_game()
	_play(state, ["e4", "e5", "Nf3"])
	check_eq(Notation.move_list(state), "1. e4 e5 2. Nf3", "Move list")
	check_eq(state.history.size(), 3, "Move list leaves the game as it was")
	_play(state, ["Nc6"])
	check_eq(Notation.move_list(state), "1. e4 e5 2. Nf3 Nc6", "Move list")

func test_move_list_with_result() -> void:
	var state := StandardSetup.create_game()
	_play(state, ["f3", "e5", "g4", "Qh4#"])
	check_eq(Notation.move_list(state), "1. f3 e5 2. g4 Qh4# 0-1", "Fool's mate")

func test_move_list_starting_with_black() -> void:
	var state := StandardSetup.from_fen("4k3/8/8/8/8/8/8/R3K3 b - - 0 30")
	_play(state, ["Kd7", "Ra7+"])
	check_eq(Notation.move_list(state), "30... Kd7 31. Ra7+", "Black moves first")

## If every move's SAN is different, reading a SAN back always finds the right move.
func test_every_move_has_its_own_san() -> void:
	for fen in [PerftTest.KIWIPETE, PerftTest.POSITION_3, PerftTest.POSITION_4, PerftTest.POSITION_5]:
		var state := StandardSetup.from_fen(fen)
		var seen := {}
		for move in state.moves():
			var text := Notation.san(state, move)
			check(not seen.has(text), "Two moves share the SAN %s in %s" % [text, fen])
			seen[text] = true
