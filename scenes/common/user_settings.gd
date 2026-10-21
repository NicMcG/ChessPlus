class_name UserSettings
extends RefCounted

## The player's own preferences (sound, volume, default armies, ...), saved on the device.
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

## How loud the game is, from 0 (silent) to 1 (full), set with VolumeControl.
static func volume() -> float:
	return clampf(_settings().get_value("audio", "volume", 1.0), 0.0, 1.0)

static func set_volume(value: float) -> void:
	var file := _settings()
	file.set_value("audio", "volume", clampf(value, 0.0, 1.0))
	file.save(save_path)

## The sound groups with a volume of their own (Mac's Settings, Oct 2026):
## ordinary moves and captures, special effects (abilities, promotion,
## checkmate, ...) and warnings (check, the buzz of a move that isn't allowed).
const SOUND_GROUPS: Array[String] = ["moves", "effects", "warnings"]

## A sound group's volume, from 0 (silent) to 1 (full), on top of the main volume.
static func group_volume(group: String) -> float:
	return clampf(_settings().get_value("audio", "volume_" + group, 1.0), 0.0, 1.0)

static func set_group_volume(group: String, value: float) -> void:
	_store("audio", "volume_" + group, clampf(value, 0.0, 1.0))

## "Your move" notifications (TurnNotifier), on unless switched off in Settings.
static func notifications_on() -> bool:
	return _settings().get_value("notify", "your_move", true)

static func set_notifications_on(on: bool) -> void:
	_store("notify", "your_move", on)

## Settings' "Reset to defaults": every setting back to how it started (sound,
## notifications, visual, keys). The online game in progress and the default
## armies (set in My armies) are kept.
static func reset_to_defaults() -> void:
	var file := _settings()
	for section in ["audio", "notify", "visual", "keys"]:
		if file.has_section(section):
			file.erase_section(section)
	file.save(save_path)

## Save one value.
static func _store(section: String, key: String, value: Variant) -> void:
	var file := _settings()
	file.set_value(section, key, value)
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

## The saved army (its file, Army.library_path) the player chose as their
## default for `team`, or "" for none (then Standard is used). See ArmyChoices.
static func default_army(team: Piece.Team) -> String:
	return _settings().get_value("armies", _default_key(team), "")

static func set_default_army(team: Piece.Team, path: String) -> void:
	var file := _settings()
	file.set_value("armies", _default_key(team), path)
	file.save(save_path)

static func _default_key(team: Piece.Team) -> String:
	return "default_white" if team == Piece.Team.WHITE else "default_black"

## The settings file, read fresh each time (it's tiny).
static func _settings() -> ConfigFile:
	var file := ConfigFile.new()
	file.load(save_path)  # A missing file just means "all defaults".
	return file
