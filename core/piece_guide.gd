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
##   "slides":  [direction, flags, first step] for directions it moves any distance
##              along (first step is 1, or more if it leaps the first squares)
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
		# A bent path: a mark where it lands (the squares on the way can block it).
		if not rule.path.is_empty():
			for steps: Array in rule.path_variants():
				_add(squares, MoveRule.path_offset(steps), flags)
			continue
		if rule.max_steps == 0:
			for dir in rule.directions:
				# A leaping slide: a jump mark on its first square, then the arrow.
				if rule.leap_steps > 0:
					_add(squares, dir * (rule.leap_steps + 1), flags | JUMP)
				slides.append([dir, flags, rule.leap_steps + 2 if rule.leap_steps > 0 else 1])
			continue
		var reach := maxi(rule.max_steps, rule.first_move_max_steps)
		for dir in rule.directions:
			# A hop that needs one of its own pieces to jump (the Rogue) isn't shown as a
			# jump: its special rule explains it.
			var leap := (rule.max_steps == 1 and maxi(absi(dir.x), absi(dir.y)) > 1) 					or (rule.leap_steps > 0 and rule.leap_over == MoveRule.LeapOver.ANYTHING)
			for i in range(1 + rule.leap_steps, reach + 1):
				var square_flags := flags
				if i > rule.max_steps:
					square_flags |= FIRST_MOVE
				if leap:
					square_flags |= JUMP
				_add(squares, dir * i, square_flags)
	var radius := MIN_RADIUS
	for offset in squares:
		radius = maxi(radius, maxi(absi(offset.x), absi(offset.y)))
	# A slide that starts after a jump needs room for its arrow past the jump mark.
	for slide in slides:
		radius = maxi(radius, slide[2])
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
