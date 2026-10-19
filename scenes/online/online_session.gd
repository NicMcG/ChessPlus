class_name OnlineSession
extends Node

## One online game, as seen from this device. It creates or joins the game on
## the server, sends this player's moves, and checks the server every
## `poll_seconds` for the opponent's moves (changed is emitted when something
## new arrives). It also keeps the clocks. The game screen does the drawing.
##
## A game on the server is one row (see OnlineBackend):
##   code              5 letters/digits players type to join, e.g. "K7QX2"
##   white_id/black_id the players' IDs (a fresh random one per game, see
##                     UserSettings.new_player_id)
##   white_army/...    each army as plain data (SavedGame.army_to_dict)
##   time_ms           each player's starting time, 0 = no time limit
##   white_ms/black_ms time left for each player as of the last move
##   moves, move_count the moves so far as Move.to_text() ("e2-e4", ...)
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
## The time limits a game can be created with: [name, milliseconds each].
const TIME_CONTROLS := [
	["No time limit", 0],
	["3 minutes", 180000],
	["5 minutes", 300000],
	["10 minutes", 600000],
	["15 minutes", 900000],
	["30 minutes", 1800000],
]
## Side choices when creating a game.
const SIDE_WHITE := 0
const SIDE_BLACK := 1
const SIDE_RANDOM := 2
## A player only loses on time once their clock is this far past zero as seen
## from the other device, to allow for the delay in hearing about moves.
const TIMEOUT_GRACE_MS := 3000

var backend: OnlineBackend
var player_id := ""
var code := ""
## The game as last seen on the server (empty until created or joined).
var row := {}
var my_team := Piece.Team.WHITE
## Seconds between checks for the opponent's moves. 0 = only when poll() is
## called (tests).
var poll_seconds := 1.5
var rng := RandomNumberGenerator.new()
## When (Time.get_ticks_msec()) the current player's turn started, as seen here.
var turn_started_ms := 0

var _timer: Timer
var _polling := false

func _init(p_backend: OnlineBackend = null, p_player_id := "") -> void:
	backend = p_backend if p_backend else SupabaseBackend.new()
	add_child(backend)
	player_id = p_player_id if p_player_id != "" else UserSettings.new_player_id()
	rng.randomize()

# --- Starting a game -------------------------------------------------------------

## Create a new game with `army` on `side` (SIDE_WHITE/BLACK/RANDOM) and a time
## limit (milliseconds each, 0 = none). Afterwards `code` is the code to share.
## `army` is an Army, or a Callable(team) -> Army (ArmyChoices.resolver) when it
## depends on the side.
func create_game(army: Variant, side: int, time_ms: int) -> Dictionary:
	my_team = Piece.Team.WHITE if side == SIDE_WHITE else Piece.Team.BLACK
	if side == SIDE_RANDOM:
		my_team = Piece.Team.WHITE if rng.randi_range(0, 1) == 0 else Piece.Team.BLACK
	var me := team_key(my_team)
	var result := OnlineBackend.failed("couldn't create a game")
	# A new code clashing with an existing game is very unlikely; try again if so.
	for attempt in 5:
		var new_row := {
			"code": new_code(), "status": WAITING, "result": "",
			"time_ms": time_ms, "white_ms": time_ms, "black_ms": time_ms,
			"moves": [], "move_count": 0,
		}
		new_row[me + "_id"] = player_id
		new_row[me + "_army"] = SavedGame.army_to_dict(ArmyChoices.resolve(army, my_team))
		result = await backend.insert(new_row)
		if result.ok and not result.rows.is_empty():
			_set_row(result.rows[0])
			code = row.code
			return result
		if not ("exist" in result.error or "409" in result.error):
			return result
	return result

## Join a friend's game by its code, playing with `army` (an Army, or a
## Callable(team) -> Army: we get whichever side is free).
func join_game(p_code: String, army: Variant) -> Dictionary:
	var wanted := p_code.strip_edges().to_upper()
	var found := await backend.fetch(wanted)
	if not found.ok:
		return found
	if found.rows.is_empty():
		return OnlineBackend.failed("There's no game with the code %s." % wanted)
	var game: Dictionary = found.rows[0]
	if str(game.get("white_id", "")) == player_id or str(game.get("black_id", "")) == player_id:
		return OnlineBackend.failed("That's your own game: send the code to a friend.")
	if game.status != WAITING:
		return OnlineBackend.failed("That game has already started.")
	# The free side is ours.
	var team := Piece.Team.BLACK if _filled(game, "white_id") else Piece.Team.WHITE
	var me := team_key(team)
	var changes := {"status": PLAYING}
	changes[me + "_id"] = player_id
	changes[me + "_army"] = SavedGame.army_to_dict(ArmyChoices.resolve(army, team))
	var joined := await backend.update(wanted, changes, {"status": WAITING})
	if not joined.ok:
		return joined
	if joined.rows.is_empty():
		return OnlineBackend.failed("Someone else joined that game first.")
	my_team = team
	code = wanted
	_set_row(joined.rows[0])
	return joined

