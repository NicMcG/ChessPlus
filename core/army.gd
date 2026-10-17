class_name Army
extends Resource

## A player's army: the pieces they bought and where each one starts.
## Saved and loaded like any Godot resource.

@export var army_name := ""
@export var pieces: Array[ArmyPiece] = []

## Put a piece on a square, replacing anything already there.
func place(def: PieceDef, square: Vector2i) -> void:
	remove_at(square)
	pieces.append(ArmyPiece.make(def, square))

func remove_at(square: Vector2i) -> void:
	for i in range(pieces.size() - 1, -1, -1):
		if pieces[i].square == square:
			pieces.remove_at(i)

## The piece type on a square, or null.
func def_at(square: Vector2i) -> PieceDef:
	for piece in pieces:
		if piece.square == square:
			return piece.def
	return null

## Total points spent.
func cost() -> float:
	var total := 0.0
	for piece in pieces:
		total += piece.def.value
	return total

## How many pieces of this type the army has.
func count_of(def: PieceDef) -> int:
	return pieces.filter(func(p: ArmyPiece) -> bool: return p.def == def).size()

## The most of this piece type an army may have (-1 means no limit).
static func max_copies(def: PieceDef, rules: GameRules) -> int:
	if def.is_royal:
		return 1
	if def.promotes:
		return -1
	return rules.army_max_copies

## Everything wrong with the army, in plain words. Empty means it's legal.
func problems(rules: GameRules, board_width: int) -> PackedStringArray:
	var found: PackedStringArray = []
	if cost() > rules.army_budget:
		found.append("Costs %s points; the budget is %s." % [_points(cost()), _points(rules.army_budget)])
	if not pieces.any(func(p: ArmyPiece) -> bool: return p.def.is_royal):
		found.append("Needs a king.")
	var checked := {}
	for piece in pieces:
		if checked.has(piece.def):
			continue
		checked[piece.def] = true
		var limit := max_copies(piece.def, rules)
		var count := count_of(piece.def)
		if limit >= 0 and count > limit:
			found.append("Too many %ss: %d (the most is %d)." % [piece.def.display_name.to_lower(), count, limit])
	var used := {}
	for piece in pieces:
		var s := piece.square
		if s.x < 0 or s.x >= board_width or s.y < 0 or s.y >= rules.army_start_rows:
			found.append("A %s is outside the starting rows." % piece.def.display_name.to_lower())
		elif used.has(s):
			found.append("Two pieces share a square.")
		used[s] = true
	return found

func is_valid(rules: GameRules, board_width: int) -> bool:
	return problems(rules, board_width).is_empty()

## 39.0 -> "39", 1.5 -> "1.5".
static func _points(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else str(value)
