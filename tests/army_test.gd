extends TestSuite

## Armies: the budget and limits, and building a game from two armies.

const PAWN = preload("res://data/pieces/pawn.tres")
const KNIGHT = preload("res://data/pieces/knight.tres")
const BISHOP = preload("res://data/pieces/bishop.tres")
const ROOK = preload("res://data/pieces/rook.tres")
const QUEEN = preload("res://data/pieces/queen.tres")
const KING = preload("res://data/pieces/king.tres")
const ELEPHANT = preload("res://data/pieces/elephant.tres")

var rules := StandardSetup.create_rules()

func _army(placements: Array) -> Army:
	var army := Army.new()
	for p in placements:
		army.place(p[0], p[1])
	return army

func _just_a_king() -> Army:
	return _army([[KING, Vector2i(4, 0)]])

func test_standard_army_is_legal_and_costs_39() -> void:
	var army := StandardSetup.army()
	check_eq(army.cost(), 39.0, "Cost")
	check_eq(army.problems(rules, 8), PackedStringArray(), "Problems")

func test_two_standard_armies_make_the_standard_game() -> void:
	var game := ArmySetup.create_game(StandardSetup.army(), StandardSetup.army(), rules)
	check_eq(Fen.write(game), Fen.STANDARD_START, "Starting position")
	check_eq(game.moves().size(), 20, "White's first moves")

func test_standard_promotion_choices() -> void:
	var game := ArmySetup.create_game(StandardSetup.army(), StandardSetup.army(), rules)
	var ids := game.rules.promotion_options.map(func(d: PieceDef) -> String: return d.id)
	check_eq(ids.size(), 4, "Four choices")
	check_eq(ids[0], "queen", "Most valuable first")
	for id in ["rook", "bishop", "knight"]:
		check(ids.has(id), "Can promote to " + id)
	check(not ids.has("king") and not ids.has("pawn"), "Never a king or a pawn")

func test_promotion_includes_opponents_pieces() -> void:
	var white := _army([[KING, Vector2i(4, 0)], [PAWN, Vector2i(0, 1)]])
	var black := _army([[KING, Vector2i(4, 0)], [ELEPHANT, Vector2i(2, 0)]])
	var game := ArmySetup.create_game(white, black, rules)
	var ids := game.rules.promotion_options.map(func(d: PieceDef) -> String: return d.id)
	check_eq(ids, ["elephant"], "White may promote to Black's elephant")
	check(rules.promotion_options.size() == 4, "The shared rules weren't changed")

func test_over_budget() -> void:
	# The standard army (39) with two pawns swapped for two elephants: 40.
	var army := StandardSetup.army()
	army.place(ELEPHANT, Vector2i(0, 1))
	army.place(ELEPHANT, Vector2i(7, 1))
	check_eq(army.cost(), 40.0, "Cost")
	check_eq(army.problems(rules, 8), PackedStringArray(["Costs 40 points; the budget is 39."]), "Problems")

func test_fractional_costs() -> void:
	var army := _army([[KING, Vector2i(4, 0)], [ELEPHANT, Vector2i(2, 0)], [ELEPHANT, Vector2i(5, 0)]])
	check_eq(army.cost(), 3.0, "Two elephants cost 3")
	rules.army_budget = 2.5
	check_eq(army.problems(rules, 8), PackedStringArray(["Costs 3 points; the budget is 2.5."]), "Problems")

func test_king_required_and_only_one() -> void:
	check_eq(Army.new().problems(rules, 8), PackedStringArray(["Needs a king."]), "Empty army")
	var two_kings := _army([[KING, Vector2i(4, 0)], [KING, Vector2i(3, 0)]])
	check_eq(two_kings.problems(rules, 8), PackedStringArray(["Too many kings: 2 (the most is 1)."]), "Two kings")

func test_king_must_start_in_the_middle_of_the_back_row() -> void:
	for file in [3, 4]:
		check(_army([[KING, Vector2i(file, 0)]]).is_valid(rules, 8), "King on file %d" % file)
	for square in [Vector2i(0, 0), Vector2i(2, 0), Vector2i(5, 0), Vector2i(4, 1)]:
		check_eq(_army([[KING, square]]).problems(rules, 8),
				PackedStringArray(["The king must start in the middle of the back row."]), "King on %s" % square)

func test_one_royal_piece_besides_the_king() -> void:
	var army := _army([[KING, Vector2i(4, 0)], [QUEEN, Vector2i(3, 0)]])
	check(army.is_valid(rules, 8), "One queen is fine")
	army.place(QUEEN, Vector2i(3, 1))
	check_eq(army.problems(rules, 8),
			PackedStringArray(["Too many royal pieces: 2 besides the king (the most is 1)."]), "Two queens")
	check(_just_a_king().is_valid(rules, 8), "No queen is fine too")

