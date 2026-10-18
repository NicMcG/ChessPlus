class_name GameOverPanel
extends ColorRect

## The result screen that appears over the board when a game ends: a headline
## ("Checkmate!", "Draw"...), a line about who won or why, an optional note
## (e.g. "Your opponent wants a rematch!"), and buttons. Tapping a button emits
## `chosen` with that button's name; the game screen decides what it does.

signal chosen(action: String)

var _title: Label
var _detail: Label
var _note: Label
var _buttons: VBoxContainer

func _init() -> void:
	color = Color(0, 0, 0, 0.55)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 10
	hide()
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.14)
	style.border_color = Color(0.55, 0.55, 0.55)
	style.set_border_width_all(2)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.x = 520
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	_title = _label(56)
	_detail = _label(32)
	_note = _label(26)
	_note.add_theme_color_override("font_color", Color("#FFD75E"))
	column.add_child(_title)
	column.add_child(_detail)
	column.add_child(_note)
	_buttons = VBoxContainer.new()
	_buttons.add_theme_constant_override("separation", 12)
	column.add_child(_buttons)

## Show the result. `buttons` is a list of [action name, button text].
func show_result(title: String, detail: String, buttons: Array) -> void:
	_title.text = title
	_detail.text = detail
	_detail.visible = detail != ""
	set_note("")
	for child in _buttons.get_children():
		_buttons.remove_child(child)
		child.queue_free()
	for entry: Array in buttons:
		var button := Button.new()
		button.name = entry[0]
		button.text = entry[1]
		button.custom_minimum_size.y = 84
		button.pressed.connect(func() -> void: chosen.emit(entry[0]))
		_buttons.add_child(button)
	show()

## A message under the result (e.g. about a rematch); "" hides it.
func set_note(text: String) -> void:
	_note.text = text
	_note.visible = text != ""

## The button for `action`, or null (for changing its text, or tests).
func button(action: String) -> Button:
	return _buttons.get_node_or_null(action)

func title_text() -> String:
	return _title.text

func detail_text() -> String:
	return _detail.text

func note_text() -> String:
	return _note.text

func _label(font_size: int) -> Label:
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	return label
