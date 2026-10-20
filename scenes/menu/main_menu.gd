extends Control

## The title screen.

signal continue_pressed
signal play_pressed
signal online_pressed
signal continue_online_pressed
signal armies_pressed
signal testing_pressed
## The Sound button was pressed (the volume button's picture follows it).
signal sound_toggled

func _ready() -> void:
	# Only offer to continue when there's an unfinished game saved.
	%Continue.visible = SavedGame.load_saved() != null
	%Continue.pressed.connect(func() -> void: continue_pressed.emit())
	%Play.pressed.connect(func() -> void: play_pressed.emit())
	%Online.pressed.connect(func() -> void: online_pressed.emit())
	# An online game in progress can be picked up again.
	var online_code := UserSettings.online_game()
	%ContinueOnline.visible = online_code != ""
	%ContinueOnline.text = "Continue online game (%s)" % online_code
	%ContinueOnline.pressed.connect(func() -> void: continue_online_pressed.emit())
	%Armies.pressed.connect(func() -> void: armies_pressed.emit())
	%Testing.pressed.connect(func() -> void: testing_pressed.emit())
	%Sound.pressed.connect(toggle_sound)
	show_sound()

func toggle_sound() -> void:
	UserSettings.set_sound_on(not UserSettings.sound_on())
	show_sound()
	sound_toggled.emit()

func show_sound() -> void:
	%Sound.text = "Sound: " + ("on" if UserSettings.sound_on() else "off")
