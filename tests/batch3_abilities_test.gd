extends TestSuite

## The ability pieces from Mac's third batch (Oct 2026): the Ghost (Haunt), the
## Bard (Song of Slumber) and the Werewolf (Full Moon).

func _game(fen: String) -> GameState:
	return Fen.parse(fen, PieceCatalog.all_defs(), StandardSetup.create_rules())

func _def(id: String) -> PieceDef:
	return PieceCatalog.all_defs().filter(func(d: PieceDef) -> bool: return d.id == id)[0]

## Where the piece on `from` can go by ordinary moves (a capture is "x").
func _targets(state: GameState, from: String) -> Array:
	var square := Board.parse_square(from)
	var found := []
	for move in state.moves():
		if move.from == square and move.ability == PieceDef.Ability.NONE:
			found.append(Board.square_name(move.to) + ("x" if move.is_capture() else ""))
	found.sort()
	return found

func _play(state: GameState, text: String) -> Move:
	var move := state.find_move(text)
	check(move != null, "Can play " + text)
	if move:
		state.make_move(move)
	return move

func _abilities(state: GameState, ability: PieceDef.Ability) -> Array[Move]:
	var found: Array[Move] = []
	found.assign(state.moves().filter(func(m: Move) -> bool: return m.ability == ability))
	return found

func test_costs_symbols_and_forms() -> void:
	check_eq([_def("ghost").value, _def("bard").value, _def("werewolf").value], [3.0, 3.5, 3.0], "Costs")
	check_eq([_def("ghost").symbol, _def("bard").symbol, _def("werewolf").symbol], ["G", "BD", "WW"], "Symbols")
	var wolf := _def("werewolf").transforms_into
	check(wolf != null and wolf.id == "werewolf_wolf", "The Werewolf knows its wolf form")
	check(not PieceCatalog.all_defs().has(wolf), "The wolf form isn't offered in the army builder")
	for def: PieceDef in [_def("ghost"), _def("bard"), _def("werewolf")]:
		check(def.ability_colors.size() == 2 and def.ability_name != "" and def.ability_text != "", "%s has its ability's name, text and colours" % def.id)

# --- Ghost: Haunt ------------------------------------------------------------------------

func test_ghost_moves() -> void:
	var state := _game("4k3/8/8/8/3G4/8/8/4K3 w - - 0 1")
	check_eq(_targets(state, "d4"), ["c3", "c5", "d5", "e3", "e5"], "Diagonal 1 any way, or 1 forward")
	check(_abilities(state, PieceDef.Ability.HAUNT).is_empty(), "No Haunt while it's on the board")

func test_ghost_haunts_after_capture() -> void:
	var state := _game("3rk3/8/8/8/3G4/8/8/4K3 b - - 0 1")
	_play(state, "d8xd4")
	var haunts := _abilities(state, PieceDef.Ability.HAUNT)
	# Ranks 1-4 have 32 squares; the white King and the black Rook stand on two.
	check_eq(haunts.size(), 30, "Any empty square in White's half")
	check(state.find_move("@a1") != null and state.find_move("@a5") == null, "Not in Black's half")
	check(state.find_move("@d4") == null and state.find_move("@e1") == null, "Not on an occupied square")
	var ghost := haunts[0].piece
	var haunt := _play(state, "@c3")
	check_eq(state.board.get_piece(Board.parse_square("c3")), ghost, "The same Ghost is back")
	check(state.lost[Piece.Team.WHITE].is_empty(), "No longer lost")
	check(ghost.ability_used, "Haunt is used up")
	_play(state, "d4-d5")
	check(_targets(state, "c3").has("d4"), "It moves like any piece once back")
	state.undo_move(state.history.back())
	state.undo_move(haunt)
	check(state.board.is_empty(Board.parse_square("c3")), "Undo takes it off the board again")
	check_eq(state.lost[Piece.Team.WHITE], [ghost], "...and back among the lost")
	check(not ghost.ability_used, "...with Haunt unused")

