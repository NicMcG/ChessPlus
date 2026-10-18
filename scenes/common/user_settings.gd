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

## This device's player ID for online games: random letters made the first time
## it's needed, then kept. It's how the server knows which side is yours.
static func player_id() -> String:
	var file := _settings()
	var id: String = file.get_value("online", "player_id", "")
	if id == "":
		var rng := RandomNumberGenerator.new()
		rng.randomize()
		for i in 16:
			id += "%x" % rng.randi_range(0, 15)
		file.set_value("online", "player_id", id)
		file.save(save_path)
	return id

## The code of the online game this device is playing ("" if none), so it can be
## picked up again from the main menu after the app closes.
static func online_game() -> String:
	return _settings().get_value("online", "game", "")

static func set_online_game(code: String) -> void:
	var file := _settings()
	file.set_value("online", "game", code)
	file.save(save_path)

## The settings file, read fresh each time (it's tiny).
static func _settings() -> ConfigFile:
	var file := ConfigFile.new()
	file.load(save_path)  # A missing file just means "all defaults".
	return file
