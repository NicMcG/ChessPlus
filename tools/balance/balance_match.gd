extends SceneTree

## The balancing tool's worker: plays bot-against-bot games between random
## legal armies (BalanceArmies) and writes one line per game to a results file,
## for analyse_balance.py to turn into an estimate of what each piece is really
## worth. Several of these run at once (run_balance.sh), each with its own seed.
##
## Run: "<godot console exe>" --headless --path . -s res://tools/balance/balance_match.gd -- \
##        --games 50 --seed 1 --out balance/results/run1_seed1.csv [--depth 2] [--time 400] [--values balance/values.json]
##
## Results lines: seed,game,white pieces,black pieces,result for White (1 / 0.5 / 0),half-moves,how it ended
## Games still going after MAX_PLIES half-moves are judged by the bot's
## evaluation: a lead of ADJUDICATE_MARGIN points or more wins, otherwise a draw.

const MAX_PLIES := 200
const ADJUDICATE_MARGIN := 3.0

func _initialize() -> void:
	var options := _options(OS.get_cmdline_user_args())
	var games := int(options.get("games", "10"))
	var seed := int(options.get("seed", "1"))
	var out_path: String = options.get("out", "balance/results/results_%d.csv" % seed)
	# A little randomness in the bots' choices, so games don't repeat or shuffle.
	var settings := {"depth": int(options.get("depth", "2")), "noise": int(options.get("noise", "12")), "time_ms": int(options.get("time", "400"))}
	if options.has("values"):
		var values: Variant = JSON.parse_string(FileAccess.get_file_as_string(options["values"]))
		if values is Dictionary:
			PracticeBot.value_overrides = values
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://").path_join(out_path.get_base_dir()))
	var file := FileAccess.open(ProjectSettings.globalize_path("res://").path_join(out_path), FileAccess.READ_WRITE if FileAccess.file_exists(out_path) else FileAccess.WRITE)
	file.seek_end()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var defs := PieceCatalog.all_defs()
	var rules := StandardSetup.create_rules()
	for game in games:
		var started := Time.get_ticks_msec()
		var white := BalanceArmies.random_army(rng, defs, rules)
		var black := BalanceArmies.random_army(rng, defs, rules)
		var result := play(white, black, rules, settings, rng.randi())
		file.store_line("%d,%d,%s,%s,%s,%d,%s" % [seed, game, BalanceArmies.counts_text(white), BalanceArmies.counts_text(black), result[0], result[1], result[2]])
		file.flush()
		print("game %d: %s in %d half-moves (%s), %.1f s" % [game, result[0], result[1], result[2], (Time.get_ticks_msec() - started) / 1000.0])
	file.close()
	PracticeBot.clear_cache()
	quit()

## Play one game; returns [result for White ("1", "0.5" or "0"), half-moves, how it ended].
static func play(white: Army, black: Army, rules: GameRules, settings: Dictionary, seed: int) -> Array:
	var state := ArmySetup.create_game(white, black, rules)
	var bots := [PracticeBot.new(PracticeBot.Level.HARD, seed), PracticeBot.new(PracticeBot.Level.HARD, seed + 1)]
	for bot: PracticeBot in bots:
		bot.settings_override = settings
	while state.outcome() == GameState.Outcome.NONE and state.history.size() < MAX_PLIES:
		var bot: PracticeBot = bots[0 if state.side_to_move == Piece.Team.WHITE else 1]
		var move := bot.choose_move(state)
		if move == null:
			break
		state.make_move(move)
	match state.outcome():
		GameState.Outcome.CHECKMATE:
			# The side to move has been checkmated.
			return ["0" if state.side_to_move == Piece.Team.WHITE else "1", state.history.size(), "checkmate"]
		GameState.Outcome.NONE:
			var score := PracticeBot.evaluate(state) / 100.0
			if state.side_to_move == Piece.Team.BLACK:
				score = -score
			if score >= ADJUDICATE_MARGIN:
				return ["1", state.history.size(), "adjudicated"]
			if score <= -ADJUDICATE_MARGIN:
				return ["0", state.history.size(), "adjudicated"]
			return ["0.5", state.history.size(), "adjudicated draw"]
		_:
			return ["0.5", state.history.size(), GameState.Outcome.keys()[state.outcome()].to_lower()]

## "--games 50 --seed 1" -> {"games": "50", "seed": "1"}
static func _options(args: PackedStringArray) -> Dictionary:
	var options := {}
	var i := 0
	while i < args.size():
		if args[i].begins_with("--") and i + 1 < args.size():
			options[args[i].substr(2)] = args[i + 1]
			i += 2
		else:
			i += 1
	return options
