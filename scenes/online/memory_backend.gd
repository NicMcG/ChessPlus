class_name MemoryBackend
extends OnlineBackend

## A pretend server that keeps games in memory, for tests: two OnlineSessions
## sharing one MemoryBackend play each other instantly, with no internet.

## code -> row. Shared by every MemoryBackend, like one server.
static var games := {}
## code -> shared army row.
static var shared_armies := {}
## Set to true to make every call fail, as if the internet were down.
var offline := false

func insert(row: Dictionary) -> Dictionary:
	if offline:
		return failed("offline")
	if games.has(row.code):
		return failed("a game with this code already exists")
	var stored := row.duplicate(true)
	stored["updated_at"] = Time.get_ticks_msec()
	games[row.code] = stored
	return succeeded([stored.duplicate(true)])

func fetch(code: String) -> Dictionary:
	if offline:
		return failed("offline")
	if not games.has(code):
		return succeeded([])
	return succeeded([games[code].duplicate(true)])

func update(code: String, changes: Dictionary, conditions: Dictionary = {}) -> Dictionary:
	if offline:
		return failed("offline")
	if not games.has(code):
		return succeeded([])
	var row: Dictionary = games[code]
	for column in conditions:
		# A column a row doesn't have yet counts as empty, like the real table's
		# defaults ('' for text).
		if row.get(column, "") != conditions[column]:
			return succeeded([])
	for column in changes:
		row[column] = changes[column]
	row["updated_at"] = Time.get_ticks_msec()
	return succeeded([row.duplicate(true)])

func call_function(name: String, args: Dictionary) -> Dictionary:
	if offline:
		return failed("offline")
	if name != "post_chat":
		return failed("no such function: " + name)
	if not games.has(args.game_code):
		return succeeded([])
	var row: Dictionary = games[args.game_code]
	var chat: Array = row.get("chat", [])
	chat.append({"from": args.sender, "text": str(args.message).left(200)})
	row["chat"] = chat
	row["updated_at"] = Time.get_ticks_msec()
	return succeeded([row.duplicate(true)])

func insert_shared_army(row: Dictionary) -> Dictionary:
	if offline:
		return failed("offline")
	if shared_armies.has(row.code):
		return failed("a shared army with this code already exists")
	shared_armies[row.code] = row.duplicate(true)
	return succeeded([row.duplicate(true)])

func fetch_shared_army(code: String) -> Dictionary:
	if offline:
		return failed("offline")
	return succeeded([shared_armies[code].duplicate(true)] if shared_armies.has(code) else [])

## Forget every game and shared army (tests start fresh).
static func clear() -> void:
	games.clear()
	shared_armies.clear()
