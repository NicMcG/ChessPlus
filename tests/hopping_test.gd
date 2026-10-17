extends TestSuite

## Hopping captures (the cannon from Chinese chess): moves like a rook, but
## captures only by jumping over exactly one piece. Uses a cannon made here in
## the test, so it doesn't depend on any piece file.

var cannon := _make_cannon()

static func _make_cannon() -> PieceDef:
	var rule := MoveRule.new()
	rule.directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	rule.max_steps = 0
	rule.captures_by_hopping = true
	var def := PieceDef.new()
	def.id = "test_cannon"
	def.display_name = "Cannon"
	def.symbol = "C"
	def.move_rules = [rule]
	return def

func _parse(fen: String) -> GameState:
	var defs := StandardSetup.piece_defs()
	defs.append(cannon)
	return Fen.parse(fen, defs, StandardSetup.create_rules())

func _cannon_moves(state: GameState) -> Array:
	var texts := []
	for move in state.moves():
		if move.piece.def == cannon:
			texts.append(move.to_text())
	texts.sort()
	return texts

func test_moves_like_a_rook_when_not_capturing() -> void:
	var state := _parse("7k/8/8/8/8/8/8/C6K w - - 0 1")
	var moves := _cannon_moves(state)
	check_eq(moves.size(), 13, "a1: 7 up + 6 right (h1 has the king)")
	check(moves.has("a1-a8") and moves.has("a1-g1"), "Slides all the way")

func test_captures_by_hopping_over_one_piece() -> void:
	# Own pawn on e3 is the screen; black pawn on e5 is beyond it.
	var state := _parse("k7/8/8/4p3/8/4P3/8/4C2K w - - 0 1")
	var moves := _cannon_moves(state).filter(func(t: String) -> bool: return t.begins_with("e1-e") or t.begins_with("e1xe"))
	check_eq(moves, ["e1-e2", "e1xe5"], "Moves to e2, can't stop beyond the screen, takes e5")

func test_cannot_capture_without_a_screen() -> void:
	var state := _parse("k7/8/8/8/8/8/4p3/4C2K w - - 0 1")
	check(not _cannon_moves(state).has("e1xe2"), "No capture of the piece right next to it")

func test_enemy_piece_can_be_the_screen() -> void:
	var state := _parse("k7/8/4r3/8/8/4p3/8/4C2K w - - 0 1")
	check(_cannon_moves(state).has("e1xe6"), "Hops the black pawn to take the rook")
	check(not _cannon_moves(state).has("e1xe3"), "Can't take the screen itself")

func test_two_pieces_in_the_way_block_the_capture() -> void:
	var state := _parse("k7/8/4r3/8/4p3/4p3/8/4C2K w - - 0 1")
	check(not _cannon_moves(state).has("e1xe6"), "Only one piece may be hopped")

func test_cannot_capture_own_piece_beyond_the_screen() -> void:
	var state := _parse("k7/8/4R3/8/8/4p3/8/4C2K w - - 0 1")
	check(not _cannon_moves(state).has("e1xe6"), "Own rook beyond the screen")

func test_gives_check_only_over_a_screen() -> void:
	check(_parse("4k3/8/8/4p3/8/8/8/K3C3 b - - 0 1").is_in_check(), "Cannon checks over e5")
	check(not _parse("4k3/8/8/8/8/8/8/K3C3 b - - 0 1").is_in_check(), "No screen, no check")
	check(not _parse("4k3/4p3/8/4p3/8/8/8/K3C3 b - - 0 1").is_in_check(), "Two screens, no check")

func test_escaping_cannon_check() -> void:
	# Black is in check (screen on e5). Adding a second piece to the line, or
	# moving the screen away, both end the check.
	var state := _parse("4k3/8/3n4/4p3/8/8/8/K3C3 b - - 0 1")
	var texts := state.moves().map(func(m: Move) -> String: return m.to_text())
	check(texts.has("d6-e4"), "Knight blocks by becoming a second screen")
	check(not texts.has("e5-e4"), "Pawn moving along the line is still the screen")
	check(texts.has("e8-d7"), "King steps off the line")

func test_screen_piece_is_pinned() -> void:
	# The black knight on e5 is the screen between the cannon and the black king,
	# but moving it away leaves no screen: that's fine. The real pin is the
	# opposite: a piece standing between the screen and the king can't leave.
	var state := _parse("4k3/4n3/8/4p3/8/8/8/K3C3 b - - 0 1")
	check(not state.is_in_check(), "Two pieces in the line: not in check")
	var texts := state.moves().map(func(m: Move) -> String: return m.to_text())
	check(not texts.has("e7-c6"), "Knight can't leave: the pawn would become the only screen")
