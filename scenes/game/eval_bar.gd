class_name EvalBar
extends Control

## A chess-style evaluation bar beside the board: the white part grows from
## White's end as White's position gets better, with the score printed at the
## winning side's end ("+1.3", "M3" = mate in 3). Shown when looking over a
## finished game; the numbers come from Plusfish (PlusfishLink).

const WHITE_SIDE := Color("#f0f0ec")
const BLACK_SIDE := Color("#3a3a38")
const UNKNOWN := Color("#6b6b67")
## How quickly the bar slides to a new score (fraction of the gap per second).
const SPEED := 8.0

## Black's side at the bottom, like BoardView.flipped.
var flipped := false:
	set(value):
		flipped = value
		queue_redraw()

## The score shown: White's point of view, in hundredths of a point.
var cp := 0
## Moves to mate (+ White mates, - Black mates), or null.
var mate: Variant = null
## False until the position has been evaluated (the bar shows grey "...").
var known := false
## The game is over in this position: "1-0", "0-1", "1/2-1/2", or "".
var result := ""

## The white part's share of the bar as drawn (it slides towards target).
var shown := 0.5

func set_score(p_cp: int, p_mate: Variant, p_result := "") -> void:
	cp = p_cp
	mate = p_mate
	result = p_result
	known = true
	queue_redraw()

func set_unknown() -> void:
	known = false
	queue_redraw()

## White's share of the bar for the current score: 50% when level, most of it
## at +4, all of it for a mate.
func target() -> float:
	if not known:
		return 0.5
	if result == "1-0":
		return 1.0
	if result == "0-1":
		return 0.0
	if mate != null:
		return 1.0 if int(mate) > 0 or (int(mate) == 0 and cp > 0) else 0.0
	return clampf(1.0 / (1.0 + exp(-0.0045 * cp)), 0.04, 0.96)

## The score as text: "+1.30", "-0.40", "0.00", "M3", "1-0".
func score_text() -> String:
	if not known:
		return "..."
	if result != "":
		return "½" if result == "1/2-1/2" else result
	if mate != null:
		return "M%d" % absi(int(mate)) if int(mate) != 0 else "#"
	if absi(cp) < 5:
		return "0.0"
	return "%+.1f" % (cp / 100.0)

func _process(delta: float) -> void:
	var goal := target()
	if absf(shown - goal) > 0.001:
		shown = lerpf(shown, goal, minf(1.0, delta * SPEED))
		queue_redraw()

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if not known:
		draw_rect(r, UNKNOWN)
	else:
		draw_rect(r, BLACK_SIDE)
		var white_h := size.y * shown
		# White's end is the bottom, or the top when the board is turned round.
		var white_rect := Rect2(0, size.y - white_h, size.x, white_h) if not flipped else Rect2(0, 0, size.x, white_h)
		draw_rect(white_rect, WHITE_SIDE)
	var text := score_text()
	var font := get_theme_default_font()
	# As big as fits across the bar (long scores like "+10.5" get smaller).
	var font_size := clampi(int(size.x * 0.55), 12, 30)
	var text_w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	while text_w > size.x - 2 and font_size > 9:
		font_size -= 1
		text_w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	# Printed at the end of whoever is ahead, in that side's opposite colour.
	var white_ahead := target() >= 0.5
	var at_bottom := white_ahead != flipped
	var y := size.y - font_size * 0.45 if at_bottom else font_size * 1.15
	var color := BLACK_SIDE if white_ahead else WHITE_SIDE
	if not known:
		color = WHITE_SIDE
		y = size.y / 2 + font_size * 0.35
	draw_string(font, Vector2((size.x - text_w) / 2, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
