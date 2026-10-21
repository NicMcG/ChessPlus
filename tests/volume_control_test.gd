extends TestSuite

## The volume button (VolumeControl) in the top-right corner of every screen.

func _root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root

func _new_control() -> VolumeControl:
	var control := VolumeControl.new()
	_root().add_child(control)
	return control

## Put things back as the test runner set them: full volume, sound off.
func _reset() -> void:
	UserSettings.set_volume(1.0)
	UserSettings.set_sound_on(false)
	GameSounds.apply_volume()

func test_volume_is_remembered() -> void:
	check_eq(UserSettings.volume(), 1.0, "Full volume to start with")
	UserSettings.set_volume(0.4)
	check(is_equal_approx(UserSettings.volume(), 0.4), "Read back from the file")
	UserSettings.set_volume(3.0)
	check_eq(UserSettings.volume(), 1.0, "Never louder than full")
	_reset()

func test_volume_sets_the_whole_game_loudness() -> void:
	UserSettings.set_volume(0.5)
	GameSounds.apply_volume()
	check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.25)), "Half way = a quarter of the power (-12 dB)")
	check(not AudioServer.is_bus_mute(0), "Not muted")
	UserSettings.set_volume(0.0)
	GameSounds.apply_volume()
	check(AudioServer.is_bus_mute(0), "All the way down = silent")
	_reset()
	check_eq(AudioServer.get_bus_volume_db(0), 0.0, "Full volume = the sounds as recorded")
	check(not AudioServer.is_bus_mute(0), "Unmuted again")

func test_button_opens_and_closes_the_slider() -> void:
	var control := _new_control()
	check(control.button.visible, "Button shown")
	check(not control.is_open(), "Slider closed to start with")
	control.button.pressed.emit()
	check(control.is_open(), "Tapping the button opens the slider")
	check(control.closer.visible, "A tap elsewhere would close it")
	control.button.pressed.emit()
	check(not control.is_open(), "Tapping it again closes it")
	control.set_open(true)
	var tap := InputEventMouseButton.new()
	tap.button_index = MOUSE_BUTTON_LEFT
	tap.pressed = true
	control.closer.gui_input.emit(tap)
	check(not control.is_open(), "A tap anywhere else closes it")
	check(not control.closer.visible, "and the rest of the screen works again")
	control.free()

func test_slider_sets_and_shows_the_volume() -> void:
	UserSettings.set_sound_on(true)
	UserSettings.set_volume(0.3)
	var control := _new_control()
	check_eq(control.slider.value, 30.0, "Slider starts at the saved volume")
	check_eq(control.percent_label.text, "30%", "and says it")
	var heard: Array[bool] = []
	control.changed.connect(func() -> void: heard.append(true))
	control.slider.value = 80
	check(is_equal_approx(UserSettings.volume(), 0.8), "Moving the slider saves the volume")
	check_eq(control.percent_label.text, "80%", "Label follows")
	check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.64)), "Applied at once")
	check_eq(heard.size(), 1, "Tells the main menu")
	check(not control.is_muted(), "Not muted")
	control.slider.value = 0
	check(control.is_muted(), "All the way down shows as muted")
	control.free()
	_reset()

func test_turning_the_volume_up_switches_sound_on() -> void:
	UserSettings.set_sound_on(false)
	var control := _new_control()
	check(control.is_muted(), "Sound off on the menu shows as muted")
	control.slider.value = 50
	check(UserSettings.sound_on(), "Turning the volume up is asking to hear it")
	check(not control.is_muted(), "No longer muted")
	control.free()
	_reset()

func test_on_every_screen_of_the_app() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	main.library = ArmyLibrary.new("user://test_armies/")
	_root().add_child(main)
	var control: VolumeControl = main.volume_control
	check(control != null and control.is_inside_tree(), "The app has one")
	check(control.layer > 0, "Drawn over the screens")
	main.show_army_list()
	main.show_army_builder(Army.new())
	main.start_game(StandardSetup.army(), StandardSetup.army())
	check_eq(main.volume_control, control, "The same one stays as the screens change")
	check(control.button.visible, "Still shown in a game")
	main.free()
	SavedGame.delete_saved()

func test_settings_sound_and_volume_button_agree() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	main.library = ArmyLibrary.new("user://test_armies/")
	_root().add_child(main)
	UserSettings.set_sound_on(true)
	main.volume_control.refresh()
	main.show_settings()
	var settings: SettingsMenu = main.screen
	settings.sound_toggle.button_pressed = false
	check(main.volume_control.is_muted(), "Sound off in Settings: the button shows muted")
	main.volume_control.slider.value = 60
	check_eq(settings.sound_toggle.text, "On", "Turning the volume up shows in Settings too")
	check_eq(settings.volume_slider.value, 60.0, "...with the same volume")
	settings.volume_slider.value = 30
	check_eq(main.volume_control.slider.value, 30.0, "And the other way round")
	main.free()
	_reset()

func test_screens_leave_room_in_the_corner() -> void:
	# The army builder and testing setup have a button at the right of their top
	# bar; it must end before the volume button starts.
	var builder: Control = load("res://scenes/armies/army_builder.tscn").instantiate()
	_root().add_child(builder)
	var testing: Control = load("res://scenes/testing/position_setup.tscn").instantiate()
	_root().add_child(testing)
	# The screens fill the window, so the corner is measured from its right edge.
	var corner := builder.size.x - VolumeControl.MARGIN_RIGHT - VolumeControl.BUTTON_SIZE
	await (Engine.get_main_loop() as SceneTree).process_frame
	await (Engine.get_main_loop() as SceneTree).process_frame
	check(builder.get_node("%TeamToggle").get_global_rect().end.x <= corner, "Builder's White/Black button clear of the corner")
	check(testing.colour_button.get_global_rect().end.x <= corner, "Testing setup's colour button clear of the corner")
	builder.free()
	testing.free()
