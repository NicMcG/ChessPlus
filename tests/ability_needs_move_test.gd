extends TestSuite

## Mac's rule (Oct 2026): a special ability can't be used until the piece has
## moved at least once; a capture or a shield break counts as a move even if
## the piece stays where it was. Also the rule texts' markup (RuleText).
## Positions come from FEN, which counts ability pieces as moved (it can't
## know), so a test that needs one unmoved says so.

const KING = preload("res://data/pieces/king.tres")
const ARCHER = preload("res://data/pieces/archer.tres")
const GHOST = preload("res://data/pieces/ghost.tres")
const ROOK = preload("res://data/pieces/rook.tres")
const PAWN = preload("res://data/pieces/pawn.tres")

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func _fen(text: String) -> GameState:
	return Fen.parse(text, PieceCatalog.all_defs(), StandardSetup.create_rules())

func _piece(state: GameState, square: String) -> Piece:
	return state.board.get_piece(Board.parse_square(square))

func _army(pieces: Array) -> Army:
	var army := Army.new()
	for entry: Array in pieces:
		army.place(entry[0], entry[1])
	return army

func test_an_ability_needs_a_move_first() -> void:
	# White's Archer on c1 could shoot Black's rook on a3 (c1-b2-a3).
	var state := _fen("4k3/8/8/8/8/r7/8/2A1K3 w - - 0 1")
	var archer := _piece(state, "c1")
	check(archer.has_moved, "Loaded from FEN, an ability piece counts as moved (FEN can't say)")
	archer.has_moved = false
	check(state.find_move("c1xa3") != null, "The ordinary capture is allowed")
	check(state.find_move("c1!a3") == null, "Crack Shot isn't: the Archer hasn't moved")
	check(not archer.can_use_ability(), "can_use_ability says no")
	check(archer.has_unused_ability(), "...but the ability is still unused (it glows)")
	# Move it, Black shuffles: now it may shoot (b2-a3 is a diagonal step).
	state.make_move(state.find_move("c1-b2"))
	state.make_move(state.find_move("e8-d8"))
	check(state.find_move("b2!a3") != null, "After moving, Crack Shot is allowed")
	state.undo_move(state.history.back())
	state.undo_move(state.history.back())
	check(not archer.has_moved and state.find_move("c1!a3") == null, "Undo: unmoved again, no Crack Shot")

func test_a_shield_break_counts_as_a_move() -> void:
	# Black's Paladin on a3 is shielded; White's Archer breaks the shield without moving.
	var state := _fen("4k3/8/8/8/8/(pd)7/8/2A1K3 w - - 0 1")
	var archer := _piece(state, "c1")
	archer.has_moved = false
	var shield_break := state.find_move("c1xa3")
	check(shield_break != null and shield_break.breaks_shield(), "Breaking the shield is an ordinary move")
	state.make_move(shield_break)
	check(archer.has_moved, "The Archer counts as moved though it stayed on c1")
	check_eq(_piece(state, "c1"), archer, "...and it is still on c1")
	state.make_move(state.find_move("e8-d8"))
	check(state.find_move("c1!a3") != null, "So Crack Shot is allowed now (the second hit takes the Paladin)")
	state.undo_move(state.history.back())
	state.undo_move(state.history.back())
	check(not archer.has_moved, "Undo puts the unmoved state back")

func test_crack_shot_itself_counts_as_a_move() -> void:
	var state := _fen("4k3/8/8/8/8/2r5/8/A3K3 w - - 0 1")
	_piece(state, "a1").has_moved = false
	check(state.find_move("a1!c3") == null, "Unmoved: no shot")
	# (A position's legal moves are kept once worked out, so a fresh one for the moved Archer.)
	state = _fen("4k3/8/8/8/8/2r5/8/A3K3 w - - 0 1")
	var archer := _piece(state, "a1")
	var shot := state.find_move("a1!c3")
	check(shot != null, "Moved: the shot is there")
	state.make_move(shot)
	check(archer.has_moved and archer.ability_used and _piece(state, "a1") == archer, "Shot: used, moved, still on a1")

