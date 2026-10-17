class_name PieceGuide
extends RefCounted

## Works out how a piece moves, from its move rules, for showing players: which
## squares around it (on an empty board) it can move to or capture on.

## Bit flags describing one square. A square can have several, e.g. MOVE + CAPTURE.
const MOVE := 1          ## It can move here.
const CAPTURE := 2       ## It can capture an enemy here.
const FIRST_MOVE := 4    ## Only on the piece's first move (like a pawn's double step).
const HOP_CAPTURE := 8   ## It can capture here by jumping over exactly one piece.

## Offset from the piece (x = right, y = forward, toward the opponent) -> flags,
## for every square within `radius` of the piece. Shown from White's side; for
## Black, flip the y.
static func pattern(def: PieceDef, radius := 4) -> Dictionary:
	var marks := {}
	for rule in def.move_rules:
		var steps := rule.max_steps if rule.max_steps > 0 else radius
		var reach := maxi(steps, rule.first_move_max_steps)
		for dir in rule.directions:
			for i in range(1, reach + 1):
				var offset: Vector2i = dir * i
				if absi(offset.x) > radius or absi(offset.y) > radius:
					break
				var flags := 0
				if rule.mode != MoveRule.Mode.CAPTURE_ONLY:
					flags |= MOVE
				if rule.mode != MoveRule.Mode.MOVE_ONLY:
					if rule.captures_by_hopping:
						# There has to be a piece in between to jump, so never next to it.
						if i >= 2:
							flags |= HOP_CAPTURE
					else:
						flags |= CAPTURE
				if i > steps:
					flags |= FIRST_MOVE
				if flags != 0:
					_add(marks, offset, flags)
	return marks

## Combine flags from several rules. A square reachable on every move doesn't
## also need the "first move only" mark.
static func _add(marks: Dictionary, offset: Vector2i, flags: int) -> void:
	if not marks.has(offset):
		marks[offset] = flags
		return
	var old: int = marks[offset]
	var combined := old | flags
	if old & FIRST_MOVE == 0 or flags & FIRST_MOVE == 0:
		combined &= ~FIRST_MOVE
	marks[offset] = combined
