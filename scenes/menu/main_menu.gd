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
