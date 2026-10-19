class_name GradientStyleBox
extends StyleBox

## A rounded box filled with a left-to-right gradient between two colours. Used
## for special abilities (the name on the piece card, the button in a game),
## each piece with its own colours (PieceDef.ability_colors).

## [left colour, right colour].
var colors := PackedColorArray([Color("#555555"), Color("#999999")])
var corner_radius := 8.0
## Dark specks like the moon's craters scattered over it (PieceDef.ability_craters).
var craters := false

## Where the craters go: [across, down] as fractions of the box, and the size as
## a fraction of its height.
## They keep to the edges, clear of the writing in the middle.
const CRATERS := [
	[0.04, 0.5, 0.12], [0.13, 0.16, 0.07], [0.22, 0.86, 0.08], [0.33, 0.14, 0.06],
	[0.45, 0.87, 0.07], [0.56, 0.13, 0.07], [0.68, 0.86, 0.06], [0.79, 0.15, 0.08],
	[0.88, 0.85, 0.07], [0.96, 0.45, 0.11],
]

func _init(p_colors := PackedColorArray(), p_radius := 8.0, margin_x := 14.0, margin_y := 4.0) -> void:
	if p_colors.size() >= 2:
		colors = p_colors
	corner_radius = p_radius
	content_margin_left = margin_x
	content_margin_right = margin_x
	content_margin_top = margin_y
	content_margin_bottom = margin_y

## The same box made lighter (amount > 0) or darker (< 0), e.g. for a pressed button.
func shaded(amount: float) -> GradientStyleBox:
	var shades := PackedColorArray()
	for color in colors:
		shades.append(color.lightened(amount) if amount > 0 else color.darkened(-amount))
	var box := GradientStyleBox.new(shades, corner_radius, content_margin_left, content_margin_top)
	box.craters = craters
	return box

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var points := _rounded_rect(rect, minf(corner_radius, minf(rect.size.x, rect.size.y) / 2))
	var point_colors := PackedColorArray()
	for point in points:
		var t := (point.x - rect.position.x) / maxf(rect.size.x, 1.0)
		point_colors.append(colors[0].lerp(colors[1], clampf(t, 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(to_canvas_item, points, point_colors)
	if craters:
		for crater: Array in CRATERS:
			var center := rect.position + Vector2(rect.size.x * crater[0], rect.size.y * crater[1])
			var radius: float = rect.size.y * crater[2]
			var under := colors[0].lerp(colors[1], crater[0])
			# A shadowed pit with a lighter rim on its lower side.
			RenderingServer.canvas_item_add_circle(to_canvas_item, center + Vector2(0, radius * 0.18), radius, under.lightened(0.35))
			RenderingServer.canvas_item_add_circle(to_canvas_item, center, radius, under.darkened(0.45))

## The outline of a rectangle with rounded corners, as points.
static func _rounded_rect(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var corners := [
		[Vector2(rect.end.x - radius, rect.position.y + radius), -PI / 2],
		[Vector2(rect.end.x - radius, rect.end.y - radius), 0.0],
		[Vector2(rect.position.x + radius, rect.end.y - radius), PI / 2],
		[Vector2(rect.position.x + radius, rect.position.y + radius), PI],
	]
	for corner: Array in corners:
		for i in 7:
			var angle: float = corner[1] + (PI / 2) * i / 6.0
			points.append(corner[0] + Vector2(cos(angle), sin(angle)) * radius)
	return points
