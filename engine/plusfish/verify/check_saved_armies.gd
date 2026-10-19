extends SceneTree

## Loads every saved-army .tres in a folder with the game's own classes and
## checks it against the game's army rules (Army.problems), so armies written
## by `plusfish export-tres` are known to load in the game.
##
##   copy it to <ChessPlus>/tools/ (Godot ignores engine/plusfish), then
##   godot --headless --path <ChessPlus> -s res://tools/check_saved_armies.gd -- <absolute folder>

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty():
		print("usage: ... -- <folder of .tres armies>")
		quit(2)
		return
	var folder: String = args[0]
	var rules := GameRules.new()
	var bad := 0
	var count := 0
	for file in DirAccess.get_files_at(folder):
		if not file.ends_with(".tres"):
			continue
		count += 1
		var army = ResourceLoader.load(folder.path_join(file), "", ResourceLoader.CACHE_MODE_IGNORE)
		if not (army is Army):
			print("%s: not an army" % file)
			bad += 1
			continue
		var problems: PackedStringArray = army.problems(rules, 8)
		print("%s: \"%s\", %d pieces, %s points, mirror_for_black %s, %s" % [file, army.army_name, army.pieces.size(), army.cost(), army.mirror_for_black, "legal" if problems.is_empty() else ", ".join(problems)])
		if not problems.is_empty():
			bad += 1
	print("%d armies, %d with problems" % [count, bad])
	quit(1 if bad > 0 or count == 0 else 0)
