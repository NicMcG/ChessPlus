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

## The position shown while looking back, as a fresh replay of the game would give.
func _fresh_fen(game: Node, moves_played: int) -> String:
	var copy := StandardSetup.create_game()
	for i in moves_played:
		copy.make_move(copy.find_move(game.state.history[i].to_text()))
	return Fen.write(copy)

func test_looking_back_shows_the_right_positions() -> void:
	var game := _open()
	for san in ["e4", "d5", "exd5", "Qxd5", "Nc3", "Qa5", "d4", "c6", "Nf3", "Bg4"]:
		_play(game, san)
	for target in [3, 2, 1, 0, 1, 5, 9, 4, 8]:
		game.view_move(target)
		check_eq(Fen.write(game.board_view.state), _fresh_fen(game, target), "Looking at move %d" % target)
	game.step_back()
	check_eq(Fen.write(game.board_view.state), _fresh_fen(game, 7), "Back one")
	game.step_forward()
	check_eq(Fen.write(game.board_view.state), _fresh_fen(game, 8), "Forward one")
	game.back_to_game()
	check(game.board_view.state == game.state, "Back to the game")
	game.undo()
	game.undo()
	_play(game, "Be2")
	game.view_move(8)
	check_eq(Fen.write(game.board_view.state), _fresh_fen(game, 8), "After the game changed")
	check(game.board_view.state != game.state, "Looking at a copy")
	check_eq(game.state.history.size(), 9, "The game itself is untouched")
	game.free()

func test_find_played_move_matches_find_move() -> void:
	var state := StandardSetup.create_game()
	for text in ["e2-e4", "d7-d5", "e4xd5", "d8xd5", "b1-c3"]:
		var move := state.find_played_move(text)
		check(move != null and move.to_text() == text, "Found " + text)
		state.make_move(move)
	check(state.find_played_move("e1-e2") == null, "Not a move here")

# --- The practice bot thinking on its own thread -------------------------------------

func _open_threaded_bot_game() -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.white_army = StandardSetup.army()
	game.black_army = StandardSetup.army()
	game.bot_team = Piece.Team.BLACK
	game.bot_level = PracticeBot.Level.EASY
	game.bot_delay_frames = 1
	game.bot_min_seconds = 0.0
	(Engine.get_main_loop() as SceneTree).root.add_child(game)
	return game

## Wait (up to 5 s) until the bot has replied.
func _wait_for_bot(game: Node) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var give_up := Time.get_ticks_msec() + 5000
	while game.bot_thinking and Time.get_ticks_msec() < give_up:
		await tree.process_frame

func test_bot_thinks_on_its_own_thread() -> void:
	var game := _open_threaded_bot_game()
	for san in ["e4", "d4", "Nf3"]:
		# The Easy bot plays at random, so a planned move may not be legal (after
		# 2. d4 Bb4+, Nf3 isn't): then any legal move will do.
		if Notation.find_move(game.state, san) == null:
			san = Notation.san(game.state, game.state.moves()[0])
		_play(game, san)
		check(game.bot_thinking, "The bot thinks after " + san)
		await _wait_for_bot(game)
		check(not game.bot_thinking, "The bot has replied to " + san)
		check_eq(game.state.side_to_move, Piece.Team.WHITE, "Your turn again")
		check(game.state.history.back().piece.team == Piece.Team.BLACK, "The bot's move is in the game")
		var reply: Move = game.state.history.back()
		check(game.state.board.get_piece(reply.to) == reply.piece, "It moved the game's own piece, not the copy's")
	check(game._bot_copy != null and game._bot_copy != game.state, "The bot searched a copy")
	game.free()
	SavedGame.delete_saved()

func test_closing_the_screen_while_the_bot_thinks() -> void:
	var game := _open_threaded_bot_game()
	_play(game, "e4")
	var tree := Engine.get_main_loop() as SceneTree
	for i in 3:
		await tree.process_frame
	game.free()
	SavedGame.delete_saved()
	check(true, "Closing the screen stops the bot's thread without errors")

func test_recordings_are_loaded_once() -> void:
	var names: Array = GameSounds.LAYERS[GameSounds.Sound.CAPTURE][0][0]
	var first := GameSounds.recording(names[0])
	check(first != null, "The recording loads")
	check(GameSounds.recording(names[0]) == first, "The second time it's the same one, not read again")

func test_bot_thinks_in_steps_on_the_web() -> void:
	# The web has no threads: the bot searches a copy a step at a time and the
	# screen keeps drawing frames in between.
	var game := _open_threaded_bot_game()
	game.bot_in_steps = true
	game.bot.level = PracticeBot.Level.HARD
	_play(game, "e4")
	check(game.bot_thinking, "The bot thinks")
	var tree := Engine.get_main_loop() as SceneTree
	var frames := 0
	var give_up := Time.get_ticks_msec() + 5000
	while game.bot_thinking and Time.get_ticks_msec() < give_up:
		await tree.process_frame
		frames += 1
	check(not game.bot_thinking, "The bot has replied")
	check(frames > 10, "Frames kept coming while it thought (%d)" % frames)
	var reply: Move = game.state.history.back()
	check(reply.piece.team == Piece.Team.BLACK, "The bot's move is in the game")
	check(game.state.board.get_piece(reply.to) == reply.piece, "It moved the game's own piece, not the copy's")
	check(game._bot_copy != null and game._bot_copy != game.state, "The bot searched a copy")
	game.free()
	SavedGame.delete_saved()

func test_new_game_while_the_bot_thinks_in_steps() -> void:
	var game := _open_threaded_bot_game()
	game.bot_in_steps = true
	game.bot.level = PracticeBot.Level.HARD
	_play(game, "e4")
	var tree := Engine.get_main_loop() as SceneTree
	for i in 5:
		await tree.process_frame
	game.new_game()
	_play(game, "d4")
	var give_up := Time.get_ticks_msec() + 5000
	while game.bot_thinking and Time.get_ticks_msec() < give_up:
		await tree.process_frame
	check_eq(game.state.history.size(), 2, "Only the new game's moves: d4 and the bot's reply")
	check_eq(game.state.history[0].to_text(), "d2-d4", "The new game's first move")
	game.free()
	SavedGame.delete_saved()
