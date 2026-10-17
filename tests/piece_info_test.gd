extends TestSuite

## The piece info card, and opening it with a long press in a game and in the
## army builder.

var infos: Array[Piece] = []

func _def(id: String) -> PieceDef:
	return load("res://data/pieces/%s.tres" % id)

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

# --- The card ------------------------------------------------------------------------

func test_cost_text() -> void:
	var rules := StandardSetup.create_rules()
	check_eq(PieceInfo.cost_text(_def("cannon"), rules), "4 points  ·  up to 2 per army", "Cannon")
	check_eq(PieceInfo.cost_text(_def("pawn"), rules), "1 point  ·  any number per army", "Pawn")
	check_eq(PieceInfo.cost_text(_def("king"), rules), "Free  ·  exactly one per army", "King")
	check_eq(PieceInfo.cost_text(_def("queen"), rules), "9 points  ·  up to 1 per army", "Queen (royal)")
	check_eq(PieceInfo.cost_text(_def("elephant"), rules), "1.5 points  ·  up to 2 per army", "Elephant")

func test_descriptions() -> void:
	check(PieceInfo.describe(_def("cannon"))[0].begins_with("Captures by jumping"), "Cannon explains hopping")
	check(PieceInfo.describe(_def("paladin"))[0].begins_with("Shield"), "Paladin explains its shield")
	check(PieceInfo.describe(_def("lance"))[0].begins_with("Promote"), "Lance explains promotion")
	check_eq(PieceInfo.describe(_def("bishop")), PackedStringArray(["No special rules."]), "Bishop")
	for def in PieceCatalog.all_defs():
		check(not PieceInfo.describe(def).is_empty(), def.id + " has a description")

func test_card_opens_and_closes() -> void:
	var holder := Control.new()
	_root().add_child(holder)
	var info := PieceInfo.open(holder, _def("pawn"))
	check_eq(info.get_node("%Name").text, "Pawn", "Name")
	# Pawn: move only, capture only, first move only.
	check_eq(info.get_node("%Legend").get_child_count(), 3, "Three legend lines")
	info.close()
	check(info.is_queued_for_deletion(), "Closing removes the card")
	holder.free()

# --- Long press in a game ------------------------------------------------------------

func _view(state: GameState) -> BoardView:
	var view := BoardView.new()
	view.size = Vector2(800, 800)
	view.show_game(state)
	view.info_requested.connect(func(piece: Piece) -> void: infos.append(piece))
	return view

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
	# Select the knight, then press-and-hold on f3: that press makes the move.
	var view := _view(StandardSetup.create_game())
	view.tap(Board.parse_square("g1"))
	view.pointer_down(view.square_center(Board.parse_square("f3")))
	view.check_long_press(Time.get_ticks_msec() + BoardView.LONG_PRESS_MS + 10)
	check_eq(infos.size(), 0, "No card after a move")
	view.free()

# --- Long press in the army builder --------------------------------------------------

func test_holding_a_tray_button_opens_the_card() -> void:
	var builder: Node = load("res://scenes/armies/army_builder.tscn").instantiate()
	builder.setup(ArmyLibrary.new("user://test_armies/"), null)
	_root().add_child(builder)
	var cannon := _def("cannon")
	var button: Button = builder._tray_buttons[cannon]
	button.button_down.emit()
	builder.check_long_press(Time.get_ticks_msec() + 1000)
	var cards := builder.get_children().filter(func(n: Node) -> bool: return n is PieceInfo)
	check_eq(cards.size(), 1, "Card opened")
	# Letting go afterwards must not select the cannon.
	button.button_pressed = true
	button.button_up.emit()
	check(builder.selected == null, "Holding didn't select the cannon")
	check(not button.button_pressed, "Button popped back up")
	builder.free()
