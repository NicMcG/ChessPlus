extends SceneTree

## Prints the request the game would send Plusfish for a game between two
## armies, so the PC and web builds can be checked against each other on any
## pieces. Armies are rows of piece ids, back row first ("-" = empty); it plays
## <plies> moves picked from the legal ones.
##   godot --headless --path <ChessPlus> -s <this file> -- <out.json> <plies> \
##     <white back> <white front> <black back> <black front>
## e.g. ... -- req.json 16 "squire,-,vampire,knight,king,vampire,-,-" "bishop,queen,ram,squire,berserker,pawn,necromancer,-" ...

func _army(back: String, front: String) -> Army:
	var by_id := {}
	for d in PieceCatalog.all_defs():
		by_id[d.id] = d
	var a := Army.new()
	var rows := [back.split(","), front.split(",")]
	for r in 2:
		for f in rows[r].size():
			if rows[r][f] != "-":
				a.place(by_id[rows[r][f]], Vector2i(f, r))
	return a

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var w := _army(args[2], args[3])
	var b := _army(args[4], args[5])
	var rules := StandardSetup.create_rules()
	var start := ArmySetup.create_game(w, b, rules)
	var state := ArmySetup.create_game(w, b, rules)
	var moves := []
	for i in int(args[1]):
		var legal := state.moves()
		if legal.is_empty():
			break
		var move: Move = legal[(i * 7) % legal.size()]
		moves.append(move.to_text())
		state.make_move(move)
	var request := PlusfishLink.request_for(start, moves)
	request["nodes"] = 20000
	var file := FileAccess.open(args[0], FileAccess.WRITE)
	file.store_string(JSON.stringify(request))
	file.close()
	quit()
