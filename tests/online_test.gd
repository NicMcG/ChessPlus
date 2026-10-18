extends TestSuite

## Online play: two OnlineSessions ("devices") sharing a pretend server
## (MemoryBackend), so no internet is needed.

const KNIGHT = preload("res://data/pieces/knight.tres")

func _session(player_id: String) -> OnlineSession:
	var session := OnlineSession.new(MemoryBackend.new(), player_id)
	session.poll_seconds = 0
	(Engine.get_main_loop() as SceneTree).root.add_child(session)
	return session

## Host creates a game (White, no clock); guest joins it.
func _started_game(time_ms := 0) -> Array:
	MemoryBackend.clear()
	var host := _session("host")
	var guest := _session("guest")
	await host.create_game(StandardSetup.army(), OnlineSession.SIDE_WHITE, time_ms)
	await guest.join_game(host.code, StandardSetup.army())
	await host.poll()
	return [host, guest]

func _free(sessions: Array) -> void:
	for session: Node in sessions:
		session.free()

func test_create_and_join() -> void:
	MemoryBackend.clear()
	var host := _session("host")
	var guest := _session("guest")
	var created := await host.create_game(StandardSetup.army(), OnlineSession.SIDE_BLACK, 0)
	check(created.ok, "Created")
	check_eq(host.code.length(), OnlineSession.CODE_LENGTH, "A 5-character code")
	check_eq(host.status(), OnlineSession.WAITING, "Waiting for an opponent")
	check_eq(host.my_team, Piece.Team.BLACK, "Host chose Black")
	var heard := []
	host.changed.connect(func(row: Dictionary) -> void: heard.append(row.status))
	var joined := await guest.join_game(host.code.to_lower() + " ", StandardSetup.army())
	check(joined.ok, "Joined (code typed in lower case, with a space)")
	check_eq(guest.my_team, Piece.Team.WHITE, "Guest gets the other side")
	await host.poll()
	check_eq(heard, [OnlineSession.PLAYING], "Host hears that the game started")
	check(host.create_state(StandardSetup.create_rules()) != null, "Both armies are there")
	_free([host, guest])

func test_random_side() -> void:
	MemoryBackend.clear()
	var teams := {}
	for i in 20:
		var host := _session("host%d" % i)
		await host.create_game(StandardSetup.army(), OnlineSession.SIDE_RANDOM, 0)
		teams[host.my_team] = true
		host.free()
	check_eq(teams.size(), 2, "Random gives both sides")

func test_join_problems() -> void:
	MemoryBackend.clear()
	var host := _session("host")
	var guest := _session("guest")
	var third := _session("third")
	check(not (await guest.join_game("ZZZZZ", StandardSetup.army())).ok, "No such game")
	await host.create_game(StandardSetup.army(), OnlineSession.SIDE_WHITE, 0)
	var own := await host.join_game(host.code, StandardSetup.army())
	check(not own.ok and "own game" in own.error, "Can't join your own game")
	await guest.join_game(host.code, StandardSetup.army())
	var late := await third.join_game(host.code, StandardSetup.army())
	check(not late.ok and "already started" in late.error, "Too late")
	_free([host, guest, third])

func test_moves_travel_between_devices() -> void:
	var pair: Array = await _started_game()
	var host: OnlineSession = pair[0]
	var guest: OnlineSession = pair[1]
	var sent := await host.send_moves(["e2-e4"], false)
	check(sent.ok and not sent.rows.is_empty(), "Move sent")
	await guest.poll()
	check_eq(guest.moves(), ["e2-e4"], "Guest sees it")
	check_eq(guest.side_to_move(), Piece.Team.BLACK, "Black's turn")
	var state := guest.create_state(StandardSetup.create_rules())
	check_eq(state.history.size(), 1, "Replayed")
	_free(pair)

func test_moves_cannot_collide() -> void:
	var pair: Array = await _started_game()
	var host: OnlineSession = pair[0]
	var guest: OnlineSession = pair[1]
	await host.send_moves(["e2-e4"], false)
	# The guest hasn't heard about e4 yet, so its idea of the move count is old.
	var clash := await guest.send_moves(["d2-d4"], false)
	check(clash.ok and clash.rows.is_empty(), "Rejected: someone moved first")
	_free(pair)