func test_ghost_haunts_once() -> void:
	var state := _game("3rk3/8/8/8/3G4/8/8/4K3 b - - 0 1")
	_play(state, "d8xd4")
	_play(state, "@d3")
	_play(state, "d4xd3")
	check(_abilities(state, PieceDef.Ability.HAUNT).is_empty(), "Captured a second time, it stays lost")

func test_black_ghost_haunts_its_own_half_and_can_give_check() -> void:
	var state := _game("3g4/7k/8/4K3/8/8/8/3R4 w - - 0 1")
	_play(state, "d1xd8")
	check(state.find_move("@a5") != null and state.find_move("@a4") == null, "Black's half is ranks 5-8")
	var haunt := state.find_move("@d6")
	check_eq(Notation.san(state, haunt), "G@d6+", "Coming back can give check (it attacks e5)")
	check_eq(Notation.find_move(state, "G@d6").to_text(), "@d6", "Found by its text")
	check_eq(Notation.picture(state, haunt), [{"piece": _def("ghost"), "team": Piece.Team.BLACK}, {"icon": Notation.ABILITY_ICON}, {"text": "d6"}, {"icon": Notation.CHECK_ICON}], "Picture: [ghost] [bolt] d6 [check]")

func test_a_lost_ghost_is_no_draw() -> void:
	var state := _game("8/8/8/4k3/3G4/8/8/4K3 b - - 0 1")
	_play(state, "e5xd4")
	check_eq(state.outcome(), GameState.Outcome.NONE, "Kings only, but White's Ghost can still come back")
	state = _game("8/8/8/4k3/3N4/8/8/4K3 b - - 0 1")
	_play(state, "e5xd4")
	check_eq(state.outcome(), GameState.Outcome.INSUFFICIENT_MATERIAL, "With a lost Knight it's a draw")

# --- Bard: Song of Slumber ---------------------------------------------------------------

func test_bard_moves_up_to_four_diagonally() -> void:
	var state := _game("4k3/8/8/8/8/8/8/2(BD)1K3 w - - 0 1")
	check_eq(_targets(state, "c1"), ["a3", "b2", "d2", "e3", "f4", "g5"], "Up to 4 squares diagonally")

func test_song_of_slumber_freezes_one_turn() -> void:
	var state := _game("4k3/8/7n/6n1/8/8/8/2(BD)1K3 w - - 0 1")
	var songs := _abilities(state, PieceDef.Ability.SONG_OF_SLUMBER)
	check_eq(songs.map(func(m: Move) -> String: return m.to_text()), ["c1~g5"], "Only the Knight within reach (h6 is 5 away)")
	var song := songs[0]
	check_eq(Notation.san(state, song), "BDc1~g5", "Its text")
	check_eq(Notation.picture(state, song)[2], {"piece": _def("knight"), "team": Piece.Team.BLACK}, "Picture: [bard] [bolt] [knight]")
	var knight := state.board.get_piece(Board.parse_square("g5"))
	state.make_move(song)
	check_eq(state.board.get_piece(Board.parse_square("c1")).def.id, "bard", "The Bard doesn't move")
	check_eq(state.frozen_piece(), knight, "The Knight is asleep")
	check(_targets(state, "g5").is_empty(), "It can't move this turn")
	check(not _targets(state, "h6").is_empty(), "The other Knight can")
	check(state.board.get_piece(Board.parse_square("c1")).ability_used, "Used up")
	_play(state, "h6-g8")
	check(state.frozen_piece() == null, "Asleep for one turn only")
	_play(state, "e1-e2")
	check(not _targets(state, "g5").is_empty(), "Awake again")
	state.undo_move(state.history.back())
	state.undo_move(state.history.back())
	state.undo_move(song)
	check(not state.board.get_piece(Board.parse_square("c1")).ability_used, "Undo gives the song back")

func test_song_of_slumber_never_targets_a_king_or_own_piece() -> void:
	var state := _game("8/8/8/8/8/1k6/2N5/1(BD)5K w - - 0 1")
	check(_abilities(state, PieceDef.Ability.SONG_OF_SLUMBER).is_empty(), "Its own Knight and the enemy King aren't targets")

