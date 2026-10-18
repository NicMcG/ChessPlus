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

## A new random ID for one online game (16 hex digits). Each game gets its own,
## so two copies of the game on one phone (e.g. the home-screen app and Safari,
## which can share storage) can play each other.
static func new_player_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var id := ""
	for i in 16:
		id += "%x" % rng.randi_range(0, 15)
	return id

## The online game this copy of the game is playing ("" if none), so it can be
## picked up again from the main menu after the app closes.
static func online_game() -> String:
	return _settings().get_value("online", "game", "")

## The player ID used in that game.
static func online_player_id() -> String:
	return _settings().get_value("online", "game_player_id", "")

static func set_online_game(code: String, player_id := "") -> void:
	var file := _settings()
	file.set_value("online", "game", code)
	file.set_value("online", "game_player_id", player_id if code != "" else "")
	file.save(save_path)

## The settings file, read fresh each time (it's tiny).
static func _settings() -> ConfigFile:
	var file := ConfigFile.new()
	file.load(save_path)  # A missing file just means "all defaults".
	return file
