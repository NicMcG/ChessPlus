extends TestSuite

## Side lines in a long game (Nicholas, Nov 2026: moves tried in a side line,
## or in a branch of a branch, lagged once the game got long). Each move tried
## used to build the whole move list again and replay the game from the start;
## now the list only adds the new move's button and the board's copy steps
## from where it is. These check the result is still exactly what doing it all
## again would show, that the work isn't redone, and that a move in a side line
## of a long game stays quick.

const LONG_GAME := 240
## Median time for one move tried in a side line of a LONG_GAME-move game. It
## took 130 ms or more when everything was redone (over 300 ms with the screen
## drawn), and about 10 ms after the change: a wide margin both ways.
const SIDE_MOVE_BUDGET_MS := 50

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

## A two-player game LONG_GAME moves long (random moves that don't end it),
## where side lines may be tried while it's on.
func _long_game(seed_value := 3) -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	_root().add_child(game)
	game.board_view.move_time = 0.0
	game.side_lines_mid_game = true
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var tries := 0
	while game.state.history.size() < LONG_GAME and tries < LONG_GAME * 20:
		tries += 1
		var move := _random_move(game.state, rng)
		game.state.make_move(move)
		var ends: bool = game.state.outcome() != GameState.Outcome.NONE
		game.state.undo_move(move)
		if not ends:
			game.play(move)
	check_eq(game.state.history.size(), LONG_GAME, "The game is %d moves long" % LONG_GAME)
	return game

static func _random_move(state: GameState, rng: RandomNumberGenerator) -> Move:
	var moves: Array[Move] = state.moves()
	var move: Move = moves[rng.randi() % moves.size()]
	while move.promotion:
		move = moves[rng.randi() % moves.size()]
	return move

## Try a random move on the board (as a tap would); returns how long it took (ms).
func _try_move(game: Node, rng: RandomNumberGenerator) -> float:
	var move := _random_move(game.board_view.state, rng)
	var t := Time.get_ticks_usec()
	game.choose(move)
	return (Time.get_ticks_usec() - t) / 1000.0

## Side line `index`'s position and notation, as replaying it from the start
## and writing it out again would give them.
func _check_line(game: Node, index: int, when: String) -> void:
	var line: Dictionary = game.side_lines[index]
	var fresh: GameState = game._replay(line["from"], line["moves"])
	check(fresh != null, "The side line replays " + when)
	if fresh == null:
		return
	check_eq(line["entries"], Notation.numbered_moves(fresh, line["from"]), "Side line %d's notation %s" % [index, when])
	if game.line_index == index and game.line_ply == line["moves"].size():
		check_eq(Fen.write(game.board_view.state), Fen.write(fresh), "The board %s" % when)

