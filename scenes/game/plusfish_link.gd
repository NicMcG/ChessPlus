class_name PlusfishLink
extends Node

## Talks to Plusfish, the analysis engine in res://engine/plusfish/, to get an
## evaluation of every position in a finished game (for the eval bar).
##
## On PC it runs the Plusfish program (built with cargo, see
## res://engine/plusfish/README.md) on a background thread; it sends the whole
## game once and results arrive one position at a time. In the web version it
## calls Plusfish compiled to WebAssembly (res://web/plusfish.js, loaded by the
## page), one position at a time, so the screen keeps running between them.
##
## Either way the game sends Plusfish everything it needs: the piece types (as
## the game has them loaded), the exact starting position and the moves played,
## so Plusfish never has to repeat how armies are set up.

## One position has been evaluated. `ply` = how many moves had been played.
## `result`: "cp" (White's point of view, in hundredths of a point), "mate"
## (null, or moves to mate: + White, - Black), "best" (Move.to_text()),
## "best_san", "outcome", "depth".
signal evaluated(ply: int, result: Dictionary)

## Search size per position. The web version is slower (and runs on the main
## thread), so it searches less.
@export var desktop_nodes := 150000
@export var web_nodes := 20000
## Seconds between positions in the web version, so the game stays responsive.
@export var web_gap := 0.1

## Off turns Plusfish off everywhere. The test runner turns it off, so tests
## that finish games don't start the program; the eval bar tests turn it on.
static var enabled := true
## Tests of the screen can claim Plusfish is there and hand in results themselves.
static var pretend_available := false

## Results so far: ply -> result dictionary.
var results := {}

var _request := {}
var _queue: Array[int] = []
var _thread: Thread
var _pid := -1
var _web_wait := 0.0
## Bumped whenever the job changes, so lines from an old process are ignored.
var _job := 0

## Where the Plusfish program is on this computer, or "" if it isn't there.
## Running from the project: a fresh cargo build if there is one, otherwise the
## copy committed in res://engine/plusfish/bin/ (made by build.sh, so it works
## without Rust); an exported PC game: next to the game's own program.
static func program_path() -> String:
	var exe := "plusfish.exe" if OS.get_name() == "Windows" else "plusfish"
	var candidates := [
		ProjectSettings.globalize_path("res://engine/plusfish/target/release/" + exe),
		ProjectSettings.globalize_path("res://engine/plusfish/bin/" + exe),
		OS.get_executable_path().get_base_dir().path_join(exe),
	]
	for path: String in candidates:
		if FileAccess.file_exists(path):
			return path
	return ""

## True if Plusfish can run here.
static func available() -> bool:
	if not enabled:
		return false
	if pretend_available:
		return true
	if OS.has_feature("web"):
		var pf: Variant = JavaScriptBridge.get_interface("plusfish")
		return pf != null and bool(pf.ready)
	return program_path() != ""

## Evaluate every position of a game: `start` is its starting position and
## `moves` the moves played since (Move.to_text()). Replaces any earlier job.
## The last position goes first, then the rest from the end backwards.
func analyse(start: GameState, moves: Array) -> void:
	stop()
	results.clear()
	_request = request_for(start, moves)
	_queue.clear()
	for ply in range(moves.size(), -1, -1):
		_queue.append(ply)
	_run()

## Look at this position next (the one on the screen).
func prioritise(ply: int) -> void:
	if results.has(ply) or not _queue.has(ply) or _queue.front() == ply:
		return
	_queue.erase(ply)
	_queue.push_front(ply)
	# The PC program works through its list in order: start again with the new one first.
	if not OS.has_feature("web"):
		_run()

## Forget the current job.
func stop() -> void:
	_job += 1
	_queue.clear()
	_stop_thread()

func is_running() -> bool:
	return not _queue.is_empty()

func _exit_tree() -> void:
	stop()

