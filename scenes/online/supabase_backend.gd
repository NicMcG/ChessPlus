class_name SupabaseBackend
extends OnlineBackend

## The real server: a "games" table in Mac's Supabase project, reached through
## Supabase's web API (PostgREST: plain web requests with JSON). Works the same
## in the PC app and in the phone's browser.

## The project's address and its public ("anon" / "publishable") key, from
## OnlineConfig. The public key is meant to be built into the app.
var url := ""
var key := ""

func _init(p_url := OnlineConfig.SUPABASE_URL, p_key := OnlineConfig.SUPABASE_KEY) -> void:
	url = p_url.trim_suffix("/")
	key = p_key

func insert(row: Dictionary) -> Dictionary:
	return await _request(HTTPClient.METHOD_POST, "/rest/v1/games", [row])

func fetch(code: String) -> Dictionary:
	return await _request(HTTPClient.METHOD_GET, "/rest/v1/games?select=*&code=eq." + code.uri_encode(), null)

func update(code: String, changes: Dictionary, conditions: Dictionary = {}) -> Dictionary:
	var path := "/rest/v1/games?code=eq." + code.uri_encode()
	for column in conditions:
		path += "&%s=eq.%s" % [column, str(conditions[column]).uri_encode()]
	return await _request(HTTPClient.METHOD_PATCH, path, changes)

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

## Send one request and wait for the answer. Each request gets its own
## HTTPRequest node, so several can be in flight at once.
func _request(method: HTTPClient.Method, path: String, body: Variant) -> Dictionary:
	var http := HTTPRequest.new()
	http.timeout = 15.0
	# Don't ask for compressed replies: in a browser, the browser already unpacks
	# them, and Godot unpacking them a second time fails.
	http.accept_gzip = false
	add_child(http)
	var headers := PackedStringArray([
		"apikey: " + key,
		"Content-Type: application/json",
		# Send back the rows that were added or changed.
		"Prefer: return=representation",
	])
	# Older "anon" keys are tokens that also go in the Authorization header.
	if key.begins_with("eyJ"):
		headers.append("Authorization: Bearer " + key)
	var data := "" if body == null else JSON.stringify(body)
	var error := http.request(url + path, headers, method, data)
	if error != OK:
		http.queue_free()
		return failed("couldn't send the request (%s)" % error_string(error))
	var reply: Array = await http.request_completed
	http.queue_free()
	var result: int = reply[0]
	var status: int = reply[1]
	var text := (reply[3] as PackedByteArray).get_string_from_utf8()
	if result != HTTPRequest.RESULT_SUCCESS:
		return failed("no connection to the server (%s)" % RESULT_NAMES.get(result, str(result)))
	if status < 200 or status >= 300:
		return failed("server said %d: %s" % [status, text.left(200)])
	var parsed: Variant = JSON.parse_string(text) if text != "" else []
	if parsed is Array:
		return succeeded(parsed)
	return failed("unexpected reply from the server")
