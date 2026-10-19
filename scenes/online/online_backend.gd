class_name OnlineBackend
extends Node

## Where online games are stored: one table of games, one row per game (a
## Dictionary of plain data: code, armies, moves, clocks, status...). This is the
## shape every backend follows; SupabaseBackend is the real server and
## MemoryBackend a stand-in for tests.
##
## Every call returns {"ok": bool, "rows": Array of rows, "error": String}. The
## calls may take a moment (they go over the internet), so use them with await.

## Add a new game. Fails if a game with the same code already exists.
func insert(_row: Dictionary) -> Dictionary:
	return failed("not implemented")

## The game with this code (rows is empty if there isn't one).
func fetch(_code: String) -> Dictionary:
	return failed("not implemented")

## Change some of a game's columns, but only if it still matches `conditions`
## (column -> value), e.g. {"move_count": 12} so two moves can't collide. rows
## holds the updated game, or is empty if the conditions didn't match.
func update(_code: String, _changes: Dictionary, _conditions: Dictionary = {}) -> Dictionary:
	return failed("not implemented")

## Run one of the server's functions (see server/*.sql), e.g.
## call_function("post_chat", {"game_code": ..., "sender": ..., "message": ...}).
## rows holds the games it changed.
func call_function(_name: String, _args: Dictionary) -> Dictionary:
	return failed("not implemented")

## Store a shared army ({"code", "army"}, see ArmyShare). Fails if the code is taken.
func insert_shared_army(_row: Dictionary) -> Dictionary:
	return failed("not implemented")

## The shared army with this code (rows is empty if there isn't one).
func fetch_shared_army(_code: String) -> Dictionary:
	return failed("not implemented")

static func succeeded(rows: Array) -> Dictionary:
	return {"ok": true, "rows": rows, "error": ""}

static func failed(error: String) -> Dictionary:
	return {"ok": false, "rows": [], "error": error}
