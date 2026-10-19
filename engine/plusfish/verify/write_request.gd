extends SceneTree

## Prints the request the game would send Plusfish for a game given in SAN, so
## the PC and web builds can be checked against each other. Copy into tools/:
##   godot --headless --path <ChessPlus> -s res://tools/write_request.gd -- <out.json> e4 e5 ...

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var start := ArmySetup.create_game(StandardSetup.army(), StandardSetup.army(), StandardSetup.create_rules())
	var state := ArmySetup.create_game(StandardSetup.army(), StandardSetup.army(), StandardSetup.create_rules())
	var moves := []
	for san in args.slice(1):
		var move := Notation.find_move(state, san)
		moves.append(move.to_text())
		state.make_move(move)
	var request := PlusfishLink.request_for(start, moves)
	request["nodes"] = 20000
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(request))
	file.close()
	quit()