## The request Plusfish expects (see res://engine/plusfish/src/api.rs).
static func request_for(start: GameState, moves: Array) -> Dictionary:
	var defs := {}
	for def in PieceCatalog.all_defs():
		defs[def.id] = def
	var board := []
	for rank in range(start.board.height):
		for file in range(start.board.width):
			var piece := start.board.get_piece(Vector2i(file, rank))
			if piece == null:
				continue
			defs[piece.def.id] = piece.def
			board.append([piece.def.id, piece.team, file, rank, piece.has_moved, piece.shield_broken, piece.ability_used])
	var promo := []
	for def in start.rules.promotion_options:
		defs[def.id] = def
		promo.append(def.id)
	var lost := []
	for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
		for piece: Piece in start.lost[team]:
			defs[piece.def.id] = piece.def
			lost.append([piece.def.id, team])
	var ep := []
	for square in start.en_passant_squares:
		ep.append([square.x, square.y])
	var victim: Variant = null
	if start.en_passant_victim != Board.NO_SQUARE:
		victim = [start.en_passant_victim.x, start.en_passant_victim.y]
	var pieces := []
	for id: String in defs:
		pieces.append(_def_to_dict(defs[id]))
	return {
		"pieces": pieces, "width": start.board.width, "height": start.board.height, "board": board,
		"side": start.side_to_move, "halfmove": start.halfmove_clock, "fullmove": start.fullmove_number,
		"ep": ep, "ep_victim": victim, "lost": lost, "promo": promo,
		"castling_corner": start.rules.castling_partner_in_corner, "moves": moves,
	}

static func _def_to_dict(def: PieceDef) -> Dictionary:
	var rules := []
	for rule in def.move_rules:
		rules.append({
			"directions": rule.directions.map(func(v: Vector2i) -> Array: return [v.x, v.y]),
			"max_steps": rule.max_steps, "first_move_max_steps": rule.first_move_max_steps,
			"mode": rule.mode, "captures_by_hopping": rule.captures_by_hopping,
			"leap_steps": rule.leap_steps, "leap_over": rule.leap_over,
			"path": rule.path.map(func(v: Vector2i) -> Array: return [v.x, v.y]),
			"mirror_files": rule.mirror_files, "mirror_ranks": rule.mirror_ranks,
		})
	return {
		"id": def.id, "name": def.display_name, "symbol": def.symbol, "value": def.value,
		"types": def.types, "keywords": def.keywords, "ability": def.ability,
		"dies_on_capture": def.dies_on_capture, "rules": rules,
	}

func _run() -> void:
	_job += 1
	_stop_thread()
	if _queue.is_empty() or OS.has_feature("web"):
		return
	var path := program_path()
	if path == "":
		_queue.clear()
		return
	var request := _request.duplicate()
	request["plies"] = _queue.duplicate()
	request["nodes"] = desktop_nodes
	var pipe := OS.execute_with_pipe(path, ["evalgame"])
	if pipe.is_empty():
		_queue.clear()
		return
	_pid = pipe["pid"]
	var stdio: FileAccess = pipe["stdio"]
	stdio.store_line(JSON.stringify(request))
	stdio.flush()
	_thread = Thread.new()
	_thread.start(_read_replies.bind(stdio, _job))

## On the background thread: hand each reply line to the main thread.
func _read_replies(stdio: FileAccess, job: int) -> void:
	while stdio.is_open() and stdio.get_error() == OK:
		var line := stdio.get_line()
		if line.is_empty():
			if stdio.eof_reached():
				break
			continue
		_on_reply.call_deferred(line, job)
		if line.contains("\"done\""):
			return
	# The program stopped without finishing (killed, or it crashed).
	_on_reply.call_deferred("{\"done\": true}", job)

func _stop_thread() -> void:
	if _pid > 0:
		OS.kill(_pid)
		_pid = -1
	if _thread:
		_thread.wait_to_finish()
		_thread = null

func _on_reply(line: String, job: int) -> void:
	if job != _job:
		return
	var reply: Variant = JSON.parse_string(line)
	if not reply is Dictionary:
		return
	if reply.has("done") or reply.has("error"):
		if reply.has("error"):
			push_warning("Plusfish: " + str(reply["error"]))
		_queue.clear()
		_stop_thread()
		return
	var ply := int(reply["ply"])
	results[ply] = reply
	_queue.erase(ply)
	evaluated.emit(ply, reply)

func _process(delta: float) -> void:
	if _queue.is_empty() or not OS.has_feature("web"):
		return
	_web_wait -= delta
	if _web_wait > 0.0 or not available():
		return
	_web_wait = web_gap
	var ply: int = _queue.pop_front()
	var request := _request.duplicate()
	request["plies"] = [ply]
	request["nodes"] = web_nodes
	var pf: JavaScriptObject = JavaScriptBridge.get_interface("plusfish")
	var out := str(pf.run(JSON.stringify(request)))
	for line in out.split("\n", false):
		_on_reply(line, _job)
