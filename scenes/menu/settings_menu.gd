class_name SettingsMenu
extends Control

## The Settings screen (Mac's design, Oct 2026): sound, visual and keyboard
## settings, the credits, and a button that puts every setting back to how it
## started. Opened from the main menu (as its own screen) and from games (the
## gear button, on top of the game). Every change is saved straight away.

## Back was pressed.
signal closed
## A sound setting changed (the volume button in the corner follows it).
signal sound_changed
## Any setting changed (an open game redraws with it).
signal settings_changed

const BACKGROUND := Color(0.17, 0.17, 0.18)
const ROW_LABEL_WIDTH := 300
## The credits the pictures, font and some of the sounds need (their licences).
const CREDITS: Array[String] = [
	"Chess pieces by Cburnett (CC BY-SA 3.0)",
	"Inter and Open Sans Italic fonts (SIL OFL 1.1)",
	"Sounds: giggle by Lomond (CC BY 3.0), thunder by Jud McCranie (CC BY-SA 4.0), church bell by Pete w. View (CC BY-SA 4.0), choir: Coro Santa Pazienza (CC BY 3.0)",
]

## The scrolling list of settings.
var sections: VBoxContainer
var sound_toggle: Button
var volume_slider: HSlider
## One slider per sound group (UserSettings.SOUND_GROUPS).
var group_sliders := {}
var notifications_toggle: Button
## Animation speed choices, by UserSettings.ANIMATION_SPEEDS key.
var speed_buttons := {}
## One switch per board helper (UserSettings.BOARD_HELPERS).
var helper_toggles := {}
var reduce_toggle: Button
## The key button of each keyboard shortcut (KeyBinds.ACTIONS), PC only.
var key_buttons := {}
## The shortcut waiting for its new key ("" when none).
var listening := ""
## The Credits or Reset pop-up while it's showing.
var popup: ModalPanel

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	layout.add_child(_top_bar())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	layout.add_child(scroll)
	var limit := WidthLimit.new()
	limit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(limit)
	sections = VBoxContainer.new()
	sections.add_theme_constant_override("separation", 16)
	limit.add_child(sections)
	_build_sound()
	_build_visual()
	if KeyBinds.has_keyboard():
		_build_keys()
	_build_other()
	refresh()

func _top_bar() -> HBoxContainer:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 12)
	var back := Button.new()
	back.text = "Back"
	back.custom_minimum_size = Vector2(130, 70)
	back.pressed.connect(close)
	bar.add_child(back)
	var title := Label.new()
	title.text = "Settings"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 40)
	bar.add_child(title)
	# As wide as Back, so the title stays centred; then room for the volume button.
	var balance := Control.new()
	balance.custom_minimum_size.x = 130
	bar.add_child(balance)
	bar.add_child(VolumeControl.make_room())
	return bar

func close() -> void:
	closed.emit()

# --- Sound -------------------------------------------------------------------------

func _build_sound() -> void:
	_heading("Sound")
	sound_toggle = _toggle_row("Sound", func(on: bool) -> void:
		UserSettings.set_sound_on(on)
		_sound_changed())
	volume_slider = _slider_row("Volume", func(value: float) -> void:
		UserSettings.set_volume(value)
		# Turning the volume up is asking to hear it, even if sound was off.
		if value > 0 and not UserSettings.sound_on():
			UserSettings.set_sound_on(true)
		_sound_changed())
	var names := {"moves": "Moves and captures", "effects": "Special effects", "warnings": "Warnings"}
	for group in UserSettings.SOUND_GROUPS:
		group_sliders[group] = _slider_row(names[group], func(value: float) -> void:
			UserSettings.set_group_volume(group, value)
			_sound_changed())
	notifications_toggle = _toggle_row("\"Your move\" notifications", func(on: bool) -> void:
		UserSettings.set_notifications_on(on)
		settings_changed.emit())

func _sound_changed() -> void:
	GameSounds.apply_volume()
	refresh()
	sound_changed.emit()
	settings_changed.emit()

# --- Visual -------------------------------------------------------------------------

func _build_visual() -> void:
	_heading("Visual")
	var names := {"off": "Off", "fast": "Fast", "normal": "Normal", "slow": "Slow"}
	speed_buttons = _choice_row("Animation speed", names, func(speed: String) -> void:
		UserSettings.set_animation_speed(speed)
		settings_changed.emit())
	var helper_names := {"coordinates": "Board coordinates", "move_dots": "Legal-move dots",
		"last_move": "Last-move highlight", "ability_glow": "Glow round unused abilities"}
	for helper in UserSettings.BOARD_HELPERS:
		helper_toggles[helper] = _toggle_row(helper_names[helper], func(on: bool) -> void:
			UserSettings.set_board_helper(helper, on)
			settings_changed.emit())
	reduce_toggle = _toggle_row("Reduce flashing and shaking", func(on: bool) -> void:
		UserSettings.set_reduce_effects(on)
		settings_changed.emit())

# --- Keyboard -----------------------------------------------------------------------

func _build_keys() -> void:
	_heading("Keyboard")
	var hint := Label.new()
	hint.text = "Press a key's button, then the new key."
	hint.add_theme_font_size_override("font_size", 22)
	hint.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	sections.add_child(hint)
	for action: String in KeyBinds.ACTIONS:
		var button := Button.new()
		button.custom_minimum_size = Vector2(220, 60)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(func() -> void: listen_for_key(action))
		_row(KeyBinds.ACTIONS[action][0], button)
		key_buttons[action] = button

