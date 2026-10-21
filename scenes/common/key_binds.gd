class_name KeyBinds
extends RefCounted

## Keyboard shortcuts for the game screen (Mac's Settings, Oct 2026; PC and
## desktop browsers). Each action has a default key, which the player can
## change in Settings; changes are saved in UserSettings (the "keys" section).
## install() puts them into Godot's InputMap as "chessplus_<action>".
## A key is stored as one number: the key plus its Ctrl/Shift/Alt flags
## (InputEventKey.get_keycode_with_modifiers()).

## In the order Settings lists them: action -> [what it's called, default key].
const ACTIONS := {
	"step_back": ["Back a move", KEY_LEFT],
	"step_forward": ["Forward a move", KEY_RIGHT],
	"step_start": ["First move", KEY_HOME],
	"step_end": ["Back to the game", KEY_END],
	"undo": ["Undo", KEY_MASK_CTRL | KEY_Z],
	"redo": ["Redo", KEY_MASK_CTRL | KEY_Y],
	"flip_board": ["Flip the board", KEY_F],
	"use_ability": ["Use ability", KEY_SPACE],
	"cancel": ["Cancel selection", KEY_ESCAPE],
	"piece_card": ["Piece card", KEY_I],
}

## The InputMap action for `action`.
static func input_action(action: String) -> String:
	return "chessplus_" + action

## The key `action` is on now.
static func key(action: String) -> int:
	return UserSettings.key_bind(action, ACTIONS[action][1])

## Put `action` on `code`. If another action already uses that key, the two
## swap, so no key ever does two things.
static func set_key(action: String, code: int) -> void:
	var old := key(action)
	for other: String in ACTIONS:
		if other != action and key(other) == code:
			UserSettings.set_key_bind(other, old)
	UserSettings.set_key_bind(action, code)
	install()

## Make the InputMap match the saved keys (at start-up, and after a change).
static func install() -> void:
	for action: String in ACTIONS:
		var name := input_action(action)
		if not InputMap.has_action(name):
			InputMap.add_action(name)
		InputMap.action_erase_events(name)
		var code := key(action)
		var event := InputEventKey.new()
		event.keycode = code & KEY_CODE_MASK
		event.ctrl_pressed = code & KEY_MASK_CTRL != 0
		event.shift_pressed = code & KEY_MASK_SHIFT != 0
		event.alt_pressed = code & KEY_MASK_ALT != 0
		InputMap.action_add_event(name, event)

## The action a key press belongs to, or "" for none.
static func action_for(event: InputEventKey) -> String:
	for action: String in ACTIONS:
		if InputMap.has_action(input_action(action)) and event.is_action_pressed(input_action(action), true, true):
			return action
	return ""

## How a key is written, e.g. "Ctrl+Z", "Left", "Space".
static func text(code: int) -> String:
	return OS.get_keycode_string(code)

## True on a computer (a keyboard is likely); false on phones and tablets.
static func has_keyboard() -> bool:
	return not (OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"))
