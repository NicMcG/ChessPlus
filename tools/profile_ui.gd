extends SceneTree

## Times what a player waits for: starting the app, opening each screen, taps
## in the army builder and testing mode, a tap on a piece, a move, the piece
## card, Settings over a game, looking back, the result screen, the bot's turn,
## and side lines in a long game (a branch of a branch too). For each step: how
## long the call itself took, how long until the next frame was on screen, and
## the slowest frame in the half second after (the first time = "cold", then
## the median of the rest = "warm"). Needs a window to time drawing:
##   "<godot console exe>" --path . --resolution 1280x800 -s res://tools/profile_ui.gd -- [rounds] [screens] [game] [sides] [bot] [plusfish]
## Naming sections runs only those; "plusfish" turns the eval bar's engine on.
## Saved games, settings and armies go to their own files, never the player's.
## Quits by itself after MAX_SECONDS, whatever happens.

const POOL := "res://engine/plusfish/reports/meta_pool.txt"
const MAX_SECONDS := 300

var _frames: Array[int] = []  # Frame end times (µs) since the step began.
var _results := {}  # label -> Array of [call µs, first frame µs, worst frame µs]
var main: Node

func _initialize() -> void:
	create_timer(MAX_SECONDS).timeout.connect(func() -> void:
		print("Gave up after %d s" % MAX_SECONDS)
		quit(1))
	SavedGame.save_path = "user://profile_current_game.json"
	SavedGame.delete_saved()
	UserSettings.save_path = "user://profile_settings.cfg"
	UserSettings.set_how_to_play_seen(true)
	UserSettings.set_sound_on(false)
	TurnNotifier.deliver = false
	PlusfishLink.enabled = false
	process_frame.connect(func() -> void: _frames.append(Time.get_ticks_usec()))
	_run.call_deferred()

func _run() -> void:
	var rounds := 3
	var args := OS.get_cmdline_user_args()
	if args.size() > 0 and args[0].is_valid_int():
		rounds = int(args[0])
	const ALL := ["screens", "game", "sides", "bot"]
	var sections: Array = Array(args).filter(func(a: String) -> bool: return a in ALL)
	if sections.is_empty():
		sections = ALL
	if args.has("plusfish"):
		PlusfishLink.enabled = true
	await _step("startup (main scene)", func() -> void:
		main = load("res://scenes/main/main.tscn").instantiate()
		root.add_child(main))
	var armies := _pool_armies()
	var library := ArmyLibrary.new("user://profile_armies/")
	main.library = library
	for army in armies.slice(0, 4):
		library.save(army)
	var saved: Array = library.armies()
	for r in rounds:
		if "sides" in sections:
			await _side_lines(armies, r)
		if "screens" in sections:
			await _screens(r, saved)
		if "game" in sections:
			await _game(r, armies)
		if "bot" in sections:
			await _bot(r, armies)
	_report()
	for army in library.armies():
		library.delete(army)
	SavedGame.delete_saved()
	main.queue_free()
	await process_frame
	quit()

## Every screen opened in turn, with a few taps in the army builder and testing mode.
func _screens(r: int, saved: Array) -> void:
	await _step("menu", main.show_main_menu)
	await _step("settings", main.show_settings)
	await _step("how to play", main.show_how_to_play)
	await _step("my armies", main.show_army_list)
	await _step("army builder (new)", main.show_army_builder.bind(null))
	await _step("army builder (edit)", main.show_army_builder.bind(saved[0]))
	var builder: Node = main.screen
	var defs: Array = builder._tray_buttons.keys()
	for i in 6:
		var def: PieceDef = defs[(i * 7 + r) % defs.size()]
		await _step("builder: pick piece", builder.select.bind(def))
		await _step("builder: place piece", builder.tap_square.bind(Vector2i(i, 0)))
	await _step("builder: switch colour", builder.toggle_team)
	await _step("match setup", main.show_match_setup)
	await _step("testing setup", main.show_testing_setup.bind(null))
	var setup: Node = main.screen
	var tray: Array = setup.tray_defs()
	for i in 4:
		await _step("testing: pick piece", setup.choose.bind(tray[(i * 5 + r) % tray.size()]))
		await _step("testing: place piece", setup.tap_square.bind(Vector2i(i, 3)))
	await _step("online lobby", main.show_online_lobby.bind(MemoryBackend.new()))

