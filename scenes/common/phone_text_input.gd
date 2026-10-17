class_name PhoneTextInput
extends RefCounted

## Makes a LineEdit usable in a phone's web browser. In a browser, the phone's
## keyboard only opens for the page's own text boxes, not for ones Godot draws.
## So when the game runs in a phone browser, tapping the LineEdit opens the
## browser's own "enter text" box (which always brings up the keyboard) and puts
## the answer into the LineEdit. Everywhere else, nothing changes.

## Call once for each LineEdit, e.g. PhoneTextInput.attach(name_edit, "Army name").
static func attach(edit: LineEdit, title: String) -> void:
	if not in_phone_browser():
		return
	edit.gui_input.connect(func(event: InputEvent) -> void:
		var press := event as InputEventMouseButton
		if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
			# Stop the LineEdit handling the tap itself, then ask the browser.
			edit.accept_event()
			edit.release_focus()
			_ask_browser(edit, title))

static func in_phone_browser() -> bool:
	return OS.has_feature("web_ios") or OS.has_feature("web_android")

static func _ask_browser(edit: LineEdit, title: String) -> void:
	var code := "prompt(%s, %s)" % [JSON.stringify(title), JSON.stringify(edit.text)]
	var answer: Variant = JavaScriptBridge.eval(code)
	if answer == null:
		return  # The player tapped Cancel.
	var text := str(answer)
	if edit.max_length > 0:
		text = text.left(edit.max_length)
	edit.text = text
	# Let listeners (like the army builder) know, as if it had been typed.
	edit.text_changed.emit(text)
