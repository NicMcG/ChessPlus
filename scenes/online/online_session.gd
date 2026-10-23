class_name OnlineSession
extends Node

## One online game, as seen from this device. It creates or joins the game on
## the server, sends this player's moves, and checks the server every
## `poll_seconds` for the opponent's moves (changed is emitted when something
## new arrives). It also shows the clocks. The game screen does the drawing.
##
## Everything goes through the server's functions (see OnlineBackend), which
## check this device may do it. A game, as the server shows it ("row"):
##   code              5 letters/digits players type to join, e.g. "K7QX2"
##   you               the sides this device plays (["white"], or both when two
##                     copies of the game on one phone play each other)
##   white_taken/...   whether each side has a player
##   white_army/...    each army as plain data (SavedGame.army_to_dict)
##   time_ms           each player's starting time, 0 = no time limit
##   white_ms/black_ms time left for each player as of the last move, kept by
##                     the server's clock; turn_ms = how long the current turn
##                     has been running
##   moves, move_count the moves so far as Move.to_text() ("e2-e4", ...)
##   version           goes up with every change (polling asks for newer only)
##   status            "waiting" (for a second player), "playing", "finished",
##                     or "cancelled"
##   result            once finished: "board" (checkmate or a draw on the board),
##                     "draw_agreed", or "white_resigned", "black_timeout", ...
##   draw_offer        "white"/"black" while that side offers a draw, else ""
##   chat              messages so far: [{"from": "white"/"black", "text": ...}]
##   rematch           once someone offers a rematch: the new game's code

## Something about the game changed on the server: the opponent joined, moved,
## resigned, or ran out of time. `row` is the new state of the game.
signal changed(row: Dictionary)

const WAITING := "waiting"
const PLAYING := "playing"
const FINISHED := "finished"
const CANCELLED := "cancelled"

## Letters and digits for game codes (no 0/O or 1/I, which look alike).
const CODE_LETTERS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const CODE_LENGTH := 5
## The time limits online games offer (Mac's full set, Oct 2026), written
## "3+2" = 3 minutes each, 2 seconds added after each of your moves:
## [name, milliseconds each, bonus milliseconds per move]. The server knows the
## same list (time_ok in server/supabase_update_6.sql).
const TIME_CONTROLS := [
	["No time limit", 0, 0],
	["1+0", 60000, 0],
	["1+1", 60000, 1000],
	["2+1", 120000, 1000],
	["3+0", 180000, 0],
	["3+2", 180000, 2000],
	["5+0", 300000, 0],
	["5+3", 300000, 3000],
	["10+0", 600000, 0],
	["10+5", 600000, 5000],
	["15+10", 900000, 10000],
	["30+0", 1800000, 0],
	["30+20", 1800000, 20000],
]
## Quick match: "Any" time (whatever the opponent picked; 10 minutes each if
## both pick Any).
const QUICK_ANY := -1
## Side choices when creating a game.
const SIDE_WHITE := 0
const SIDE_BLACK := 1
const SIDE_RANDOM := 2
## A player only loses on time once their clock is this far past zero as seen
## from the other device, to allow for the delay in hearing about moves (the
## server allows 2.5 s).
const TIMEOUT_GRACE_MS := 3000

var backend: OnlineBackend
## Who this device is on the server (its sign-in).
var player_id: String:
	get: return backend.user_id()
var code := ""
## The game as last seen on the server (empty until created or joined).
var row := {}
var my_team := Piece.Team.WHITE
## Seconds between checks for the opponent's moves. 0 = only when poll() is
## called (tests).
var poll_seconds := 1.5
## Mac's Mute: the opponent's chat messages are hidden (for this game and its
## rematches; the game screen carries it over).
var muted := false
var rng := RandomNumberGenerator.new()
## When (Time.get_ticks_msec()) the current player's turn started, as seen here.
var turn_started_ms := 0

var _timer: Timer
var _polling := false

## `p_player_id` is for tests: the pretend server's player this device is.
func _init(p_backend: OnlineBackend = null, p_player_id := "") -> void:
	backend = p_backend if p_backend else SupabaseBackend.new()
	if backend is MemoryBackend and p_player_id != "":
		(backend as MemoryBackend).user = p_player_id
	add_child(backend)
	rng.randomize()

# --- Starting a game -------------------------------------------------------------

