class_name GameSounds
extends Node

## Plays the game's sound effects. The sounds are made by code (short tones and
## clicks), so there are no sound files yet; they're placeholders until real
## sounds are chosen. Nothing plays while sound is switched off in the menu.

enum Sound { MOVE, CAPTURE, CHECK }

## Samples per second for the made-up sounds (plenty for short clicks).
const RATE := 22050

## Made once and shared, since they never change.
static var _streams := {}

## The sound played most recently (for tests), or -1.
var last_played := -1

var _player: AudioStreamPlayer

func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.max_polyphony = 3
	add_child(_player)

## The right sound for `move`, which has just been made in `state`: check beats
## capture beats an ordinary move.
func play_for_move(state: GameState, move: Move) -> void:
	if state.is_in_check():
		play(Sound.CHECK)
	elif move.is_capture() or move.breaks_shield():
		play(Sound.CAPTURE)
	else:
		play(Sound.MOVE)

func play(sound: Sound) -> void:
	last_played = sound
	if not UserSettings.sound_on() or _player == null:
		return
	_player.stream = stream_for(sound)
	_player.play()

static func stream_for(sound: Sound) -> AudioStreamWAV:
	if not _streams.has(sound):
		_streams[sound] = _make(sound)
	return _streams[sound]

## Build a sound sample by sample. Each one is a few sine waves (and a little
## noise for the "click" of wood on wood) that fade away quickly.
static func _make(sound: Sound) -> AudioStreamWAV:
	var noise := RandomNumberGenerator.new()
	noise.seed = 7  # Same "random" click every time.
	var length: float = {Sound.MOVE: 0.08, Sound.CAPTURE: 0.14, Sound.CHECK: 0.4}[sound]
	var count := int(length * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var t := float(i) / RATE
		var click := noise.randf_range(-1.0, 1.0)
		var value := 0.0
		match sound:
			Sound.MOVE:  # A soft, high "tock".
				value = 0.55 * sin(TAU * 520 * t) * exp(-t * 60) \
						+ 0.25 * sin(TAU * 1040 * t) * exp(-t * 90) \
						+ 0.35 * click * exp(-t * 400)
			Sound.CAPTURE:  # Lower, louder and with more knock.
				value = 0.7 * sin(TAU * 300 * t) * exp(-t * 35) \
						+ 0.3 * sin(TAU * 610 * t) * exp(-t * 50) \
						+ 0.6 * click * exp(-t * 150)
			Sound.CHECK:  # A two-note chime.
				value = (0.35 * sin(TAU * 880 * t) + 0.2 * sin(TAU * 1320 * t)) \
						* exp(-t * 9) * minf(1.0, t * 300)
		data.encode_s16(i * 2, int(clampf(value, -1.0, 1.0) * 32767))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	return stream