## Pick up a game this device is already in (after the app was closed).
func resume(p_code: String) -> Dictionary:
	var found := await backend.fetch(p_code)
	if not found.ok:
		return found
	if found.rows.is_empty():
		return OnlineBackend.failed("That game no longer exists.")
	var game: Dictionary = found.rows[0]
	if str(game.get("white_id", "")) == player_id:
		my_team = Piece.Team.WHITE
	elif str(game.get("black_id", "")) == player_id:
		my_team = Piece.Team.BLACK
	else:
		return OnlineBackend.failed("You're not a player in that game.")
	code = p_code
	_set_row(game)
	return found

## Give up waiting for an opponent (only before anyone has joined).
func cancel() -> Dictionary:
	return await _change({"status": CANCELLED}, {"status": WAITING})

# --- Playing ---------------------------------------------------------------------

## Send the whole move list after this player's move (`moves` as Move.to_text()),
## with both clocks, and whether that move ended the game on the board.
## Only works if the server still has the move count we last saw, so the two
## players can never both add a move at once.
func send_moves(moves: Array, finished: bool) -> Dictionary:
	var now_ms := Time.get_ticks_msec()
	var changes := {"moves": moves.duplicate(), "move_count": moves.size()}
	if timed():
		changes[team_key(my_team) + "_ms"] = maxi(0, clock_ms(my_team, now_ms))
	if finished:
		changes["status"] = FINISHED
		changes["result"] = "board"
	# Moving instead of answering turns down the opponent's draw offer.
	if draw_offer() == team_key(Piece.other_team(my_team)):
		changes["draw_offer"] = ""
	var result := await _change(changes, {"move_count": move_count(), "status": PLAYING})
	return result

## Offer the opponent a draw (one offer at a time).
func offer_draw() -> Dictionary:
	return await _change({"draw_offer": team_key(my_team)}, {"status": PLAYING, "draw_offer": ""})

## Answer the opponent's draw offer.
func answer_draw(accept: bool) -> Dictionary:
	var theirs := team_key(Piece.other_team(my_team))
	if accept:
		return await _change({"status": FINISHED, "result": "draw_agreed", "draw_offer": ""},
				{"status": PLAYING, "draw_offer": theirs})
	return await _change({"draw_offer": ""}, {"draw_offer": theirs})

## Who is offering a draw right now: "white", "black" or "".
func draw_offer() -> String:
	return str(row.get("draw_offer", ""))

## Send a chat message (up to 200 characters).
func post_chat(text: String) -> Dictionary:
	var message := text.strip_edges().left(200)
	if message == "":
		return OnlineBackend.failed("empty message")
	var result := OnlineBackend.failed("not sent")
	for attempt in 3:
		result = await backend.call_function("post_chat", {"game_code": code, "sender": team_key(my_team), "message": message})
		if result.ok:
			break
	if result.ok and not result.rows.is_empty():
		_set_row(result.rows[0])
	return result

## The chat so far: [{"from": "white"/"black", "text": ...}, ...].
func chat() -> Array:
	return row.get("chat", [])

## The rematch game's code once someone has offered one, else "".
func rematch_code() -> String:
	return str(row.get("rematch", ""))

## Point this game at its rematch (`new_code`). Fails (rows empty) if the other
## player got there first: then join theirs instead (see rematch_code()).
func claim_rematch(new_code: String) -> Dictionary:
	return await _change({"rematch": new_code}, {"rematch": ""})

func resign() -> Dictionary:
	return await _change({"status": FINISHED, "result": team_key(my_team) + "_resigned"}, {"status": PLAYING})

## Record that `team` ran out of time (sent by whichever player notices first).
func claim_timeout(team: Piece.Team) -> Dictionary:
	var changes := {"status": FINISHED, "result": team_key(team) + "_timeout"}
	changes[team_key(team) + "_ms"] = 0
	return await _change(changes, {"status": PLAYING, "move_count": move_count()})

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

## Look at the server once; emits changed if the game is different now.
func poll() -> void:
	if _polling or code == "":
		return
	_polling = true
	var result := await backend.fetch(code)
	_polling = false
	if result.ok and not result.rows.is_empty() and _differs(result.rows[0]):
		_set_row(result.rows[0])
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

func new_code() -> String:
	var text := ""
	for i in CODE_LENGTH:
		text += CODE_LETTERS[rng.randi_range(0, CODE_LETTERS.length() - 1)]
	return text

# --- Inside ------------------------------------------------------------------------

## Update the game on the server and remember the result. A network failure is
## retried a few times; a mismatch (someone else changed it first) is not.
func _change(changes: Dictionary, conditions: Dictionary) -> Dictionary:
	var result := OnlineBackend.failed("not sent")
	for attempt in 3:
		result = await backend.update(code, changes, conditions)
		if result.ok:
			break
	if result.ok and not result.rows.is_empty():
		_set_row(result.rows[0])
	return result

func _set_row(new_row: Dictionary) -> void:
	# A new move (or the game starting) starts the next player's clock here.
	if int(new_row.get("move_count", 0)) != move_count() or str(new_row.get("status", "")) != status():
		turn_started_ms = Time.get_ticks_msec()
	row = new_row

func _differs(new_row: Dictionary) -> bool:
	for column in ["status", "result", "move_count", "white_id", "black_id", "draw_offer", "rematch"]:
		if str(new_row.get(column, "")) != str(row.get(column, "")):
			return true
	return (new_row.get("chat", []) as Array).size() != chat().size()

static func _filled(game: Dictionary, column: String) -> bool:
	var value: Variant = game.get(column)
	return value != null and str(value) != ""
