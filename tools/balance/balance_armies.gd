class_name BalanceArmies
extends RefCounted

## Random legal armies for the balancing tool (see balance_match.gd). Each one
## spends as much as it can of a budget (between MIN_BUDGET and the real budget,
## so the armies' totals differ and the extra points work as a measuring stick)
## on randomly chosen piece types, within the army rules, so that over many
## games every piece type turns up in many different company. The king goes on
## one of its allowed squares with the three squares in front of it filled first
## (as a player would shelter it), pawn types preferred there and then along the
## front row; everything else is placed at random on what's left.

const BOARD_WIDTH := 8
const MIN_BUDGET := 30.0

## A random legal army using `rng`.
static func random_army(rng: RandomNumberGenerator, defs: Array, rules: GameRules) -> Army:
	var army := Army.new()
	army.army_name = "Random"
	var king: PieceDef = null
	var buyable: Array[PieceDef] = []
	for def: PieceDef in defs:
		if def.is_king_type():
			king = def
		else:
			buyable.append(def)
	var king_files := Army.king_files(BOARD_WIDTH)
	var king_square := Vector2i(king_files[rng.randi_range(0, king_files.size() - 1)], 0)
	army.place(king, king_square)
	var free_squares := BOARD_WIDTH * rules.army_start_rows - 1
	var chosen: Array[PieceDef] = []
	var budget := rng.randf_range(MIN_BUDGET, rules.army_budget)
	while free_squares > 0:
		var options := buyable.filter(func(def: PieceDef) -> bool: return _can_add(army, chosen, def, rules, budget))
		if options.is_empty():
			break
		var def: PieceDef = options[rng.randi_range(0, options.size() - 1)]
		chosen.append(def)
		free_squares -= 1
	_place(army, chosen, king_square, rng, rules)
	return army

## Whether one more `def` keeps the army legal (budget, copy limits, royals).
static func _can_add(army: Army, chosen: Array[PieceDef], def: PieceDef, rules: GameRules, budget: float) -> bool:
	var cost := army.cost() + def.value
	for other in chosen:
		cost += other.value
	if cost > budget + 0.001:
		return false
	var limit := Army.max_copies(def, rules)
	if limit >= 0 and chosen.count(def) >= limit:
		return false
	if def.is_royal_type():
		var royals := chosen.filter(func(d: PieceDef) -> bool: return d.is_royal_type()).size()
		if royals >= rules.army_max_extra_royals:
			return false
	return true

static func _place(army: Army, chosen: Array[PieceDef], king_square: Vector2i, rng: RandomNumberGenerator, rules: GameRules) -> void:
	var front: Array[Vector2i] = []
	var back: Array[Vector2i] = []
	for file in BOARD_WIDTH:
		front.append(Vector2i(file, 1))
		if Vector2i(file, 0) != king_square:
			back.append(Vector2i(file, 0))
	_shuffle(front, rng)
	_shuffle(back, rng)
	# The three squares in front of the king are taken first (popped last = first).
	for file in [king_square.x - 1, king_square.x + 1, king_square.x]:
		var shelter := Vector2i(file, 1)
		if shelter in front:
			front.erase(shelter)
			front.append(shelter)
	var pawns := chosen.filter(func(d: PieceDef) -> bool: return d.is_pawn_type())
	var others := chosen.filter(func(d: PieceDef) -> bool: return not d.is_pawn_type())
	_shuffle(others, rng)
	# Pawn types along the front row, starting in front of the king.
	for def: PieceDef in pawns:
		army.place(def, front.pop_back() if not front.is_empty() else back.pop_back())
	# Then other pieces finish sheltering the king, and the rest go anywhere.
	while not others.is_empty() and not front.is_empty() and absi(front.back().x - king_square.x) <= 1:
		army.place(others.pop_back(), front.pop_back())
	var rest: Array[Vector2i] = back + front
	_shuffle(rest, rng)
	for def: PieceDef in others:
		army.place(def, rest.pop_back())

static func _shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap

## "pawn:6;knight:2;..." — how many of each piece type (the king left out).
static func counts_text(army: Army) -> String:
	var counts := {}
	for piece in army.pieces:
		if not piece.def.is_king_type():
			counts[piece.def.id] = counts.get(piece.def.id, 0) + 1
	var parts := PackedStringArray()
	var ids := counts.keys()
	ids.sort()
	for id: String in ids:
		parts.append("%s:%d" % [id, counts[id]])
	return ";".join(parts)
