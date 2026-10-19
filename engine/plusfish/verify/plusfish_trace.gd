extends SceneTree

## Plays random games with the game's own rules engine and writes, for every
## position, the FEN, every legal move and the outcome, so Plusfish can check it
## generates exactly the same. Copied into the game's tools/ folder to run:
##   godot --headless --path <ChessPlus> -s res://tools/plusfish_trace.gd -- <games.txt> <out.jsonl>
## games.txt: one game per line: "<white>|<black>|<seed>|<max plies>", where an
## army is "piece_id@file,row;piece_id@file,row;..." (rows from the owner's side).

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var input := FileAccess.open(args[0], FileAccess.READ)
	var output := FileAccess.open(args[1], FileAccess.WRITE)
	var game_index := 0
	while not input.eof_reached():
		var line := input.get_line().strip_edges()
		if line.is_empty():
			continue
		var parts := line.split("|")
		var state := ArmySetup.create_game(_army(parts[0]), _army(parts[1]), StandardSetup.create_rules())
		var rng := RandomNumberGenerator.new()
		rng.seed = parts[2].to_int()
		var max_plies := parts[3].to_int()
		for ply in range(max_plies + 1):
			var moves := state.moves()
			var texts := []
			for move in moves:
				texts.append(move.to_text())
			texts.sort()
			var outcome := state.outcome()
			var record := {"g": game_index, "ply": ply, "fen": Fen.write(state), "moves": texts,
					"outcome": outcome, "check": state.is_in_check()}
			var chosen: Move = null
			if outcome == GameState.Outcome.NONE and ply < max_plies:
				chosen = _pick(moves, rng)
				record["played"] = chosen.to_text()
			output.store_line(JSON.stringify(record))
			if chosen == null:
				break
			state.make_move(chosen)
		game_index += 1
	output.close()
	quit()

## Random, but leaning towards the interesting moves (captures, shield breaks,
## abilities, promotions, castling) so the odd rules get exercised.
func _pick(moves: Array[Move], rng: RandomNumberGenerator) -> Move:
	var special: Array[Move] = []
	for move in moves:
		if move.is_capture() or move.ability != PieceDef.Ability.NONE or move.promotion or move.is_castling():
			special.append(move)
	if not special.is_empty() and rng.randf() < 0.45:
		return special[rng.randi_range(0, special.size() - 1)]
	return moves[rng.randi_range(0, moves.size() - 1)]

func _army(text: String) -> Army:
	var army := Army.new()
	for item in text.split(";", false):
		var bits := item.split("@")
		var square := bits[1].split(",")
		army.place(load("res://data/pieces/%s.tres" % bits[0]), Vector2i(square[0].to_int(), square[1].to_int()))
	return army
