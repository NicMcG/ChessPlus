extends TestSuite

## The piece card, the pop-up version in games (opened by holding a piece), and
## the always-showing card in the army builder.

var infos: Array[Piece] = []

func _def(id: String) -> PieceDef:
	return load("res://data/pieces/%s.tres" % id)

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

# --- What the card says ---------------------------------------------------------------

func test_details_line_shows_cost_and_types() -> void:
	check_eq(PieceCard.details_text(_def("king")), "Free  ·  King, Royal", "King")
	check_eq(PieceCard.details_text(_def("queen")), "9 points  ·  Royal", "Queen")
	check_eq(PieceCard.details_text(_def("pawn")), "1 point  ·  Pawn", "Pawn")
	check_eq(PieceCard.details_text(_def("cannon")), "4 points", "Cannon: no types")
	check_eq(PieceCard.details_text(_def("elephant")), "1.5 points", "Elephant")

func test_keywords() -> void:
	check_eq(PieceCard.keyword_names(_def("knight")), PackedStringArray(["Jump"]), "Knight")
	check_eq(PieceCard.keyword_names(_def("rook")), PackedStringArray(["Castle"]), "Rook")
	check_eq(PieceCard.keyword_names(_def("lance")), PackedStringArray(["Promote"]), "Lance")
	check_eq(PieceCard.keyword_names(_def("paladin")), PackedStringArray(["Shield"]), "Paladin")
	for def in PieceCatalog.all_defs():
		for keyword in PieceCard.keyword_names(def):
			check(PieceCard.KEYWORD_COLORS.has(keyword), keyword + " has a colour")

func test_special_section_only_for_the_cannon_so_far() -> void:
	check(PieceCard.special_rules(_def("cannon"))[0].begins_with("Captures by jumping"), "Cannon")
	for def in PieceCatalog.all_defs():
		if def.id != "cannon":
			check(PieceCard.special_rules(def).is_empty(), def.id + " has nothing special")

func test_alternate_pictures() -> void:
	check_eq(PieceArt.all_textures(_def("paladin"), Piece.Team.WHITE).size(), 2, "Paladin with and without shield")
	check_eq(PieceArt.all_textures(_def("knight"), Piece.Team.WHITE).size(), 1, "Knight: one picture")

func test_legend_lists_only_what_is_shown() -> void:
	check_eq(PieceGuideBoard.legend_kinds(PieceGuide.guide(_def("pawn"))), ["move", "capture", "first"] as Array[String], "Pawn")
	check_eq(PieceGuideBoard.legend_kinds(PieceGuide.guide(_def("knight"))), ["jump"] as Array[String], "Knight")
	check_eq(PieceGuideBoard.legend_kinds(PieceGuide.guide(_def("rook"))), ["slide"] as Array[String], "Rook")
	check_eq(PieceGuideBoard.legend_kinds(PieceGuide.guide(_def("cannon"))), ["slide_move"] as Array[String], "Cannon")
	check_eq(PieceGuideBoard.legend_kinds(PieceGuide.guide(_def("man"))), ["both"] as Array[String], "Man")

func test_card_fills_in() -> void:
	var card: PieceCard = load("res://scenes/common/piece_card.tscn").instantiate()
	card.show_piece(_def("paladin"))
	_root().add_child(card)
	check_eq(card.get_node("%Name").text, "Paladin", "Name")
	check_eq(card.get_node("%Pictures").get_child_count(), 2, "Both pictures")
	check_eq(card.get_node("%Keywords").get_child_count(), 1, "One keyword box")
	check(not card.get_node("%Special").visible, "No special section")
	card.show_piece(_def("cannon"))
	check(card.get_node("%Special").visible, "Cannon has a special section")
	card.free()

# --- Pop-up in a game -------------------------------------------------------------------

func _view(state: GameState) -> BoardView:
	var view := BoardView.new()
	view.size = Vector2(800, 800)
	view.show_game(state)
	view.info_requested.connect(func(piece: Piece) -> void: infos.append(piece))
	return view