func test_resign_and_finish() -> void:
	var pair: Array = await _started_game()
	var host: OnlineSession = pair[0]
	var guest: OnlineSession = pair[1]
	await guest.resign()
	await host.poll()
	check_eq(host.status(), OnlineSession.FINISHED, "Finished")
	check_eq(host.result_code(), "black_resigned", "Black resigned")
	_free(pair)

func test_cancel_while_waiting() -> void:
	MemoryBackend.clear()
	var host := _session("host")
	var guest := _session("guest")
	await host.create_game(StandardSetup.army(), OnlineSession.SIDE_WHITE, 0)
	await host.cancel()
	check_eq(host.status(), OnlineSession.CANCELLED, "Cancelled")
	check(not (await guest.join_game(host.code, StandardSetup.army())).ok, "Can't join a cancelled game")
	_free([host, guest])

func test_clocks() -> void:
	var pair: Array = await _started_game(60000)
	var host: OnlineSession = pair[0]
	var guest: OnlineSession = pair[1]
	var start := host.turn_started_ms
	check_eq(host.clock_ms(Piece.Team.WHITE, start + 10000), 50000, "White's clock runs on White's turn")
	check_eq(host.clock_ms(Piece.Team.BLACK, start + 10000), 60000, "Black's doesn't")
	check(host.out_of_time(Piece.Team.WHITE, start + 60000), "Out of time at zero on your own device")
	check(not guest.out_of_time(Piece.Team.WHITE, guest.turn_started_ms + 60000), "The opponent waits a little longer")
	check(guest.out_of_time(Piece.Team.WHITE, guest.turn_started_ms + 60000 + OnlineSession.TIMEOUT_GRACE_MS), "Then claims it")
	await guest.claim_timeout(Piece.Team.WHITE)
	check_eq(guest.result_code(), "white_timeout", "White lost on time")
	_free(pair)

func test_resume_after_closing() -> void:
	var pair: Array = await _started_game()
	var host: OnlineSession = pair[0]
	await host.send_moves(["e2-e4"], false)
	var again := _session("host")
	var resumed := await again.resume(host.code)
	check(resumed.ok, "Resumed")
	check_eq(again.my_team, Piece.Team.WHITE, "Same side as before")
	check_eq(again.moves(), ["e2-e4"], "Same moves")
	var stranger := _session("stranger")
	check(not (await stranger.resume(host.code)).ok, "Someone else can't take over")
	_free(pair + [again, stranger])

func test_custom_armies_travel() -> void:
	MemoryBackend.clear()
	var host := _session("host")
	var guest := _session("guest")
	var army := Army.new()
	army.army_name = "Knights"
	army.place(load("res://data/pieces/king.tres"), Vector2i(4, 0))
	army.place(KNIGHT, Vector2i(1, 0))
	await host.create_game(army, OnlineSession.SIDE_WHITE, 0)
	await guest.join_game(host.code, StandardSetup.army())
	var white := guest.army(Piece.Team.WHITE)
	check(white != null and white.def_at(Vector2i(1, 0)) == KNIGHT, "The host's own army arrives")
	_free([host, guest])

func test_offline_errors_are_reported() -> void:
	MemoryBackend.clear()
	var backend := MemoryBackend.new()
	backend.offline = true
	var host := OnlineSession.new(backend, "host")
	(Engine.get_main_loop() as SceneTree).root.add_child(host)
	var created := await host.create_game(StandardSetup.army(), OnlineSession.SIDE_WHITE, 0)
	check(not created.ok and created.error != "", "Fails with a message")
	host.free()

# --- Screens -------------------------------------------------------------------------

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

## An online game screen for `session`.
func _game_screen(session: OnlineSession) -> Node:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	if session.get_parent():
		session.get_parent().remove_child(session)
	game.online = session
	_root().add_child(game)
	return game

func test_lobby_create_then_friend_joins() -> void:
	MemoryBackend.clear()
	var lobby: Node = load("res://scenes/online/online_lobby.tscn").instantiate()
	var backend := MemoryBackend.new()
	lobby.backend = backend
	lobby.player_id = "host"
	_root().add_child(lobby)
	var ready_sessions := []
	lobby.game_ready.connect(func(session: OnlineSession) -> void: ready_sessions.append(session))
	await lobby.create()
	check(lobby.waiting.visible, "Waiting screen")
	check_eq(lobby.code_label.text, lobby.session.code, "Shows the code")
	var guest := _session("guest")
	await guest.join_game(lobby.session.code, StandardSetup.army())
	await lobby.session.poll()
	check_eq(ready_sessions.size(), 1, "Host's game starts when the friend joins")
	lobby.free()
	guest.free()
	backend.free()

