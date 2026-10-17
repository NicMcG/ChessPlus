extends TestSuite

## Checks the board view's tap handling (which piece is selected, which move is
## sent) without drawing anything.

var chosen: Array[Move] = []
var choices: Array = []

func _view_for(state: GameState) -> BoardView:
	var view := BoardView.new()
	view.show_game(state)
	view.move_chosen.connect(func(move: Move) -> void: chosen.append(move))
	view.choice_needed.connect(func(moves: Array[Move]) -> void: choices.append(moves))
	return view

func _square(name: String) -> Vector2i:
	return Board.parse_square(name)

func test_tap_piece_then_square_sends_the_move() -> void:
	var view := _view_for(StandardSetup.create_game())
	view.tap(_square("e2"))
	view.tap(_square("e4"))
	check_eq(chosen.size(), 1, "Moves sent")
	if chosen.size() == 1:
		check_eq(chosen[0].to_text(), "e2-e4", "Move sent")
	view.free()

func test_illegal_square_just_deselects() -> void:
	var view := _view_for(StandardSetup.create_game())
	view.tap(_square("e2"))
	view.tap(_square("e5"))
	view.tap(_square("e4"))
	check_eq(chosen.size(), 0, "No move: e5 was illegal, so e4 was a fresh tap on an empty square")
	view.free()

func test_tapping_another_own_piece_switches_selection() -> void:
	var view := _view_for(StandardSetup.create_game())
	view.tap(_square("e2"))
	view.tap(_square("g1"))
	view.tap(_square("f3"))
	check_eq(chosen.size(), 1, "Moves sent")
	if chosen.size() == 1:
		check_eq(chosen[0].to_text(), "g1-f3", "Move sent")
	view.free()

func test_cannot_select_opponents_piece() -> void:
	var view := _view_for(StandardSetup.create_game())
	view.tap(_square("e7"))
	view.tap(_square("e5"))
	check_eq(chosen.size(), 0, "Black can't move on White's turn")
	view.free()

func test_promotion_asks_for_a_choice() -> void:
	var view := _view_for(StandardSetup.from_fen("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1"))
	view.tap(_square("b7"))
	view.tap(_square("b8"))
	check_eq(chosen.size(), 0, "No move sent yet")
	check_eq(choices.size(), 1, "Asked once")
	if choices.size() == 1:
		check_eq(choices[0].size(), 4, "Four promotion choices")
	view.free()

func test_no_taps_after_game_over() -> void:
	var state := StandardSetup.from_fen("rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3")
	var view := _view_for(state)
	view.tap(_square("a2"))
	view.tap(_square("a3"))
	check_eq(chosen.size(), 0, "Checkmated side can't move")
	view.free()

func test_every_piece_has_a_picture() -> void:
	var view := BoardView.new()
	for def in StandardSetup.piece_defs():
		for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
			check(view.texture_for(def, team) != null, "%s %s" % [team, def.id])
	view.free()

# --- Dragging. The view is given a size so squares have screen positions. ------

func _sized_view(state: GameState) -> BoardView:
	var view := _view_for(state)
	view.size = Vector2(800, 800)
	return view

func _drag(view: BoardView, from: String, to: String) -> void:
	var start := view.square_center(_square(from))
	var end := view.square_center(_square(to))
	view.pointer_down(start)
	view.pointer_move(start.lerp(end, 0.5))
	view.pointer_move(end)
	view.pointer_up(end)

func test_drag_makes_the_move() -> void:
	var view := _sized_view(StandardSetup.create_game())
	_drag(view, "g1", "f3")
	check_eq(chosen.size(), 1, "Moves sent")
	if chosen.size() == 1:
		check_eq(chosen[0].to_text(), "g1-f3", "Move sent")
	view.free()

func test_drag_to_illegal_square_keeps_selection() -> void:
	var view := _sized_view(StandardSetup.create_game())
	_drag(view, "g1", "g3")
	check_eq(chosen.size(), 0, "No move for an illegal drop")
	# The knight is still selected, so tapping a legal square now moves it.
	view.tap(_square("h3"))
	check_eq(chosen.size(), 1, "Tap after a failed drag")
	view.free()

func test_drag_promotion_asks_for_a_choice() -> void:
	var view := _sized_view(StandardSetup.from_fen("4k3/1P6/8/8/8/8/8/4K3 w - - 0 1"))
	_drag(view, "b7", "b8")
	check_eq(choices.size(), 1, "Asked which piece")
	view.free()

func test_press_and_release_on_selected_piece_deselects() -> void:
	var view := _sized_view(StandardSetup.create_game())
	var e2 := view.square_center(_square("e2"))
	view.pointer_down(e2)
	view.pointer_up(e2)
	view.pointer_down(e2)
	view.pointer_up(e2)
	view.tap(_square("e4"))
	check_eq(chosen.size(), 0, "Second click deselected, so e4 doesn't move anything")
	view.free()

func test_small_wobble_is_still_a_tap() -> void:
	var view := _sized_view(StandardSetup.create_game())
	var e2 := view.square_center(_square("e2"))
	view.pointer_down(e2)
	view.pointer_move(e2 + Vector2(3, 2))
	view.pointer_up(e2 + Vector2(3, 2))
	view.pointer_down(view.square_center(_square("e4")))
	check_eq(chosen.size(), 1, "Tap, tap still moves")
	view.free()