func test_a_ghost_must_have_moved_before_it_was_captured() -> void:
	# White's Ghost on b2 is taken by Black's rook before it ever moved: no Haunt.
	var state := _fen("4k3/1r6/8/8/8/8/1G6/4K3 w - - 0 1")
	_piece(state, "b2").has_moved = false
	state.make_move(state.find_move("e1-d1"))
	state.make_move(state.find_move("b7xb2"))
	check(MoveGenerator.haunting_ghosts(state, Piece.Team.WHITE).is_empty(), "A Ghost captured before it moved can't Haunt")
	check(state.find_move("@e4") == null, "No Haunt move")
	# The same, but the Ghost steps first.
	state = _fen("4k3/1r6/8/8/8/8/1G6/4K3 w - - 0 1")
	_piece(state, "b2").has_moved = false
	state.make_move(state.find_move("b2-b3"))
	state.make_move(state.find_move("b7xb3"))
	check_eq(MoveGenerator.haunting_ghosts(state, Piece.Team.WHITE).size(), 1, "A Ghost that moved can Haunt once captured")
	check(state.find_move("@e4") != null, "Haunt is offered")

func test_a_raised_piece_may_use_its_ability_at_once() -> void:
	# Raise Dead's piece comes back "as if the game had just started" but counts as moved
	# (it can't castle), so its ability is available straight away (noted for Mac).
	var state := _fen("4k3/8/8/8/8/2r5/8/(NC)3K3 w - - 0 1")
	state.lost[Piece.Team.WHITE].append(Piece.new(ARCHER, Piece.Team.WHITE))
	var raise := state.find_move("a1!=A")
	check(raise != null, "Raise Dead brings the Archer back")
	state.make_move(raise)
	state.make_move(state.find_move("e8-d8"))
	check(state.find_move("a1!c3") != null, "The raised Archer may shoot at once")

func test_testing_positions_count_ability_pieces_as_moved() -> void:
	var setup := TestingPosition.new()
	setup.pieces[Board.parse_square("e1")] = [KING, Piece.Team.WHITE]
	setup.pieces[Board.parse_square("e8")] = [KING, Piece.Team.BLACK]
	setup.pieces[Board.parse_square("a1")] = [ARCHER, Piece.Team.WHITE]
	setup.pieces[Board.parse_square("c3")] = [ROOK, Piece.Team.BLACK]
	setup.pieces[Board.parse_square("a2")] = [PAWN, Piece.Team.WHITE]
	setup.captured.append([GHOST, Piece.Team.WHITE])
	var state := setup.create_state()
	check(state.find_move("a1!c3") != null, "Testing mode: a set-up Archer may shoot at once (mid-game)")
	check(not _piece(state, "a2").has_moved, "Other pieces are unmoved as before")
	check_eq(MoveGenerator.haunting_ghosts(state, Piece.Team.WHITE).size(), 1, "A set-up captured Ghost may Haunt")

func test_army_games_start_with_abilities_locked() -> void:
	# A real army game: nothing has moved, so no ability is available on move 1.
	var white := _army([[KING, Vector2i(4, 0)], [ARCHER, Vector2i(2, 0)]])
	var black := _army([[KING, Vector2i(4, 0)], [ROOK, Vector2i(0, 0)]])
	var state := ArmySetup.create_game(white, black, StandardSetup.create_rules())
	check(not _piece(state, "c1").has_moved, "The Archer starts unmoved")
	check(state.moves().all(func(m: Move) -> bool: return m.ability == PieceDef.Ability.NONE), "No ability moves at the start")

func test_game_screen_says_the_piece_must_move_first() -> void:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.white_army = _army([[KING, Vector2i(4, 0)], [ARCHER, Vector2i(2, 0)]])
	game.black_army = _army([[KING, Vector2i(4, 0)], [ROOK, Vector2i(0, 0)]])
	_root().add_child(game)
	game.board_view.move_time = 0.0
	game.board_view.tap(Board.parse_square("c1"))
	check(game.ability_button.visible, "The button shows")
	game.use_ability()
	check_eq(game.last_notice, "Crack Shot can be used once this piece has moved.", "Says the piece must move first")
	check(not game.board_view.aiming, "Not aiming")
	game.free()

