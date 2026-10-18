extends TestSuite

## The result screen (GameOverPanel) in every kind of game, and the online
## extras around it: draw offers, chat and rematches (over MemoryBackend).

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func _frames(count: int) -> void:
	for i in count:
		await (Engine.get_main_loop() as SceneTree).process_frame

func _play_all(game: Node, moves: Array) -> void:
	for san in moves:
		game.play(Notation.find_move(game.state, san))

const FOOLS_MATE := ["f3", "e5", "g4", "Qh4#"]

# --- On one device -----------------------------------------------------------------

func test_two_player_checkmate_shows_the_result() -> void:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	_root().add_child(game)
	check(not game.game_over_panel.visible, "Hidden during the game")
	_play_all(game, FOOLS_MATE)
	check(game.game_over_panel.visible, "Shown at checkmate")
	check_eq(game.game_over_panel.title_text(), "Checkmate!", "Headline")
	check_eq(game.game_over_panel.detail_text(), "Black wins", "Who won")
	check(game.game_over_panel.button("again") != null, "New game button")
	game.game_over_panel.button("board").pressed.emit()
	check(not game.game_over_panel.visible, "View board hides it")
	game.undo()
	check(not game.is_over(), "Undo brings the game back")
	game.play(Notation.find_move(game.state, "Qh4#"))
	check(game.game_over_panel.visible, "Shown again at the new mate")
	game.game_over_panel.button("again").pressed.emit()
	check_eq(game.state.history.size(), 0, "New game started")
	check(not game.game_over_panel.visible, "And the result is gone")
	game.free()

func test_draw_reasons() -> void:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	# Black to move, not in check, and no legal move: stalemate.
	game.start_fen = "k7/2Q5/1K6/8/8/8/8/8 b - - 0 1"
	_root().add_child(game)
	check(game.game_over_panel.visible, "Result shown")
	check_eq(game.result_texts(), ["Draw", "Stalemate: no legal moves, but not in check"], "Stalemate explained")
	game.free()

func test_against_the_bot_says_you_win_or_lose() -> void:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	game.white_army = StandardSetup.army()
	game.black_army = StandardSetup.army()
	game.bot_team = Piece.Team.WHITE
	game.bot_delay_frames = 0
	_root().add_child(game)
	# Replace the bot's opening with Fool's mate played by hand, Black (you) mating.
	game.new_game()
	game.bot_team = -1
	game.state = StandardSetup.create_game()
	game.bot_team = Piece.Team.WHITE
	for san in FOOLS_MATE:
		game.state.make_move(Notation.find_move(game.state, san))
	check_eq(game.result_texts(), ["Checkmate!", "You win!"], "You (Black) mated the bot")
	game.free()

# --- Online ------------------------------------------------------------------------

func _session(player_id: String) -> OnlineSession:
	var session := OnlineSession.new(MemoryBackend.new(), player_id)
	session.poll_seconds = 0
	_root().add_child(session)
	return session

## Two game screens in a started online game: [host (White), guest (Black)].
func _online_pair(time_ms := 0) -> Array:
	MemoryBackend.clear()
	var host := _session("host")
	var guest := _session("guest")
	await host.create_game(StandardSetup.army(), OnlineSession.SIDE_WHITE, time_ms)
	await guest.join_game(host.code, StandardSetup.army())
	await host.poll()
	var screens := []
	for session in [host, guest]:
		var game: Node = load("res://scenes/game/game.tscn").instantiate()
		_root().remove_child(session)
		game.online = session
		_root().add_child(game)
		screens.append(game)
	return screens

