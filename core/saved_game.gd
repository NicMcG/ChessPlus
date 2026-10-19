class_name SavedGame
extends RefCounted

## A game in progress, saved on the device so it can be continued after the app
## is closed. Holds the two armies, the practice bot's side and level (if any),
## and the moves so far. Continuing rebuilds the starting position from the
## armies and replays the moves.
##
## Moves are stored as Move.to_text() ("e2-e4", "e4xd5", "e7-e8=Q"), which is
## instant to write, unlike full notation.

const DEFAULT_PATH := "user://current_game.json"

## Where the game is saved. Tests point this somewhere else.
static var save_path := DEFAULT_PATH

var white_army: Army
var black_army: Army
## The bot's Piece.Team, or -1 for a two-player game.
var bot_team := -1
var bot_level := PracticeBot.Level.MEDIUM
## The eval bar was chosen for this game (it's always on against the bot).
var eval_bar := false
## The engine's best move was chosen for this game against the bot.
var best_move := false
## The eval bar was switched off during this game against the bot.
var eval_bar_hidden := false
var moves: PackedStringArray = []
## When the game started and when it was last saved (a move, an undo...), in
## seconds since 1970. 0 = not known (saved by an older version).
var started_time := 0.0
var saved_time := 0.0

## A local game left this long without a move ends on its own (Mac: 2 days).
const ABANDONED_AFTER := 2 * 24 * 60 * 60

## A record of `state`, which was started from these armies and settings.
static func from_state(state: GameState, white: Army, black: Army, p_bot_team: int, p_bot_level: int) -> SavedGame:
	var saved := SavedGame.new()
	saved.white_army = white
	saved.black_army = black
	saved.bot_team = p_bot_team
	saved.bot_level = p_bot_level
	for move in state.history:
		saved.moves.append(move.to_text())
	return saved

## Rebuild the game: set up the armies, then replay the moves. Returns null if a
## move can't be replayed (for example if the rules have changed since).
func create_state(rules: GameRules) -> GameState:
	var state := ArmySetup.create_game(white_army, black_army, rules)
	for text in moves:
		var move := state.find_move(text)
		if move == null:
			return null
		state.make_move(move)
	return state

func save(now := Time.get_unix_time_from_system()) -> Error:
	saved_time = now
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(to_dict()))
	return OK

## The saved game, or null if there isn't one (or it can't be read).
static func load_saved() -> SavedGame:
	if not FileAccess.file_exists(save_path):
		return null
	# JSON.new().parse (unlike JSON.parse_string) fails quietly on a broken file.
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string(save_path)) != OK or not json.data is Dictionary:
		return null
	return from_dict(json.data)

## If the saved game has gone ABANDONED_AFTER without a move, end it (delete
## the save) and return a note saying so, for the next time the app opens;
## otherwise "". A save from before times were kept starts its clock now.
static func end_if_abandoned(now := Time.get_unix_time_from_system()) -> String:
	var saved := load_saved()
	if saved == null:
		return ""
	if saved.saved_time <= 0:
		saved.save(now)
		return ""
	if now - saved.saved_time < ABANDONED_AFTER:
		return ""
	delete_saved()
	var since := saved.started_time if saved.started_time > 0 else saved.saved_time
	return "Your game from %s was ended because no move was made for 2 days." % date_text(since)

## A date like "Oct 19", in the device's time zone.
static func date_text(unix_time: float) -> String:
	var bias_minutes: int = Time.get_time_zone_from_system().get("bias", 0)
	var date := Time.get_datetime_dict_from_unix_time(int(unix_time) + bias_minutes * 60)
	const MONTHS := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	return "%s %d" % [MONTHS[int(date.month) - 1], int(date.day)]

static func delete_saved() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)

func to_dict() -> Dictionary:
	return {
		"white": army_to_dict(white_army),
		"black": army_to_dict(black_army),
		"bot_team": bot_team,
		"bot_level": bot_level,
		"eval_bar": eval_bar,
		"best_move": best_move,
		"eval_bar_hidden": eval_bar_hidden,
		"moves": Array(moves),
		"started": started_time,
		"saved": saved_time,
	}

static func from_dict(data: Dictionary) -> SavedGame:
	var saved := SavedGame.new()
	saved.white_army = army_from_dict(data.get("white", {}))
	saved.black_army = army_from_dict(data.get("black", {}))
	if saved.white_army == null or saved.black_army == null:
		return null
	saved.bot_team = int(data.get("bot_team", -1))
	saved.bot_level = int(data.get("bot_level", PracticeBot.Level.MEDIUM))
	saved.eval_bar = bool(data.get("eval_bar", false))
	saved.best_move = bool(data.get("best_move", false))
	saved.eval_bar_hidden = bool(data.get("eval_bar_hidden", false))
	saved.started_time = float(data.get("started", 0.0))
	saved.saved_time = float(data.get("saved", 0.0))
	for text in data.get("moves", []):
		saved.moves.append(str(text))
	return saved

## An army as plain data: its name, [piece id, file, row] for each piece, and
## whether it's turned round when played as Black (Army.mirror_for_black).
static func army_to_dict(army: Army) -> Dictionary:
	var pieces := []
	for piece in army.pieces:
		pieces.append([piece.def.id, piece.square.x, piece.square.y])
	return {"name": army.army_name, "pieces": pieces, "mirror": army.mirror_for_black}

## Back from plain data. Null if a piece type no longer exists.
static func army_from_dict(data: Dictionary) -> Army:
	var by_id := {}
	for def in PieceCatalog.all_defs():
		by_id[def.id] = def
	var army := Army.new()
	army.army_name = str(data.get("name", ""))
	# Saved before armies were turned round for Black: keep them as they were, so
	# a game in progress carries on the same.
	army.mirror_for_black = bool(data.get("mirror", false))
	for entry in data.get("pieces", []):
		var def: PieceDef = by_id.get(str(entry[0]))
		if def == null:
			return null
		army.place(def, Vector2i(int(entry[1]), int(entry[2])))
	return army
