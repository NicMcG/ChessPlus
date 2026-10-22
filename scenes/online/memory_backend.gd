class_name MemoryBackend
extends OnlineBackend

## A pretend server that keeps games in memory, for tests: OnlineSessions with
## their own MemoryBackends play each other instantly, with no internet. It
## follows the same rules as the real server's functions
## (server/supabase_update_3.sql): who may do what, server clocks, limits.
## Each MemoryBackend is one device: `user` is who it's signed in as.

## code -> game (with the players' IDs). Shared by every MemoryBackend, like one server.
static var games := {}
## code -> army data.
static var shared_armies := {}
## Added to the server's clock (tests use it to pretend time has passed).
static var clock_offset_ms := 0
## Set to true to make every call fail, as if the internet were down.
var offline := false
## Who this device is signed in as.
var user := ""

const TIME_CONTROLS := [0, 180000, 300000, 600000, 900000, 1800000]
const LAG_ALLOWANCE_MS := 2500

func _init(p_user := "") -> void:
	user = p_user if p_user != "" else "device-%d" % randi()

func user_id() -> String:
	return user

static func now_ms() -> int:
	return Time.get_ticks_msec() + clock_offset_ms

## Forget every game and shared army (tests start fresh).
static func clear() -> void:
	games.clear()
	shared_armies.clear()
	clock_offset_ms = 0

func call_function(name: String, args: Dictionary) -> Dictionary:
	if offline:
		return failed("offline")
	match name:
		"create_game": return _create(args)
		"join_game": return _join(args)
		"get_game": return _get_game(args)
		"play_move": return _play(args)
		"resign_game": return _resign(args)
		"offer_draw": return _offer_draw(args)
		"answer_draw": return _answer_draw(args)
		"cancel_game": return _cancel(args)
		"claim_timeout": return _claim_timeout(args)
		"send_chat": return _send_chat(args)
		"claim_rematch": return _claim_rematch(args)
		"share_army": return _share_army(args)
		"get_shared_army": return _get_shared_army(args)
	return failed("no such function: " + name)

# --- The server's functions -----------------------------------------------------------------

func _create(args: Dictionary) -> Dictionary:
	var seat := str(args.p_seat)
	if seat == "random":
		seat = "white" if randi() % 2 == 0 else "black"
	if seat not in ["white", "black"]:
		return failed("Choose White, Black or Random.")
	if int(args.p_time_ms) not in TIME_CONTROLS:
		return failed("That time limit isn't one of the choices.")
	var army: Variant = args.p_white_army if seat == "white" else args.p_black_army
	if not army_ok(army):
		return failed("That army can't be used online.")
	if games.values().filter(func(g: Dictionary) -> bool: return g.created_by == user and g.status == OnlineSession.WAITING).size() >= 5:
		return failed("You already have 5 games waiting for an opponent.")
	var code := _new_code(games)
	var g := {
		"code": code, "status": OnlineSession.WAITING, "result": "", "version": 0,
		"time_ms": int(args.p_time_ms), "white_ms": int(args.p_time_ms), "black_ms": int(args.p_time_ms),
		"moves": [], "move_count": 0, "eval_bar": bool(args.get("p_eval_bar", false)),
		"white_id": user if seat == "white" else "", "black_id": user if seat == "black" else "",
		"white_army": army if seat == "white" else null, "black_army": army if seat == "black" else null,
		"chat": [], "draw_offer": "", "rematch": "", "created_by": user, "turn_started": 0,
	}
	games[code] = g
	return succeeded([_view(g)])

func _join(args: Dictionary) -> Dictionary:
	var code := str(args.p_code).strip_edges().to_upper()
	if not games.has(code):
		return failed("There's no game with the code %s." % code)
	var g: Dictionary = games[code]
	if g.status == OnlineSession.CANCELLED:
		return failed("That game was cancelled.")
	if g.status != OnlineSession.WAITING:
		return failed("That game has already started.")
	var seat := "white" if g.white_id == "" else "black"
	var army: Variant = args.p_white_army if seat == "white" else args.p_black_army
	if not army_ok(army):
		return failed("That army can't be used online.")
	g[seat + "_id"] = user
	g[seat + "_army"] = army
	g.status = OnlineSession.PLAYING
	g.turn_started = now_ms()
	_touch(g)
	var view := _view(g)
	view["seat"] = seat
	return succeeded([view])

