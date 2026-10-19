class_name KingFrame
extends Control

## The border round the king's box in the army builder's tray (Mac's design):
## the king is the only piece with one. White when viewing White pieces, black
## when viewing Black. Drawn over the button, ignoring the mouse.

var team := Piece.Team.WHITE:
	set(value):
		team = value
		queue_redraw()

## The border's thickness as a share of the box's width.
const BAND := 0.06

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var band := maxf(4.0, size.x * BAND)
	var color := Color.WHITE if team == Piece.Team.WHITE else Color.BLACK
	draw_rect(Rect2(Vector2.ONE * band / 2, size - Vector2.ONE * band), color, false, band)
