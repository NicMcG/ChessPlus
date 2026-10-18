class_name GradientStyleBox
extends StyleBox

## A rounded box filled with a left-to-right gradient between two colours. Used
## for special abilities (the name on the piece card, the button in a game),
## each piece with its own colours (PieceDef.ability_colors).

## [left colour, right colour].
var colors := PackedColorArray([Color("#555555"), Color("#999999")])
var corner_radius := 8.0

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
	return GradientStyleBox.new(shades, corner_radius, content_margin_left, content_margin_top)

func _draw(to_canvas_item: RID, rect: Rect2) -> void:
	var points := _rounded_rect(rect, minf(corner_radius, minf(rect.size.x, rect.size.y) / 2))
	var point_colors := PackedColorArray()
	for point in points:
		var t := (point.x - rect.position.x) / maxf(rect.size.x, 1.0)
		point_colors.append(colors[0].lerp(colors[1], clampf(t, 0.0, 1.0)))
	RenderingServer.canvas_item_add_polygon(to_canvas_item, points, point_colors)

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