func _get_game(args: Dictionary) -> Dictionary:
	var code := str(args.p_code).strip_edges().to_upper()
	if not games.has(code):
		return succeeded([])
	var g: Dictionary = games[code]
	if int(g.version) == int(args.get("p_known_version", -1)):
		return succeeded([{"version": g.version, "unchanged": true}])
	return succeeded([_view(g)])

func _play(args: Dictionary) -> Dictionary:
	var found := _my_game(args)
	if found.has("error"):
		return failed(found.error)
	var g: Dictionary = found.game
	var mover := _mover(g)
	if g.status != OnlineSession.PLAYING or int(g.move_count) != int(args.p_expected) or args.p_seat != mover:
		return succeeded([])
	var text := str(args.p_move)
	if not RegEx.create_from_string("^[A-Za-z0-9!=@~x-]{2,16}$").search(text):
		return failed("That move can't be sent.")
	var left := 0
	if int(g.time_ms) > 0:
		var elapsed := maxi(0, now_ms() - int(g.turn_started))
		var charged := mini(elapsed, maxi(maxi(int(args.p_think_ms), 0), elapsed - LAG_ALLOWANCE_MS))
		left = int(g[mover + "_ms"]) - charged
		if left <= 0:
			_finish(g, mover + "_timeout")
			g[mover + "_ms"] = 0
			return succeeded([_view(g)])
		g[mover + "_ms"] = left
	g.moves.append(text)
	g.move_count = int(g.move_count) + 1
	if g.draw_offer != mover:
		g.draw_offer = ""
	g.turn_started = now_ms()
	if bool(args.get("p_finished", false)):
		g.status = OnlineSession.FINISHED
		g.result = "board"
	_touch(g)
	return succeeded([_view(g)])

func _resign(args: Dictionary) -> Dictionary:
	var found := _my_game(args)
	if found.has("error"):
		return failed(found.error)
	var g: Dictionary = found.game
	if g.status != OnlineSession.PLAYING:
		return succeeded([])
	g.draw_offer = ""
	_finish(g, str(args.p_seat) + "_resigned")
	return succeeded([_view(g)])

func _offer_draw(args: Dictionary) -> Dictionary:
	var found := _my_game(args)
	if found.has("error"):
		return failed(found.error)
	var g: Dictionary = found.game
	if g.status != OnlineSession.PLAYING or g.draw_offer != "":
		return succeeded([])
	g.draw_offer = args.p_seat
	_touch(g)
	return succeeded([_view(g)])

func _answer_draw(args: Dictionary) -> Dictionary:
	var found := _my_game(args)
	if found.has("error"):
		return failed(found.error)
	var g: Dictionary = found.game
	if g.draw_offer == "" or g.draw_offer == args.p_seat:
		return succeeded([])
	g.draw_offer = ""
	if bool(args.p_accept) and g.status == OnlineSession.PLAYING:
		_finish(g, "draw_agreed")
	else:
		_touch(g)
	return succeeded([_view(g)])

func _cancel(args: Dictionary) -> Dictionary:
	var found := _my_game(args)
	if found.has("error"):
		return failed(found.error)
	var g: Dictionary = found.game
	if g.status != OnlineSession.WAITING:
		return succeeded([])
	g.status = OnlineSession.CANCELLED
	_touch(g)
	return succeeded([_view(g)])

func _claim_timeout(args: Dictionary) -> Dictionary:
	var found := _my_game(args)
	if found.has("error"):
		return failed(found.error)
	var g: Dictionary = found.game
	var mover := _mover(g)
	var grace := 0 if args.p_seat == mover else LAG_ALLOWANCE_MS
	if g.status == OnlineSession.PLAYING and int(g.time_ms) > 0 \
			and now_ms() - int(g.turn_started) > int(g[mover + "_ms"]) + grace:
		g[mover + "_ms"] = 0
		_finish(g, mover + "_timeout")
	return succeeded([_view(g)])

func _send_chat(args: Dictionary) -> Dictionary:
	var found := _my_game(args)
	if found.has("error"):
		return failed(found.error)
	var g: Dictionary = found.game
	var text := str(args.p_text).strip_edges().left(200)
	if text == "":
		return failed("Empty message.")
	if g.chat.size() >= 300:
		return failed("This game's chat is full.")
	var now := now_ms()
	var recent: Array = g.chat.filter(func(m: Dictionary) -> bool: return m.from == args.p_seat and int(m.at) > now - 10000)
	if recent.size() >= 5:
		return failed("You're sending messages too fast.")
	g.chat.append({"from": args.p_seat, "text": text, "at": now})
	_touch(g)
	return succeeded([_view(g)])

