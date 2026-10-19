class_name KingFrame
extends Control

## The decorative border round the king's box in the army builder's tray (Mac's
## design): the king is the only piece with a border, a fairly thick band with
## swirls along it. Viewing White pieces it's white with black swirls; viewing
## Black, black with white swirls. Drawn over the button, ignoring the mouse.

var team := Piece.Team.WHITE:
	set(value):
		team = value
		queue_redraw()

## The band's thickness as a share of the box's width.
const BAND := 0.1

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _draw() -> void:
	var band := maxf(6.0, size.x * BAND)
	var base := Color.WHITE if team == Piece.Team.WHITE else Color.BLACK
	var ink := Color.BLACK if team == Piece.Team.WHITE else Color.WHITE
	var outer := Rect2(Vector2.ZERO, size)
	var inner := outer.grow(-band)
	# The band: the outer rectangle with the inner one left out, as four strips.
	draw_rect(Rect2(outer.position, Vector2(outer.size.x, band)), base)
	draw_rect(Rect2(Vector2(0, outer.end.y - band), Vector2(outer.size.x, band)), base)
	draw_rect(Rect2(Vector2(0, band), Vector2(band, outer.size.y - band * 2)), base)
	draw_rect(Rect2(Vector2(outer.end.x - band, band), Vector2(band, outer.size.y - band * 2)), base)
	# Thin edges either side of the band.
	draw_rect(outer.grow(-0.75), ink, false, 1.5)
	draw_rect(inner.grow(0.75), ink, false, 1.5)
	# Swirls: little spirals along the band, alternating which way they turn,
	# with a curl in each corner.
	var r := band * 0.32
	var mid := band / 2
	for corner: Vector2 in [Vector2(mid, mid), Vector2(size.x - mid, mid), Vector2(mid, size.y - mid), Vector2(size.x - mid, size.y - mid)]:
		_draw_spiral(corner, r * 1.05, 1.0, ink)
	_swirls_along(Vector2(band, mid), Vector2(size.x - band, mid), r, ink)
	_swirls_along(Vector2(band, size.y - mid), Vector2(size.x - band, size.y - mid), r, ink)
	_swirls_along(Vector2(mid, band), Vector2(mid, size.y - band), r, ink)
	_swirls_along(Vector2(size.x - mid, band), Vector2(size.x - mid, size.y - band), r, ink)

## Spirals spaced evenly between `from` and `to`, turning alternately.
func _swirls_along(from: Vector2, to: Vector2, r: float, ink: Color) -> void:
	var count := maxi(1, int(from.distance_to(to) / (r * 4.2)))
	for i in count:
		var at := from.lerp(to, (i + 0.5) / count)
		_draw_spiral(at, r, 1.0 if i % 2 == 0 else -1.0, ink)

## A small spiral (about one and a half turns) centred on `at`.
func _draw_spiral(at: Vector2, r: float, turn: float, ink: Color) -> void:
	var points := PackedVector2Array()
	var steps := 18
	for i in steps + 1:
		var t := float(i) / steps
		var angle := turn * t * TAU * 1.5
		points.append(at + Vector2.from_angle(angle) * r * (0.15 + 0.85 * t))
	draw_polyline(points, ink, maxf(1.0, r * 0.28), true)