func test_popup_opens_and_closes() -> void:
	var holder := Control.new()
	_root().add_child(holder)
	var info := PieceInfo.open(holder, _def("pawn"))
	check_eq(info.get_node("%Card").get_node("%Name").text, "Pawn", "Shows the pawn")
	info.close()
	check(info.is_queued_for_deletion(), "Closing removes it")
	holder.free()

func test_holding_a_piece_asks_for_its_card() -> void:
	var view := _view(StandardSetup.create_game())
	var moves := []
	view.move_chosen.connect(func(m: Move) -> void: moves.append(m))
	var g1 := view.square_center(Board.parse_square("g1"))
	view.pointer_down(g1)
	view.check_long_press(Time.get_ticks_msec() + BoardView.LONG_PRESS_MS + 10)
	check_eq(infos.size(), 1, "Card requested")
	if infos.size() == 1:
		check_eq(infos[0].def.id, "knight", "For the knight")
	view.pointer_up(g1)
	view.tap(Board.parse_square("f3"))
	check_eq(moves.size(), 0, "The hold didn't leave the knight selected")
	view.free()

func test_short_press_is_just_a_tap() -> void:
	var view := _view(StandardSetup.create_game())
	view.pointer_down(view.square_center(Board.parse_square("g1")))
	view.check_long_press(Time.get_ticks_msec() + 100)
	check_eq(infos.size(), 0, "No card for a quick tap")
	view.free()

func test_holding_an_opponents_piece_works_too() -> void:
	var view := _view(StandardSetup.create_game())
	view.pointer_down(view.square_center(Board.parse_square("d8")))
	view.check_long_press(Time.get_ticks_msec() + BoardView.LONG_PRESS_MS + 10)
	check(infos.size() == 1 and infos[0].team == Piece.Team.BLACK, "Black queen's card")
	view.free()

func test_moving_away_cancels_the_hold() -> void:
	var view := _view(StandardSetup.create_game())
	var a7 := view.square_center(Board.parse_square("a7"))
	view.pointer_down(a7)
	view.pointer_move(a7 + Vector2(60, 0))
	view.check_long_press(Time.get_ticks_msec() + BoardView.LONG_PRESS_MS + 10)
	check_eq(infos.size(), 0, "Wandered off: no card")
	view.free()

func test_pressing_a_move_square_does_not_open_a_card() -> void:
	var view := _view(StandardSetup.create_game())
	view.tap(Board.parse_square("g1"))
	view.pointer_down(view.square_center(Board.parse_square("f3")))
	view.check_long_press(Time.get_ticks_msec() + BoardView.LONG_PRESS_MS + 10)
	check_eq(infos.size(), 0, "No card after a move")
	view.free()

# --- Army builder ------------------------------------------------------------------------

func _builder() -> Node:
	var builder: Node = load("res://scenes/armies/army_builder.tscn").instantiate()
	builder.setup(ArmyLibrary.new("user://test_armies/"), null)
	_root().add_child(builder)
	return builder

func test_builder_card_follows_the_tray() -> void:
	var builder := _builder()
	check_eq(builder.card.def.id, "king", "Starts on the king")
	builder.select(_def("cannon"))
	check_eq(builder.card.def.id, "cannon", "Switches to the cannon")
	builder.select(null)
	check_eq(builder.card.def.id, "cannon", "Deselecting keeps the last card")
	builder.free()

func test_builder_colour_switch() -> void:
	var builder := _builder()
	builder.select(_def("knight"))
	builder.toggle_team()
	check_eq(builder.team, Piece.Team.BLACK, "Now black")
	check_eq(builder.team_button.text, "Black", "Button says Black")
	check_eq(builder.card.team, Piece.Team.BLACK, "Card in black")
	check_eq(builder.army_board.team, Piece.Team.BLACK, "Board pieces in black")
	check_eq(builder._tray_buttons[_def("knight")].icon, PieceArt.texture_for(_def("knight"), Piece.Team.BLACK), "Tray in black")
	builder.toggle_team()
	check_eq(builder.team_button.text, "White", "And back")
	builder.free()
