class_name GameSounds
extends Node

## Plays the game's sound effects. Most are recordings from Kenney's free (CC0)
## "Impact Sounds" and "Interface Sounds" packs, in res://audio/sfx/; a few that
## the packs don't have (the cannon's boom, the arrow's whoosh, Raise Dead's
## eerie swell, the checkmate dust) are made by code. Sounds with several
## recordings pick one at random each time, so repeated moves don't sound
## mechanical. Nothing plays while sound is switched off in the menu.
##
## The board's animations say when each sound should play (BoardView's
## sound_cue signal), so e.g. a capture is heard when the pieces meet.

enum Sound {
	MOVE, CAPTURE, CHECK,
	## A dragged piece dropped onto its square.
	SLAM,
	## A piece landing after a jump.
	LAND,
	## Each of the two pieces landing when castling.
	CASTLE,
	PROMOTE,
	CANNON_FIRE, CANNON_HIT,
	ARROW_WHOOSH, ARROW_HIT,
	RAISE_DEAD,
	SHIELD_BREAK,
	CHECKMATE,
	## The checkmated king crumbling into dust.
	DUST,
}

## Recordings for each sound: [file names in res://audio/sfx/ (one is picked at
## random), pitch (1 = as recorded, lower = deeper), volume in decibels].
const RECORDED := {
	Sound.MOVE: [["impactWood_light_000", "impactWood_light_001", "impactWood_light_002"], 1.0, 0.0],
	Sound.CAPTURE: [["impactPunch_medium_000", "impactPunch_medium_001", "impactPunch_medium_002"], 1.0, 0.0],
	Sound.CHECK: [["impactBell_heavy_000"], 1.15, -4.0],
	Sound.SLAM: [["impactWood_heavy_000", "impactWood_heavy_001", "impactWood_heavy_002"], 0.85, 2.0],
	Sound.LAND: [["impactWood_medium_000", "impactWood_medium_001", "impactWood_medium_002"], 1.0, 0.0],
	Sound.CASTLE: [["impactWood_medium_000", "impactWood_medium_002"], 0.9, 0.0],
	Sound.PROMOTE: [["maximize_006"], 1.0, 0.0],
	Sound.CANNON_HIT: [["impactMining_000", "impactMining_001"], 0.8, 2.0],
	Sound.ARROW_HIT: [["impactPlank_medium_000", "impactPlank_medium_001"], 1.1, 0.0],
	Sound.SHIELD_BREAK: [["impactMetal_heavy_000", "impactMetal_heavy_001"], 1.0, -2.0],
	Sound.CHECKMATE: [["impactBell_heavy_002"], 0.6, 0.0],
}

## Samples per second for the sounds made by code.
const RATE := 22050

## Made-by-code sounds, built the first time they're needed.
var _made := {}

## The sound played most recently (for tests), or -1.
var last_played := -1

## A few players, used in turn, so several sounds can ring at once (e.g. the
## cannon's boom is still going when it hits), each with its own pitch.
var _players: Array[AudioStreamPlayer] = []
var _next := 0

func _ready() -> void:
	for i in 6:
		var player := AudioStreamPlayer.new()
		add_child(player)
		_players.append(player)

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
	var player := _players[_next]
	_next = (_next + 1) % _players.size()
	if RECORDED.has(sound):
		var entry: Array = RECORDED[sound]
		var names: Array = entry[0]
		player.pitch_scale = entry[1]
		player.volume_db = entry[2]
		player.stream = load("res://audio/sfx/%s.ogg" % names.pick_random())
	else:
		if not _made.has(sound):
			_made[sound] = make_stream(sound)
		player.pitch_scale = 1.0
		player.volume_db = 0.0
		player.stream = _made[sound]
	player.play()

## Every recording or made sound for `sound` (for tests).
static func streams_for(sound: Sound) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	if RECORDED.has(sound):
		for file_name: String in RECORDED[sound][0]:
			streams.append(load("res://audio/sfx/%s.ogg" % file_name))
	else:
		streams.append(make_stream(sound))
	return streams

## Build one of the made-by-code sounds, sample by sample.
static func make_stream(sound: Sound) -> AudioStreamWAV:
	var noise := RandomNumberGenerator.new()
	noise.seed = 7  # The same "random" sound every time.
	var length: float = {Sound.CANNON_FIRE: 0.9, Sound.ARROW_WHOOSH: 0.3, Sound.RAISE_DEAD: 1.3, Sound.DUST: 2.0}.get(sound, 0.2)
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	# A smoothed noise value, for rumbles and rushing air.
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
			Sound.ARROW_WHOOSH:  # Rushing air that swells and fades as it passes.
				var cutoff := 0.05 + 0.25 * t / length
				band += (white - band) * cutoff
				value = 1.6 * band * sin(PI * t / length)
			Sound.RAISE_DEAD:  # Two slightly out-of-tune low notes rising, with a breathy hiss.
				var rise := 1.0 + 0.5 * t / length
				var swell := sin(PI * t / length)
				low += (white - low) * 0.1
				value = swell * (0.35 * sin(TAU * 110 * rise * t) + 0.3 * sin(TAU * 131 * rise * t) \
						+ 0.2 * sin(TAU * 165.5 * rise * t) + 0.6 * low)
			Sound.DUST:  # A soft sandy hiss that drifts away.
				band += (white - band) * 0.3
				value = 0.5 * (white - band) * minf(1.0, t * 6) * exp(-t * 1.6)
		data.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
