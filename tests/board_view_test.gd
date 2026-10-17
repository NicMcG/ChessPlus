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

func test_every_piece_has_a_picture_in_each_style() -> void:
	var view := BoardView.new()
	for style in ["classic", "flat", "token"]:
		view.piece_style = style
		for def in StandardSetup.piece_defs():
			for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
				check(view.texture_for(def, team) != null, "%s %s %s" % [style, team, def.id])
	view.free()
