extends Control

## The title screen.

signal play_pressed
signal armies_pressed

func _ready() -> void:
	%Play.pressed.connect(func() -> void: play_pressed.emit())
	%Armies.pressed.connect(func() -> void: armies_pressed.emit())
