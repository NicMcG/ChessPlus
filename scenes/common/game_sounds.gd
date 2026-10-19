class_name GameSounds
extends Node

## Plays the game's sound effects. Most are recordings in res://audio/sfx/ (their
## licences are there): Kenney's free (CC0) Impact, Interface, RPG Audio, Sci-Fi
## and Music Jingles packs, OpenGameArt's CC0 "Scrapes" (the move sound), a
## public-domain wolf howl, sheep and angelic choir, OpenGameArt CC0 sounds (a
## cartoon bite, a zombie groan, a guitar strum, a music-box lullaby, a bow and
## an arrow's whistle), and a giggle, a thunder crack and a church bell from
## Wikimedia Commons (credited on the main menu). Only two are made by
## code, both ones Mac liked: the cannon's boom and the balloon pop (Mac: every
## other made sound replaced by recordings). A sound can be several layers played together (e.g. a capture is a
## punch, a slap and a wooden thwack at once). Recordings with several takes pick
## one at random each time, so repeats don't sound mechanical. Nothing plays
## while sound is switched off in the menu. Mac's direction (Oct 2026): sound
## design in the spirit of anime: punchy, dramatic, magical.
##
## The board's animations say when each sound should play (BoardView's
## sound_cue signal), so e.g. a capture is heard when the pieces meet.

enum Sound {
	## A piece landing after an ordinary move (a wooden knock).
	MOVE, CAPTURE, CHECK,
	## A dragged piece dropped onto its square.
	SLAM,
	## A piece landing after a jump.
	LAND,
	## Castling: the two pieces dashing past each other.
	CASTLE,
	PROMOTE,
	CANNON_FIRE, CANNON_HIT,
	ARROW_WHOOSH, ARROW_HIT,
	RAISE_DEAD,
	SHIELD_BREAK,
	CHECKMATE,
	## The checkmated king crumbling into dust.
	DUST,
	## A special ability being used (before its own effect starts).
	ABILITY,
	## The burst of light as a promoting pawn turns into its new piece.
	SPARKLE,
	## The quick slash of an en passant capture.
	SWIPE,
	## Song of Slumber: a few soft pizzicato notes, falling, slowed right down.
	LULLABY,
	## Haunt: a deep gothic bell over a low boom.
	HAUNT,
	## Full Moon: a wolf's howl.
	HOWL,
	## Full Moon: a growl before the howl.
	GROWL,
	## An ordinary move's wood scraping along the board as it slides.
	SCRAPE,
	## A tap where the selected piece can't go: a negative buzz.
	ILLEGAL,
	## A move stopped by a Parapet (or a Knight a Squire protects): a thock, like
	## hitting a wall.
	BLOCKED,
	## While choosing a target for an ability: a magical whirr (it loops; see
	## start_loop).
	AIMING,
	## Crack Shot: the bow's twang as the arrow is loosed, and the magic humming
	## under the whole shot.
	BOW, MAGIC_HUM,
	## The Jester's giggle as it jumps in, and the balloon pop as it bursts.
	GIGGLE, POP,
	## Raise Dead: a sharp crack and a clap of thunder, and a zombie's groan as
	## the dead rise.
	THUNDER, GROAN,
	## A Ram that dies from its own charge.
	SHEEP,
	## A Vampire biting (gaining its shield).
	BITE,
	## Castling's two pieces slamming down.
	CASTLE_SLAM,
	## En passant: the passed pawn hitting the board after its dramatic pause.
	FALL,
	## A promoting piece's spin: one whoosh per turn, coming faster and faster.
	SPIN,
	## Promotion: a holy choir behind it all.
	CHOIR,
	## Song of Slumber: a strum just before the lullaby.
	STRUM,
}