func test_lobby_join_problems_are_shown() -> void:
	MemoryBackend.clear()
	var lobby: Node = load("res://scenes/online/online_lobby.tscn").instantiate()
	var backend := MemoryBackend.new()
	lobby.backend = backend
	lobby.player_id = "guest"
	_root().add_child(lobby)
	lobby.code_edit.text = "ABC"
	await lobby.join()
	check(lobby.message_label.text.contains("5"), "Too short: says how long codes are")
	lobby.code_edit.text = "ZZZZZ"
	await lobby.join()
	check(lobby.message_label.text.contains("no game"), "Unknown code: " + lobby.message_label.text)
	lobby.free()
	backend.free()

func test_online_game_between_two_screens() -> void:
	var pair: Array = await _started_game()
	var host_screen := _game_screen(pair[0])
	var guest_screen := _game_screen(pair[1])
	check(host_screen.board_view.input_enabled, "White (host) can move")
	check(not guest_screen.board_view.input_enabled, "Black (guest) has to wait")
	check_eq(guest_screen.status_label.text, "Your opponent's move", "Guest is told to wait")
	check(not host_screen.undo_button.visible, "No undo online")
	check_eq(host_screen.new_game_button.text, "Resign", "Resign instead of New game")
	host_screen.play(Notation.find_move(host_screen.state, "e4"))
	await get_tree_frames(2)
	check(not host_screen.board_view.input_enabled, "Host waits after moving")
	await guest_screen.online.poll()
	check_eq(guest_screen.state.history.size(), 1, "Guest received e4")
	check(guest_screen.board_view.input_enabled, "Now the guest can move")
	check_eq(guest_screen.status_label.text, "Your move", "And is told so")
	host_screen.free()
	guest_screen.free()

func test_resign_from_the_game_screen() -> void:
	var pair: Array = await _started_game()
	var host_screen := _game_screen(pair[0])
	var guest_screen := _game_screen(pair[1])
	host_screen.resign()
	check_eq(host_screen.new_game_button.text, "Tap again to resign", "First tap asks to confirm")
	await host_screen.resign()
	check_eq(host_screen.status_label.text, "You resigned", "Host resigned")
	await guest_screen.online.poll()
	check_eq(guest_screen.status_label.text, "Your opponent resigned - you win!", "Guest wins")
	check_eq(UserSettings.online_game(), "", "No longer offered on the menu")
	host_screen.free()
	guest_screen.free()

func test_checkmate_finishes_the_online_game() -> void:
	var pair: Array = await _started_game()
	var host_screen := _game_screen(pair[0])
	var guest_screen := _game_screen(pair[1])
	for san in ["f3", "e5", "g4", "Qh4#"]:
		var mover: Node = host_screen if host_screen.state.side_to_move == host_screen.online.my_team else guest_screen
		var other: Node = guest_screen if mover == host_screen else host_screen
		mover.play(Notation.find_move(mover.state, san))
		await get_tree_frames(2)
		await other.online.poll()
	check_eq(host_screen.online.status(), OnlineSession.FINISHED, "Finished on the server")
	check_eq(host_screen.status_label.text, "Checkmate! Your opponent wins", "Host lost")
	check_eq(guest_screen.status_label.text, "Checkmate! You win", "Guest won")
	host_screen.free()
	guest_screen.free()

func test_menu_offers_the_online_game_again() -> void:
	var pair: Array = await _started_game()
	var host_screen := _game_screen(pair[0])
	check_eq(UserSettings.online_game(), host_screen.online.code, "Remembered")
	var menu: Node = load("res://scenes/menu/main_menu.tscn").instantiate()
	_root().add_child(menu)
	check(menu.get_node("%ContinueOnline").visible, "Continue online game shown")
	menu.free()
	host_screen.free()
	(pair[1] as Node).free()
	UserSettings.set_online_game("")

func get_tree_frames(count: int) -> void:
	for i in count:
		await (Engine.get_main_loop() as SceneTree).process_frame

func test_your_army_is_at_the_bottom() -> void:
	var pair: Array = await _started_game()
	var host_screen := _game_screen(pair[0])
	var guest_screen := _game_screen(pair[1])
	check(not host_screen.board_view.flipped, "White (host): White at the bottom")
	check(guest_screen.board_view.flipped, "Black (guest): Black at the bottom")
	host_screen.free()
	guest_screen.free()
