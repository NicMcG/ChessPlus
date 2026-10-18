class_name WebTextField
extends Node

## Added under a LineEdit in the web version (by PhoneTextInput.attach): keeps a
## real web-page text box exactly on top of it. The player taps and types in the
## real box (so the keyboard opens and any language or emoji works); the text
## is copied into the LineEdit as they type, and back if the game changes it.
## The LineEdit's own text is made invisible so only one copy shows.

var edit: LineEdit
var _id := ""
## What was last placed / sent, so the page is only told about changes.
var _placed := Rect2()
var _shown := false
var _text := ""

func _ready() -> void:
	edit = get_parent()
	_id = WebOverlay.create_input(_on_page_event)
	WebOverlay.set_attribute(_id, "placeholder", edit.placeholder_text)
	if edit.max_length > 0:
		WebOverlay.set_attribute(_id, "maxLength", edit.max_length)
	_text = edit.text
	WebOverlay.set_value(_id, _text)
	for color in ["font_color", "font_placeholder_color", "caret_color", "font_selected_color"]:
		edit.add_theme_color_override(color, Color(0, 0, 0, 0))
	edit.focus_mode = Control.FOCUS_NONE

func _process(_delta: float) -> void:
	var show := edit.is_visible_in_tree()
	var rect := WebOverlay.canvas_rect(edit)
	if show != _shown or rect != _placed:
		_shown = show
		_placed = rect
		var font_px := edit.get_theme_font_size("font_size") * WebOverlay.canvas_scale(edit)
		WebOverlay.place(_id, rect, font_px, show)
	# The game changed the text (e.g. cleared it after sending): show that.
	if edit.text != _text:
		_text = edit.text
		WebOverlay.set_value(_id, _text)

func _exit_tree() -> void:
	if _id != "":
		WebOverlay.remove(_id)
		_id = ""

func _on_page_event(kind: String, value: String) -> void:
	if not is_instance_valid(edit):
		return
	if edit.max_length > 0:
		value = value.left(edit.max_length)
	_text = value
	if kind == "input":
		edit.text = value
		edit.text_changed.emit(value)
		# A listener may change the text (e.g. to capitals); send it back.
		if edit.text != value:
			_text = edit.text
			WebOverlay.set_value(_id, _text)
	elif kind == "submit":
		edit.text = value
		edit.text_submitted.emit(value)