## A two-player game: taps, moves, the piece card, Settings, looking back, Undo, resigning.
func _game(r: int, armies: Array[Army]) -> void:
	await _step("start game (two players)", main.start_game.bind(armies[0], armies[1]))
	var game: Node = main.screen
	game.board_view.move_time = BoardView.BASE_MOVE_TIME
	var rng := RandomNumberGenerator.new()
	rng.seed = 11 + r
	for ply in 30:
		if game.is_over():
			break
		var moves: Array[Move] = game.state.moves()
		var move: Move = moves[rng.randi() % moves.size()]
		while move.promotion or move.ability or move.decoy_choice:
			move = moves[rng.randi() % moves.size()]
		await _step("tap piece", func() -> void: game.board_view.tap(move.from))
		await _step("tap target (move)", func() -> void: game.board_view.tap(move.to), 0.6)
	var piece: Piece = game.state.board.get_piece(game.state.board.pieces_of(Piece.Team.WHITE).keys()[0])
	await _step("piece card", func() -> void: game.board_view.info_requested.emit(piece))
	for child in game.get_children():
		if child is PieceInfo:
			child.queue_free()
	await _step("settings over game", game.open_settings)
	await _step("close settings", game.close_settings)
	await _step("view move 1", game.view_move.bind(1))
	await _step("step forward", game.step_forward)
	await _step("view move 20", game.view_move.bind(20))
	await _step("step back", game.step_back)
	await _step("back to game", game.back_to_game)
	await _step("undo", game.undo)
	await _step("redo", game.redo)
	await _step("resign (result screen)", func() -> void:
		game.resign_local()
		game.resign_local(), 1.0)

## Against the Hard bot: your moves and its replies (it thinks on a thread).
func _bot(r: int, armies: Array[Army]) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 31 + r
	var game: Node
	await _step("start game (bot, hard)", main.start_game.bind(armies[2], armies[3], Piece.Team.BLACK, PracticeBot.Level.HARD))
	game = main.screen
	game.board_view.move_time = BoardView.BASE_MOVE_TIME
	game.bot_min_seconds = 0.0
	for ply in 4:
		if game.is_over():
			break
		var moves: Array[Move] = game.state.moves()
		var move: Move = moves[rng.randi() % moves.size()]
		while move.promotion or move.ability or move.decoy_choice:
			move = moves[rng.randi() % moves.size()]
		await _step("bot: your move", func() -> void: game.board_view.tap(move.from); game.board_view.tap(move.to), 0.2)
		_frames.clear()
		var t := Time.get_ticks_usec()
		while game.bot_thinking or game.board_view.is_animating():
			await process_frame
		_record("bot: whole reply (frames)", [Time.get_ticks_usec() - t, 0, _worst(t)])

## A long game, then side lines from the middle of it, a branch of a branch,
## and tapping around them: the moves are tried on the board (Mac and Nicholas
## both noticed lag here once a game or its side lines got long).
const LONG_GAME := 220

func _side_lines(armies: Array[Army], r: int) -> void:
	main.start_game(armies[4 + r % 3], armies[5 + r % 3])
	var game: Node = main.screen
	await process_frame
	game.board_view.move_time = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 100 + r
	var t := Time.get_ticks_usec()
	while game.state.history.size() < LONG_GAME and not game.is_over():
		var move := _random_move(game.state, rng)
		# Keep the game going: no move that ends it.
		game.state.make_move(move)
		var ends: bool = game.state.outcome() != GameState.Outcome.NONE
		game.state.undo_move(move)
		if ends:
			continue
		game.play(move)
	print("Long game: %d plies in %d ms (%s vs %s)" % [game.state.history.size(), (Time.get_ticks_usec() - t) / 1000,
			game.white_army.army_name, game.black_army.army_name])
	game.resign_local()
	game.resign_local()
	await process_frame
	game.game_over_panel.hide()
	game.board_view.move_time = BoardView.BASE_MOVE_TIME
	var size: int = game.state.history.size()
	await _step("long: view middle move", game.view_move.bind(size / 2))
	for i in 25:
		await _step("long: side line move", _tap_random_move.bind(game, rng), 0.4)
	await _step("long: tap side line move", game.view_side_line.bind(0, 8))
	for i in 25:
		await _step("long: branch of branch move", _tap_random_move.bind(game, rng), 0.4)
	await _step("long: tap game move", game.view_move.bind(size - 10))
	await _step("long: step back", game.step_back)
	await _step("long: tap 2nd line move", game.view_side_line.bind(1, 20))
	await _step("long: step back in line", game.step_back)
	await _step("long: back to game", game.back_to_game)
	for i in 10:
		await _step("long: side move from the end", _tap_random_move.bind(game, rng), 0.4)
	print("  with side lines: ", _breakdown(game))
	await _step("long: remove side line", game.remove_side_line.bind(0))
	await _step("long: remove shown line", game.remove_side_line.bind(game.line_index))

