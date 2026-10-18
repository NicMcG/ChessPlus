extends TestSuite

## The balancing tool's random armies (tools/balance/).

func test_random_armies_are_legal() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var rules := StandardSetup.create_rules()
	var defs := PieceCatalog.all_defs()
	var low := 100.0
	var high := 0.0
	for i in 200:
		var army := BalanceArmies.random_army(rng, defs, rules)
		var found := army.problems(rules, 8)
		# A random army has no name; that's the only thing allowed to be "wrong".
		var real := Array(found).filter(func(p: String) -> bool: return not p.contains("name"))
		check(real.is_empty(), "Legal army: %s" % ", ".join(real))
		low = minf(low, army.cost())
		high = maxf(high, army.cost())
	check(low < 33 and high > 37, "Budgets vary (%.1f to %.1f)" % [low, high])

func test_counts_text() -> void:
	var army := StandardSetup.army()
	check_eq(BalanceArmies.counts_text(army), "bishop:2;knight:2;pawn:8;queen:1;rook:2", "Piece counts")

func test_random_armies_shelter_the_king() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var rules := StandardSetup.create_rules()
	for i in 50:
		var army := BalanceArmies.random_army(rng, PieceCatalog.all_defs(), rules)
		var king: Vector2i
		for piece in army.pieces:
			if piece.def.is_king_type():
				king = piece.square
		if army.pieces.size() >= 4:
			check(army.def_at(Vector2i(king.x, 1)) != null, "Something in front of the king")