## Each sound's layers, played together. A layer is either [file names in
## res://audio/sfx/ (one picked at random), pitch (1 = as recorded, lower =
## deeper), volume in decibels] or ["made", volume in decibels] for the sound
## made by code (make_stream). A recording's layer can end with a Dictionary of
## extras: "glide": [pitch, seconds] slides the pitch there as it plays.
const WOOD_KNOCK := ["impactWood_light_000", "impactWood_light_001", "impactWood_light_002"]
const WOOD_HEAVY := ["impactWood_heavy_000", "impactWood_heavy_001", "impactWood_heavy_002"]
const PUNCH_HEAVY := ["impactPunch_heavy_000", "impactPunch_heavy_001", "impactPunch_heavy_002"]
const PUNCH_MEDIUM := ["impactPunch_medium_000", "impactPunch_medium_001", "impactPunch_medium_002"]
const SLAP := ["impactSoft_heavy_000", "impactSoft_heavy_001", "impactSoft_heavy_002"]
const PLANK := ["impactPlank_medium_000", "impactPlank_medium_001", "impactPlank_medium_002"]
const LAYERS := {
	Sound.MOVE: [[WOOD_KNOCK, 1.0, 0.0]],
	# Something heavy pushed across stone (Mac: short, low, no squeak).
	Sound.SCRAPE: [[["stone_scrape_1", "stone_scrape_2"], 0.7, -5.0]],
	# Punchy: a heavy punch, a flat slap and a wooden thwack together.
	Sound.CAPTURE: [[PUNCH_HEAVY, 0.95, 3.0], [SLAP, 1.15, 2.0], [PLANK, 1.05, -2.0]],
	Sound.CHECK: [[["impactBell_heavy_000"], 1.15, -4.0]],
	Sound.SLAM: [[WOOD_HEAVY, 0.85, 2.0]],
	Sound.LAND: [[["impactWood_medium_000", "impactWood_medium_001", "impactWood_medium_002"], 1.0, 0.0]],
	# Castling's dash: a quick blade-like swish.
	Sound.CASTLE: [[["knifeSlice", "knifeSlice2"], 1.35, -4.0]],
	Sound.CASTLE_SLAM: [[["impactMining_000", "impactMining_001"], 0.75, 3.0], [WOOD_HEAVY, 0.7, 2.0], [PUNCH_HEAVY, 0.8, 0.0]],
	# Rushing whooshes as it spins up (Mac: whooshing, not whirring).
	Sound.PROMOTE: [[["cloth1", "cloth2"], 1.2, 2.0], [["forceField_002"], 1.5, -10.0]],
	Sound.CHOIR: [[["holy_choir"], 1.0, -6.0]],
	Sound.STRUM: [[["strum"], 1.0, -4.0]],
	Sound.SPIN: [[["cloth2", "knifeSlice"], 1.7, -3.0]],
	Sound.SPARKLE: [[["glass_002", "glass_004"], 1.5, 0.0], [["impactBell_heavy_000"], 2.0, -10.0]],
	# A sword's schwing.
	Sound.SWIPE: [[["drawKnife1", "drawKnife2", "drawKnife3"], 1.05, 8.0], [["knifeSlice2"], 1.0, -2.0]],
	Sound.FALL: [[WOOD_HEAVY, 0.7, 2.0], [SLAP, 0.8, 0.0]],
	Sound.CANNON_FIRE: [["made", 0.0]],
	Sound.CANNON_HIT: [[["impactMining_000", "impactMining_001"], 0.8, 2.0]],
	# The arrow whistling all the way to its target.
	Sound.ARROW_WHOOSH: [[["arrow_whistle"], 0.75, -2.0]],
	# A bowstring plucked as the arrow is loosed.
	Sound.BOW: [[["bow_shot"], 1.0, 2.0]],
	# The arrow striking home: thwack and crunch.
	Sound.ARROW_HIT: [
		[["impactPlank_medium_000", "impactPlank_medium_001"], 1.1, 6.0],
		[PUNCH_HEAVY, 1.1, 4.0],
		[["explosionCrunch_000"], 1.4, -2.0],
	],
	Sound.MAGIC_HUM: [[["forceField_001"], 0.6, -10.0]],
	# A special ability powering up (Mac).
	Sound.ABILITY: [[["power_up"], 1.0, 0.0]],
	# A rushing whoosh (it loops; see start_loop).
	Sound.AIMING: [[["thrusterFire_003"], 1.3, -15.0]],
	Sound.RAISE_DEAD: [[["forceField_000"], 0.55, -2.0]],
	# Snappy and crisp: a glass-sharp crack on top of the thunder, louder.
	Sound.THUNDER: [[["thunder_crack"], 1.05, 5.0], [["impactGlass_heavy_001", "impactGlass_heavy_002"], 1.4, 2.0], [["explosionCrunch_000"], 1.6, 0.0]],
	Sound.GROAN: [[["zombie_groan"], 1.0, -1.0]],
	# A shield shattering like glass.
	Sound.SHIELD_BREAK: [[["glass_shatter"], 1.0, 0.0]],
	# A deep bell: the recorded strike, slowed right down, over a long low rumble.
	Sound.CHECKMATE: [[["impactBell_heavy_002"], 0.45, 6.0], [["lowFrequency_explosion_000"], 0.5, 0.0]],
	Sound.DUST: [[["cloth1"], 0.5, -8.0]],
	# A soft music-box lullaby, slowed a little to sound sleepy.
	Sound.LULLABY: [[["lullaby"], 0.9, -4.0]],
	# Gothic: a big church bell's toll over a low boom.
	Sound.HAUNT: [[["church_bell"], 0.85, 0.0], [["lowFrequency_explosion_001"], 0.7, -9.0]],
	Sound.HOWL: [[["wolf_howl"], 1.0, -3.0]],
	Sound.GROWL: [[["wolf_growl"], 0.85, 0.0]],
	Sound.ILLEGAL: [[["error_005", "error_006"], 1.0, -6.0]],
	Sound.BLOCKED: [[WOOD_HEAVY, 0.55, 3.0], [PLANK, 0.6, -2.0]],
	# Short, soft and a little echoey (Mac).
	Sound.GIGGLE: [[["jester_giggle"], 1.15, -9.0]],
	Sound.POP: [["made", 0.0]],
	Sound.SHEEP: [[["sheep_baa"], 1.0, -2.0]],
	# A bite: a chomp and a crunch.
	# A sharp bite.
	Sound.BITE: [[["bite"], 1.0, 2.0]],
}

