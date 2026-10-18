class_name CheckmateEffect
extends Control

## Checkmate (Mac's design): the beaten king rises off the board towards the
## player, growing until it fills the middle of the screen, then crumbles away
## into dust that drifts off, while the result screen slowly fades in.
##
## The picture is cut into a grid of small pieces; each piece starts drifting at
## its own moment (sweeping across the king, with some randomness), moving up
## and sideways, shrinking and fading.

signal finished
## The moment the king starts crumbling (the game screen fades the result in then).
signal crumbling

## Seconds for the king to rise to the middle of the screen.
const RISE := 0.9
## Seconds it stays whole there before crumbling.
const HOLD := 0.35
## Seconds over which the crumbling sweeps across the king.
const SWEEP := 1.3
## Seconds each speck takes to drift away.
const DRIFT := 1.1
## The grid the picture is cut into.
const GRID := 26

var texture: Texture2D
## Where the king is on the board (in this control's coordinates) at the start.
var start_rect: Rect2
var time := 0.0
var _crumble_sent := false
## [cell (column, row), delay (s), drift velocity (in king sizes per second), spin]
var _specks: Array = []

func setup(p_texture: Texture2D, p_start_rect: Rect2) -> void:
	texture = p_texture
	start_rect = p_start_rect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var random := RandomNumberGenerator.new()
	random.seed = 12
	for row in GRID:
		for column in GRID:
			# Crumbles from the top right towards the bottom left, raggedly.
			var sweep := (float(GRID - 1 - column) + row) / (2.0 * (GRID - 1))
			var delay := sweep * SWEEP + random.randf_range(0.0, 0.35)
			var velocity := Vector2(random.randf_range(0.15, 0.6), random.randf_range(-0.55, -0.15))
			_specks.append([Vector2i(column, row), delay, velocity, random.randf_range(-3.0, 3.0)])

## The whole effect's length in seconds.
static func length() -> float:
	return RISE + HOLD + SWEEP + 0.35 + DRIFT

func _process(delta: float) -> void:
	advance(delta)

## Move on by `delta` seconds (tests call this to skip ahead).
func advance(delta: float) -> void:
	time += delta
	if not _crumble_sent and time >= RISE + HOLD:
		_crumble_sent = true
		crumbling.emit()
	queue_redraw()
	if time >= length():
		finished.emit()
		queue_free()

## Where the king is drawn while whole: from its square to a big square in the
## middle of the screen.
func _king_rect() -> Rect2:
	var big := minf(size.x, size.y) * 0.55
	var middle := Rect2(size / 2 - Vector2(big, big) / 2, Vector2(big, big))
	var t := clampf(time / RISE, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3)
	return Rect2(start_rect.position.lerp(middle.position, eased), start_rect.size.lerp(middle.size, eased))

func _draw() -> void:
	if texture == null:
		return
	# The rest of the screen darkens a little as the king comes forward.
	var dim := clampf(time / RISE, 0.0, 1.0) * 0.35
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, dim * clampf((length() - time) / DRIFT, 0.0, 1.0)))
	var rect := _king_rect()
	var crumble_time := time - RISE - HOLD
	if crumble_time < 0:
		# A soft shadow behind it, as if it were lifted off the board.
		var lifted := clampf(time / RISE, 0.0, 1.0)
		draw_texture_rect(texture, Rect2(rect.position + rect.size * 0.04 * lifted, rect.size), false, Color(0, 0, 0, 0.35 * lifted))
		draw_texture_rect(texture, rect, false)
		return
	var source_cell := texture.get_size() / GRID
	var cell := rect.size / GRID
	for speck: Array in _specks:
		var at: Vector2i = speck[0]
		var since: float = crumble_time - speck[1]
		var place := rect.position + Vector2(at) * cell
		var source := Rect2(Vector2(at) * source_cell, source_cell)
		if since <= 0:
			draw_texture_rect_region(texture, Rect2(place, cell), source)
			continue
		var t := since / DRIFT
		if t >= 1.0:
			continue
		var velocity: Vector2 = speck[2]
		# Drifts away, picking up speed, and turns to dust (shrinks, fades, goes sandy).
		var drift := velocity * rect.size.x * (since + since * since)
		var shrink := 1.0 - t
		var middle := place + cell / 2 + drift
		var piece_size := cell * (0.4 + 0.6 * shrink)
		draw_set_transform(middle, speck[3] * t, Vector2.ONE)
		draw_texture_rect_region(texture, Rect2(-piece_size / 2, piece_size), source, Color(0.92, 0.85, 0.72, 1.0 - t).lerp(Color(1, 1, 1, 1.0 - t), shrink * 0.5))
		draw_set_transform(Vector2.ZERO)
