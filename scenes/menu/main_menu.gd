extends Control

## The title screen.

signal continue_pressed
signal play_pressed
signal armies_pressed

func _ready() -> void:
	# Only offer to continue when there's an unfinished game saved.
	%Continue.visible = SavedGame.load_saved() != null
	%Continue.pressed.connect(func() -> void: continue_pressed.emit())
	%Play.pressed.connect(func() -> void: play_pressed.emit())
	%Armies.pressed.connect(func() -> void: armies_pressed.emit())
	%Sound.pressed.connect(toggle_sound)
	_show_sound()

func toggle_sound() -> void:
	UserSettings.set_sound_on(not UserSettings.sound_on())
	_show_sound()

func _show_sound() -> void:
	%Sound.text = "Sound: " + ("on" if UserSettings.sound_on() else "off")
