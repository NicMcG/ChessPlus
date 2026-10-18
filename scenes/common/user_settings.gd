class_name UserSettings
extends RefCounted

## The player's own preferences (so far just sound on/off), saved on the device.
## Everything is static: there's only one set of settings.

const DEFAULT_PATH := "user://settings.cfg"

## Where the settings are saved. Tests point this somewhere else.
static var save_path := DEFAULT_PATH

static func sound_on() -> bool:
	return _settings().get_value("audio", "sound_on", true)

static func set_sound_on(on: bool) -> void:
	var file := _settings()
	file.set_value("audio", "sound_on", on)
	file.save(save_path)

## The settings file, read fresh each time (it's tiny).
static func _settings() -> ConfigFile:
	var file := ConfigFile.new()
	file.load(save_path)  # A missing file just means "all defaults".
	return file
