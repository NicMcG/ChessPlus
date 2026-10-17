extends TestSuite

## Checks the game screen (game.tscn) by loading it into the running scene tree.

func _open() -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	return game

func _play(game: Node, san: String) -> void:
	var move := Notation.find_move(game.state, san)
	check(move != null, "Should be legal: " + san)
	if move:
		game.play(move)

func test_undo_takes_back_one_move() -> void:
	var game := _open()
	check(game.undo_button.disabled, "Undo is off at the start")
	_play(game, "e4")
	_play(game, "e5")
	check(not game.undo_button.disabled, "Undo is on after moves")
	game.undo()
	check_eq(game.state.history.size(), 1, "One move left")
	check_eq(game.moves_label.text, "1. e4", "Move list after undo")
	check_eq(game.status_label.text, "Black to move", "Status after undo")
	game.undo()
	check_eq(Fen.write(game.state), Fen.STANDARD_START, "Back to the start")
	check(game.undo_button.disabled, "Undo is off again")
	game.free()

func test_undo_after_checkmate_resumes_play() -> void:
	var game := _open()
	for san in ["f3", "e5", "g4", "Qh4#"]:
		_play(game, san)
	check_eq(game.status_label.text, "Checkmate! Black wins", "Status at mate")
	game.undo()
	check_eq(game.status_label.text, "Black to move", "Status after undoing the mate")
	game.free()

func test_new_game_resets() -> void:
	var game := _open()
	_play(game, "e4")
	game.new_game()
	check_eq(game.state.history.size(), 0, "No moves")
	check_eq(game.moves_label.text, game.TIP, "Tip instead of an empty move list")
	game.free()