func _claim_rematch(args: Dictionary) -> Dictionary:
	var found := _my_game(args)
	if found.has("error"):
		return failed(found.error)
	var g: Dictionary = found.game
	if g.status != OnlineSession.FINISHED or g.rematch != "":
		return succeeded([])
	var new_code := str(args.p_new_code).to_upper()
	var other: Dictionary = games.get(new_code, {})
	if other.is_empty() or other.created_by != user or other.status != OnlineSession.WAITING:
		return failed("That rematch game isn't yours.")
	g.rematch = new_code
	_touch(g)
	return succeeded([_view(g)])

func _share_army(args: Dictionary) -> Dictionary:
	if not army_ok(args.p_army):
		return failed("That army can't be shared.")
	var code := _new_code(shared_armies)
	shared_armies[code] = (args.p_army as Dictionary).duplicate(true)
	return succeeded([{"code": code}])

func _get_shared_army(args: Dictionary) -> Dictionary:
	var code := str(args.p_code).strip_edges().to_upper()
	if not shared_armies.has(code):
		return succeeded([])
	return succeeded([{"army": (shared_armies[code] as Dictionary).duplicate(true)}])

# --- Inside -----------------------------------------------------------------------------

## The server's checks on an army's shape and size (see army_ok in the SQL).
static func army_ok(army: Variant) -> bool:
	if not army is Dictionary or JSON.stringify(army).length() > 3000:
		return false
	var pieces: Variant = army.get("pieces")
	if not pieces is Array or pieces.size() < 1 or pieces.size() > 16 or str(army.get("name", "")).length() > 40:
		return false
	for entry: Variant in pieces:
		if not entry is Array or entry.size() != 3 or not entry[0] is String:
			return false
		if not (entry[1] is int or entry[1] is float) or not (entry[2] is int or entry[2] is float):
			return false
		if int(entry[1]) < 0 or int(entry[1]) > 7 or int(entry[2]) < 0 or int(entry[2]) > 1:
			return false
	return true

## The caller's game after checking the seat is theirs: {"game"} or {"error"}.
func _my_game(args: Dictionary) -> Dictionary:
	var code := str(args.p_code).strip_edges().to_upper()
	if not games.has(code):
		return {"error": "There's no game with the code %s." % code}
	var g: Dictionary = games[code]
	var seat := str(args.get("p_seat", ""))
	if seat not in ["white", "black"] or g[seat + "_id"] != user:
		return {"error": "You're not a player in that game."}
	return {"game": g}

static func _mover(g: Dictionary) -> String:
	return "white" if int(g.move_count) % 2 == 0 else "black"

static func _finish(g: Dictionary, result: String) -> void:
	g.status = OnlineSession.FINISHED
	g.result = result
	_touch(g)

static func _touch(g: Dictionary) -> void:
	g.version = int(g.version) + 1

func _view(g: Dictionary) -> Dictionary:
	var player: bool = user in [g.white_id, g.black_id]
	var you := []
	for seat in ["white", "black"]:
		if g[seat + "_id"] == user:
			you.append(seat)
	return {
		"code": g.code, "status": g.status, "result": g.result, "version": g.version,
		"time_ms": g.time_ms, "white_ms": g.white_ms, "black_ms": g.black_ms,
		"moves": g.moves.duplicate(), "move_count": g.move_count, "eval_bar": g.eval_bar,
		"white_army": g.white_army, "black_army": g.black_army,
		"white_taken": g.white_id != "", "black_taken": g.black_id != "",
		"turn_ms": maxi(0, now_ms() - int(g.turn_started)) if g.status == OnlineSession.PLAYING else 0,
		"you": you,
		"chat": g.chat.duplicate(true) if player else [],
		"draw_offer": g.draw_offer if player else "",
		"rematch": g.rematch if player else "",
	}

static func _new_code(taken: Dictionary) -> String:
	while true:
		var code := ""
		for i in OnlineSession.CODE_LENGTH:
			code += OnlineSession.CODE_LETTERS[randi() % OnlineSession.CODE_LETTERS.length()]
		if not taken.has(code):
			return code
	return ""
