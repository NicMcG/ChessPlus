class_name GameSounds
extends Node

## Plays the game's sound effects. Most are recordings from Kenney's free (CC0)
## "Impact Sounds" and "Interface Sounds" packs, in res://audio/sfx/; the rest
## are made by code (the cannon's boom, the arrow's whoosh, Raise Dead's swell,
## the checkmate bell's long hum and the dust). A sound can be several layers played together
## (e.g. a capture is a heavy punch and a wooden crack at once). Recordings with
## several takes pick one at random each time, so repeats don't sound mechanical.
## Nothing plays while sound is switched off in the menu.
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
	## A special ability being used (before its own effect starts).
	ABILITY,
	## The burst of light as a promoting pawn turns into its new piece.
	SPARKLE,
	## The quick swipe of an en passant capture.
	SWIPE,
	## Song of Slumber: a few soft music-box notes, falling.
	LULLABY,
	## Haunt: an eerie, wavering note.
	HAUNT,
}

## Each sound's layers, played together. A layer is either [file names in
## res://audio/sfx/ (one picked at random), pitch (1 = as recorded, lower =
## deeper), volume in decibels] or ["made", volume in decibels] for the sound
## made by code (make_stream).
const LAYERS := {
	Sound.MOVE: [[["impactWood_light_000", "impactWood_light_001", "impactWood_light_002"], 1.0, 0.0]],
	Sound.CAPTURE: [
		[["impactPunch_heavy_000", "impactPunch_heavy_001", "impactPunch_heavy_002"], 0.9, 2.0],
		[["impactWood_heavy_000", "impactWood_heavy_001", "impactWood_heavy_002"], 0.8, 0.0],
		[["impactPlate_heavy_000", "impactPlate_heavy_001"], 0.7, -9.0],
	],
	Sound.CHECK: [[["impactBell_heavy_000"], 1.15, -4.0]],
	Sound.SLAM: [[["impactWood_heavy_000", "impactWood_heavy_001", "impactWood_heavy_002"], 0.85, 2.0]],
	Sound.LAND: [[["impactWood_medium_000", "impactWood_medium_001", "impactWood_medium_002"], 1.0, 0.0]],
	Sound.CASTLE: [[["impactWood_medium_000", "impactWood_medium_002"], 0.9, 0.0]],
	# A rising swell as the pawn lifts and spins.
	Sound.PROMOTE: [[["maximize_006"], 0.9, 2.0], [["maximize_008"], 0.7, -4.0]],
	Sound.SPARKLE: [[["glass_002", "glass_004"], 1.5, 0.0], [["impactBell_heavy_000"], 2.0, -10.0]],
	Sound.SWIPE: [["made", -2.0]],
	Sound.CANNON_FIRE: [["made", 0.0]],
	Sound.CANNON_HIT: [[["impactMining_000", "impactMining_001"], 0.8, 2.0]],
	Sound.ARROW_WHOOSH: [["made", 0.0]],
	# The arrow striking home: a sharp wooden thunk with a punch behind it.
	Sound.ARROW_HIT: [
		[["impactPlank_medium_000", "impactPlank_medium_001"], 1.1, 4.0],
		[["impactPunch_medium_000", "impactPunch_medium_001", "impactPunch_medium_002"], 1.2, 0.0],
	],
	# A rising magical swell with a glassy sparkle.
	Sound.ABILITY: [[["maximize_008"], 0.85, 0.0], [["glass_002", "glass_004"], 1.3, -6.0]],
	Sound.RAISE_DEAD: [["made", 0.0]],
	Sound.SHIELD_BREAK: [[["impactMetal_heavy_000", "impactMetal_heavy_001"], 1.0, -2.0]],
	# A deep bell: the recorded strike, slowed right down, over a long made hum.
	Sound.CHECKMATE: [[["impactBell_heavy_002"], 0.45, 6.0], ["made", 3.0]],
	Sound.DUST: [["made", -12.0]],
	Sound.LULLABY: [["made", -3.0]],
	Sound.HAUNT: [["made", -5.0]],
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

func _ready() -> void:
	for i in 8:
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
	for layer: Array in LAYERS[sound]:
		var player := _players[_next]
		_next = (_next + 1) % _players.size()
		_set_up(player, sound, layer)
		player.play()

func _set_up(player: AudioStreamPlayer, sound: Sound, layer: Array) -> void:
	if layer[0] is String:  # "made"
		player.stream = made_stream(sound)
		player.pitch_scale = 1.0
		player.volume_db = layer[1]
	else:
		var names: Array = layer[0]
		player.stream = load("res://audio/sfx/%s.ogg" % names.pick_random())
		player.pitch_scale = layer[1]
		player.volume_db = layer[2]

## Every recording or made sound for `sound` (for tests).
static func streams_for(sound: Sound) -> Array[AudioStream]:
	var streams: Array[AudioStream] = []
	for layer: Array in LAYERS[sound]:
		if layer[0] is String:
			streams.append(made_stream(sound))
		else:
			for file_name: String in layer[0]:
				streams.append(load("res://audio/sfx/%s.ogg" % file_name))
	return streams

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
	var length: float = {Sound.CANNON_FIRE: 0.9, Sound.ARROW_WHOOSH: 0.3, Sound.SWIPE: 0.2,
			Sound.RAISE_DEAD: 1.3, Sound.CHECKMATE: 6.0, Sound.DUST: 2.0,
			Sound.LULLABY: 1.4, Sound.HAUNT: 1.3}.get(sound, 0.2)
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
			Sound.ARROW_WHOOSH:  # Rushing air that swells and fades as it passes.
				var cutoff := 0.05 + 0.25 * t / length
				band += (white - band) * cutoff
				value = 1.6 * band * sin(PI * t / length)
			Sound.SWIPE:  # A short, sharp rush of air, brighter than the arrow's.
				var cutoff := 0.2 + 0.5 * t / length
				band += (white - band) * cutoff
				value = 1.4 * (white - band * 0.5) * sin(PI * t / length) * (1.0 - t / length)
			Sound.RAISE_DEAD:  # Two slightly out-of-tune low notes rising, with a breathy hiss.
				var rise := 1.0 + 0.5 * t / length
				var swell := sin(PI * t / length)
				low += (white - low) * 0.1
				value = swell * (0.35 * sin(TAU * 110 * rise * t) + 0.3 * sin(TAU * 131 * rise * t) \
						+ 0.2 * sin(TAU * 165.5 * rise * t) + 0.6 * low)
			Sound.CHECKMATE:  # A huge bell's hum: deep partials that ring on and slowly die.
				var base := 49.0
				var ring := 0.0
				for partial: Array in [[0.5, 0.5, 0.35], [1.0, 0.45, 0.45], [1.19, 0.3, 0.7], [1.56, 0.22, 0.9], [2.0, 0.2, 1.1], [2.51, 0.12, 1.5]]:
					ring += partial[1] * sin(TAU * base * partial[0] * t) * exp(-t * partial[2])
				value = ring * minf(1.0, t * 40) * (1.0 + 0.08 * sin(TAU * 1.3 * t))
			Sound.LULLABY:  # Music-box notes G, E, C: each a soft ping that rings away.
				for note: Array in [[0.0, 784.0], [0.32, 659.3], [0.64, 523.3]]:
					var since: float = t - note[0]
					if since >= 0.0:
						var ping := exp(-since * 4.0) * minf(1.0, since * 200)
						value += 0.3 * ping * (sin(TAU * note[1] * since) + 0.25 * sin(TAU * note[1] * 2.0 * since))
			Sound.HAUNT:  # A thin, wavering "oooo" that slides up and back down.
				var glide := 1.0 + 0.25 * sin(PI * t / length)
				var waver := 1.0 + 0.012 * sin(TAU * 5.5 * t)
				band += (white - band) * 0.05
				value = sin(PI * t / length) * (0.45 * sin(TAU * 440.0 * glide * waver * t) \
						+ 0.12 * sin(TAU * 880.0 * glide * waver * t) + 0.25 * band)
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
