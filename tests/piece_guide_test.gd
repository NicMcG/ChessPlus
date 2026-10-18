extends TestSuite

## The movement picture on the piece card.

const MOVE := PieceGuide.MOVE
const CAPTURE := PieceGuide.CAPTURE
const FIRST := PieceGuide.FIRST_MOVE
const JUMP := PieceGuide.JUMP

func _guide(id: String) -> Dictionary:
	return PieceGuide.guide(load("res://data/pieces/%s.tres" % id))

func test_knight_jumps() -> void:
	var g := _guide("knight")
	check_eq(g.squares.size(), 8, "Eight squares")
	check_eq(g.squares.get(Vector2i(1, 2)), MOVE | CAPTURE | JUMP, "(1, 2) is a jump")
	check_eq(g.slides.size(), 0, "No slides")
	check_eq(g.radius, 2, "Fits a 5 x 5 picture")

func test_pawn() -> void:
	var g := _guide("pawn")
	check_eq(g.squares.get(Vector2i(0, 1)), MOVE, "Forward one: move only")
	check_eq(g.squares.get(Vector2i(0, 2)), MOVE | FIRST, "Forward two: first move only")
	check_eq(g.squares.get(Vector2i(1, 1)), CAPTURE, "Diagonal: capture only")
	check_eq(g.squares.size(), 4, "Four squares")

func test_sliders_are_directions_not_squares() -> void:
	var rook := _guide("rook")
	check_eq(rook.squares.size(), 0, "No fixed squares")
	check_eq(rook.slides.size(), 4, "Four directions")
	check(rook.slides.all(func(s: Array) -> bool: return s[1] == MOVE | CAPTURE), "Moves and captures along them")
	check_eq(_guide("queen").slides.size(), 8, "Queen: eight directions")
	check_eq(_guide("lance").slides, [[Vector2i(0, 1), MOVE | CAPTURE, 1]], "Lance: straight forward")

func test_cannon_slides_without_capturing() -> void:
	var g := _guide("cannon")
	check_eq(g.slides.size(), 4, "Four directions")
	check(g.slides.all(func(s: Array) -> bool: return s[1] == MOVE), "Its hopping capture isn't drawn")

func test_step_pieces() -> void:
	check_eq(_guide("king").squares.size(), 8, "King: eight neighbours")
	check_eq(_guide("man").squares.size(), 8, "Man: eight neighbours")
	check_eq(_guide("paladin").squares.size(), 4, "Paladin: four neighbours")
	check(_guide("man").squares.values().all(func(f: int) -> bool: return f == MOVE | CAPTURE), "Steps aren't jumps")
	check(_guide("elephant").squares.values().all(func(f: int) -> bool: return f & JUMP != 0), "Elephant jumps")

func test_long_jumps_widen_the_picture() -> void:
	var rule := MoveRule.new()
	rule.directions = [Vector2i(3, 1)]
	var camel := PieceDef.new()
	camel.move_rules = [rule]
	check_eq(PieceGuide.guide(camel).radius, 3, "A (3, 1) jump needs a 7 x 7 picture")

func test_every_piece_has_something_to_show() -> void:
	for def in PieceCatalog.all_defs():
		var g := PieceGuide.guide(def)
		check(not g.squares.is_empty() or not g.slides.is_empty(), def.id)
