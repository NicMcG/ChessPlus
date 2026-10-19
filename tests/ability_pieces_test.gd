extends TestSuite

## The Ram (dies when it captures), the Archer (Crack Shot) and the Necromancer
## (Raise Dead): special abilities, lost pieces, undo, saving and notation.

const QUEEN = preload("res://data/pieces/queen.tres")
const PAWN = preload("res://data/pieces/pawn.tres")
const PALADIN = preload("res://data/pieces/paladin.tres")

func _parse(fen: String) -> GameState:
	return Fen.parse(fen, PieceCatalog.all_defs(), StandardSetup.create_rules())

func _def(id: String) -> PieceDef:
	return load("res://data/pieces/%s.tres" % id)

func _ids(pieces: Array) -> Array:
	return pieces.map(func(p: Piece) -> String: return p.def.id)

func test_costs_symbols_and_tags() -> void:
	check_eq([_def("ram").symbol, _def("ram").value], ["RM", 3.0], "Ram")
	check_eq([_def("archer").symbol, _def("archer").value], ["A", 4.5], "Archer")
	check_eq([_def("necromancer").symbol, _def("necromancer").value], ["NC", 3.5], "Necromancer")
	check(_def("ram").dies_on_capture and _def("ram").special_rule != "", "Ram: special rule")
	check_eq(_def("archer").ability_name, "Crack Shot", "Archer's ability")
	check_eq(_def("necromancer").ability_name, "Raise Dead", "Necromancer's ability")
	check(_def("archer").special_rule == "" and _def("necromancer").special_rule == "", "No special rules for them")

# --- Ram -------------------------------------------------------------------------------

func test_ram_dies_when_it_captures() -> void:
	var state := _parse("4k3/8/8/3p4/8/8/8/3(RM)K3 w - - 0 1")
	var before := Fen.write(state)
	var move := state.find_move("d1xd5")
	check(move != null, "Ram can capture")
	state.make_move(move)
	check(state.board.is_empty(Board.parse_square("d5")) and state.board.is_empty(Board.parse_square("d1")), "Both gone")
	check_eq(_ids(state.lost[Piece.Team.BLACK]), ["pawn"], "Black lost the pawn")
	check_eq(_ids(state.lost[Piece.Team.WHITE]), ["ram"], "White lost the Ram")
	state.undo_move(move)
	check_eq(Fen.write(state), before, "Undo puts both back")
	check(state.lost[0].is_empty() and state.lost[1].is_empty(), "Nothing lost after undo")

func test_ram_dies_breaking_a_shield() -> void:
	var state := _parse("4k3/8/8/3(pd)4/8/8/8/3(RM)K3 w - - 0 1")
	var move := state.find_move("d1xd5")
	state.make_move(move)
	check(state.board.get_piece(Board.parse_square("d5")).shield_broken, "Shield broken")
	check(state.board.is_empty(Board.parse_square("d1")), "Ram gone")
	state.undo_move(move)
	check(state.board.get_piece(Board.parse_square("d1")) != null, "Ram back after undo")
	check(not state.board.get_piece(Board.parse_square("d5")).shield_broken, "Shield back after undo")

func test_ram_still_gives_check() -> void:
	check(_parse("3k4/8/8/8/8/8/8/3(RM)K3 b - - 0 1").is_in_check(), "Ram attacks along its lines")

# --- Archer ----------------------------------------------------------------------------

func test_crack_shot_captures_without_moving() -> void:
	var state := _parse("4k3/8/8/8/8/2n5/8/A3K3 w - - 0 1")
	check(state.find_move("a1xc3") != null, "Normal capture")
	var shot := state.find_move("a1!c3")
	check(shot != null, "Crack Shot")
	state.make_move(shot)
	var archer := state.board.get_piece(Board.parse_square("a1"))
	check(archer != null and archer.def.id == "archer", "Archer stays on a1")
	check(state.board.is_empty(Board.parse_square("c3")), "Knight gone")
	check(archer.ability_used, "Ability used")
	check(Fen.write(state).begins_with("4k3/8/8/8/8/8/8/A^3K3"), "FEN marks it used: " + Fen.write(state))
	state.undo_move(shot)
	check(not archer.ability_used and state.board.get_piece(Board.parse_square("c3")) != null, "Undo")

func test_crack_shot_once_per_archer() -> void:
	var state := _parse("4k3/8/8/8/8/2n5/8/A^3K3 w - - 0 1")
	check(state.find_move("a1xc3") != null, "Can still capture normally")
	check(state.find_move("a1!c3") == null, "No second Crack Shot")
	state = _parse("4k3/8/8/8/8/2n2n2/8/A3A^K2 w - - 0 1")
	check(state.find_move("a1!c3") != null and state.find_move("e1!f2") == null, "Each archer has its own")

func test_crack_shot_on_a_shield() -> void:
	var state := _parse("4k3/8/8/8/8/2(pd)5/8/A3K3 w - - 0 1")
	var shot := state.find_move("a1!c3")
	state.make_move(shot)
	check(state.board.get_piece(Board.parse_square("c3")).shield_broken, "Only the shield breaks")
	check(state.board.get_piece(Board.parse_square("a1")).ability_used, "Ability used")

