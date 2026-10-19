extends SceneTree

## Opens the game screen, optionally plays some moves and taps some squares,
## then saves a picture of the window. Used to check the look without clicking.
## Run (needs a window, so not --headless):
##   "<godot console exe>" --path . -s res://tools/screenshot.gd -- <out.png> [moves...] [tap:e2]
## Moves are in algebraic notation, e.g. e4 e5 Nf3. "tap:e2" taps square e2.
## "fen:<position>" starts from a FEN position, with "_" instead of spaces.
## "hold:g1>f3" starts dragging the g1 piece and holds it most of the way to f3.
## "wait:2" lets 2 seconds pass (animations, the checkmate effect, Plusfish).
## "board" presses View board on the result screen (and skips the checkmate effect).
## "view:5" looks at the position after 5 moves, as tapping the move list does.
## "testing" (anywhere) opens it as a testing-mode game from the standard position.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_path: String = args[0] if args.size() > 0 else "user://screenshot.png"
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	if args.has("testing"):
		game.testing_position = TestingPosition.standard()
	root.add_child(game)
	await process_frame
	for arg in args.slice(1):
		if arg == "testing":
			continue
		elif arg.begins_with("fen:"):
			game.state = Fen.parse(arg.substr(4).replace("_", " "), PieceCatalog.all_defs(), StandardSetup.create_rules())
			game.board_view.show_game(game.state)
			game._update_text()
		elif arg.begins_with("hold:"):
			var ends := arg.substr(5).split(">")
			var start: Vector2 = game.board_view.square_center(Board.parse_square(ends[0]))
			var end: Vector2 = game.board_view.square_center(Board.parse_square(ends[1]))
			game.board_view.pointer_down(start)
			game.board_view.pointer_move(start.lerp(end, 0.8))
		elif arg.begins_with("tap:"):
			game.board_view.tap(Board.parse_square(arg.substr(4)))
		elif arg.begins_with("wait:"):
			var until := Time.get_ticks_msec() + int(float(arg.substr(5)) * 1000)
			while Time.get_ticks_msec() < until:
				await process_frame
		elif arg == "board":
			game._stop_checkmate_effect()
			game._on_game_over_action("board")
		elif arg.begins_with("view:"):
			game.view_move(int(arg.substr(5)))
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
