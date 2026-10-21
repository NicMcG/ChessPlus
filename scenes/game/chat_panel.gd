class_name ChatPanel
extends ColorRect

## The chat window in an online game: the messages so far ("You: ..." /
## "Opponent: ..."), a box to type in, Send and Close. It doesn't talk to the
## server itself: it emits `send_requested` and the game screen sends it.

signal send_requested(text: String)

var _messages: VBoxContainer
var _scroll: ScrollContainer
var _input: LineEdit
var _send: Button
## Web version: the messages are shown by the browser in this page element
## (laid over the message area), so emoji and every alphabet display properly.
var _web_list := ""
var _web_rect := Rect2()
var _web_shown := false

func _init() -> void:
	color = UiStyle.SCRIM
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 15
	hide()
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 40)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.dialog_box(20))
	margin.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var top := HBoxContainer.new()
	var heading := Label.new()
	heading.text = "Chat"
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.theme_type_variation = &"DialogTitle"
	top.add_child(heading)
	var close := Button.new()
	close.text = "Close"
	close.theme_type_variation = &"GhostButton"
	close.custom_minimum_size = Vector2(140, 70)
	close.pressed.connect(hide)
	top.add_child(close)
	column.add_child(top)
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_scroll)
	_messages = VBoxContainer.new()
	_messages.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_messages.add_theme_constant_override("separation", 8)
	_scroll.add_child(_messages)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	_input = LineEdit.new()
	_input.placeholder_text = "Type a message"
	_input.max_length = 200
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.custom_minimum_size.y = 80
	_input.text_submitted.connect(func(_text: String) -> void: _send_typed())
	row.add_child(_input)
	_send = Button.new()
	_send.text = "Send"
	_send.custom_minimum_size = Vector2(150, 80)
	_send.pressed.connect(_send_typed)
	row.add_child(_send)
	column.add_child(row)

func _ready() -> void:
	PhoneTextInput.attach(_input, "Message")
	if WebOverlay.available():
		_web_list = WebOverlay.create_list()

func _process(_delta: float) -> void:
	if _web_list == "":
		return
	var show := _scroll.is_visible_in_tree()
	var rect := WebOverlay.canvas_rect(_scroll)
	if show != _web_shown or rect != _web_rect:
		_web_shown = show
		_web_rect = rect
		WebOverlay.place(_web_list, rect, 28 * WebOverlay.canvas_scale(_scroll), show, 12)

func _exit_tree() -> void:
	if _web_list != "":
		WebOverlay.remove(_web_list)
		_web_list = ""

## Show `messages` (from OnlineSession.chat()); `my_side` is "white"/"black".
func show_messages(messages: Array, my_side: String) -> void:
	for child in _messages.get_children():
		_messages.remove_child(child)
		child.queue_free()
	if _web_list != "":
		_show_in_browser(messages, my_side)
		return
	if messages.is_empty():
		_messages.add_child(_message_label("No messages yet. Say hello!", UiStyle.TEXT_MUTED))
	for message: Dictionary in messages:
		var mine: bool = message.get("from", "") == my_side
		var who := "You" if mine else "Opponent"
		_messages.add_child(_message_label("%s: %s" % [who, message.get("text", "")],
				UiStyle.ACCENT_TEXT if mine else UiStyle.TEXT))
	_scroll_to_end.call_deferred()

func _show_in_browser(messages: Array, my_side: String) -> void:
	var items := []
	if messages.is_empty():
		items.append({"text": "No messages yet. Say hello!", "color": "#999999"})
	for message: Dictionary in messages:
		var mine: bool = message.get("from", "") == my_side
		items.append({"text": "%s: %s" % ["You" if mine else "Opponent", message.get("text", "")],
				"color": "#FFD75E" if mine else "#FFFFFF"})
	WebOverlay.set_items(_web_list, items)

## The message being typed (for tests).
func typed_text() -> String:
	return _input.text

func set_typed_text(text: String) -> void:
	_input.text = text

func _send_typed() -> void:
	var text := _input.text.strip_edges()
	if text == "":
		return
	_input.text = ""
	send_requested.emit(text)

func _message_label(text: String, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", color)
	return label

func _scroll_to_end() -> void:
	if is_inside_tree():
		_scroll.scroll_vertical = int(_scroll.get_v_scroll_bar().max_value)