## Create a new game with `army` on `side` (SIDE_WHITE/BLACK/RANDOM) and a time
## limit (milliseconds each, 0 = none). Afterwards `code` is the code to share.
## `army` is an Army, or a Callable(team) -> Army (ArmyChoices.resolver) when it
## depends on the side (the server picks a Random side).
## `eval_bar`: show the eval bar to both players during the game.
func create_game(army: Variant, side: int, time_ms: int, eval_bar := false, increment_ms := 0) -> Dictionary:
	var seat := "random" if side == SIDE_RANDOM else team_key(Piece.Team.WHITE if side == SIDE_WHITE else Piece.Team.BLACK)
	var args := _armies(army)
	args.merge({"seat": seat, "time_ms": time_ms, "increment_ms": increment_ms, "eval_bar": eval_bar, "rules": RuleSet.version()})
	var result := await backend.referee("create", args)
	if not result.ok or result.rows.is_empty():
		return result if not result.ok else OnlineBackend.failed("couldn't create a game")
	var game: Dictionary = result.rows[0]
	code = str(game.code)
	my_team = Piece.Team.BLACK if "black" in game.get("you", []) else Piece.Team.WHITE
	_set_row(game)
	return result

## Join a friend's game by its code, playing with `army` (an Army, or a
## Callable(team) -> Army: we get whichever side is free).
func join_game(p_code: String, army: Variant) -> Dictionary:
	var wanted := p_code.strip_edges().to_upper()
	var args := _armies(army)
	args.merge({"code": wanted, "rules": RuleSet.version()})
	var result := await backend.referee("join", args)
	if not result.ok or result.rows.is_empty():
		return result if not result.ok else OnlineBackend.failed("couldn't join that game")
	var game: Dictionary = result.rows[0]
	code = wanted
	my_team = Piece.Team.BLACK if game.get("seat", "") == "black" else Piece.Team.WHITE
	_set_row(game)
	return result

## Pick up a game this device is already in (after the app was closed), as
## `team` if it plays both sides.
func resume(p_code: String, team := -1) -> Dictionary:
	var found := await backend.call_function("get_game", {"p_code": p_code})
	if not found.ok:
		return found
	if found.rows.is_empty():
		return OnlineBackend.failed("That game no longer exists.")
	var game: Dictionary = found.rows[0]
	var sides: Array = game.get("you", [])
	if sides.is_empty():
		return OnlineBackend.failed("You're not a player in that game.")
	var wanted := team_key(team) if team >= 0 else ""
	my_team = Piece.Team.WHITE if (wanted if wanted in sides else str(sides[0])) == "white" else Piece.Team.BLACK
	code = p_code
	_set_row(game)
	return found

## Give up waiting for an opponent (only before anyone has joined).
func cancel() -> Dictionary:
	return await _act("cancel_game", {})

# --- Quick match -----------------------------------------------------------------

## Seconds between checks of the quick-match queue while waiting (0 = only when
## check_quick_match() is called: tests).
var quick_poll_seconds := 2.0
## True while waiting for a quick match.
var looking := false
var _quick_args := {}

## Look for an opponent (Mac's Quick match): `army` (an Army or a
## Callable(team) -> Army) and a time limit (milliseconds each, 0 = none,
## QUICK_ANY = whatever the opponent picked). Waits until paired (then the
## game is this session's, as after joining) or cancel_quick_match().
## {"ok", "error"}; on success `code` is the game.
func find_quick_match(army: Variant, time_ms: int, increment_ms := 0) -> Dictionary:
	_quick_args = _armies(army)
	_quick_args.merge({"time_ms": time_ms, "increment_ms": increment_ms, "rules": RuleSet.version()})
	looking = true
	var result := await _try_quick()
	while looking and result.ok and code == "":
		if quick_poll_seconds <= 0:
			break  # Tests check the queue themselves (check_quick_match).
		await get_tree().create_timer(quick_poll_seconds).timeout
		if not looking:
			break
		result = await check_quick_match()
	looking = false
	if not result.ok:
		return result
	return OnlineBackend.succeeded([row]) if code != "" else OnlineBackend.failed("cancelled")

## One check of the queue while waiting: picks up the game if someone paired
## with us, asks the referee to pair again if someone who fits is waiting.
func check_quick_match() -> Dictionary:
	var status := await backend.call_function("quick_match_status", {})
	if not status.ok or status.rows.is_empty():
		return status
	var answer: Dictionary = status.rows[0]
	if answer.get("code") is String:
		return await _take_quick_game(answer.code)
	if answer.get("gone", false):
		# Dropped from the queue (away too long): join it again.
		return await _try_quick()
	if int(answer.get("others", 0)) > 0:
		return await _try_quick()
	return OnlineBackend.succeeded([])

