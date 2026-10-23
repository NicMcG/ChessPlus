class_name SupabaseBackend
extends OnlineBackend

## The real server: Mac's Supabase project, reached through plain web requests
## (works the same in the PC app and the phone's browser). Each device signs in
## anonymously (no email, nothing for the player to do), so the server knows
## who is who; the sign-in is saved and renewed before it runs out. Then every
## action is one of the server's functions (server/supabase_update_3.sql).

## The project's address and its public ("publishable") key, from OnlineConfig.
## The public key is meant to be built into the app: on its own it can't read
## or change anything.
var url := ""
var key := ""
## Which saved sign-in to use: "" = this device's own; the live server check
## (tools/online_live_check.gd) uses others to be two players at once.
var slot := ""

## Sign-ins in use, by slot: {user_id, access_token, refresh_token, expires_at}.
static var _sessions := {}
## Slots whose sign-in is being made or renewed right now (others wait for it).
static var _renewing := {}

## Something to wait on while another request renews the sign-in.
class Waiter extends RefCounted:
	signal done

func _init(p_url := OnlineConfig.SUPABASE_URL, p_key := OnlineConfig.SUPABASE_KEY, p_slot := "") -> void:
	url = p_url.trim_suffix("/")
	key = p_key
	slot = p_slot

func user_id() -> String:
	return str(_session().get("user_id", ""))

func call_function(name: String, args: Dictionary) -> Dictionary:
	var signed := await sign_in()
	if not signed.ok:
		return signed
	var reply := await _request("/rest/v1/rpc/" + name, args, true)
	if reply.status == 401:
		# The sign-in ran out early (or was renewed elsewhere): renew and try once more.
		_session().erase("access_token")
		signed = await sign_in()
		if not signed.ok:
			return signed
		reply = await _request("/rest/v1/rpc/" + name, args, true)
	if not reply.ok:
		return failed(reply.error)
	var data: Variant = reply.data
	if data == null:
		return succeeded([])
	if data is Array:
		return succeeded(data)
	return succeeded([data])

func referee(action: String, args: Dictionary) -> Dictionary:
	var body := args.duplicate()
	body["action"] = action
	var signed := await sign_in()
	if not signed.ok:
		return signed
	var reply := await _request("/functions/v1/referee", body, true)
	if reply.status == 401:
		_session().erase("access_token")
		signed = await sign_in()
		if not signed.ok:
			return signed
		reply = await _request("/functions/v1/referee", body, true)
	if not reply.ok:
		return failed(reply.error)
	var data: Variant = reply.data
	var game: Variant = data.get("game") if data is Dictionary else null
	if game is Dictionary:
		return succeeded([game])
	# Quick match: paired by someone else meanwhile (the game's code), or still waiting.
	if data is Dictionary and data.get("paired") is String:
		return succeeded([{"paired": data.paired}])
	return succeeded([])

## Make sure this device is signed in (signing in or renewing if needed).
## {"ok", "error"}.
func sign_in() -> Dictionary:
	while _renewing.has(slot):
		await (_renewing[slot] as Waiter).done
	var current := _session()
	if current.has("access_token") and float(current.get("expires_at", 0)) - Time.get_unix_time_from_system() > 60:
		return succeeded([])
	var waiter := Waiter.new()
	_renewing[slot] = waiter
	var result := failed("not signed in")
	if current.has("refresh_token"):
		result = await _auth("/auth/v1/token?grant_type=refresh_token", {"refresh_token": current.refresh_token})
		if not result.ok:
			# Another copy of the game (sharing this device's storage) may have
			# renewed it already: use theirs if so.
			var saved := UserSettings.online_sign_in(slot)
			if saved.get("refresh_token", "") != current.get("refresh_token", "") and saved.has("refresh_token"):
				_sessions[slot] = saved
				result = await _auth("/auth/v1/token?grant_type=refresh_token", {"refresh_token": saved.refresh_token})
	if not result.ok:
		# A new anonymous sign-in: a new player as far as the server knows.
		result = await _auth("/auth/v1/signup", {})
	_renewing.erase(slot)
	waiter.done.emit()
	return result

