class_name EvalGraph
extends Control

## The whole game's evaluation as a graph, shown after the game: left to right
## is the game from the start to the end, and the white part grows from White's
## end as White's position gets better (like the eval bar, on its side). The
## height is each side's winning chances (MoveQuality.white_chances), so a big
## jump in the line is a big change in who's winning. Mistakes and blunders
## get an orange or red dot. Tapping (or dragging along) the graph shows the
## position at that point of the game.

## The player tapped or dragged to the position after `ply` moves.
signal ply_chosen(ply: int)

const WHITE_SIDE := Color("#f0f0ec")
const BLACK_SIDE := Color("#3a3a38")
const MIDDLE_LINE := Color(0.5, 0.5, 0.5, 0.6)
## The position on the board: a gold line, the colour of a hovered move.
const CURRENT_LINE := Color("#FFD75E")
const DOT_RADIUS := 6.0

## Moves in the game (the graph runs from 0 to this).
var plies := 0
## White's chances in each position evaluated so far: ply -> -1..+1.
var chances := {}
## Marked moves: ply -> MoveQuality.Mark.
var marks := {}
## The position on the board (moves played), drawn as a line.
var current := -1
## Black's side at the bottom, like BoardView.flipped.
var flipped := false

var _last_chosen := -1

func _init() -> void:
	custom_minimum_size.y = 90
	mouse_filter = Control.MOUSE_FILTER_STOP

func show_game(p_plies: int, p_chances: Dictionary, p_marks: Dictionary, p_current: int, p_flipped: bool) -> void:
	plies = p_plies
	chances = p_chances
	marks = p_marks
	current = p_current
	flipped = p_flipped
	queue_redraw()

## Where the position after `ply` moves is across the graph (the ends are kept
## in a dot's width, so a mark on the first or last move shows whole).
func x_for(ply: int) -> float:
	var inner := maxf(1.0, size.x - DOT_RADIUS * 2.0)
	if plies <= 0:
		return size.x / 2.0
	return DOT_RADIUS + inner * float(ply) / plies

## The position nearest a point across the graph.
func ply_at(x: float) -> int:
	if plies <= 0:
		return 0
	var inner := maxf(1.0, size.x - DOT_RADIUS * 2.0)
	return clampi(roundi((x - DOT_RADIUS) / inner * plies), 0, plies)

## How far up the graph White's chances `c` reach (from White's end).
func y_for(c: float) -> float:
	var white_share := (clampf(c, -1.0, 1.0) + 1.0) / 2.0
	return white_share * size.y if flipped else size.y - white_share * size.y

func _gui_input(event: InputEvent) -> void:
	var press := event as InputEventMouseButton
	if press and press.button_index == MOUSE_BUTTON_LEFT:
		if press.pressed:
			_last_chosen = -1
			_choose(press.position.x)
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		_choose(motion.position.x)
		accept_event()

func _choose(x: float) -> void:
	var ply := ply_at(x)
	if ply == _last_chosen:
		return
	_last_chosen = ply
	ply_chosen.emit(ply)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BLACK_SIDE)
	var known: Array = chances.keys()
	known.sort()
	# White's part: from White's edge up to the line through every known position.
	if known.size() >= 2:
		var edge := 0.0 if flipped else size.y
		var shape := PackedVector2Array([Vector2(x_for(known[0]), edge)])
		for ply: int in known:
			shape.append(Vector2(x_for(ply), y_for(chances[ply])))
		shape.append(Vector2(x_for(known.back()), edge))
		draw_colored_polygon(shape, WHITE_SIDE)
	draw_line(Vector2(0, size.y / 2.0), Vector2(size.x, size.y / 2.0), MIDDLE_LINE, 1.0)
	if current >= 0 and current <= plies:
		draw_line(Vector2(x_for(current), 0), Vector2(x_for(current), size.y), CURRENT_LINE, 2.0)
	for ply: int in marks:
		if not chances.has(ply):
			continue
		var at := Vector2(x_for(ply), y_for(chances[ply]))
		draw_circle(at, DOT_RADIUS + 1.5, Color.BLACK)
		draw_circle(at, DOT_RADIUS, MoveQuality.color_of(marks[ply]))
