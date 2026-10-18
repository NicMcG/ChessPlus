class_name UserSettings
extends RefCounted

## The player's own preferences (so far just sound on/off), saved on the device.
## Everything is static: there's only one set of settings.

const DEFAULT_PATH := "user://settings.cfg"

## Where the settings are saved. Tests point this somewhere else.
static var save_path := DEFAULT_PATH

static var _file: ConfigFile

static func sound_on() -> bool:
	return _settings().get_value("audio", "sound_on", true)

static func set_sound_on(on: bool) -> void:
	_settings().set_value("audio", "sound_on", on)
	_file.save(save_path)

## Read the settings file the first time it's needed (or after a test moved it).
static func _settings() -> ConfigFile:
	if _file == null:
		_file = ConfigFile.new()
		_file.load(save_path)  # A missing file just means "all defaults".
	return _file

## Forget what was read, so the next call reads `save_path` again (for tests).
static func reload() -> void:
	_file = null
