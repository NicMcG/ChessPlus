extends TestSuite

## The Man, Cannon, Lance and Paladin, the Promote and Shield keywords, and
## two-letter symbols.

const KING = preload("res://data/pieces/king.tres")
const QUEEN = preload("res://data/pieces/queen.tres")
const ROOK = preload("res://data/pieces/rook.tres")
const MAN = preload("res://data/pieces/man.tres")
const CANNON = preload("res://data/pieces/cannon.tres")
const LANCE = preload("res://data/pieces/lance.tres")
const PALADIN = preload("res://data/pieces/paladin.tres")

func _parse(fen: String) -> GameState:
	return Fen.parse(fen, PieceCatalog.all_defs(), StandardSetup.create_rules())

func _moves_of(state: GameState, id: String) -> Array:
	var texts := []
	for move in state.moves():
		if move.piece.def.id == id:
			texts.append(move.to_text())
	texts.sort()
	return texts

func _sans(state: GameState) -> Array:
	return state.moves().map(func(m: Move) -> String: return Notation.san(state, m))

func test_costs_and_tags() -> void:
	check_eq([MAN.value, CANNON.value, LANCE.value, PALADIN.value], [3.0, 4.0, 3.5, 2.0], "Costs")
	check(not CANNON.has_castle(), "Cannon has no Castle keyword")
	check(LANCE.has_promote() and LANCE.can_promote() and not LANCE.is_pawn_type(), "Lance: Promote, not a pawn")
	check(PALADIN.has_shield(), "Paladin: Shield")
	check_eq(PALADIN.symbol, "PD", "Paladin symbol")

# --- Man ---------------------------------------------------------------------------

func test_man_moves_one_square_any_way() -> void:
	var state := _parse("7k/8/8/8/3M4/8/8/K7 w - - 0 1")
	check_eq(_moves_of(state, "man").size(), 8, "Eight squares")

func test_man_is_not_royal() -> void:
	# Attacking a man isn't check, and it can walk into attacks.
	var state := _parse("7k/8/8/8/3M3r/8/8/K7 w - - 0 1")
	check(not state.is_in_check(), "Not check")
	check(_moves_of(state, "man").has("d4-d3"), "Not stopped by attacks")

# --- Cannon ------------------------------------------------------------------------

func test_cannon_piece_hops_to_capture() -> void:
	var state := _parse("k7/8/8/4p3/8/4P3/8/4C2K w - - 0 1")
	check(_sans(state).has("Cxe5"), "Cxe5 over the e3 pawn")
	check(not _sans(state).has("Cxe3"), "Can't take its own screen")

func test_no_castling_with_a_cannon() -> void:
	var white := Army.new()
	white.place(KING, Vector2i(4, 0))
	white.place(CANNON, Vector2i(7, 0))
	var black := Army.new()
	black.place(KING, Vector2i(4, 0))
	var game := ArmySetup.create_game(white, black, StandardSetup.create_rules())
	check(not game.moves().any(func(m: Move) -> bool: return m.is_castling()), "No castling")

# --- Lance -------------------------------------------------------------------------

func test_lance_slides_forward_only() -> void:
	var state := _parse("k7/8/8/8/3L4/8/8/7K w - - 0 1")
	# Reaching the last row it must promote (standard choices in a FEN game).
	check_eq(_moves_of(state, "lance"), ["d4-d5", "d4-d6", "d4-d7", "d4-d8=B", "d4-d8=N", "d4-d8=Q", "d4-d8=R"], "White: up only")
	state = _parse("k7/8/8/8/3l4/8/8/7K b - - 0 1")
	check_eq(_moves_of(state, "lance"), ["d4-d1=B", "d4-d1=N", "d4-d1=Q", "d4-d1=R", "d4-d2", "d4-d3"], "Black: down only")

func test_lance_promotes_like_a_pawn() -> void:
	var white := Army.new()
	white.place(KING, Vector2i(4, 0))
	white.place(LANCE, Vector2i(0, 0))
	white.place(QUEEN, Vector2i(3, 0))
	var black := Army.new()
	black.place(KING, Vector2i(4, 0))
	black.place(ROOK, Vector2i(0, 0))  # Turned round for Black: on h8.
	var game := ArmySetup.create_game(white, black, StandardSetup.create_rules())
	var to_a8 := _moves_of(game, "lance").filter(func(t: String) -> bool: return t.begins_with("a1-a8"))
	check_eq(to_a8, ["a1-a8=L", "a1-a8=Q", "a1-a8=R"], "Must promote; same choices as pawns (queen, rook, lance)")

