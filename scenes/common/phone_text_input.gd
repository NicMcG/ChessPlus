class_name PhoneTextInput
extends RefCounted

## Makes a LineEdit work properly in the web version. A phone browser only opens
## its keyboard for the page's own text boxes, not for ones the game draws, and
## the game's font has no emoji or other alphabets. So in a browser, a real web
## text box is laid exactly over the LineEdit (see WebTextField) and the text is
## kept in step. Everywhere else, nothing changes.

## Call once for each LineEdit, e.g. PhoneTextInput.attach(name_edit, "Army name").
## (`title` is kept for the callers; the box shows the LineEdit's placeholder.)
static func attach(edit: LineEdit, _title: String) -> void:
	if not in_browser():
		return
	edit.add_child(WebTextField.new())

static func in_browser() -> bool:
	return WebOverlay.available()

static func in_phone_browser() -> bool:
	return OS.has_feature("web_ios") or OS.has_feature("web_android")