## Wait for the next key, for shortcut `action`.
func listen_for_key(action: String) -> void:
	listening = action
	refresh()

## While waiting for a key: that key becomes the shortcut (any key, with Ctrl,
## Shift or Alt if held; pressing only one of those waits on).
func _input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if listening == "" or key == null or not key.pressed or key.echo:
		return
	if key.keycode in [KEY_CTRL, KEY_SHIFT, KEY_ALT, KEY_META]:
		return
	get_viewport().set_input_as_handled()
	set_key(listening, key.get_keycode_with_modifiers())

## Put shortcut `action` on `code` (two shortcuts on one key swap).
func set_key(action: String, code: int) -> void:
	KeyBinds.set_key(action, code)
	listening = ""
	refresh()
	settings_changed.emit()

# --- Credits and reset ---------------------------------------------------------------

func _build_other() -> void:
	_heading("More")
	_wide_button("Credits", show_credits)
	_wide_button("Reset to defaults", ask_reset)

func show_credits() -> void:
	popup = ModalPanel.new("Credits")
	for line in CREDITS:
		popup.add_text(line, 24)
	popup.add_button("Close", popup.close)
	add_child(popup)

func ask_reset() -> void:
	popup = ModalPanel.new("Reset to defaults?")
	popup.add_text("Every setting and key goes back to how it started.")
	popup.add_button("Reset", func() -> void:
		reset_to_defaults()
		popup.close())
	popup.add_button("Cancel", popup.close)
	add_child(popup)

func reset_to_defaults() -> void:
	UserSettings.reset_to_defaults()
	KeyBinds.install()
	listening = ""
	_sound_changed()

## Show the saved settings (after a change here, or elsewhere such as the volume
## button in the corner).
func refresh() -> void:
	if sound_toggle == null:
		return
	_show_toggle(sound_toggle, UserSettings.sound_on())
	_show_slider(volume_slider, UserSettings.volume())
	for group in group_sliders:
		_show_slider(group_sliders[group], UserSettings.group_volume(group))
	_show_toggle(notifications_toggle, UserSettings.notifications_on())
	for speed in speed_buttons:
		(speed_buttons[speed] as Button).set_pressed_no_signal(speed == UserSettings.animation_speed())
	for helper in helper_toggles:
		_show_toggle(helper_toggles[helper], UserSettings.board_helper(helper))
	_show_toggle(reduce_toggle, UserSettings.reduce_effects())
	for action in key_buttons:
		(key_buttons[action] as Button).text = "Press a key..." if action == listening else KeyBinds.text(KeyBinds.key(action))

# --- Building blocks ---------------------------------------------------------------

func _heading(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", Color(0.94, 0.78, 0.36))
	sections.add_child(label)

## A row: the setting's name on the left, its control on the right.
func _row(text: String, control: Control) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	var label := Label.new()
	label.text = text
	label.custom_minimum_size.x = ROW_LABEL_WIDTH
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 28)
	row.add_child(label)
	row.add_child(control)
	sections.add_child(row)
	return row

## An On/Off switch (gold when on, like the default-army buttons).
func _toggle_row(text: String, on_toggled: Callable) -> Button:
	var button := _gold_toggle()
	button.toggled.connect(func(on: bool) -> void:
		button.text = "On" if on else "Off"
		on_toggled.call(on))
	_row(text, button)
	return button

## A choice of several (only one on at a time), on its own line under its
## name so it fits a phone; `choices` maps each value to its button text, and
## `on_chosen` gets the value. Returns value -> button.
func _choice_row(text: String, choices: Dictionary, on_chosen: Callable) -> Dictionary:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 28)
	sections.add_child(label)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	sections.add_child(row)
	var group := ButtonGroup.new()
	var buttons := {}
	for value: String in choices:
		var button := _gold_toggle()
		button.text = choices[value]
		button.button_group = group
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(func() -> void: on_chosen.call(value))
		row.add_child(button)
		buttons[value] = button
	return buttons

## A toggle button that goes gold when on.
func _gold_toggle() -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(150, 64)
	button.focus_mode = Control.FOCUS_NONE
	var on_style := StyleBoxFlat.new()
	on_style.bg_color = Color(0.94, 0.78, 0.36)
	on_style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("pressed", on_style)
	button.add_theme_stylebox_override("hover_pressed", on_style)
	for color in ["font_pressed_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(color, Color(0.12, 0.12, 0.12))
	return button

func _show_toggle(button: Button, on: bool) -> void:
	button.set_pressed_no_signal(on)
	button.text = "On" if on else "Off"

## A 0-100% slider with its value beside it; `on_changed` gets 0..1.
func _slider_row(text: String, on_changed: Callable) -> HSlider:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.custom_minimum_size.x = 360
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	slider.focus_mode = Control.FOCUS_NONE
	VolumeControl.style_slider(slider)
	box.add_child(slider)
	var percent := Label.new()
	percent.custom_minimum_size.x = 90
	percent.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	percent.add_theme_font_size_override("font_size", 26)
	box.add_child(percent)
	slider.set_meta("percent", percent)
	slider.value_changed.connect(func(value: float) -> void:
		percent.text = "%d%%" % int(value)
		on_changed.call(value / 100.0))
	_row(text, box)
	return slider

func _show_slider(slider: HSlider, value: float) -> void:
	slider.set_value_no_signal(roundf(value * 100))
	(slider.get_meta("percent") as Label).text = "%d%%" % int(slider.value)

func _wide_button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 80
	button.pressed.connect(on_pressed)
	sections.add_child(button)
	return button
