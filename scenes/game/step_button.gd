class_name StepButton
extends Button

## A button showing an arrowhead pointing left (`step` = -1) or right (+1): the
## Back / Forward buttons for stepping through the moves while looking back.
## The arrow is drawn in code because the game's font has no arrow symbols.

## -1 = back a move, 1 = forward a move.
@export var step := 1

const ARROW_HEIGHT := 0.4

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE

func _draw() -> void:
	var color := get_theme_color("font_disabled_color" if disabled else "font_color")
	var h := size.y * ARROW_HEIGHT
	var w := h * 0.75
	var middle := size / 2
	var tip := middle + Vector2(w / 2 * step, 0)
	var back_x := middle.x - w / 2 * step
	draw_colored_polygon(PackedVector2Array([
		tip,
		Vector2(back_x, middle.y - h / 2),
		Vector2(back_x, middle.y + h / 2),
	]), color)