# --- Necromancer -----------------------------------------------------------------------

func test_necromancer_cannot_capture() -> void:
	var state := _parse("4k3/8/8/8/8/3p4/3(NC)4/4K3 w - - 0 1")
	check(state.find_move("d2xd3") == null, "Can't capture")
	check(state.find_move("d2-c3") != null, "Moves one square")
	check(not _parse("8/8/8/8/8/3k4/3(NC)4/4K3 b - - 0 1").is_in_check(), "Never gives check")

func test_raise_dead_brings_back_a_lost_piece() -> void:
	var state := _parse("3k4/8/8/8/8/8/3(NC)4/4K3 w - - 0 1")
	check(state.find_move("d2!=Q") == null, "Nothing lost: nothing to raise")
	var lost_queen := Piece.new(QUEEN, Piece.Team.WHITE)
	state.lost[Piece.Team.WHITE].append_array([Piece.new(PAWN, Piece.Team.WHITE), lost_queen,
			Piece.new(_def("necromancer"), Piece.Team.WHITE)])
	check(state.find_move("d2!=P") == null, "Pawns can't come back")
	check(state.find_move("d2!=NC") == null, "Necromancers can't come back")
	var raise := state.find_move("d2!=Q")
	check(raise != null, "Can raise the queen")
	state.make_move(raise)
	var queen := state.board.get_piece(Board.parse_square("d2"))
	check(queen != null and queen.def == QUEEN, "Queen on the Necromancer's square")
	check(state.is_in_check(), "And it gives check along the d-file")
	check_eq(_ids(state.lost[Piece.Team.WHITE]), ["pawn", "necromancer"], "Queen no longer lost")
	state.undo_move(raise)
	check_eq(state.board.get_piece(Board.parse_square("d2")).def.id, "necromancer", "Undo: Necromancer back")
	check_eq(state.lost[Piece.Team.WHITE][1], lost_queen, "Undo: queen lost again, same place")

func test_raised_piece_comes_back_fresh() -> void:
	var state := _parse("3k4/8/8/8/8/8/3(NC)4/4K3 w - - 0 1")
	var paladin := Piece.new(PALADIN, Piece.Team.WHITE)
	paladin.shield_broken = true
	state.lost[Piece.Team.WHITE].append(paladin)
	state.make_move(state.find_move("d2!=PD"))
	check(state.board.get_piece(Board.parse_square("d2")).has_active_shield(), "Shield is back")

func test_captured_pieces_are_lost_and_can_be_raised() -> void:
	# Black takes White's queen, then White's Necromancer brings it back.
	var state := _parse("3k4/8/8/3q4/3Q4/8/2(NC)5/4K3 b - - 0 1")
	state.make_move(state.find_move("d5xd4"))
	check_eq(_ids(state.lost[Piece.Team.WHITE]), ["queen"], "Queen lost")
	check(state.find_move("c2!=Q") != null, "Necromancer can raise it")

func test_a_necromancer_with_something_to_raise_keeps_the_game_going() -> void:
	var state := _parse("3k4/8/8/8/8/8/3(NC)4/4K3 w - - 0 1")
	check_eq(state.outcome(), GameState.Outcome.INSUFFICIENT_MATERIAL, "Nothing to raise: a draw")
	state.lost[Piece.Team.WHITE].append(Piece.new(QUEEN, Piece.Team.WHITE))
	check_eq(state.outcome(), GameState.Outcome.NONE, "A queen to raise: play on")

# --- Notation ----------------------------------------------------------------------------

func _picture_words(state: GameState, move: Move) -> String:
	var words: PackedStringArray = []
	for part: Dictionary in Notation.picture(state, move):
		words.append(part.piece.id if part.has("piece") else ("<%s>" % part.icon if part.has("icon") else part.text))
	return " ".join(words)

func test_ability_notation() -> void:
	var state := _parse("4k3/8/8/8/8/2n5/8/A3K3 w - - 0 1")
	check_eq(_picture_words(state, state.find_move("a1!c3")), "archer <ability> knight", "Crack Shot: [archer] [bolt] [knight]")
	check_eq(Notation.san(state, state.find_move("a1!c3")), "Axc3!", "Text version")
	state = _parse("3k4/8/8/8/8/8/3(NC)4/4K3 w - - 0 1")
	state.lost[Piece.Team.WHITE].append(Piece.new(QUEEN, Piece.Team.WHITE))
	check_eq(_picture_words(state, state.find_move("d2!=Q")), "necromancer <ability> queen <check>", "Raise Dead with check")
	state = _parse("4k3/8/8/3p4/8/8/8/3(RM)K3 w - - 0 1")
	check_eq(_picture_words(state, state.find_move("d1xd5")), "ram <capture> d5", "A Ram capture is written like any capture")

func test_saved_game_replays_abilities() -> void:
	var state := ArmySetup.create_game(StandardSetup.army(), StandardSetup.army(), StandardSetup.create_rules())
	check(state != null, "Game")
	var shot := Move.new(Vector2i(0, 0), Vector2i(2, 2), null)
	shot.ability = PieceDef.Ability.CRACK_SHOT
	check_eq(shot.to_text(), "a1!c3", "Crack Shot text for saving")
