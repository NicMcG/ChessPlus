class_name VolumeControl
extends CanvasLayer

## A speaker button in the top-right corner of every screen (the main scene owns
## one, drawn on top of whichever screen is showing). Tapping it opens a slider
## beside it to set how loud the game is; tapping the button again, or anywhere
## else, closes it. The volume is saved in UserSettings and applied to all of
## the game's sound at once (GameSounds.apply_volume).

## The volume or sound on/off changed here (the main menu's Sound button listens).
signal changed

## The button's size and its distance from the top and right edges of the screen.
## Screens with a button of their own in that corner leave room (make_room()).
const BUTTON_SIZE := 64.0
const MARGIN_TOP := 16.0
const MARGIN_RIGHT := 16.0
## How long the slider takes to open, in seconds.
const OPEN_TIME := 0.15

var button: Button
var slider: HSlider
var percent_label: Label
## The rounded box holding the slider; hidden while closed.
var panel: PanelContainer
## Covers the rest of the screen while the slider is open, so a tap anywhere
## else closes it (and doesn't also press whatever is underneath).
var closer: Control
var _icon: SpeakerIcon
## Plays a knock when the slider is let go, so you hear the new volume.
var _sounds: GameSounds
var _tween: Tween

## A gap as wide as the button, for the end of a screen's top bar, so that
## screen's own buttons don't end up underneath it.
static func make_room() -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(BUTTON_SIZE, 0)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap

func _ready() -> void:
	layer = 10  # Above every screen.
	_sounds = GameSounds.new()
	add_child(_sounds)
	closer = Control.new()
	closer.set_anchors_preset(Control.PRESET_FULL_RECT)
	closer.visible = false
	closer.gui_input.connect(_on_closer_input)
	add_child(closer)
	_build_panel()
	_build_button()
	refresh()

func _build_button() -> void:
	button = Button.new()
	button.focus_mode = Control.FOCUS_NONE
	_place_top_right(button, MARGIN_RIGHT, BUTTON_SIZE)
	button.pressed.connect(func() -> void: set_open(not is_open()))
	_icon = SpeakerIcon.new()
	_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(_icon)
	add_child(button)

func _build_panel() -> void:
	panel = PanelContainer.new()
	var box := StyleBoxFlat.new()
	box.bg_color = Color(0.11, 0.11, 0.12)
	box.set_corner_radius_all(int(BUTTON_SIZE / 2))
	box.content_margin_left = 26
	box.content_margin_right = 18
	panel.add_theme_stylebox_override("panel", box)
	# Just left of the button, the same height.
	_place_top_right(panel, MARGIN_RIGHT + BUTTON_SIZE + 8, 340)
	panel.visible = false
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	slider = HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.focus_mode = Control.FOCUS_NONE
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_slider()
	slider.value_changed.connect(_on_slider_changed)
	slider.drag_ended.connect(func(_moved: bool) -> void: _sounds.play(GameSounds.Sound.MOVE))
	row.add_child(slider)
	percent_label = Label.new()
	percent_label.custom_minimum_size.x = 76
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent_label.add_theme_font_size_override("font_size", 26)
	row.add_child(percent_label)
	add_child(panel)

## A thick track that fills in gold up to a big round handle: the theme's own
## slider is too thin to drag with a finger.
func _style_slider() -> void:
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.32, 0.32, 0.34)
	track.set_corner_radius_all(5)
	track.content_margin_top = 5
	track.content_margin_bottom = 5
	var filled := track.duplicate() as StyleBoxFlat
	filled.bg_color = Color(0.94, 0.78, 0.36)
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", filled)
	var handle := _round_handle(Color.WHITE)
	slider.add_theme_icon_override("grabber", handle)
	slider.add_theme_icon_override("grabber_highlight", handle)
	slider.custom_minimum_size.y = 40

## A white dot, as a picture (sliders want their handle as one).
static func _round_handle(color: Color) -> Texture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, color)
	gradient.set_color(1, Color(color, 0))
	gradient.add_point(0.88, color)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(0.5, 0.0)
	texture.width = 34
	texture.height = 34
	return texture

## Anchor `control` to the top-right corner, `from_right` in from the right edge.
func _place_top_right(control: Control, from_right: float, width: float) -> void:
	control.anchor_left = 1.0
	control.anchor_right = 1.0
	control.offset_right = -from_right
	control.offset_left = -from_right - width
	control.offset_top = MARGIN_TOP
	control.offset_bottom = MARGIN_TOP + BUTTON_SIZE

func is_open() -> bool:
	return panel.visible

## Open or close the slider. It grows out of the button towards the left.
func set_open(open: bool) -> void:
	if open == is_open():
		return
	if _tween:
		_tween.kill()
	closer.visible = open
	panel.visible = open
	if open:
		refresh()
		panel.pivot_offset = Vector2(panel.size.x, panel.size.y / 2)
		panel.scale = Vector2(0.05, 1)
		panel.modulate.a = 0
		_tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_property(panel, "scale", Vector2.ONE, OPEN_TIME)
		_tween.tween_property(panel, "modulate:a", 1.0, OPEN_TIME)

## Show the saved settings (after the main menu's Sound button, say).
func refresh() -> void:
	slider.set_value_no_signal(roundf(UserSettings.volume() * 100))
	percent_label.text = "%d%%" % int(slider.value)
	_icon.waves = 0 if is_muted() else (1 if slider.value < 50 else 2)
	_icon.queue_redraw()
	button.tooltip_text = "Sound off" if is_muted() else "Volume"

## No sound: switched off on the main menu, or the volume is all the way down.
func is_muted() -> bool:
	return not UserSettings.sound_on() or UserSettings.volume() <= 0.0

func _on_slider_changed(value: float) -> void:
	UserSettings.set_volume(value / 100)
	# Turning the volume up is asking to hear it, even if sound was switched off.
	if value > 0 and not UserSettings.sound_on():
		UserSettings.set_sound_on(true)
	GameSounds.apply_volume()
	refresh()
	changed.emit()

func _on_closer_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.is_pressed():
		set_open(false)
		closer.accept_event()

## The picture on the button: a loudspeaker with 0-2 sound waves, or a cross
## when muted.
class SpeakerIcon extends Control:
	var waves := 2

	func _draw() -> void:
		var c := size / 2
		var u := minf(size.x, size.y) / 64.0  # Drawn on a 64 x 64 grid.
		var white := Color(0.95, 0.95, 0.95)
		var x0 := c.x - 20 * u
		draw_colored_polygon(PackedVector2Array([
			Vector2(x0, c.y - 7 * u), Vector2(x0 + 9 * u, c.y - 7 * u),
			Vector2(x0 + 20 * u, c.y - 17 * u), Vector2(x0 + 20 * u, c.y + 17 * u),
			Vector2(x0 + 9 * u, c.y + 7 * u), Vector2(x0, c.y + 7 * u),
		]), white)
		var mid := Vector2(x0 + 22 * u, c.y)
		if waves == 0:
			var cross := Vector2(x0 + 31 * u, c.y)
			var r := 6 * u
			draw_line(cross + Vector2(-r, -r), cross + Vector2(r, r), white, 3.5 * u, true)
			draw_line(cross + Vector2(-r, r), cross + Vector2(r, -r), white, 3.5 * u, true)
			return
		for i in waves:
			var radius := (7 + 8 * i) * u
			draw_arc(mid, radius, -PI / 3.2, PI / 3.2, 16, white, 3.5 * u, true)
