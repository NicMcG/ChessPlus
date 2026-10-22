class_name MouseBinds
extends RefCounted

## Which mouse button does what on the game board (Settings, PC and desktop
## browsers), like KeyBinds for the keyboard. Each action has a default button,
## which the player can change in Settings; changes are saved in UserSettings
## (the "mouse" section) as the button's number (MOUSE_BUTTON_LEFT, ...).
## A finger on a touch screen always selects and moves, whatever is set here.

## In the order Settings lists them: action -> [what it's called, default button].
const ACTIONS := {
	"move": ["Select and move pieces", MOUSE_BUTTON_LEFT],
	"mark": ["Mark squares and draw arrows", MOUSE_BUTTON_RIGHT],
	"piece_card": ["Piece card", MOUSE_BUTTON_MIDDLE],
}

## The buttons that can be chosen (not the scroll wheel), and how they're written.
const BUTTON_NAMES := {
	MOUSE_BUTTON_LEFT: "Left click",
	MOUSE_BUTTON_RIGHT: "Right click",
	MOUSE_BUTTON_MIDDLE: "Middle click",
	MOUSE_BUTTON_XBUTTON1: "Side button 1",
	MOUSE_BUTTON_XBUTTON2: "Side button 2",
}

## The button `action` is on now.
static func button(action: String) -> int:
	return UserSettings.mouse_bind(action, ACTIONS[action][1])

## Put `action` on mouse button `index`. If another action already uses that
## button, the two swap, so no button ever does two things.
static func set_button(action: String, index: int) -> void:
	var old := button(action)
	for other: String in ACTIONS:
		if other != action and button(other) == index:
			UserSettings.set_mouse_bind(other, old)
	UserSettings.set_mouse_bind(action, index)

## The action a press or release of mouse button `index` belongs to, or "" for
## none. Read from the saved settings each time (only on clicks; the file is tiny).
static func action_for(index: int) -> String:
	for action: String in ACTIONS:
		if button(action) == index:
			return action
	return ""

## True for a button Settings can put an action on.
static func can_use(index: int) -> bool:
	return BUTTON_NAMES.has(index)

## How a button is written, e.g. "Right click".
static func text(index: int) -> String:
	return BUTTON_NAMES.get(index, "Button %d" % index)

## Using a button on something, for tips: "middle-click" (... any piece), or
## "click side button 1 on" (... any piece).
static func verb(index: int) -> String:
	match index:
		MOUSE_BUTTON_LEFT:
			return "left-click"
		MOUSE_BUTTON_RIGHT:
			return "right-click"
		MOUSE_BUTTON_MIDDLE:
			return "middle-click"
	return "click %s on" % text(index).to_lower()
