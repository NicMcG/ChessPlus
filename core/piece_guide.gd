class_name PieceGuide
extends RefCounted

## Works out how a piece moves, from its move rules, for the picture on the piece
## card: the squares it can reach, and the directions it can slide along.

## Bit flags describing one square (or one slide direction).
const MOVE := 1         ## It can move here.
const CAPTURE := 2      ## It can capture an enemy here.
const FIRST_MOVE := 4   ## Only on the piece's first move (like a pawn's double step).
const JUMP := 8         ## It leaps here in one go, so it can't be blocked (like a knight).

## The smallest picture: 2 squares each side of the piece, a 5 x 5 board.
const MIN_RADIUS := 2

## Everything the picture needs:
##   "squares": offset -> flags, for squares it reaches in a fixed number of steps
##   "slides":  [direction, flags] pairs, for directions it moves any distance along
##   "radius":  squares to show each side of the piece (at least MIN_RADIUS, more if
##              a jump wouldn't fit)
## Offsets are (x = right, y = forward, toward the opponent), shown from White's side.
static func guide(def: PieceDef) -> Dictionary:
	var squares := {}
	var slides := []
	for rule in def.move_rules:
		var flags := 0
		if rule.mode != MoveRule.Mode.CAPTURE_ONLY:
			flags |= MOVE
		# A hopping capture can't be drawn on an empty board; the card explains it instead.
		if rule.mode != MoveRule.Mode.MOVE_ONLY and not rule.captures_by_hopping:
			flags |= CAPTURE
		if flags == 0:
			continue
		if rule.max_steps == 0:
			for dir in rule.directions:
				slides.append([dir, flags])
			continue
		var reach := maxi(rule.max_steps, rule.first_move_max_steps)
		for dir in rule.directions:
			var leap := rule.max_steps == 1 and maxi(absi(dir.x), absi(dir.y)) > 1
			for i in range(1, reach + 1):
				var square_flags := flags
				if i > rule.max_steps:
					square_flags |= FIRST_MOVE
				if leap:
					square_flags |= JUMP
				_add(squares, dir * i, square_flags)
	var radius := MIN_RADIUS
	for offset in squares:
		radius = maxi(radius, maxi(absi(offset.x), absi(offset.y)))
	return {"squares": squares, "slides": slides, "radius": radius}

## Combine flags from several rules. A square reachable on every move doesn't
## also need the "first move only" mark.
static func _add(squares: Dictionary, offset: Vector2i, flags: int) -> void:
	if not squares.has(offset):
		squares[offset] = flags
		return
	var old: int = squares[offset]
	var combined := old | flags
	if old & FIRST_MOVE == 0 or flags & FIRST_MOVE == 0:
		combined &= ~FIRST_MOVE
	squares[offset] = combined
