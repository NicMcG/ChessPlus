class_name ModalPanel
extends ColorRect

## A simple pop-up: the screen dims and a rounded panel with a heading appears
## in the middle; whatever is added to `column` goes inside it. Taps outside it
## do nothing (close it with a button that calls close()).

signal closed

var column: VBoxContainer
var heading: Label
## Paragraphs added with add_paragraphs (they scroll inside the panel).
var paragraphs: VBoxContainer
var _scroll: ScrollContainer
## Width of paragraph text on a wide screen (a phone keeps the usual 470).
const WIDE_TEXT_WIDTH := 760

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

## Several paragraphs that may be taller than the screen (e.g. the privacy
## notice): wider on wide screens, and scrolling inside the panel when they
## still don't fit, so the buttons below always show.
func add_paragraphs(lines: Array, font_size := 24) -> VBoxContainer:
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	paragraphs = VBoxContainer.new()
	paragraphs.add_theme_constant_override("separation", 14)
	paragraphs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(paragraphs)
	column.add_child(_scroll)
	for line: String in lines:
		var label := add_text(line, font_size)
		label.reparent(paragraphs)
	resized.connect(_fit_paragraphs)
	_fit_paragraphs.call_deferred()
	return paragraphs

func _fit_paragraphs() -> void:
	if not is_inside_tree():
		return
	var width := WIDE_TEXT_WIDTH if ScreenShape.is_wide(size) else 470
	for label: Control in paragraphs.get_children():
		label.custom_minimum_size.x = width
	# Let the labels wrap at the new width, then give the text all the height
	# the screen has left after the heading, the buttons and the margins.
	_scroll.custom_minimum_size.y = 0
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var others := 0.0
	for child: Control in column.get_children():
		if child != _scroll:
			others += child.get_combined_minimum_size().y + column.get_theme_constant("separation")
	var room := size.y - others - 120
	_scroll.custom_minimum_size.y = maxf(120, minf(paragraphs.get_combined_minimum_size().y, room))

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