## Forget the saved sign-ins kept in memory (the test runner, before quitting).
static func clear_cache() -> void:
	_sessions.clear()
	_renewing.clear()

func _session() -> Dictionary:
	if not _sessions.has(slot):
		_sessions[slot] = UserSettings.online_sign_in(slot)
	return _sessions[slot]

## Sign in or renew at the server's sign-in address; keeps and saves the result.
func _auth(path: String, body: Dictionary) -> Dictionary:
	var reply := await _request(path, body, false)
	if not reply.ok:
		if "anonymous" in reply.error.to_lower() and "disabled" in reply.error.to_lower():
			return failed("Online play isn't switched on on the server yet.")
		return failed(reply.error)
	var data: Variant = reply.data
	if not data is Dictionary or not data.has("access_token") or not data.has("refresh_token"):
		return failed("unexpected reply from the server's sign-in")
	var user: Variant = data.get("user")
	var session := {
		"user_id": str(user.get("id", "")) if user is Dictionary else "",
		"access_token": str(data.access_token),
		"refresh_token": str(data.refresh_token),
		"expires_at": Time.get_unix_time_from_system() + float(data.get("expires_in", 3600)),
	}
	_sessions[slot] = session
	UserSettings.set_online_sign_in(session, slot)
	return succeeded([])

## Godot's names for why a request failed, shown in error messages.
const RESULT_NAMES := {
	HTTPRequest.RESULT_CHUNKED_BODY_SIZE_MISMATCH: "chunked body size mismatch",
	HTTPRequest.RESULT_CANT_CONNECT: "can't connect",
	HTTPRequest.RESULT_CANT_RESOLVE: "can't find the server",
	HTTPRequest.RESULT_CONNECTION_ERROR: "connection error",
	HTTPRequest.RESULT_TLS_HANDSHAKE_ERROR: "secure connection failed",
	HTTPRequest.RESULT_NO_RESPONSE: "no response",
	HTTPRequest.RESULT_BODY_SIZE_LIMIT_EXCEEDED: "reply too big",
	HTTPRequest.RESULT_BODY_DECOMPRESS_FAILED: "couldn't unpack the reply",
	HTTPRequest.RESULT_REQUEST_FAILED: "request failed",
	HTTPRequest.RESULT_REDIRECT_LIMIT_REACHED: "too many redirects",
	HTTPRequest.RESULT_TIMEOUT: "timed out",
}

## POST `body` (as JSON) to `path` and wait for the answer: {"ok", "status",
## "data" (the reply as JSON), "error"}. `signed`: send the sign-in with it.
## Each request gets its own HTTPRequest node, so several can be in flight.
func _request(path: String, body: Dictionary, signed: bool) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 15.0
	# Don't ask for compressed replies: in a browser, the browser already unpacks
	# them, and Godot unpacking them a second time fails.
	http.accept_gzip = false
	add_child(http)
	var headers := PackedStringArray(["apikey: " + key, "Content-Type: application/json"])
	if signed:
		headers.append("Authorization: Bearer " + str(_session().get("access_token", "")))
	var error := http.request(url + path, headers, HTTPClient.METHOD_POST, JSON.stringify(body))
	if error != OK:
		http.queue_free()
		return {"ok": false, "status": 0, "data": null, "error": "couldn't send the request (%s)" % error_string(error)}
	var reply: Array = await http.request_completed
	http.queue_free()
	var result: int = reply[0]
	var status: int = reply[1]
	var text := (reply[3] as PackedByteArray).get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS:
		return {"ok": false, "status": 0, "data": null, "error": "no connection to the server (%s)" % RESULT_NAMES.get(result, str(result))}
	var parsed: Variant = JSON.parse_string(text) if text.strip_edges() != "" else null
	if status < 200 or status >= 300:
		# The server's functions explain refusals in plain words ("message");
		# the sign-in server uses "msg" or "error_description".
		var message := "server said %d" % status
		if parsed is Dictionary:
			for field in ["message", "msg", "error_description", "error"]:
				if parsed.get(field) is String and parsed[field] != "":
					message = parsed[field]
					break
		return {"ok": false, "status": status, "data": null, "error": message}
	return {"ok": true, "status": status, "data": parsed, "error": ""}