func test_plusfish_is_off_for_ability_pieces_until_it_knows_the_rule() -> void:
	var with_archer := _fen("4k3/8/8/8/8/8/8/2A1K3 w - - 0 1")
	check(not PlusfishLink.supports(with_archer), "An ability piece on the board: off")
	var plain := _fen("4k3/8/8/8/8/8/8/R3K3 w - - 0 1")
	check(PlusfishLink.supports(plain), "No abilities: on")
	plain.lost[Piece.Team.WHITE].append(Piece.new(GHOST, Piece.Team.WHITE))
	check(not PlusfishLink.supports(plain), "A lost Ghost: off too")
	PlusfishLink.pretend_knows_abilities = true
	check(PlusfishLink.supports(with_archer), "Tests can pretend Plusfish knows the rule")
	PlusfishLink.pretend_knows_abilities = false
	# The online referee follows through the rule set: it judges no ability game either.
	RuleSet.clear_cache()
	check_eq(int(RuleSet.data()["known_abilities"]), int(PieceDef.Ability.NONE), "The rule set says Plusfish knows no ability")
	PlusfishLink.pretend_knows_abilities = true
	RuleSet.clear_cache()
	check_eq(int(RuleSet.data()["known_abilities"]), int(PlusfishLink.KNOWN_ABILITIES), "...until it learns the rule")
	PlusfishLink.pretend_knows_abilities = false
	RuleSet.clear_cache()

func test_rule_text_markup() -> void:
	check_eq(RuleText.to_bbcode("Needs a *King*."), "Needs a [i]King[/i].", "Types in italics")
	check_eq(RuleText.plain("Needs a *King*."), "Needs a King.", "Plain text drops the marks")
	check_eq(RuleText.to_bbcode("it gains {Shield}."), "it gains [bgcolor=#8fd0f5][color=#0b2a3d] SHIELD [/color][/bgcolor].", "Keywords in their box")
	check_eq(RuleText.plain("it gains {Shield}."), "it gains SHIELD.", "Plain keyword in capitals")
	check_eq(RuleText.plain_lines(PackedStringArray(["*Royal* and *King*"])), PackedStringArray(["Royal and King"]), "Lines")
	# Every rule text in the game uses only known marks.
	for def in PieceCatalog.all_defs() + [load("res://data/pieces/forms/werewolf_wolf.tres") as PieceDef]:
		for text in [def.special_rule, def.ability_text, def.move_note]:
			var bbcode := RuleText.to_bbcode(text)
			check(not bbcode.contains("{") and not bbcode.contains("*"), "%s: marks all understood in %s" % [def.id, text])
	for tag in PieceCard.EXPLANATIONS:
		check(not RuleText.to_bbcode(PieceCard.EXPLANATIONS[tag]).contains("*"), tag + ": marks all understood")

func test_cards_show_types_in_italics_and_keywords_in_boxes() -> void:
	var card: PieceCard = load("res://scenes/common/piece_card.tscn").instantiate()
	card.show_piece(load("res://data/pieces/vampire.tres"))
	_root().add_child(card)
	var special: RichTextLabel = card.get_node("%SpecialText")
	check(special.text.contains("[bgcolor=") and special.text.contains(" SHIELD "), "The Vampire's rule shows SHIELD in its box: " + special.text)
	card.show_piece(load("res://data/pieces/jester.tres"))
	check(special.text.contains("non-[i]Pawn[/i]"), "The Jester's rule: the type in italics, not the non: " + special.text)
	card.show_piece(load("res://data/pieces/bard.tres"))
	var ability: RichTextLabel = card.get_node("%AbilityText")
	check(ability.text.contains("non-[i]King[/i]"), "The Bard's ability: any King-type piece: " + ability.text)
	card.free()
	# The army builder's problems too.
	var builder: Node = load("res://scenes/armies/army_builder.tscn").instantiate()
	builder.setup(ArmyLibrary.new("user://test_armies/"))
	_root().add_child(builder)
	check(builder.problems_label.text.contains("Needs a [i]King[/i]."), "The builder's problems: " + builder.problems_label.text)
	builder.free()
