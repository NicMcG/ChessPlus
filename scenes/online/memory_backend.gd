class_name MemoryBackend
extends OnlineBackend

## A pretend server that keeps games in memory, for tests: two OnlineSessions
## sharing one MemoryBackend play each other instantly, with no internet.

## code -> row. Shared by every MemoryBackend, like one server.
static var games := {}
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
		if row.get(column) != conditions[column]:
			return succeeded([])
	for column in changes:
		row[column] = changes[column]
	row["updated_at"] = Time.get_ticks_msec()
	return succeeded([row.duplicate(true)])

## Forget every game (tests start fresh).
static func clear() -> void:
	games.clear()
