extends SceneTree

## Opens the whole app (the main scene) and saves a picture of every screen, to
## check something that shows on all of them (e.g. the volume button).
## Run (needs a window, so not --headless):
##   "<godot console exe>" --path . --resolution 720x1280 -s res://tools/screenshot_screens.gd -- <out folder> [open]
## "open" also opens the volume slider before each picture.
## Saves <out folder>/<screen>.png for: menu, armies, builder, setup, game,
## online, testing.

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://screens"
	var open := args.has("open")
	SavedGame.save_path = "user://screenshot_screens_game.json"
	PlusfishLink.enabled = false
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	var shows := {
		"menu": main.show_main_menu,
		"armies": main.show_army_list,
		"builder": func() -> void: main.show_army_builder(Army.new()),
		"setup": main.show_match_setup,
		"game": func() -> void: main.start_game(StandardSetup.army(), StandardSetup.army()),
		"online": main.show_online_lobby.bind(MemoryBackend.new()),
		"testing": main.show_testing_setup,
	}
	for screen_name: String in shows:
		(shows[screen_name] as Callable).call()
		for i in 10:
			await process_frame
		main.volume_control.set_open(open)
		for i in 5:
			await process_frame
		var path := out_dir.path_join(screen_name + ".png")
		root.get_texture().get_image().save_png(path)
		print("Saved ", path)
	DirAccess.remove_absolute(SavedGame.save_path)
	main.free()
	MemoryBackend.clear()
	quit()
