extends SceneTree

## Opens the game screen, optionally plays some moves and taps some squares,
## then saves a picture of the window. Used to check the look without clicking.
## Run (needs a window, so not --headless):
##   "<godot console exe>" --path . -s res://tools/screenshot.gd -- <out.png> [moves...] [tap:e2]
## Moves are in algebraic notation, e.g. e4 e5 Nf3. "tap:e2" taps square e2.
## "fen:<position>" starts from a FEN position, with "_" instead of spaces.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "user://screenshot.png"
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	for arg in args.slice(1):
		if arg.begins_with("fen:"):
			game.state = StandardSetup.from_fen(arg.substr(4).replace("_", " "))
			game.board_view.show_game(game.state)
			game._update_text()
		elif arg.begins_with("tap:"):
			game.board_view.tap(Board.parse_square(arg.substr(4)))
		else:
			var move := Notation.find_move(game.state, arg)
			if move == null:
				push_error("Not a legal move: " + arg)
				break
			game.play(move)
	for i in 5:
		await process_frame
	root.get_texture().get_image().save_png(out_path)
	print("Saved ", out_path)
	quit()
