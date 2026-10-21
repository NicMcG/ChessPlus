extends TestSuite

## The Settings screen (Mac's design, Oct 2026): sound groups with their own
## volumes, notifications, credits and Reset to defaults.

func _root() -> Node:
	return (Engine.get_main_loop() as SceneTree).root

func _open() -> SettingsMenu:
	var settings := SettingsMenu.new()
	_root().add_child(settings)
	return settings

func _finish() -> void:
	UserSettings.reset_to_defaults()
	UserSettings.set_sound_on(false)  # Tests run silently (see run_tests.gd).
	GameSounds.apply_volume()

func test_each_sound_group_has_its_own_volume() -> void:
	var settings := _open()
	settings.group_sliders["warnings"].value = 25
	check_eq(UserSettings.group_volume("warnings"), 0.25, "Saved")
	check_eq(UserSettings.group_volume("moves"), 1.0, "The others unchanged")
	var bus := GameSounds.bus_index("warnings")
	check(is_equal_approx(AudioServer.get_bus_volume_db(bus), linear_to_db(0.25 * 0.25)), "Its sound bus follows")
	settings.group_sliders["effects"].value = 0
	check(AudioServer.is_bus_mute(GameSounds.bus_index("effects")), "0% mutes that group")
	settings.free()
	_finish()

func test_sounds_are_sorted_into_groups() -> void:
	check_eq(GameSounds.group_of(GameSounds.Sound.CHECK), "warnings", "Check is a warning")
	check_eq(GameSounds.group_of(GameSounds.Sound.ILLEGAL), "warnings", "So is the buzz")
	check_eq(GameSounds.group_of(GameSounds.Sound.CAPTURE), "moves", "A capture is a move sound")
	check_eq(GameSounds.group_of(GameSounds.Sound.CHOIR), "effects", "Promotion's choir is an effect")
	check_eq(GameSounds.group_of(GameSounds.Sound.THUNDER), "effects", "So is Raise Dead's thunder")
	check_eq(AudioServer.get_bus_send(GameSounds.bus_index("moves")), &"Master", "Group buses feed the main volume")

func test_notifications_can_be_switched_off() -> void:
	var settings := _open()
	TurnNotifier.force_background = true
	TurnNotifier.sent.clear()
	settings.notifications_toggle.button_pressed = false
	check(not UserSettings.notifications_on(), "Saved")
	TurnNotifier.your_turn("Your opponent played e5.")
	check(TurnNotifier.sent.is_empty(), "No notification while switched off")
	settings.notifications_toggle.button_pressed = true
	TurnNotifier.your_turn("Your opponent played e5.")
	check_eq(TurnNotifier.sent.size(), 1, "Back on: notified")
	TurnNotifier.force_background = false
	TurnNotifier.sent.clear()
	settings.free()
	_finish()

func test_credits_and_reset() -> void:
	var settings := _open()
	settings.show_credits()
	var text := ""
	for child in settings.popup.column.get_children():
		if child is Label:
			text += (child as Label).text + "\n"
	check(text.contains("Cburnett (CC BY-SA 3.0)"), "The pieces' credit")
	check(text.contains("Coro Santa Pazienza"), "The choir's credit")
	settings.popup.close()
	settings.volume_slider.value = 40
	settings.group_sliders["moves"].value = 10
	settings.notifications_toggle.button_pressed = false
	settings.reset_to_defaults()
	check_eq(UserSettings.volume(), 1.0, "Volume back to full")
	check_eq(UserSettings.group_volume("moves"), 1.0, "Group volumes back")
	check(UserSettings.notifications_on(), "Notifications back on")
	check_eq(settings.volume_slider.value, 100.0, "The screen shows it")
	settings.free()
	_finish()

func test_main_menu_opens_settings_and_back() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	main.library = ArmyLibrary.new("user://test_armies/")
	_root().add_child(main)
	main.screen.get_node("%Settings").pressed.emit()
	check(main.screen is SettingsMenu, "Settings opens from the main menu")
	(main.screen as SettingsMenu).close()
	check(main.screen.scene_file_path == "res://scenes/menu/main_menu.tscn", "Back returns to the main menu")
	main.free()

func _board() -> BoardView:
	var view := BoardView.new()
	view.size = Vector2(640, 640)
	_root().add_child(view)
	view.show_game(StandardSetup.create_game())
	return view