func test_lance_does_not_reset_fifty_moves() -> void:
	var state := _parse("k7/8/8/8/3L4/8/8/7K w - - 10 30")
	state.make_move(state.find_move("d4-d5"))
	check_eq(state.halfmove_clock, 11, "Lance move counts toward 50")

# --- Paladin and Shield ---------------------------------------------------------------

func test_paladin_moves_one_square_straight() -> void:
	var state := _parse("k7/8/8/8/3(PD)4/8/8/7K w - - 0 1")
	check_eq(_moves_of(state, "paladin"), ["d4-c4", "d4-d3", "d4-d5", "d4-e4"], "Four squares")
	check(_sans(state).has("PDd5"), "Written PDd5")

func test_two_letter_symbols_in_positions() -> void:
	for fen in ["k7/8/8/8/3(PD)4/8/8/7K w - - 0 1", "k7/8/8/3(pd)4/8/8/8/7K b - - 0 1", "k7/8/8/3(pd)'4/8/8/8/7K b - - 0 1"]:
		check_eq(Fen.write(_parse(fen)), fen, "Round trip " + fen)
	check(_parse("k7/8/8/3(pd)'4/8/8/8/7K b - - 0 1").board.get_piece(Board.parse_square("d5")).shield_broken, "' means shield broken")

func test_first_capture_only_breaks_the_shield() -> void:
	# White rook on d1 "captures" the black paladin on d5.
	var state := _parse("k7/8/8/3(pd)4/8/8/8/3R3K w - - 7 20")
	check(Notation.find_move(state, "Rxd5") == null, "Not a plain capture while the shield is up")
	var hit := Notation.find_move(state, "Rxd5*")
	check(hit != null and hit.breaks_shield(), "Rxd5* breaks the shield")
	state.make_move(hit)
	check_eq(state.board.get_piece(Board.parse_square("d1")).def, ROOK, "Rook stays on d1")
	var paladin := state.board.get_piece(Board.parse_square("d5"))
	check(paladin.def == PALADIN and paladin.shield_broken, "Paladin still there, shield gone")
	check_eq(state.side_to_move, Piece.Team.BLACK, "Turn used up")
	check_eq(state.halfmove_clock, 0, "Counts as a capture for the 50-move rule")
	check_eq(Fen.write(state), "k7/8/8/3(pd)'4/8/8/8/3R3K b - - 0 20", "Position")
	state.undo_move(hit)
	check(not paladin.shield_broken, "Undo gives the shield back")
	check_eq(Fen.write(state), "k7/8/8/3(pd)4/8/8/8/3R3K w - - 7 20", "Position after undo")

func test_second_capture_takes_the_paladin() -> void:
	var state := _parse("k7/8/8/3(pd)'4/8/8/8/3R3K w - - 0 20")
	var take := Notation.find_move(state, "Rxd5")
	check(take != null and not take.breaks_shield(), "A real capture now")
	state.make_move(take)
	check_eq(state.board.get_piece(Board.parse_square("d5")).def, ROOK, "Rook on d5")

func test_pawn_breaking_a_shield_on_the_last_rank_does_not_promote() -> void:
	var state := _parse("k2(pd)4/4P3/8/8/8/8/8/7K w - - 0 1")
	var hits := state.moves().filter(func(m: Move) -> bool: return m.breaks_shield())
	check_eq(hits.size(), 1, "One shield-break move, no promotion choices")
	if hits.size() == 1:
		check(hits[0].promotion == null, "No promotion")
		check_eq(Notation.san(state, hits[0]), "exd8*", "Written like a capture, with *")

func test_king_breaking_a_shield_stays_safe() -> void:
	# The king stays on e1 when it hits the paladin on d2, so the rook on d8 (which
	# would attack d2 once the paladin was gone) doesn't make that illegal.
	var state := _parse("k2r4/8/8/8/8/8/3(pd)4/4K3 w - - 0 1")
	check(_sans(state).has("Kxd2*"), "King can break the shield")

func test_breaking_a_checking_shield_does_not_end_the_check() -> void:
	# The shielded paladin on e2 checks the king. Hitting it leaves it there, still
	# giving check, so the king must step away instead.
	var state := _parse("k7/8/8/8/8/8/4(pd)3/4K3 w - - 0 1")
	check(state.is_in_check(), "In check from the paladin")
	var sans := _sans(state)
	check(not sans.has("Kxe2*"), "Can't just hit the shield")
	check(sans.has("Kf1") and sans.has("Kd1"), "Must move away")

func test_shield_state_counts_for_repetition() -> void:
	var a := _parse("k7/8/8/3(pd)4/8/8/8/3R3K w - - 0 1")
	var b := _parse("k7/8/8/3(pd)'4/8/8/8/3R3K w - - 0 1")
	check(a._position_key() != b._position_key(), "Broken shield = different position")
