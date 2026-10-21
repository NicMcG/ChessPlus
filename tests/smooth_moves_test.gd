extends TestSuite

## The game screen keeps work from earlier moves instead of redoing it after
## every move (the move list's entries and buttons, GameState.outcome()); these
## check it still shows exactly what doing it all again would.

func _open(fen := "") -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.start_fen = fen
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	return game

func _play(game: Node, san: String) -> void:
	var move := Notation.find_move(game.state, san)
	check(move != null, "Should be legal: " + san)
	if move:
		game.play(move)

## The move list's lines as a list built from scratch would show them.
func _fresh_lines(game: Node) -> PackedStringArray:
	var fresh := MoveList.new()
	fresh.show_moves(Notation.numbered_moves(game.state), "", -1, "")
	var lines := fresh.lines()
	fresh.free()
	return lines

func _check_list(game: Node, when: String) -> void:
	check_eq(game.move_list.lines(), _fresh_lines(game), "Move list " + when)
	check_eq(game.move_list.buttons.size(), game.state.history.size(), "One button per move " + when)

func test_move_list_matches_a_fresh_one() -> void:
	var game := _open()
	for san in ["e4", "e5", "Nf3", "Nc6", "Bb5", "a6"]:
		_play(game, san)
		_check_list(game, "after " + san)
	var first: Button = game.move_list.buttons[0]
	_play(game, "Ba4")
	check(game.move_list.buttons[0] == first, "Earlier moves keep their buttons")
	game.undo()
	_check_list(game, "after Undo")
	game.undo()
	_check_list(game, "after two Undos")
	game.redo()
	_check_list(game, "after Redo")
	game.view_move(3)
	_check_list(game, "while looking back")
	check(game.move_list.viewed_button == game.move_list.buttons[2], "The viewed move is highlighted")
	game.view_move(1)
	check(game.move_list.viewed_button == game.move_list.buttons[0], "The highlight moves")
	game.back_to_game()
	check(game.move_list.viewed_button == null, "No highlight back in the game")
	game.new_game()
	_check_list(game, "after New game")
	game.free()

func test_black_moving_first_keeps_its_numbers() -> void:
	var game := _open("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq - 0 1")
	for san in ["e5", "Nf3", "Nc6", "Bc4"]:
		_play(game, san)
		_check_list(game, "after " + san)
	check_eq(game.move_list.lines()[0], "1... e5", "Black's first move")
	game.undo()
	game.undo()
	game.undo()
	_check_list(game, "back to Black's first move")
	game.free()

func test_side_lines_and_back() -> void:
	var game := _open()
	game.side_lines_mid_game = true
	for san in ["e4", "e5", "Nf3"]:
		_play(game, san)
	game.view_move(1)
	game.choose(Notation.find_move(game.board_view.state, "c5"))
	check_eq(game.side_lines.size(), 1, "A side line")
	check_eq(game.move_list.buttons.size(), 3, "The game's moves are still listed")
	game.remove_side_line(0)
	_check_list(game, "after removing the side line")
	game.free()

func test_outcome_follows_the_position() -> void:
	var state := Fen.parse("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1", PieceCatalog.all_defs(), StandardSetup.create_rules())
	check_eq(state.outcome(), GameState.Outcome.NONE, "Play on")
	var mate := state.find_move("a1-a8")
	state.make_move(mate)
	check_eq(state.outcome(), GameState.Outcome.CHECKMATE, "Mate")
	state.undo_move(mate)
	check_eq(state.outcome(), GameState.Outcome.NONE, "Taken back")
	# Trying moves (make, then undo) leaves it right.
	state.moves()
	check_eq(state.outcome(), GameState.Outcome.NONE, "Still on after trying every move")
	var other := state.find_move("a1-a2")
	state.make_move(other)
	check_eq(state.outcome(), GameState.Outcome.NONE, "Another move: play on")
	state.undo_move(other)
	# Changing the board by hand counts too.
	state.board.set_piece(Board.parse_square("a1"), null)
	for square in ["f7", "g7", "h7"]:
		state.board.set_piece(Board.parse_square(square), null)
	check_eq(state.outcome(), GameState.Outcome.INSUFFICIENT_MATERIAL, "Only kings left")