func test_online_resign_result() -> void:
	var pair: Array = await _online_pair()
	var host: Node = pair[0]
	var guest: Node = pair[1]
	host.resign()
	await host.resign()
	check_eq([host.game_over_panel.title_text(), host.game_over_panel.detail_text()], ["You resigned", "You lose"], "Host's result")
	await guest.online.poll()
	check_eq([guest.game_over_panel.title_text(), guest.game_over_panel.detail_text()], ["Your opponent resigned", "You win!"], "Guest's result")
	check_eq(host.new_game_button.text, "Results", "The Resign button now shows the result")
	host.game_over_panel.hide()
	host.resign()
	check(host.game_over_panel.visible, "And brings it back")
	host.free()
	guest.free()

func test_online_draw_offer() -> void:
	var pair: Array = await _online_pair()
	var host: Node = pair[0]
	var guest: Node = pair[1]
	check(host.draw_button.visible, "Draw button during the game")
	await host.offer_draw()
	check_eq(host.draw_button.text, "Draw offered", "Host sees the offer is out")
	await guest.online.poll()
	check(guest.offer_bar.visible, "Guest is asked")
	await guest.answer_draw(true)
	check_eq([guest.game_over_panel.title_text(), guest.game_over_panel.detail_text()], ["Draw", "Agreed by both players"], "Agreed draw")
	await host.online.poll()
	check(host.game_over_panel.visible, "Host sees it too")
	check(not host.draw_button.visible, "No draw button after the game")
	host.free()
	guest.free()

func test_online_chat() -> void:
	var pair: Array = await _online_pair()
	var host: Node = pair[0]
	var guest: Node = pair[1]
	await host.send_chat("Good luck!")
	await guest.online.poll()
	check_eq(guest.chat_button.text, "Chat (1)", "Unread count")
	guest.open_chat()
	check(guest.chat_panel.visible, "Chat opens")
	check_eq(guest.chat_button.text, "Chat", "Read now")
	guest.chat_panel.set_typed_text("Thanks, you too")
	guest.chat_panel._send_typed()
	await _frames(2)
	await host.online.poll()
	check_eq(host.online.chat().size(), 2, "Reply arrived")
	host.free()
	guest.free()

func test_online_rematch_offerer_picks_the_side() -> void:
	var pair: Array = await _online_pair(300000)
	var host: Node = pair[0]
	var guest: Node = pair[1]
	await guest.resign()
	await guest.resign()
	await host.online.poll()
	var host_next := []
	var guest_next := []
	host.rematch_ready.connect(func(s: OnlineSession) -> void: host_next.append(s))
	guest.rematch_ready.connect(func(s: OnlineSession) -> void: guest_next.append(s))
	# The host offers a rematch...
	await host._rematch_with(StandardSetup.army(), OnlineSession.SIDE_WHITE)
	check(host.game_over_panel.note_text().begins_with("Waiting"), "Host waits")
	# ...the guest is told, and accepts.
	await guest.online.poll()
	check_eq(guest.game_over_panel.note_text(), "Your opponent wants a rematch!", "Guest is told")
	check_eq(guest.game_over_panel.button("rematch").text, "Accept rematch", "Accept button")
	await guest._rematch_with(StandardSetup.army())
	check_eq(guest_next.size(), 1, "Guest goes to the rematch")
	var host_session: OnlineSession = host.get_children().filter(func(n: Node) -> bool: return n is OnlineSession and n != host.online)[0]
	await host_session.poll()
	check_eq(host_next.size(), 1, "Host goes to the rematch too")
	if host_next.size() == 1 and guest_next.size() == 1:
		check_eq(host_next[0].my_team, Piece.Team.WHITE, "Host chose White again")
		check_eq(guest_next[0].my_team, Piece.Team.BLACK, "Guest gets the other side")
		check(host_next[0].timed(), "Same time limit")
	host.free()
	guest.free()

func test_rematch_picker_asks_the_offerer_for_a_side() -> void:
	var offer := ArmyPicker.new(null, "Rematch", true)
	check(offer.side_pick != null, "Offering: White / Black / Random")
	var accept := ArmyPicker.new(null, "Rematch", false)
	check(accept.side_pick == null, "Accepting: army only")
	offer.free()
	accept.free()