func test_animation_speed() -> void:
	var settings := _open()
	settings.speed_buttons["slow"].pressed.emit()
	check_eq(UserSettings.animation_speed(), "slow", "Saved")
	var view := _board()
	check(is_equal_approx(view.move_time, BoardView.BASE_MOVE_TIME * 1.5), "The board plays animations 1.5x as long")
	settings.speed_buttons["off"].pressed.emit()
	view.apply_settings()
	check_eq(view.move_time, 0.0, "Off: no animation")
	settings.reset_to_defaults()
	view.apply_settings()
	check(is_equal_approx(view.move_time, BoardView.BASE_MOVE_TIME), "Reset: normal again")
	check(settings.speed_buttons["normal"].button_pressed, "...and the screen shows Normal")
	view.free()
	settings.free()
	_finish()

func test_board_helpers_and_reduced_effects() -> void:
	var settings := _open()
	settings.helper_toggles["coordinates"].button_pressed = false
	settings.helper_toggles["move_dots"].button_pressed = false
	settings.reduce_toggle.button_pressed = true
	var view := _board()
	check(not view.helpers.coordinates and not view.helpers.move_dots, "The board takes the switches")
	check(view.helpers.last_move and view.helpers.ability_glow, "...and leaves the others on")
	check(view.reduce_effects, "Reduce flashing and shaking")
	check(UserSettings.board_helper("last_move"), "Saved per helper")
	view.free()
	settings.free()
	_finish()

func _key(code: int) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = code & KEY_CODE_MASK
	event.ctrl_pressed = code & KEY_MASK_CTRL != 0
	event.pressed = true
	return event

func test_keys_can_be_changed_and_swap() -> void:
	var settings := _open()
	check_eq(settings.key_buttons["flip_board"].text, "F", "Flip starts on F")
	settings.key_buttons["flip_board"].pressed.emit()
	check_eq(settings.key_buttons["flip_board"].text, "Press a key...", "Waiting for a key")
	settings._input(_key(KEY_B))
	check_eq(KeyBinds.key("flip_board"), KEY_B, "Now on B")
	check_eq(KeyBinds.action_for(_key(KEY_B)), "flip_board", "The InputMap follows")
	check_eq(KeyBinds.action_for(_key(KEY_F)), "", "F does nothing now")
	settings.listen_for_key("piece_card")
	settings._input(_key(KEY_B))
	check_eq(KeyBinds.key("piece_card"), KEY_B, "The piece card takes B...")
	check_eq(KeyBinds.key("flip_board"), KEY_I, "...and flip gets its old key (I): no key does two things")
	check_eq(KeyBinds.text(KeyBinds.key("undo")), "Ctrl+Z", "Undo shows Ctrl+Z")
	settings.reset_to_defaults()
	check_eq(KeyBinds.key("flip_board"), KEY_F, "Reset: back to F")
	check_eq(KeyBinds.action_for(_key(KEY_F)), "flip_board", "...in the InputMap too")
	settings.free()
	_finish()

func test_shortcuts_in_a_game() -> void:
	var game: Node = load("res://scenes/game/game.tscn").instantiate()
	_root().add_child(game)
	game.board_view.move_time = 0.0
	for san in ["e4", "e5", "Nf3"]:
		game.play(Notation.find_move(game.state, san))
	check(game.run_shortcut("step_back"), "Left: look back a move")
	check_eq(game.viewing, 2, "...at the position after 1. e4 e5")
	game.run_shortcut("step_start")
	check_eq(game.viewing, 0, "Home: the start")
	game.run_shortcut("step_forward")
	check_eq(game.viewing, 1, "Right: a move on")
	game.run_shortcut("step_end")
	check_eq(game.viewing, -1, "End: back to the game")
	game.run_shortcut("undo")
	check_eq(game.state.history.size(), 2, "Ctrl+Z: undo")
	game.run_shortcut("redo")
	check_eq(game.state.history.size(), 3, "Ctrl+Y: redo")
	game.run_shortcut("flip_board")
	check(game.board_view.flipped, "F: the board turns round")
	game.run_shortcut("flip_board")
	check(not game.board_view.flipped, "...and back")
	check(not game.run_shortcut("cancel"), "Esc with nothing selected does nothing")
	game.board_view.tap(Board.parse_square("e5"))
	check(game.board_view.selected_square() != Board.NO_SQUARE, "Black's pawn chosen")
	check(game.run_shortcut("cancel"), "Esc...")
	check_eq(game.board_view.selected_square(), Board.NO_SQUARE, "...lets go of it")
	game.board_view.tap(Board.parse_square("e5"))
	check(game.run_shortcut("piece_card"), "I opens the chosen piece's card")
	var cards := game.find_children("*", "PieceInfo", false, false)
	check_eq(cards.size(), 1, "One card")
	for card in cards:
		card.free()
	game.settings_open = true
	var key := _key(KEY_F)
	game._input(key)
	check(not game.board_view.flipped, "No shortcuts while Settings is open")
	game.free()
	_finish()