## Stop looking. If a game was made just before, it's this session's after all
## (`code` is set): play it.
func cancel_quick_match() -> Dictionary:
	looking = false
	var left := await backend.call_function("leave_quick_match", {})
	if left.ok and not left.rows.is_empty() and left.rows[0].get("code") is String:
		return await _take_quick_game(left.rows[0].code)
	return left

func _try_quick() -> Dictionary:
	var result := await backend.referee("quick", _quick_args)
	if not result.ok or result.rows.is_empty():
		return result
	var answer: Dictionary = result.rows[0]
	if answer.get("paired") is String:
		return await _take_quick_game(answer.paired)
	code = str(answer.code)
	my_team = Piece.Team.BLACK if answer.get("seat", "") == "black" else Piece.Team.WHITE
	_set_row(answer)
	return result

func _take_quick_game(game_code: String) -> Dictionary:
	looking = false
	return await resume(game_code)

## How many players are online and how many are waiting for a quick match
## (Mac's live counts on Play online): {"online", "looking"}, or {} if the
## server can't be reached.
func online_counts() -> Dictionary:
	var result := await backend.call_function("online_counts", {})
	return result.rows[0] if result.ok and not result.rows.is_empty() else {}

## Report the opponent (Mac's Report): the server keeps this game's chat and
## moves for Mac to read.
func report_opponent(reason := "") -> Dictionary:
	var full := {"p_code": code, "p_seat": team_key(my_team), "p_reason": reason}
	return await backend.call_function("report_player", full)

# --- Playing ---------------------------------------------------------------------

## Send this player's move (Move.to_text()) to the referee, which checks it's
## legal and decides whether it ended the game (`finished` only counts in a
## game the referee can't judge). Only works if the server still has the move count we last saw, so the
## two players can never both add a move at once (else no rows). The server's
## clock decides the time used (this device's own measure is sent along, and
## the server allows for the delay in hearing about the opponent's move).
func send_move(move_text: String, finished: bool) -> Dictionary:
	var think_ms := maxi(0, Time.get_ticks_msec() - turn_started_ms)
	var args := {"code": code, "seat": team_key(my_team), "move": move_text, "expected": move_count(),
			"think_ms": think_ms, "finished": finished}
	var result := OnlineBackend.failed("not sent")
	for attempt in 3:
		result = await backend.referee("move", args)
		if result.ok or not result.error.begins_with("no connection"):
			break
	if result.ok and not result.rows.is_empty():
		_set_row(result.rows[0])
	return result

## Offer the opponent a draw (one offer at a time).
func offer_draw() -> Dictionary:
	return await _act("offer_draw", {})

## Answer the opponent's draw offer.
func answer_draw(accept: bool) -> Dictionary:
	return await _act("answer_draw", {"p_accept": accept})

## Who is offering a draw right now: "white", "black" or "".
func draw_offer() -> String:
	return str(row.get("draw_offer", ""))

## Send a chat message (up to 200 characters).
func post_chat(text: String) -> Dictionary:
	var message := text.strip_edges().left(200)
	if message == "":
		return OnlineBackend.failed("empty message")
	return await _act("send_chat", {"p_text": message}, 3)

## The chat so far: [{"from": "white"/"black", "text": ...}, ...].
func chat() -> Array:
	return row.get("chat", [])

## The rematch game's code once someone has offered one, else "".
func rematch_code() -> String:
	return str(row.get("rematch", ""))

## Point this game at its rematch (`new_code`, a game this device just created).
## Fails (rows empty) if the other player got there first: then join theirs
## instead (see rematch_code()).
func claim_rematch(new_code: String) -> Dictionary:
	return await _act("claim_rematch", {"p_new_code": new_code})

func resign() -> Dictionary:
	return await _act("resign_game", {}, 3)

## Ask the server to end the game because the side to move ran out of time. The
## server checks with its own clock: if the time isn't up there yet, the game
## goes on (try again a little later).
func claim_timeout(_team: Piece.Team) -> Dictionary:
	return await _act("claim_timeout", {})

# --- Checking the server ----------------------------------------------------------

## Start checking the server every poll_seconds.
func start_polling() -> void:
	if poll_seconds <= 0 or _timer:
		return
	_timer = Timer.new()
	_timer.wait_time = poll_seconds
	_timer.timeout.connect(poll)
	add_child(_timer)
	_timer.start()

func stop_polling() -> void:
	if _timer:
		_timer.queue_free()
		_timer = null

