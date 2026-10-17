extends TestSuite

## The movement patterns shown in the piece guide.

const MOVE := PieceGuide.MOVE
const CAPTURE := PieceGuide.CAPTURE
const FIRST := PieceGuide.FIRST_MOVE
const HOP := PieceGuide.HOP_CAPTURE

func _def(id: String) -> PieceDef:
	return load("res://data/pieces/%s.tres" % id)

func test_knight() -> void:
	var marks := PieceGuide.pattern(_def("knight"))
	check_eq(marks.size(), 8, "Eight squares")
	check_eq(marks.get(Vector2i(1, 2)), MOVE | CAPTURE, "Moves or captures on (1, 2)")

func test_pawn() -> void:
	var marks := PieceGuide.pattern(_def("pawn"))
	check_eq(marks.get(Vector2i(0, 1)), MOVE, "Forward one: move only")
	check_eq(marks.get(Vector2i(0, 2)), MOVE | FIRST, "Forward two: first move only")
	check_eq(marks.get(Vector2i(1, 1)), CAPTURE, "Diagonal: capture only")
	check_eq(marks.size(), 4, "Four squares")

func test_rook_slides_to_the_edge_of_the_guide() -> void:
	var marks := PieceGuide.pattern(_def("rook"))
	check_eq(marks.size(), 16, "Four squares in each of four directions")
	check(marks.has(Vector2i(0, 4)) and not marks.has(Vector2i(0, 5)), "Stops at the edge of a 9x9 guide")

func test_cannon_hops_to_capture() -> void:
	var marks := PieceGuide.pattern(_def("cannon"))
	check_eq(marks.get(Vector2i(0, 1)), MOVE, "Next to it: move only (nothing to jump)")
	check_eq(marks.get(Vector2i(0, 3)), MOVE | HOP, "Further: move, or capture by jumping")

func test_lance_forward_only() -> void:
	var marks := PieceGuide.pattern(_def("lance"))
	check_eq(marks.keys().size(), 4, "Four squares, all forward")
	check(marks.keys().all(func(o: Vector2i) -> bool: return o.x == 0 and o.y > 0), "Only straight ahead")

func test_elephant_and_man() -> void:
	check_eq(PieceGuide.pattern(_def("elephant")).size(), 4, "Elephant: four jumps")
	check_eq(PieceGuide.pattern(_def("man")).size(), 8, "Man: eight neighbours")
	check_eq(PieceGuide.pattern(_def("paladin")).size(), 4, "Paladin: four neighbours")

func test_every_piece_has_a_pattern() -> void:
	for def in PieceCatalog.all_defs():
		check(not PieceGuide.pattern(def).is_empty(), def.id + " has squares to show")
