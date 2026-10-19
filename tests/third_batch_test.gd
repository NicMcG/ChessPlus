extends TestSuite

## The third batch of custom pieces (Mac's designs, Oct 2026).

func _game(fen: String) -> GameState:
	return Fen.parse(fen, PieceCatalog.all_defs(), StandardSetup.create_rules())

## Where the piece on `from` can go: "d4-e5" style moves (a capture is "x").
func _targets(state: GameState, from: String) -> Array:
	var square := Board.parse_square(from)
	var found := []
	for move in state.moves():
		if move.from == square:
			found.append(Board.square_name(move.to) + ("x" if move.is_capture() else ""))
	found.sort()
	return found

func _def(id: String) -> PieceDef:
	return PieceCatalog.all_defs().filter(func(d: PieceDef) -> bool: return d.id == id)[0]

func test_costs_and_symbols() -> void:
	check_eq([_def("princess").value, _def("galleon").value, _def("catapult").value, _def("assassin").value], [7.0, 4.5, 3.0, 2.0], "Costs")
	var symbols := PieceCatalog.all_defs().map(func(d: PieceDef) -> String: return d.symbol)
	for symbol: String in symbols:
		check_eq(symbols.count(symbol), 1, "Symbol %s is unique" % symbol)

func test_princess_slides_up_to_four() -> void:
	var state := _game("k7/8/8/8/3(PR)4/8/8/7K w - - 0 1")
	var targets := _targets(state, "d4")
	check("h8" in targets and "d8" in targets and "a1" in targets, "Reaches 4 away: %s" % [targets])
	check_eq(targets.size(), 27, "8 directions, up to 4 squares (fewer near the edge)")
	state = _game("7k/8/8/8/8/8/8/(PR)6K w - - 0 1")
	targets = _targets(state, "a1")
	check("a5" in targets and not "a6" in targets, "No further than 4")

func test_galleon_moves_like_a_queen_captures_close() -> void:
	var state := _game("k7/8/8/3p4/2p(GA)p3/2p1p3/8/7K w - - 0 1")
	var targets := _targets(state, "d4")
	check("c4x" in targets and "e4x" in targets, "Captures sideways")
	check("c3x" in targets and "e3x" in targets, "Captures diagonally (backwards too)")
	check(not "d5x" in targets, "Can't capture straight ahead")
	state = _game("k7/8/8/8/3(GA)4/8/8/7K w - - 0 1")
	check("d8" in _targets(state, "d4") and "h8" in _targets(state, "d4"), "Moves like a queen")

func test_catapult_steps_and_throws() -> void:
	var state := _game("k7/8/3p4/3p4/3(CT)4/8/8/7K w - - 0 1")
	var targets := _targets(state, "d4")
	check("d6x" in targets, "Captures 2 away, over a piece in between")
	check(not "d5x" in targets, "Can't capture next to it")
	check("c4" in targets and "e5" in targets, "Steps like a king")
	check(_def("catapult").has_jump(), "Jump keyword")

func test_assassin_moves_forward_captures_back() -> void:
	var state := _game("k7/8/8/8/3(AS)4/2ppp3/8/7K w - - 0 1")
	var targets := _targets(state, "d4")
	check_eq(targets, ["c3x", "c5", "d3x", "d5", "d6", "e3x", "e5"], "Up to 2 forward, 1 diagonally forward; captures the 3 squares behind")
	state = _game("k7/8/8/3p4/3(AS)4/8/8/7K w - - 0 1")
	check(not "d6" in _targets(state, "d4"), "Forward move is blocked")
