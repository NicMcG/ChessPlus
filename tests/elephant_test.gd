extends TestSuite

## The elephant: jumps exactly two squares diagonally in any direction.

func _parse(fen: String) -> GameState:
	return Fen.parse(fen, PieceCatalog.all_defs(), StandardSetup.create_rules())

func _elephant_moves(state: GameState) -> Array:
	var texts := []
	for move in state.moves():
		if move.piece.def.id == "elephant":
			texts.append(move.to_text())
	texts.sort()
	return texts

func test_catalog_has_the_elephant() -> void:
	var ids := PieceCatalog.all_defs().map(func(d: PieceDef) -> String: return d.id)
	check(ids.has("elephant"), "Elephant in the catalog")
	for id in ["pawn", "knight", "bishop", "rook", "queen", "king", "man", "cannon", "lance", "paladin"]:
		check(ids.has(id), "Catalog has " + id)

func test_symbols_are_unique_capitals() -> void:
	var seen := {}
	var capitals := RegEx.create_from_string("^[A-Z]{1,2}$")
	for def in PieceCatalog.all_defs():
		check(not seen.has(def.symbol), "Symbol used twice: " + def.symbol)
		check(capitals.search(def.symbol) != null, "One or two capital letters: " + def.symbol)
		seen[def.symbol] = true

func test_moves_from_the_middle() -> void:
	var state := _parse("4k3/8/8/8/3E4/8/8/4K3 w - - 0 1")
	check_eq(_elephant_moves(state), ["d4-b2", "d4-b6", "d4-f2", "d4-f6"], "Four jumps")

func test_corner_has_one_move() -> void:
	var state := _parse("4k3/8/8/8/8/8/8/E3K3 w - - 0 1")
	check_eq(_elephant_moves(state), ["a1-c3"], "Only c3 from a1")

func test_jumps_over_pieces() -> void:
	# Every square next to the elephant is full, but it still jumps.
	var state := _parse("4k3/8/8/2ppp3/2pEp3/2ppp3/8/4K3 w - - 0 1")
	check_eq(_elephant_moves(state), ["d4-b2", "d4-b6", "d4-f2", "d4-f6"], "Jumps over the ring")

func test_captures_but_not_own_pieces() -> void:
	var state := _parse("4k3/8/5p2/8/3E4/8/1P6/4K3 w - - 0 1")
	check_eq(_elephant_moves(state), ["d4-b6", "d4-f2", "d4xf6"], "Takes f6, blocked by own b2")

func test_black_elephant() -> void:
	var state := _parse("4k3/8/8/8/3e4/8/8/4K3 b - - 0 1")
	check_eq(_elephant_moves(state), ["d4-b2", "d4-b6", "d4-f2", "d4-f6"], "Same jumps for Black")

func test_stays_on_one_colour() -> void:
	var state := _parse("4k3/8/8/8/3E4/8/8/4K3 w - - 0 1")
	for move in state.moves():
		if move.piece.def.id == "elephant":
			check_eq((move.to.x + move.to.y) % 2, (move.from.x + move.from.y) % 2, "Same colour: " + move.to_text())

func test_gives_check_over_pieces() -> void:
	# Elephant on c6 attacks e8 even with d7 in between.
	check(_parse("4k3/3p4/2E5/8/8/8/8/4K3 b - - 0 1").is_in_check(), "Elephant checks over d7")
	check(not _parse("4k3/8/3E4/8/8/8/8/4K3 b - - 0 1").is_in_check(), "Elephant on d6 doesn't check e8")

func test_notation() -> void:
	var state := _parse("4k3/8/5p2/8/3E4/8/8/4K3 w - - 0 1")
	var texts := state.moves().map(func(m: Move) -> String: return Notation.san(state, m))
	check(texts.has("Exf6"), "Capture written Exf6")
	check(texts.has("Eb2"), "Move written Eb2")

func test_fen_round_trip() -> void:
	var fen := "rnbqkbnr/pppppppp/2e2e2/8/8/2E2E2/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
	check_eq(Fen.write(_parse(fen)), fen, "Round trip with elephants")

func test_lone_elephant_cannot_checkmate() -> void:
	check_eq(_parse("4k3/8/8/8/3E4/8/8/4K3 w - - 0 1").outcome(), GameState.Outcome.INSUFFICIENT_MATERIAL, "King and elephant vs king")

func test_value() -> void:
	var elephant: PieceDef = load("res://data/pieces/elephant.tres")
	check_eq(elephant.value, 1.5, "Elephant value")

func test_has_a_picture() -> void:
	var view := BoardView.new()
	var elephant: PieceDef = load("res://data/pieces/elephant.tres")
	check(view.texture_for(elephant, Piece.Team.WHITE) != null, "White elephant image")
	check(view.texture_for(elephant, Piece.Team.BLACK) != null, "Black elephant image")
	view.free()

func test_sandbox_scene_starts_with_elephants() -> void:
	var game: Node = load("res://scenes/sandbox/elephant_sandbox.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	check_eq(game.state.board.get_piece(Vector2i(2, 2)).def.id, "elephant", "Elephant on c3")
	# 6 free pawns x 2 (c2 and f2 are blocked by the elephants) + 1 per knight
	# (c3 and f3 are taken) + 2 per elephant (a1, e1, d1, h1 hold own pieces) = 18.
	check_eq(game.state.moves().size(), 18, "White's first moves")
	game.free()
