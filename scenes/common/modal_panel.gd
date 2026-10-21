class_name ModalPanel
extends ColorRect

## A simple pop-up: the screen dims and a rounded panel with a heading appears
## in the middle; whatever is added to `column` goes inside it. Taps outside it
## do nothing (close it with a button that calls close()).

signal closed

var column: VBoxContainer
var heading: Label

func _init(title: String) -> void:
	color = UiStyle.SCRIM
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 520
	center.add_child(panel)
	column = VBoxContainer.new()
	column.add_theme_constant_override("separation", 14)
	panel.add_child(column)
	heading = Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.theme_type_variation = &"DialogTitle"
	column.add_child(heading)

## A label for messages, wrapped to the panel's width.
func add_text(text: String, font_size := 26) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.custom_minimum_size.x = 470
	label.add_theme_font_size_override("font_size", font_size)
	column.add_child(label)
	return label

## `look` is a theme style for the button, e.g. &"AccentButton" for the main
## one, &"GhostButton" for Cancel (none = a plain button).
func add_button(text: String, on_pressed: Callable, look := &"") -> Button:
	var button := Button.new()
	button.text = text
	button.theme_type_variation = look
	button.custom_minimum_size.y = 80
	button.pressed.connect(on_pressed)
	column.add_child(button)
	return button

func close() -> void:
	closed.emit()
	queue_free()