func test_side_line_moves_in_a_long_game() -> void:
	var game := _long_game()
	var first: Button = game.move_list.buttons[0]
	var last: Button = game.move_list.buttons.back()
	game.view_move(LONG_GAME / 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var times: Array[float] = []
	var first_side: Button = null
	for i in 30:
		times.append(_try_move(game, rng))
		if first_side == null:
			first_side = game.move_list.side_buttons[0][0]
		check(game.move_list.side_buttons[0][0] == first_side, "The side line keeps its buttons (move %d)" % (i + 1))
	check_eq(game.side_lines.size(), 1, "One side line")
	check_eq(game.side_lines[0]["moves"].size(), 30, "30 moves long")
	check(game.move_list.buttons[0] == first and game.move_list.buttons.back() == last, "The game's moves keep their buttons")
	check_eq(game.move_list.buttons.size(), LONG_GAME, "The game's moves are all still listed")
	check_eq(game.move_list.side_buttons[0].size(), 30, "A button per side line move")
	_check_line(game, 0, "after 30 moves")
	times.sort()
	var median := times[times.size() / 2]
	check(median < SIDE_MOVE_BUDGET_MS, "A move in a side line of a %d-move game takes %.1f ms (median), under %d ms" % [LONG_GAME, median, SIDE_MOVE_BUDGET_MS])
	game.free()

func test_branch_of_a_branch_in_a_long_game() -> void:
	var game := _long_game()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	game.view_move(LONG_GAME / 2)
	for i in 20:
		_try_move(game, rng)
	var line_buttons: Array = game.move_list.side_buttons[0].duplicate()
	var shown: GameState = game.board_view.state
	# Back to its 8th move: the copy on the board steps back, no replay.
	game.view_side_line(0, 8)
	check(is_same(game.board_view.state, shown), "The board's copy is stepped back, not made again")
	check(game.move_list.viewed_button == line_buttons[7], "Its 8th move is highlighted")
	var times: Array[float] = []
	for i in 20:
		times.append(_try_move(game, rng))
	check_eq(game.side_lines.size(), 2, "A second side line")
	var branch: Dictionary = game.side_lines[1]
	check_eq(branch["from"], LONG_GAME / 2, "Leaving the game where the first does")
	check_eq(branch["moves"].slice(0, 8), game.side_lines[0]["moves"].slice(0, 8), "Starting with the first line's 8 moves")
	check_eq(branch["moves"].size(), 28, "Then the 20 moves tried")
	_check_line(game, 1, "for the branch")
	_check_line(game, 0, "for the first line, untouched")
	check_eq(game.move_list.side_buttons[0], line_buttons, "The first line keeps its buttons")
	times.sort()
	var median := times[times.size() / 2]
	check(median < SIDE_MOVE_BUDGET_MS, "A move in a branch of a branch takes %.1f ms (median), under %d ms" % [median, SIDE_MOVE_BUDGET_MS])
	# Tapping round: a game move far away, the second line, the first again.
	for step: Array in [["game move", func() -> void: game.view_move(LONG_GAME - 10)],
			["second line", func() -> void: game.view_side_line(1, 25)],
			["first line", func() -> void: game.view_side_line(0, 3)],
			["game start", func() -> void: game.view_move(1)]]:
		step[1].call()
		var fresh: GameState = game._replay(game.viewing, []) if game.line_index < 0 				else game._replay(game.viewing, game.side_lines[game.line_index]["moves"].slice(0, game.line_ply))
		check_eq(Fen.write(game.board_view.state), Fen.write(fresh), "The board after tapping the " + step[0])
	game.free()

func test_removing_a_side_line_keeps_the_others() -> void:
	var game := _long_game(9)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	game.view_move(40)
	for i in 6:
		_try_move(game, rng)
	game.view_move(LONG_GAME - 30)
	for i in 6:
		_try_move(game, rng)
	check_eq(game.side_lines.size(), 2, "Two side lines")
	var second: Array = game.move_list.side_buttons[1].duplicate()
	game.remove_side_line(0)
	check_eq(game.side_lines.size(), 1, "One left")
	check_eq(game.move_list.side_buttons[0], second, "The other keeps its buttons")
	check_eq(game.line_index, 0, "...and is still the one shown, now first")
	# Its buttons now stand for side line 0.
	var button: Button = game.move_list.side_buttons[0][2]
	button.button_down.emit()
	button.pressed.emit()
	check_eq(game.line_index, 0, "Tapping its move shows side line 0")
	check_eq(game.line_ply, 3, "...at that move")
	game.move_list.remove_button(0).pressed.emit()
	check(game.side_lines.is_empty(), "Its x removes it")
	game.free()

## Replaying makes only the moving piece's moves (find_played_move), and
## find_legal_move checks the one found: both must agree with find_move.
func test_find_played_move_with_every_kind_of_move() -> void:
	# Pieces with abilities, a Jester and a Squire, so their moves are replayed too.
	var army: Army = ArmyShare.from_text('Chess Plus army "All sorts": P G J BD A WW P P / R NC SQ Q K N V R')["army"]
	check(army != null, "The army reads")
	if army == null:
		return
	var state := ArmySetup.create_game(army, army, StandardSetup.create_rules())
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var checked := 0
	var illegal := 0
	for ply in 120:
		var moves: Array[Move] = state.moves()
		if moves.is_empty() or state.outcome() != GameState.Outcome.NONE:
			break
		for move in moves:
			var found := state.find_played_move(move.to_text())
			var legal := state.find_legal_move(move.to_text())
			checked += 1
			if found == null or found.to_text() != move.to_text() or legal == null or legal.to_text() != move.to_text():
				check(false, "find_played_move / find_legal_move found %s at ply %d" % [move.to_text(), ply])
				return
		# Moves that would leave the king attacked: find_legal_move finds none, as find_move.
		for move in MoveGenerator.pseudo_legal_moves(state):
			if not moves.any(func(m: Move) -> bool: return m.to_text() == move.to_text()):
				illegal += 1
				if state.find_legal_move(move.to_text()) != null:
					check(false, "find_legal_move found the illegal %s at ply %d" % [move.to_text(), ply])
					return
		# Abilities and captures half the time, so they get used.
		var special := moves.filter(func(m: Move) -> bool: return m.ability != PieceDef.Ability.NONE or m.is_capture())
		var pick: Move = special[rng.randi() % special.size()] if not special.is_empty() and rng.randf() < 0.5 else moves[rng.randi() % moves.size()]
		state.make_move(pick)
	check(checked > 1000, "Checked %d moves" % checked)
	check(illegal > 0, "...and %d illegal ones" % illegal)
