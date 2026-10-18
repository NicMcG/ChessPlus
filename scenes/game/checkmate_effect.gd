class_name CheckmateEffect
extends Control

## Checkmate (Mac's design): the beaten king rises off the board towards the
## player, growing until it fills the middle of the screen, then crumbles away
## into fine dust from left to right; "CHECKMATE" in giant letters, as wide as
## the king, appears letter by letter once the crumbling has passed each one. It stays until the player taps
## anywhere; then the game screen shows the usual result screen.
##
## The picture is cut into a grid of tiny pieces; each starts drifting at its
## own moment (sweeping across the king, with some randomness), moving up and to
## the right, shrinking and fading.

## The king starts crumbling (the game screen starts the dust and wind sounds).
signal crumbling
## The player tapped to go on to the result screen.
signal dismissed

## Seconds for the king to rise to the middle of the screen.
const RISE := 0.9
## Seconds it stays whole there before crumbling.
const HOLD := 0.35
## Seconds over which the crumbling sweeps across the king, left to right.
const SWEEP := 1.8
## Seconds each speck takes to drift away.
const DRIFT := 1.2
## The grid the picture is cut into (more = finer dust).
const GRID := 46
const WORD := "CHECKMATE"
const WORD_COLOR := Color("#F3E7D3")
const WORD_OUTLINE := Color("#5A0F0C")

var texture: Texture2D
## Where the king is on the board (in this control's coordinates) at the start.
var start_rect: Rect2
var time := 0.0
var _crumble_sent := false
var _done := false
## [cell (column, row), delay (s), drift velocity (in king sizes per second), spin]
var _specks: Array = []

func setup(p_texture: Texture2D, p_start_rect: Rect2) -> void:
	texture = p_texture
	start_rect = p_start_rect

func _ready() -> void:
	# Catches every tap, so nothing underneath can be pressed until it's dismissed.
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var random := RandomNumberGenerator.new()
	random.seed = 12
	for row in GRID:
		for column in GRID:
			# Left to right, raggedly.
			var delay := float(column) / (GRID - 1) * SWEEP + random.randf_range(0.0, 0.3)
			var velocity := Vector2(random.randf_range(0.2, 0.7), random.randf_range(-0.5, -0.1))
			_specks.append([Vector2i(column, row), delay, velocity, random.randf_range(-3.0, 3.0)])

## When the dust has all blown away (from the start).
static func crumble_end() -> float:
	return RISE + HOLD + SWEEP + 0.3 + DRIFT

func _process(delta: float) -> void:
	advance(delta)

## Move on by `delta` seconds (tests call this to skip ahead).
func advance(delta: float) -> void:
	time += delta
	if not _crumble_sent and time >= RISE + HOLD:
		_crumble_sent = true
		crumbling.emit()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.pressed:
		accept_event()
		dismiss()

## Go on to the result screen (a tap anywhere).
func dismiss() -> void:
	if _done:
		return
	_done = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	dismissed.emit()
	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.4)
	fade.tween_callback(queue_free)

## The big square in the middle of the screen where the king ends up.
func _middle() -> Rect2:
	var big := minf(size.x, size.y) * 0.85
	return Rect2(size / 2 - Vector2(big, big) / 2, Vector2(big, big))

## Where the king is drawn while whole: from its square to the middle.
func _king_rect() -> Rect2:
	var t := clampf(time / RISE, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 3)
	var middle := _middle()
	return Rect2(start_rect.position.lerp(middle.position, eased), start_rect.size.lerp(middle.size, eased))

func _draw() -> void:
	if texture == null:
		return
	# The rest of the screen darkens as the king comes forward.
	draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, clampf(time / RISE, 0.0, 1.0) * 0.55))
	var rect := _king_rect()
	var crumble_time := time - RISE - HOLD
	if crumble_time < 0:
		# A soft shadow behind it, as if it were lifted off the board.
		var lifted := clampf(time / RISE, 0.0, 1.0)
		draw_texture_rect(texture, Rect2(rect.position + rect.size * 0.04 * lifted, rect.size), false, Color(0, 0, 0, 0.35 * lifted))
		draw_texture_rect(texture, rect, false)
		return
	_draw_word(rect, crumble_time)
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
		var piece_size := cell * (0.2 + 0.6 * (1.0 - t))
		draw_set_transform(place + cell / 2 + drift, speck[3] * t, Vector2.ONE)
		draw_texture_rect_region(texture, Rect2(-piece_size / 2, piece_size), source, Color(0.92, 0.85, 0.72, 1.0 - t))
		draw_set_transform(Vector2.ZERO)
	if crumble_time > SWEEP + DRIFT:
		var font := get_theme_default_font()
		var hint := "Tap anywhere to continue"
		var hint_size := int(minf(size.x, size.y) * 0.04)
		var alpha := clampf((crumble_time - SWEEP - DRIFT) / 0.8, 0.0, 1.0) * 0.8
		draw_string(font, Vector2(0, size.y * 0.75), hint, HORIZONTAL_ALIGNMENT_CENTER, size.x, hint_size, Color(1, 1, 1, alpha))

## "CHECKMATE" across the king's square, each letter fading in just after the
## crumbling (sweeping left to right over the square) has passed it.
func _draw_word(rect: Rect2, crumble_time: float) -> void:
	var font := get_theme_default_font()
	var font_size := int(rect.size.x * 0.98 / maxf(font.get_string_size(WORD, HORIZONTAL_ALIGNMENT_LEFT, -1, 100).x, 1.0) * 100)
	var width := font.get_string_size(WORD, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var x := rect.get_center().x - width / 2
	var baseline := rect.get_center().y + font_size * 0.35
	var outline := maxi(2, font_size / 14)
	# Where the crumbling has got to, plus a little extra so the dust has cleared.
	var front := rect.position.x + rect.size.x * (crumble_time - 0.35) / SWEEP
	for i in WORD.length():
		var letter := WORD[i]
		var letter_width := font.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
		var alpha := clampf((front - (x + letter_width)) / (rect.size.x * 0.12), 0.0, 1.0)
		if alpha > 0:
			draw_string_outline(font, Vector2(x, baseline), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline, Color(WORD_OUTLINE, alpha))
			draw_string(font, Vector2(x, baseline), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(WORD_COLOR, alpha))
		x += letter_width
