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
	if def.is_king_type():
		return 1
	if def.is_pawn_type():
		return -1
	if def.is_royal_type():
		return mini(rules.army_max_extra_royals, rules.army_max_copies)
	return rules.army_max_copies

## The back-row files the king may start on: the middle two (d and e on 8 files),
## or the single middle file on an odd-width board.
static func king_files(board_width: int) -> Array[int]:
	if board_width % 2 == 1:
		return [board_width / 2]
	return [board_width / 2 - 1, board_width / 2]

## Everything wrong with the army, in plain words. Empty means it's legal.
func problems(rules: GameRules, board_width: int) -> PackedStringArray:
	var found: PackedStringArray = []
	if cost() > rules.army_budget:
		found.append("Costs %s points; the budget is %s." % [_points(cost()), _points(rules.army_budget)])

	var kings := pieces.filter(func(p: ArmyPiece) -> bool: return p.def.is_king_type())
	if kings.is_empty():
		found.append("Needs a king.")
	for king in kings:
		if king.square.y != 0 or not king_files(board_width).has(king.square.x):
			found.append("The king must start in the middle of the back row.")

	var extra_royals := pieces.filter(func(p: ArmyPiece) -> bool:
			return p.def.is_royal_type() and not p.def.is_king_type()).size()
	if extra_royals > rules.army_max_extra_royals:
		found.append("Too many royal pieces: %d besides the king (the most is %d)." % [extra_royals, rules.army_max_extra_royals])

	var checked := {}
	for piece in pieces:
		if checked.has(piece.def):
			continue
		checked[piece.def] = true
		var limit := max_copies(piece.def, rules)
		var count := count_of(piece.def)
		# Extra royal pieces are already reported above, as a group.
		var royal_only := piece.def.is_royal_type() and not piece.def.is_king_type()
		if limit >= 0 and count > limit and not royal_only:
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