func test_putting_the_last_free_piece_to_sleep_is_stalemate() -> void:
	# Black's King on h8 can't move and its pawn is blocked: only the Knight can.
	var state := _game("7k/5K1p/7P/8/8/2(BD)5/8/n7 w - - 0 1")
	_play(state, "c3~a1")
	check_eq(state.outcome(), GameState.Outcome.STALEMATE, "No legal moves and not in check")

# --- Werewolf: Full Moon -----------------------------------------------------------------

func test_werewolf_turns_into_a_wolf() -> void:
	var state := _game("4k3/8/8/8/3(WW)4/8/8/4K3 w - - 0 1")
	check_eq(_targets(state, "d4"), ["c3", "c5", "d5", "e3", "e5"], "Human: diagonal 1 any way, or 1 forward")
	var change := state.find_move("d4!")
	check(change != null, "Full Moon is available")
	check_eq(Notation.san(state, change), "WWd4!", "Its text")
	var wolf_def := _def("werewolf").transforms_into
	check_eq(Notation.picture(state, change)[2], {"piece": wolf_def, "team": Piece.Team.WHITE}, "Picture: [werewolf] [bolt] [wolf]")
	var piece := state.board.get_piece(Board.parse_square("d4"))
	state.make_move(change)
	check_eq(piece.def, wolf_def, "Now a wolf")
	check_eq(piece.starting_def(), _def("werewolf"), "...that started as a Werewolf")
	check_eq(Fen.write(state).split(" ")[0], "4k3/8/8/8/3(WF)^4/8/8/4K3", "Written as WF in positions")
	_play(state, "e8-d8")
	check_eq(_targets(state, "d4"), ["b6", "c4", "c5", "d3", "d5", "d6", "e4", "e5", "f6"], "Wolf: 1 sideways or back, up to 2 forward or diagonally forward")
	check(_abilities(state, PieceDef.Ability.FULL_MOON).is_empty(), "No second Full Moon")
	state.undo_move(state.history.back())
	state.undo_move(change)
	check_eq(piece.def, _def("werewolf"), "Undo turns it back")
	check(piece.base_def == null and not piece.ability_used, "...with Full Moon unused")

func test_wolf_moves_are_blocked() -> void:
	var state := _game("4k3/8/8/3p4/3(WF)^4/8/8/4K3 w - - 0 1")
	var targets := _targets(state, "d4")
	check("d5x" in targets and not "d6" in targets, "A piece in front blocks the 2-square move")
	check_eq(state.board.get_piece(Board.parse_square("d4")).starting_def(), _def("werewolf"), "Read from a position, a wolf knows it was a Werewolf")

func test_wolf_attacks_count_for_check() -> void:
	var state := _game("8/8/1k6/8/3(WW)4/8/8/4K3 w - - 0 1")
	_play(state, "d4!")
	check(state.is_in_check(), "The new wolf checks the King on b6 (2 diagonally forward)")

func test_raise_dead_brings_back_a_werewolf_not_a_wolf() -> void:
	var state := _game("4k3/8/8/3r4/3(WF)^4/8/8/(NC)3K3 b - - 0 1")
	_play(state, "d5xd4")
	check_eq(MoveGenerator.raisable_defs(state, Piece.Team.WHITE), [_def("werewolf")] as Array[PieceDef], "A lost wolf is raised as the Werewolf it started as")
	var raise := _play(state, "a1!=WW")
	check(raise != null and raise.raised.can_use_ability(), "Fresh, with its Full Moon back")

func test_eval_bar_steps_aside() -> void:
	for id in ["ghost", "bard", "werewolf"]:
		var state := _game("4k3/8/8/8/3%s4/8/8/4K3 w - - 0 1" % ("(%s)" % _def(id).symbol if _def(id).symbol.length() > 1 else _def(id).symbol))
		check(not PlusfishLink.supports(state), "Plusfish doesn't know the %s's ability yet" % id)
