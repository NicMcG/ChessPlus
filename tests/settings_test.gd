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