## Samples per second for the sounds made by code.
const RATE := 22050

## Made-by-code sounds, built the first time they're needed.
static var _made := {}

## The sound played most recently (for tests), or -1.
var last_played := -1

## A few players, used in turn, so several sounds can ring at once (e.g. the
## cannon's boom is still going when it hits), each with its own pitch.
var _players: Array[AudioStreamPlayer] = []
var _next := 0

## Plays a looping sound (AIMING) until stop_loop.
var _loop_player: AudioStreamPlayer
var _loop_sound := -1
## Pitch slides in progress, by player.
var _glides := {}

func _ready() -> void:
	_loop_player = _new_player()
	for i in 12:
		_players.append(_new_player())

## A sound player, mixed by Godot itself: in the web version the default is to
## hand each sound to the browser to play, and over a session those started
## coming later and later (Mac's report, Oct 2026) until the app was restarted.
func _new_player() -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
	add_child(player)
	return player


## Older single-sound choice for a move that was just made in `state` (used when
## no animation is shown): check beats capture beats an ordinary move.
func play_for_move(state: GameState, move: Move) -> void:
	if state.is_in_check():
		play(Sound.CHECK)
	elif move.is_capture() or move.breaks_shield():
		play(Sound.CAPTURE)
	else:
		play(Sound.MOVE)

