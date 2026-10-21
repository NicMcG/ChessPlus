class_name Backdrop
extends ColorRect

## The background behind a screen: the app's dark grey (UiStyle.BACKGROUND),
## a touch lighter at the top and darker at the bottom, so screens have a bit
## of depth instead of looking flat.

var _fade: GradientTexture2D

func _ready() -> void:
	color = UiStyle.BACKGROUND
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gradient := Gradient.new()
	gradient.set_color(0, UiStyle.BACKGROUND_TOP)
	gradient.set_color(1, UiStyle.BACKGROUND_BOTTOM)
	gradient.add_point(0.45, UiStyle.BACKGROUND)
	_fade = GradientTexture2D.new()
	_fade.gradient = gradient
	_fade.width = 4
	_fade.height = 256
	_fade.fill_to = Vector2(0, 1)

func _draw() -> void:
	draw_texture_rect(_fade, Rect2(Vector2.ZERO, size), false)
