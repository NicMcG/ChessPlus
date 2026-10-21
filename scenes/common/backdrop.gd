class_name Backdrop
extends ColorRect

## The background behind a screen: the app's dark grey (UiStyle.BACKGROUND),
## a touch lighter at the top and darker at the bottom, so screens have a bit
## of depth instead of looking flat.

## The main menu also shows a faint chessboard across the top, fading out.
@export var checkers := false

## How many squares across, and how far down the checkers fade out (a share of
## the height).
const CHECKER_COLUMNS := 8
const CHECKER_DEPTH := 0.55
const CHECKER_ALPHA := 0.035

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
	resized.connect(queue_redraw)

func _draw() -> void:
	draw_texture_rect(_fade, Rect2(Vector2.ZERO, size), false)
	if checkers:
		_draw_checkers()

## Light squares only, each row fainter than the one above.
func _draw_checkers() -> void:
	# Squares sized from the shorter side, so wide windows don't get huge ones.
	var square := minf(size.x, size.y * 0.6) / CHECKER_COLUMNS
	if square < 4:
		return
	var columns := ceili(size.x / square)
	var rows := ceili(size.y * CHECKER_DEPTH / square)
	var left := (size.x - columns * square) / 2
	for row in rows:
		var alpha := CHECKER_ALPHA * pow(1.0 - float(row) / rows, 1.6)
		for column in columns:
			if (row + column) % 2 == 0:
				draw_rect(Rect2(left + column * square, row * square, square, square), Color(1, 1, 1, alpha))