func play(sound: Sound) -> void:
	last_played = sound
	if not UserSettings.sound_on() or _players.is_empty():
		return
	for layer: Array in LAYERS[sound]:
		var player := _players[_next]
		_next = (_next + 1) % _players.size()
		_set_up(player, sound, layer)
		player.play()

func _set_up(player: AudioStreamPlayer, sound: Sound, layer: Array) -> void:
	if _glides.has(player):
		(_glides[player] as Tween).kill()
		_glides.erase(player)
	if layer[0] is String:  # "made"
		player.stream = made_stream(sound)
		player.pitch_scale = 1.0
		player.volume_db = layer[1]
	else:
		var names: Array = layer[0]
		player.stream = recording(names.pick_random())
		player.pitch_scale = layer[1]
		player.volume_db = layer[2]
		var extras: Dictionary = layer[3] if layer.size() > 3 else {}
		if extras.has("glide"):
			var glide: Array = extras["glide"]
			var tween := create_tween()
			tween.tween_property(player, "pitch_scale", glide[0], glide[1])
			_glides[player] = tween

## Start `sound` looping (the whirr while choosing an ability's target), until
## stop_loop. Starting the same one again does nothing.
func start_loop(sound: Sound) -> void:
	if _loop_sound == sound and _loop_player.playing:
		return
	_loop_sound = sound
	last_played = sound
	if not UserSettings.sound_on():
		return
	var layer: Array = LAYERS[sound][0]
	var stream: AudioStream = recording((layer[0] as Array)[0]).duplicate()
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	_loop_player.stream = stream
	_loop_player.pitch_scale = layer[1]
	_loop_player.volume_db = layer[2]
	_loop_player.play()

func stop_loop() -> void:
	_loop_sound = -1
	if _loop_player:
		_loop_player.stop()

func is_looping() -> bool:
	return _loop_sound >= 0

## Every recording or made sound for `sound` (for tests).
static func streams_for(sound: Sound) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	for layer: Array in LAYERS[sound]:
		if layer[0] is String:
			streams.append(made_stream(sound))
		else:
			for file_name: String in layer[0]:
				streams.append(recording(file_name))
	return streams

## A recording in res://audio/sfx/ by name: the .ogg file, or the .wav if
## there's no .ogg (the wolf's howl).
static func recording(file_name: String) -> AudioStream:
	var path := "res://audio/sfx/%s.ogg" % file_name
	if not ResourceLoader.exists(path):
		path = "res://audio/sfx/%s.wav" % file_name
	return load(path)

static func made_stream(sound: Sound) -> AudioStreamWAV:
	if not _made.has(sound):
		_made[sound] = make_stream(sound)
	return _made[sound]

static func clear_cache() -> void:
	_made.clear()

## Build one of the made-by-code sounds, sample by sample.
static func make_stream(sound: Sound) -> AudioStreamWAV:
	var noise := RandomNumberGenerator.new()
	noise.seed = 7  # The same "random" sound every time.
	var length: float = {Sound.CANNON_FIRE: 0.9, Sound.POP: 0.25}.get(sound, 0.2)
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	# Smoothed noise values, for rumbles, scrapes and rushing air.
	var low := 0.0
	var band := 0.0
	for i in count:
		var t := float(i) / RATE
		var white := noise.randf_range(-1.0, 1.0)
		var value := 0.0
		match sound:
			Sound.CANNON_FIRE:  # A deep thump that drops in pitch, with a rumble.
				low += (white - low) * 0.04
				value = 0.9 * sin(TAU * (70.0 - 30.0 * t) * t) * exp(-t * 5) \
						+ 2.2 * low * exp(-t * 3.5) + 0.5 * white * exp(-t * 60)
			Sound.POP:  # A balloon bursting: a sharp crack of noise that dies at once.
				band += (white - band) * 0.5
				value = (0.9 * white + 0.6 * band) * exp(-t * 45.0) * minf(1.0, t * 3000.0)
		data.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