## What the parts of a screen update cost (ms) at this moment.
static func _breakdown(game: Node) -> String:
	var out := PackedStringArray()
	var size: int = game.state.history.size()
	for step: Array in [["update_text", game._update_text], ["entries", game._numbered_moves],
			["move_list", func() -> void: game.move_list.show_moves(game._numbered_moves(), "1-0", game.viewing, "", game.side_lines, game.line_index, game.line_ply)],
			["eval_bar", game._update_eval_bar], ["captures", game._update_captures],
			["game_over", game._update_game_over], ["ability", game._refresh_ability_button],
			["replay half", func() -> void: game._replay(size / 2, [])],
			["replay all", func() -> void: game._replay(size, [])],
			["line moves", game.shown_line_moves],
			["save", game._save_progress]]:
		var t := Time.get_ticks_usec()
		step[1].call()
		out.append("%s %.1f" % [step[0], (Time.get_ticks_usec() - t) / 1000.0])
	return ", ".join(out)

func _tap_random_move(game: Node, rng: RandomNumberGenerator) -> void:
	var move := _random_move(game.board_view.state, rng)
	game.board_view.tap(move.from)
	game.board_view.tap(move.to)

func _random_move(state: GameState, rng: RandomNumberGenerator) -> Move:
	var moves: Array[Move] = state.moves()
	var move: Move = moves[rng.randi() % moves.size()]
	while move.promotion or move.ability or move.decoy_choice:
		move = moves[rng.randi() % moves.size()]
	return move

## Calls `action`, then waits `watch` seconds of frames.
func _step(label: String, action: Callable, watch := 0.5) -> void:
	await process_frame
	_frames.clear()
	var t := Time.get_ticks_usec()
	action.call()
	var call_us := Time.get_ticks_usec() - t
	var until := Time.get_ticks_usec() + int(watch * 1e6) + call_us
	while Time.get_ticks_usec() < until:
		await process_frame
	var first := (_frames[0] - t) if not _frames.is_empty() else 0
	_record(label, [call_us, first, _worst(t)])

func _worst(t: int) -> int:
	var worst := 0
	var previous := t
	for f in _frames:
		worst = maxi(worst, f - previous)
		previous = f
	return worst

func _record(label: String, row: Array) -> void:
	if not _results.has(label):
		_results[label] = []
	_results[label].append(row)

func _report() -> void:
	print("%-28s %8s %8s %8s %8s   (ms; first = cold run, rest median)" % ["step", "call", "1st frm", "worst", "n"])
	for label: String in _results:
		var rows: Array = _results[label]
		var cold: Array = rows[0]
		print("%-28s %8.1f %8.1f %8.1f %8d   cold" % [label, cold[0] / 1000.0, cold[1] / 1000.0, cold[2] / 1000.0, 1])
		if rows.size() > 1:
			var rest := rows.slice(1)
			print("%-28s %8.1f %8.1f %8.1f %8d   warm" % ["", _median(rest, 0), _median(rest, 1), _median(rest, 2), rest.size()])

static func _median(rows: Array, i: int) -> float:
	var values := rows.map(func(row: Array) -> int: return row[i])
	values.sort()
	return values[values.size() / 2] / 1000.0

## The meta pool's armies, as Army resources (over the budget is fine here).
static func _pool_armies() -> Array[Army]:
	var armies: Array[Army] = []
	var rules := StandardSetup.create_rules()
	for line in FileAccess.get_file_as_string(POOL).split("\n"):
		if line.begins_with("#") or line.strip_edges() == "":
			continue
		var fields := line.split("|")
		var rows := fields[0].strip_edges().split("/")
		for order in [[0, 1], [1, 0]]:
			var text := 'Chess Plus army "%s": %s / %s' % [fields[1].strip_edges(), _row(rows[order[0]]), _row(rows[order[1]])]
			var army: Army = ArmyShare.from_text(text)["army"]
			if army and Array(army.problems(rules, 8)).all(func(p: String) -> bool: return "point" in p):
				armies.append(army)
				break
	armies.append(StandardSetup.army())
	return armies

## "Q2K(SQ)" -> "Q - - K SQ"
static func _row(compact: String) -> String:
	var out := PackedStringArray()
	var i := 0
	while i < compact.length():
		var c := compact[i]
		if c == "(":
			var end := compact.find(")", i)
			out.append(compact.substr(i + 1, end - i - 1))
			i = end + 1
		elif c.is_valid_int():
			for k in int(c):
				out.append("-")
			i += 1
		else:
			out.append(c)
			i += 1
	return " ".join(out)