func test_tags_on_the_standard_pieces() -> void:
	check(KING.is_king_type() and KING.is_royal_type(), "King: king + royal")
	check(QUEEN.is_royal_type() and not QUEEN.is_king_type(), "Queen: royal")
	check(PAWN.is_pawn_type(), "Pawn: pawn type")
	check(KNIGHT.has_jump() and ELEPHANT.has_jump(), "Knight and elephant: jump")
	check(ROOK.has_castle(), "Rook: castle")
	check(not BISHOP.has_jump() and BISHOP.types == 0, "Bishop: no tags")

func test_pawns_can_promote_to_a_queen() -> void:
	var game := ArmySetup.create_game(_army([[KING, Vector2i(4, 0)], [QUEEN, Vector2i(3, 0)]]), _just_a_king(), rules)
	check_eq(game.rules.promotion_options, [QUEEN] as Array[PieceDef], "Queen is royal but not a king type")

func test_back_row_pawn_can_still_double_step() -> void:
	var game := ArmySetup.create_game(_army([[KING, Vector2i(4, 0)], [PAWN, Vector2i(0, 0)]]), _just_a_king(), rules)
	var texts := game.moves().map(func(m: Move) -> String: return m.to_text())
	check(texts.has("a1-a2") and texts.has("a1-a3"), "a1 pawn: one or two squares")

func test_at_most_two_of_a_type() -> void:
	var army := _army([[KING, Vector2i(4, 0)], [KNIGHT, Vector2i(1, 0)], [KNIGHT, Vector2i(6, 0)], [KNIGHT, Vector2i(3, 1)]])
	check_eq(army.problems(rules, 8), PackedStringArray(["Too many knights: 3 (the most is 2)."]), "Three knights")
	army.remove_at(Vector2i(3, 1))
	check(army.is_valid(rules, 8), "Two knights are fine")

func test_pawns_have_no_limit() -> void:
	var army := _just_a_king()
	for file in range(8):
		army.place(PAWN, Vector2i(file, 1))
	for file in [0, 1, 2, 3, 5, 6, 7]:
		army.place(PAWN, Vector2i(file, 0))
	check_eq(army.count_of(PAWN), 15, "Fifteen pawns")
	check(army.is_valid(rules, 8), "Any number of pawns")

func test_only_the_first_two_rows() -> void:
	var army := _army([[KING, Vector2i(4, 0)], [KNIGHT, Vector2i(1, 2)]])
	check_eq(army.problems(rules, 8), PackedStringArray(["A knight is outside the starting rows."]), "Third row")
	army = _army([[KING, Vector2i(4, 0)], [KNIGHT, Vector2i(8, 0)]])
	check_eq(army.problems(rules, 8), PackedStringArray(["A knight is outside the starting rows."]), "Off the board")

func test_placing_replaces_what_was_there() -> void:
	var army := _just_a_king()
	army.place(KNIGHT, Vector2i(1, 0))
	army.place(BISHOP, Vector2i(1, 0))
	check_eq(army.def_at(Vector2i(1, 0)), BISHOP, "Bishop replaced the knight")
	check_eq(army.pieces.size(), 2, "King and bishop")

func test_black_is_placed_on_its_own_side() -> void:
	var black := _army([[KING, Vector2i(4, 0)], [QUEEN, Vector2i(3, 0)], [PAWN, Vector2i(0, 1)]])
	var game := ArmySetup.create_game(_just_a_king(), black, rules)
	check_eq(game.board.get_piece(Board.parse_square("d8")).def, QUEEN, "Queen on d8")
	check_eq(game.board.get_piece(Board.parse_square("a7")).team, Piece.Team.BLACK, "Black pawn on a7")
	check_eq(game.board.get_piece(Board.parse_square("e8")).def, KING, "King on e8")

# --- Castling needs the rook in a back-rank corner. ----------------------------

func _castles(white: Army) -> Array:
	var game := ArmySetup.create_game(white, _just_a_king(), rules)
	return game.moves().filter(func(m: Move) -> bool: return m.is_castling()).map(func(m: Move) -> String: return m.to_text())

func test_castling_with_corner_rook_from_any_king_square() -> void:
	check_eq(_castles(_army([[KING, Vector2i(3, 0)], [ROOK, Vector2i(7, 0)]])), ["d1-f1"], "King d1, rook h1")

func test_no_castling_with_rook_off_the_corner() -> void:
	check_eq(_castles(_army([[KING, Vector2i(4, 0)], [ROOK, Vector2i(1, 0)]])), [], "Rook on b1")

func test_no_castling_when_too_close() -> void:
	check_eq(_castles(_army([[KING, Vector2i(6, 0)], [ROOK, Vector2i(7, 0)]])), [], "King next to the rook")
