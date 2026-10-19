class_name CostBadge
extends Control

## The small dark badge with a piece's cost in the army builder's tray. Drawn by
## hand rather than as a Label: a Label leaves room under the text for letters
## that hang below the line (g, y), which made the number sit high in its badge.
## Here the digits are centred on their own height.

var text := "":
	set(value):
		text = value
		_resize()
var font_size := 20:
	set(value):
		font_size = value
		_resize()

## The badge's colour (the army builder colours it by the piece's type).
var color := Color(0.08, 0.08, 0.09, 0.85):
	set(value):
		color = value
		queue_redraw()

const PAD_X := 6.0
const PAD_Y := 3.0

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

## Digits are about this share of the font size tall.
const DIGIT_HEIGHT := 0.72

func _resize() -> void:
	var font := get_theme_default_font()
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	custom_minimum_size = Vector2(width + PAD_X * 2, font_size * DIGIT_HEIGHT + PAD_Y * 2)
	size = custom_minimum_size
	queue_redraw()

func _draw() -> void:
	var badge := StyleBoxFlat.new()
	badge.bg_color = color
	badge.set_corner_radius_all(6)
	draw_style_box(badge, Rect2(Vector2.ZERO, size))
	var font := get_theme_default_font()
	var baseline := size.y / 2 + font_size * DIGIT_HEIGHT / 2
	draw_string(font, Vector2(PAD_X, baseline), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
