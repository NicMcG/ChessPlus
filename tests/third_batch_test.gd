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

# --- Batch 2: Parapet, Vampire, Squire, Jester -----------------------------------

func _has_move(state: GameState, text: String) -> bool:
	return state.find_move(text) != null

func test_parapet_stops_knights_two_straight_then_one() -> void:
	var state := _game("k7/8/8/8/8/8/8/1N5K w - - 0 1")
	check_eq(_targets(state, "b1"), ["a3", "c3", "d2"], "A free knight")
	state = _game("k7/8/8/8/8/8/1(PA)6/1N5K w - - 0 1")
	check_eq(_targets(state, "b1"), ["d2"], "Parapet on b2: a3 and c3 pass over it (b2, b3 first)")
	state = _game("k7/8/8/8/8/8/8/1N(pa)4K w - - 0 1")
	check(not "d2" in _targets(state, "b1"), "An enemy Parapet on c1 stops b1-d2 (c1, d1 first)")

func test_parapet_stops_leaps() -> void:
	var state := _game("k7/8/8/8/8/8/3(PA)4/2E4K w - - 0 1")
	check(not "e3" in _targets(state, "c1"), "Elephant can't jump over it")
	state = _game("k7/8/8/8/8/3(PA)4/8/3W3K w - - 0 1")
	check(not "d4" in _targets(state, "d1"), "Wizard can't leap it")

func test_parapet_is_no_screen() -> void:
	var state := _game("r6k/8/8/8/P7/8/8/C6K w - - 0 1")
	check("a8x" in _targets(state, "a1"), "A pawn is a screen")
	state = _game("r6k/8/8/8/(PA)7/8/8/C6K w - - 0 1")
	check(not "a8x" in _targets(state, "a1"), "A Parapet isn't")

func test_parapet_blocks_check() -> void:
	check(_game("4k3/8/8/8/8/3n4/8/4K3 w - - 0 1").is_in_check(), "The knight on d3 checks e1")
	check(not _game("4k3/8/8/8/8/3n4/3(PA)4/4K3 w - - 0 1").is_in_check(), "Not over a Parapet on d2 (even your own)")

func test_vampire_gains_a_shield_by_capturing() -> void:
	var state := _game("k7/8/8/8/4p3/3V4/8/7K w - - 0 1")
	var vampire := state.board.get_piece(Board.parse_square("d3"))
	check(not vampire.has_active_shield(), "No shield to start with")
	var move := state.find_move("d3xe4")
	state.make_move(move)
	check(vampire.has_active_shield(), "Shield after capturing")
	check(Fen.write(state).contains("V+"), "Saved in positions: " + Fen.write(state))
	check(Fen.parse(Fen.write(state), PieceCatalog.all_defs(), StandardSetup.create_rules()).board.get_piece(Board.parse_square("e4")).gained_shield, "And read back")
	state.undo_move(move)
	check(not vampire.has_active_shield(), "Undo takes it away")

func test_vampire_shield_breaks_like_a_paladin() -> void:
	var state := _game("k3r3/8/8/8/4V+3/8/8/7K b - - 0 1")
	var vampire := state.board.get_piece(Board.parse_square("e4"))
	var hit := state.find_move("e8xe4")
	check(hit != null and hit.breaks_shield(), "The first capture only breaks the shield")
	state.make_move(hit)
	check(not vampire.has_active_shield(), "Shield gone")
	check(state.board.get_piece(Board.parse_square("e4")) == vampire, "Vampire still there")
	state.undo_move(hit)
	check(vampire.has_active_shield(), "Undo puts it back")

func test_squire_protects_knights() -> void:
	var state := _game("k7/8/8/b7/8/2N5/8/7K b - - 0 1")
	check(_has_move(state, "a5xc3"), "Without a Squire the knight can be taken")
	state = _game("k7/8/8/b7/8/2N5/8/2(SQ)4K b - - 0 1")
	check(not _has_move(state, "a5xc3"), "With a Squire 2 squares away, it can't")
	state = _game("k7/8/8/b7/8/2N5/2P5/2(SQ)4K b - - 0 1")
	check(_has_move(state, "a5xc3"), "Unless the Squire's way is blocked")

func test_jester_takes_the_hit() -> void:
	var state := _game("k7/2b5/8/4R3/3J4/8/8/7K b - - 0 1")
	var rook := state.board.get_piece(Board.parse_square("e5"))
	var jester := state.board.get_piece(Board.parse_square("d4"))
	var move := state.find_move("c7xe5")
	check(move != null and move.captured == jester, "Capturing the rook takes the Jester instead")
	state.make_move(move)
	check_eq(state.board.get_piece(Board.parse_square("d4")), rook, "The rook moved to the Jester's square")
	check_eq(state.board.get_piece(Board.parse_square("e5")).def.id, "bishop", "The bishop took the Jester on e5")
	check(state.lost[Piece.Team.WHITE].has(jester), "The Jester is lost")
	state.undo_move(move)
	check_eq(state.board.get_piece(Board.parse_square("e5")), rook, "Undo: rook back")
	check_eq(state.board.get_piece(Board.parse_square("d4")), jester, "Undo: Jester back")
	state = _game("k7/2b5/8/4P3/3J4/8/8/7K b - - 0 1")
	check_eq(state.find_move("c7xe5").captured.def.id, "pawn", "Pawns aren't swapped")

func test_jester_swap_animates_and_plusfish_steps_aside() -> void:
	var state := _game("k7/2b5/8/4R3/3J4/8/8/7K b - - 0 1")
	var jester := state.board.get_piece(Board.parse_square("d4"))
	check(not PlusfishLink.supports(state), "Plusfish doesn't know the Jester's rule yet")
	check(PlusfishLink.supports(StandardSetup.create_game()), "But it does know standard chess")
	var move := state.find_move("c7xe5")
	state.make_move(move)
	var animation := MoveAnimation.for_move(move, state, false)
	check(animation.has_segment(jester, "hop"), "The Jester jumps into the way")
	check(animation.has_segment(jester, "knock"), "And is knocked off")
	check(animation.has_segment(move.decoy_piece, "slide"), "The rook moves to the Jester's square")