## Look at the server once; emits changed if the game is different now. Only
## asks for the game if it changed since last time, so a quiet check is a tiny
## reply.
func poll() -> void:
	if _polling or code == "":
		return
	_polling = true
	var result := await backend.call_function("get_game", {"p_code": code, "p_known_version": int(row.get("version", -1))})
	_polling = false
	if result.ok and not result.rows.is_empty() and not result.rows[0].get("unchanged", false):
		var game: Dictionary = result.rows[0]
		var differs := _differs(game)
		_set_row(game)
		if differs:
			changed.emit(row)

# --- About the game ----------------------------------------------------------------

func status() -> String:
	return str(row.get("status", ""))

func result_code() -> String:
	return str(row.get("result", ""))

## Numbers come back from the server's JSON as decimals; these give whole numbers.
func move_count() -> int:
	return int(row.get("move_count", 0))

func moves() -> Array:
	return row.get("moves", [])

## Seconds added to a player's clock after each of their moves (in ms).
func increment_ms() -> int:
	return int(row.get("increment_ms", 0))

func timed() -> bool:
	return int(row.get("time_ms", 0)) > 0

func army(team: Piece.Team) -> Army:
	var data: Variant = row.get(team_key(team) + "_army")
	return SavedGame.army_from_dict(data) if data is Dictionary else null

## The game as a GameState: the armies set up, then every move replayed. Null if
## the moves can't be replayed.
func create_state(rules: GameRules) -> GameState:
	var saved := SavedGame.new()
	saved.white_army = army(Piece.Team.WHITE)
	saved.black_army = army(Piece.Team.BLACK)
	if saved.white_army == null or saved.black_army == null:
		return null
	for text in moves():
		saved.moves.append(str(text))
	return saved.create_state(rules)

## Whose turn it is (White moves first, then they alternate).
func side_to_move() -> Piece.Team:
	return Piece.Team.WHITE if move_count() % 2 == 0 else Piece.Team.BLACK

## `team`'s time left in milliseconds, counting down while it's their turn.
func clock_ms(team: Piece.Team, now_ms := Time.get_ticks_msec()) -> int:
	var left := int(row.get(team_key(team) + "_ms", 0))
	if status() == PLAYING and side_to_move() == team:
		left -= now_ms - turn_started_ms
	return left

## True if `team`'s clock has run out: for this player at zero, for the opponent
## a little past zero (see TIMEOUT_GRACE_MS).
func out_of_time(team: Piece.Team, now_ms := Time.get_ticks_msec()) -> bool:
	if not timed() or status() != PLAYING or side_to_move() != team:
		return false
	var grace := 0 if team == my_team else TIMEOUT_GRACE_MS
	return clock_ms(team, now_ms) <= -grace

static func team_key(team: Piece.Team) -> String:
	return "white" if team == Piece.Team.WHITE else "black"

# --- Inside ------------------------------------------------------------------------

## Run one of the server's game functions for this game and this player's side,
## and remember the game it sends back. A network failure is retried up to
## `tries` times; a refusal or "nothing changed" is not.
func _act(function: String, args: Dictionary, tries := 1) -> Dictionary:
	var full := args.duplicate()
	full["p_code"] = code
	full["p_seat"] = team_key(my_team)
	var result := OnlineBackend.failed("not sent")
	for attempt in tries:
		result = await backend.call_function(function, full)
		if result.ok or not result.error.begins_with("no connection"):
			break
	if result.ok and not result.rows.is_empty():
		_set_row(result.rows[0])
	return result

## Both armies as server arguments: `army` resolved for each side (it may
## depend on the side, see ArmyChoices).
func _armies(army: Variant) -> Dictionary:
	return {
		"white_army": SavedGame.army_to_dict(ArmyChoices.resolve(army, Piece.Team.WHITE)),
		"black_army": SavedGame.army_to_dict(ArmyChoices.resolve(army, Piece.Team.BLACK)),
	}

func _set_row(new_row: Dictionary) -> void:
	# The current turn started turn_ms ago by the server's clock.
	if new_row.has("turn_ms"):
		turn_started_ms = Time.get_ticks_msec() - int(new_row.turn_ms)
	row = new_row

func _differs(new_row: Dictionary) -> bool:
	for column in ["status", "result", "move_count", "white_taken", "black_taken", "draw_offer", "rematch"]:
		if str(new_row.get(column, "")) != str(row.get(column, "")):
			return true
	return (new_row.get("chat", []) as Array).size() != chat().size()

