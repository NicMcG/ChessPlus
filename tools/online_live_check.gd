extends SceneTree

## Checks the real online server (Mac's Supabase project) after
## server/supabase_update_3.sql: signs in as two pretend players and a stranger
## (their own sign-ins, kept in a separate settings file), plays a short game,
## and tries what a cheater would. Prints PASS/FAIL for each check; leaves a
## finished game and a shared army behind (they're cleared away later).
##
## Run: "<godot console exe>" --headless --path . -s res://tools/online_live_check.gd

var failures := 0

func _initialize() -> void:
	UserSettings.save_path = "user://online_live_check.cfg"
	_run.call_deferred()

func check(ok: bool, what: String) -> void:
	print(("PASS  " if ok else "FAIL  ") + what)
	if not ok:
		failures += 1

func _backend(slot: String) -> SupabaseBackend:
	var backend := SupabaseBackend.new(OnlineConfig.SUPABASE_URL, OnlineConfig.SUPABASE_KEY, slot)
	root.add_child(backend)
	return backend

func _session(slot: String) -> OnlineSession:
	var session := OnlineSession.new(SupabaseBackend.new(OnlineConfig.SUPABASE_URL, OnlineConfig.SUPABASE_KEY, slot))
	session.poll_seconds = 0
	root.add_child(session)
	return session

