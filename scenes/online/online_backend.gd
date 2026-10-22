class_name OnlineBackend
extends Node

## Where online games are kept. Everything goes through the server's functions
## (server/supabase_update_3.sql): create_game, join_game, get_game, play_move,
## resign_game, offer_draw, answer_draw, cancel_game, claim_timeout,
## send_chat, claim_rematch, share_army, get_shared_army. Nobody touches the
## tables directly, and each function checks the caller may do what they ask.
## SupabaseBackend is the real server, MemoryBackend a stand-in for tests.
##
## Every call returns {"ok": bool, "rows": Array, "error": String}. A function
## that answers with a game (or other data) gives it as rows[0]; "nothing
## changed" (e.g. the opponent moved first) gives no rows. The calls may take a
## moment (they go over the internet), so use them with await.

## Run one of the server's functions with its arguments (names as in the SQL,
## e.g. {"p_code": "K7QX2", "p_seat": "white"}).
func call_function(_name: String, _args: Dictionary) -> Dictionary:
	return failed("not implemented")

## Who this device is on the server ("" until it has signed in).
func user_id() -> String:
	return ""

static func succeeded(rows: Array) -> Dictionary:
	return {"ok": true, "rows": rows, "error": ""}

static func failed(error: String) -> Dictionary:
	return {"ok": false, "rows": [], "error": error}