func _run() -> void:
	var white := _session("live_white")
	var black := _session("live_black")
	var stranger := _session("live_stranger")
	for s: OnlineSession in [white, black, stranger]:
		var signed: Dictionary = await (s.backend as SupabaseBackend).sign_in()
		check(signed.ok, "signed in (%s)" % signed.error)
	check(white.player_id != "" and white.player_id != black.player_id, "two different players")

	# Nothing can be read or changed directly any more.
	var direct := await _raw(white.backend as SupabaseBackend, "/rest/v1/games?select=*&limit=1", HTTPClient.METHOD_GET, "")
	check(direct.status >= 400 or direct.text.strip_edges() == "[]", "the games table can't be read directly (%d)" % direct.status)
	var direct_write := await _raw(white.backend as SupabaseBackend, "/rest/v1/games", HTTPClient.METHOD_POST, JSON.stringify({"code": "HACK1", "status": "playing"}))
	check(direct_write.status >= 400, "a game can't be written directly (%d)" % direct_write.status)
	var anon := await _raw(null, "/rest/v1/rpc/get_game", HTTPClient.METHOD_POST, JSON.stringify({"p_code": "ABCDE"}))
	check(anon.status >= 400, "without signing in, nothing works (%d)" % anon.status)

	# A game: White creates (3 minutes each), Black joins.
	var created := await white.create_game(StandardSetup.army(), OnlineSession.SIDE_WHITE, 180000)
	check(created.ok and white.code.length() == 5, "created a game (%s)" % created.error)
	var joined := await black.join_game(white.code, StandardSetup.army())
	check(joined.ok and black.my_team == Piece.Team.BLACK, "joined as Black (%s)" % joined.error)
	var late := await stranger.join_game(white.code, StandardSetup.army())
	check(not late.ok and "already started" in late.error, "a third player can't join (%s)" % late.error)

	# Cheating attempts.
	var early := await black.send_move("e7-e5", false)
	check(early.ok and early.rows.is_empty(), "Black can't move on White's turn")
	black.my_team = Piece.Team.WHITE
	var pretend := await black.send_move("e2-e4", false)
	check(not pretend.ok and "not a player" in pretend.error, "Black can't move for White (%s)" % pretend.error)
	var pretend_resign := await black.resign()
	check(not pretend_resign.ok, "Black can't resign for White")
	black.my_team = Piece.Team.BLACK
	var nosy := await stranger.resume(white.code)
	check(not nosy.ok, "a stranger isn't a player (%s)" % nosy.error)

	# Playing.
	var moved := await white.send_move("e2-e4", false)
	check(moved.ok and white.move_count() == 1, "White played e4 (%s)" % moved.error)
	await black.poll()
	check(black.moves() == ["e2-e4"], "Black sees e4")
	var quiet: Dictionary = await black.backend.call_function("get_game", {"p_code": black.code, "p_known_version": int(black.row.version)})
	check(quiet.ok and quiet.rows[0].get("unchanged", false), "a quiet check gets only the version back")
	moved = await black.send_move("e7-e5", false)
	check(moved.ok and black.move_count() == 2, "Black played e5 (%s)" % moved.error)
	check(int(black.row.black_ms) <= 180000 and int(black.row.black_ms) > 150000, "the server's clock counted Black's time (%d ms left)" % int(black.row.black_ms))

	# The referee: illegal moves, rule-breaking armies, out-of-date copies.
	await white.poll()
	var illegal := await white.send_move("e1-e3", false)
	check(not illegal.ok and "isn't allowed" in illegal.error, "the referee refuses an illegal move (%s)" % illegal.error)
	var greedy := Army.new()
	greedy.place(load("res://data/pieces/king.tres"), Vector2i(4, 0))
	for file in [0, 1, 2, 3, 5, 6, 7]:
		greedy.place(load("res://data/pieces/queen.tres"), Vector2i(file, 0))
	var other := _session("live_stranger")
	var refused := await other.create_game(greedy, OnlineSession.SIDE_WHITE, 0)
	check(not refused.ok and "army rules" in refused.error, "the referee refuses an army over the budget (%s)" % refused.error)
	var outdated: Dictionary = await other.backend.referee("create", {"seat": "white", "white_army": SavedGame.army_to_dict(StandardSetup.army()),
			"black_army": SavedGame.army_to_dict(StandardSetup.army()), "time_ms": 0, "rules": "old-version"})
	check(not outdated.ok and "out of date" in outdated.error, "an out-of-date copy is told to update (%s)" % outdated.error)

	# Chat: the players see it, a stranger doesn't, and it has a speed limit.
	var said := await white.post_chat("Good luck!")
	check(said.ok, "White sent a chat message (%s)" % said.error)
	var peek: Dictionary = await stranger.backend.call_function("get_game", {"p_code": white.code})
	check(peek.ok and peek.rows[0].chat == [] and not (peek.rows[0] as Dictionary).has("white_id"), "a stranger sees no chat and no player IDs")
	for i in 5:
		await white.post_chat("spam %d" % i)
	var too_fast := await white.post_chat("one more")
	check(not too_fast.ok and "too fast" in too_fast.error, "chat speed limit (%s)" % too_fast.error)

	# Draw offer declined, then White resigns.
	await white.offer_draw()
	await black.poll()
	check(black.draw_offer() == "white", "Black sees the draw offer")
	await black.answer_draw(false)
	var resigned := await white.resign()
	check(resigned.ok and white.result_code() == "white_resigned", "White resigned (%s)" % resigned.error)

	# A quick checkmate: the referee ends the game, whatever the player says.
	var mate_white := _session("live_white")
	var mate_black := _session("live_black")
	await mate_white.create_game(StandardSetup.army(), OnlineSession.SIDE_WHITE, 0)
	await mate_black.join_game(mate_white.code, StandardSetup.army())
	for text in ["f2-f3", "e7-e5", "g2-g4", "d8-h4"]:
		await mate_white.poll()
		await mate_black.poll()
		var mover: OnlineSession = mate_white if mate_white.side_to_move() == Piece.Team.WHITE else mate_black
		var sent := await mover.send_move(text, false)
		check(sent.ok, "played %s (%s)" % [text, sent.error])
	check(mate_black.status() == OnlineSession.FINISHED and mate_black.result_code() == "board", "the referee ended the game at checkmate")

	# Quick match: one waits, the other is paired with them; then a report.
	var q1 := _session("live_white")
	var q2 := _session("live_black")
	q1.quick_poll_seconds = 0
	q2.quick_poll_seconds = 0
	q1._quick_args = q1._armies(StandardSetup.army())
	q1._quick_args.merge({"time_ms": 180000, "rules": RuleSet.version()})
	var waiting := await q1._try_quick()
	check(waiting.ok and q1.code == "", "quick match: the first player waits (%s)" % waiting.error)
	var found := await q2.find_quick_match(StandardSetup.army(), OnlineSession.QUICK_ANY)
	check(found.ok and q2.code != "", "quick match: the second is paired at once (%s)" % found.error)
	await q1.check_quick_match()
	check(q1.code == q2.code and q1.my_team != q2.my_team, "quick match: both in the same game, opposite sides")
	check(int(q2.row.get("time_ms", 0)) == 180000, "quick match: Any takes the other player's 3 minutes")
	var reported := await q1.report_opponent("live check")
	check(reported.ok, "reported the opponent (%s)" % reported.error)
	var twice := await q1.report_opponent("live check")
	check(not twice.ok and "already" in twice.error, "only one report per game (%s)" % twice.error)
	var left := await q1.resign()
	check(left.ok, "resigned the quick game")

	# Sharing an army.
	var shared := await ArmyShare.share(white.backend, StandardSetup.army())
	check(shared.ok and str(shared.code).length() == 5, "shared an army (%s)" % shared.error)
	var fetched: Dictionary = await black.backend.call_function("get_shared_army", {"p_code": shared.code})
	check(fetched.ok and not fetched.rows.is_empty() and fetched.rows[0].army is Dictionary, "read the shared army back")

	print("\n%s" % ("ALL PASSED" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures > 0 else 0)

## A raw request, as a cheater would send it ({"status", "text"}); `backend`
## supplies the sign-in (null = none, just the public key).
func _raw(backend: SupabaseBackend, path: String, method: HTTPClient.Method, body: String) -> Dictionary:
	var http := HTTPRequest.new()
	http.accept_gzip = false
	root.add_child(http)
	var headers := PackedStringArray(["apikey: " + OnlineConfig.SUPABASE_KEY, "Content-Type: application/json"])
	if backend:
		headers.append("Authorization: Bearer " + str(backend._session().get("access_token", "")))
	http.request(OnlineConfig.SUPABASE_URL + path, headers, method, body)
	var reply: Array = await http.request_completed
	http.queue_free()
	return {"status": int(reply[1]), "text": (reply[3] as PackedByteArray).get_string_from_utf8()}
