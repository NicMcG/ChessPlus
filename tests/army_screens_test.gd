extends TestSuite

## Saving armies, and the army screens (builder, list, match setup, main flow).
## Everything is saved in a test folder, never the player's real armies.

const TEST_DIR := "user://test_armies/"
const KING = preload("res://data/pieces/king.tres")
const QUEEN = preload("res://data/pieces/queen.tres")
const KNIGHT = preload("res://data/pieces/knight.tres")
const PAWN = preload("res://data/pieces/pawn.tres")
const ELEPHANT = preload("res://data/pieces/elephant.tres")

func _fresh_library() -> ArmyLibrary:
	if DirAccess.dir_exists_absolute(TEST_DIR):
		for file in DirAccess.get_files_at(TEST_DIR):
			DirAccess.remove_absolute(TEST_DIR + file)
	# No default armies left over from another test.
	UserSettings.set_default_army(Piece.Team.WHITE, "")
	UserSettings.set_default_army(Piece.Team.BLACK, "")
	return ArmyLibrary.new(TEST_DIR)

func _small_army(army_name: String) -> Army:
	var army := Army.new()
	army.army_name = army_name
	army.place(KING, Vector2i(4, 0))
	army.place(KNIGHT, Vector2i(1, 0))
	army.place(PAWN, Vector2i(0, 1))
	return army

func _open(scene: Node) -> Node:
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	return scene

# --- ArmyLibrary ---------------------------------------------------------------

func test_save_and_load() -> void:
	var library := _fresh_library()
	check_eq(library.save(_small_army("Knights")), OK, "Saved")
	var armies := library.armies()
	check_eq(armies.size(), 1, "One army")
	if armies.size() == 1:
		check_eq(armies[0].army_name, "Knights", "Name")
		check_eq(armies[0].cost(), 4.0, "Cost")
		# Loaded pieces must be the very same piece types, or counting breaks.
		check_eq(armies[0].def_at(Vector2i(1, 0)), KNIGHT, "Same knight piece type")
		check_eq(armies[0].count_of(KNIGHT), 1, "Counting works after loading")

func test_saving_again_overwrites() -> void:
	var library := _fresh_library()
	var army := _small_army("First")
	library.save(army)
	army.army_name = "Renamed"
	library.save(army)
	var armies := library.armies()
	check_eq(armies.size(), 1, "Still one army")
	if armies.size() == 1:
		check_eq(armies[0].army_name, "Renamed", "Name updated")

func test_delete() -> void:
	var library := _fresh_library()
	library.save(_small_army("A"))
	library.save(_small_army("B"))
	library.delete(library.armies()[0])
	var names := library.armies().map(func(a: Army) -> String: return a.army_name)
	check_eq(names, ["B"], "A deleted")

func test_at_most_ten() -> void:
	var library := _fresh_library()
	for i in ArmyLibrary.MAX_ARMIES:
		library.save(_small_army("Army %d" % i))
	check(library.is_full(), "Full at 10")
	check_eq(library.save(_small_army("Eleventh")), ERR_CANT_CREATE, "No room for an 11th")
	check_eq(library.count(), 10, "Still 10")
	var first := library.armies()[0]
	first.army_name = "Edited"
	check_eq(library.save(first), OK, "Editing a saved army is still fine when full")

# --- Army builder ----------------------------------------------------------------

func _builder(library: ArmyLibrary, existing: Army = null) -> Node:
	var builder: Node = load("res://scenes/armies/army_builder.tscn").instantiate()
	builder.setup(library, existing)
	return _open(builder)

func test_builder_starts_empty_and_places_pieces() -> void:
	var builder := _builder(_fresh_library())
	check_eq(builder.army.pieces.size(), 0, "Empty board")
	check(builder.save_button.disabled, "Can't save an empty army")
	builder.select(KING)
	builder.tap_square(Vector2i(4, 0))
	builder.select(QUEEN)
	builder.tap_square(Vector2i(3, 0))
	check_eq(builder.army.cost(), 9.0, "King + queen")
	check_eq(builder.points_label.text, "Points: 9 / 39", "Points shown")
	check(builder.problems_label.text.contains("name"), "Still needs a name")
	builder.name_edit.text = "Queenly"
	builder.name_edit.text_changed.emit("Queenly")
	check(not builder.save_button.disabled, "Ready to save")
	builder.free()

func test_builder_tap_removes_and_swaps() -> void:
	var builder := _builder(_fresh_library())
	builder.select(KNIGHT)
	builder.tap_square(Vector2i(1, 0))
	builder.tap_square(Vector2i(1, 0))
	check_eq(builder.army.def_at(Vector2i(1, 0)), null, "Tapping the same type removes it")
	builder.tap_square(Vector2i(1, 0))
	builder.select(ELEPHANT)
	builder.tap_square(Vector2i(1, 0))
	check_eq(builder.army.def_at(Vector2i(1, 0)), ELEPHANT, "Another type swaps it")
	builder.select(null)
	builder.tap_square(Vector2i(1, 0))
	check_eq(builder.army.pieces.size(), 0, "With nothing selected, tapping removes")
	builder.free()

func test_builder_shows_rule_problems() -> void:
	var builder := _builder(_fresh_library())
	builder.select(KING)
	builder.tap_square(Vector2i(0, 0))
	check(builder.problems_label.text.contains("middle of the back row"), "King in the corner")
	check_eq(builder._allowed_squares(), [Vector2i(3, 0), Vector2i(4, 0)] as Array[Vector2i], "King squares highlighted")
	builder.select(KNIGHT)
	for file in [1, 2, 6]:
		builder.tap_square(Vector2i(file, 0))
	check(builder.problems_label.text.contains("Too many knights"), "Three knights")
	check(builder._tray_buttons[KNIGHT].modulate.a < 1.0, "Tray fades a piece with none left")
	check(builder._tray_buttons[QUEEN].modulate.a == 1.0, "Queen still to add")
	check_eq(builder._tray_buttons[KNIGHT].get_node("Cost").text, "3", "Tray shows the cost")
	builder.free()

func test_builder_saves_and_edits_a_copy() -> void:
	var library := _fresh_library()
	library.save(_small_army("Original"))
	var saved_army := library.armies()[0]
	var builder := _builder(library, saved_army)
	builder.select(ELEPHANT)
	builder.tap_square(Vector2i(2, 0))
	check_eq(saved_army.pieces.size(), 3, "The original isn't changed while editing")
	var emitted := []
	builder.saved.connect(func(a: Army) -> void: emitted.append(a))
	builder.save()
	check_eq(emitted.size(), 1, "Saved signal")
	check_eq(library.count(), 1, "Overwrote, didn't add")
	check_eq(library.armies()[0].pieces.size(), 4, "Elephant added in the file")
	builder.free()

func test_phone_text_input_does_nothing_outside_browsers() -> void:
	# Tests run on PC, so attaching must leave the LineEdit working normally.
	check(not PhoneTextInput.in_browser(), "Not a browser")
	var edit := LineEdit.new()
	PhoneTextInput.attach(edit, "Name")
	check_eq(edit.get_child_count(), 0, "No web text box added on PC")
	check(not edit.has_theme_color_override("font_color"), "Its text stays visible")
	edit.free()

func test_pc_borrows_system_fonts_for_emoji_and_other_alphabets() -> void:
	SystemFonts.install()
	var system_fonts := ThemeDB.fallback_font.fallbacks.filter(func(f: Font) -> bool: return f is SystemFont)
	check_eq(system_fonts.size(), SystemFonts.FALLBACKS.size(), "Fallback fonts added")
	SystemFonts.install()
	check_eq(ThemeDB.fallback_font.fallbacks.filter(func(f: Font) -> bool: return f is SystemFont).size(),
			SystemFonts.FALLBACKS.size(), "Only once")

# --- Army list and match setup -------------------------------------------------

func test_army_list_shows_saved_armies() -> void:
	var library := _fresh_library()
	library.save(_small_army("Alpha"))
	library.save(_small_army("Beta"))
	var army_list: Node = load("res://scenes/armies/army_list.tscn").instantiate()
	army_list.library = library
	_open(army_list)
	check_eq(army_list.list.get_child_count(), 2, "Two rows")
	check_eq(army_list.count_label.text, "2 of 10 saved", "Count")
	check(not army_list.new_button.disabled, "Room for more")
	army_list.free()

func test_match_setup_offers_standard_and_saved() -> void:
	var library := _fresh_library()
	library.save(_small_army("Mine"))
	var setup: Node = load("res://scenes/menu/match_setup.tscn").instantiate()
	setup.library = library
	_open(setup)
	check_eq(setup.first_pick.item_count, 4, "Default, Random, Standard, Mine")
	check(setup.first_pick.get_item_text(0).begins_with("Default"), "Default first")
	check_eq(setup.first_pick.selected, 0, "Default chosen to start with")
	var started := []
	setup.start_requested.connect(func(w: Army, b: Army, _bot: int, _level: int) -> void: started.append([w, b]))
	setup.second_pick.select(3)
	setup.start()
	check_eq(started.size(), 1, "Start pressed")
	if started.size() == 1:
		check_eq(started[0][0].army_name, "Standard", "White: standard")
		check_eq(started[0][1].army_name, "Mine", "Black: mine")
	setup.free()

# --- The whole flow --------------------------------------------------------------

func test_main_starts_a_game_with_two_armies() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	main.library = _fresh_library()
	_open(main)
	main.start_game(StandardSetup.army(), _small_army("Small"))
	var game: Node = main.screen
	# Built on b1 / a2; Black's army is turned round, so g8 / h7.
	check_eq(game.state.board.get_piece(Board.parse_square("g8")).def, KNIGHT, "Black's knight on g8")
	check_eq(game.state.board.get_piece(Board.parse_square("h7")).def, PAWN, "Black's pawn on h7")
	check(game.state.board.pieces_of(Piece.Team.BLACK).values().all(func(p: Piece) -> bool: return p.def != QUEEN), "Black has no queen")
	check(game.menu_button.visible, "Menu button shown")
	main.free()

# --- Default and Random armies ----------------------------------------------------

func test_default_army_per_side() -> void:
	var library := _fresh_library()
	library.save(_small_army("Knights"))
	library.save(_small_army("Other"))
	var knights: Army = library.armies().filter(func(a: Army) -> bool: return a.army_name == "Knights")[0]
	var choices := ArmyChoices.new(library)
	check_eq(choices.army_for(0, Piece.Team.WHITE).army_name, "Standard", "No default set: Standard")
	UserSettings.set_default_army(Piece.Team.BLACK, knights.library_path)
	choices = ArmyChoices.new(library)
	check_eq(choices.army_for(0, Piece.Team.BLACK).army_name, "Knights", "Black's default")
	check_eq(choices.army_for(0, Piece.Team.WHITE).army_name, "Standard", "White still Standard")
	check_eq(choices.entries[0].label, "Default (Standard / Knights)", "Says what Default means")
	check_eq(ArmyChoices.resolve(choices.resolver(0), Piece.Team.BLACK).army_name, "Knights", "Decided later, by side")
	_fresh_library()

func test_random_army_is_one_of_mine() -> void:
	var library := _fresh_library()
	check_eq(ArmyChoices.new(library).entries.size(), 2, "No saved armies: no Random (Default, Standard)")
	library.save(_small_army("A"))
	library.save(_small_army("B"))
	var choices := ArmyChoices.new(library)
	check_eq(choices.entries[1].kind, ArmyChoices.RANDOM, "Random second")
	var seen := {}
	for i in 40:
		seen[choices.army_for(1, Piece.Team.WHITE).army_name] = true
	check_eq(seen.keys().size(), 2, "Picks among my armies")
	check(not seen.has("Standard"), "Never Standard")
	_fresh_library()

func test_army_list_marks_defaults() -> void:
	var library := _fresh_library()
	library.save(_small_army("Mine"))
	var army_list: Node = load("res://scenes/armies/army_list.tscn").instantiate()
	army_list.library = library
	_open(army_list)
	var mine: Army = library.armies()[0]
	army_list.set_default(mine, Piece.Team.WHITE, true)
	check_eq(UserSettings.default_army(Piece.Team.WHITE), mine.library_path, "White default set")
	army_list.ask_delete(mine)
	army_list.confirm_delete.confirmed.emit()
	check_eq(UserSettings.default_army(Piece.Team.WHITE), "", "Deleting it clears the default")
	army_list.free()
	_fresh_library()

# --- Sharing armies ---------------------------------------------------------------

func test_share_and_import_an_army() -> void:
	MemoryBackend.clear()
	var library := _fresh_library()
	var backend := MemoryBackend.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(backend)
	# Share the standard set under a new name from the builder.
	var mine := StandardSetup.army()
	mine.army_name = "Sharer"
	mine.mirror_for_black = true
	var builder: Node = load("res://scenes/armies/army_builder.tscn").instantiate()
	builder.setup(library, mine)
	builder.backend = backend
	_open(builder)
	check(not builder.share_button.disabled, "A legal army can be shared")
	await builder.share()
	var code_label: Label = builder.share_panel.find_child("Code", true, false)
	check(code_label != null and code_label.text.length() == OnlineSession.CODE_LENGTH, "Shows a 5-letter code")
	var code: String = code_label.text if code_label else ""
	builder.free()
	# A friend imports it.
	library.save(_small_army("Sharer"))
	var army_list: Node = load("res://scenes/armies/army_list.tscn").instantiate()
	army_list.library = library
	army_list.backend = backend
	_open(army_list)
	army_list.ask_import()
	await army_list.import_code(code.to_lower())
	var names := library.armies().map(func(a: Army) -> String: return a.army_name)
	check("Sharer (2)" in names, "Imported, renamed so names don't clash")
	var imported: Army = library.armies().filter(func(a: Army) -> bool: return a.army_name == "Sharer (2)")[0]
	check_eq(imported.pieces.size(), 16, "All 16 pieces")
	check(imported.mirror_for_black, "Still turned round for Black like a built army")
	# A wrong code says so.
	army_list.ask_import()
	await army_list.import_code("ZZZZZ")
	var message: Label = army_list.import_panel.find_child("Message", true, false)
	check(message.text.contains("no army"), "Unknown code: " + message.text)
	army_list.free()
	backend.free()
	MemoryBackend.clear()
	_fresh_library()

func test_share_needs_a_legal_named_army() -> void:
	var builder: Node = load("res://scenes/armies/army_builder.tscn").instantiate()
	builder.setup(_fresh_library(), null)
	_open(builder)
	check(builder.share_button.disabled, "An empty army can't be shared")
	builder.free()

func test_builder_drag_and_right_click() -> void:
	var builder := _builder(_fresh_library())
	builder.drop_piece(KNIGHT, Vector2i(1, 0))
	check_eq(builder.army.def_at(Vector2i(1, 0)), KNIGHT, "Dropped from the tray onto b1")
	check_eq(builder.selected, KNIGHT, "And that type is now chosen")
	builder.army_board.size = Vector2(400, 100)
	check(builder.army_board._can_drop_data(builder.army_board.square_center(Vector2i(2, 1)), {"tray_piece": KNIGHT}), "The board takes tray pieces")
	check(not builder.army_board._can_drop_data(Vector2.ZERO - Vector2(50, 50), {"tray_piece": KNIGHT}), "But not off the board")
	builder.remove_at(Vector2i(1, 0))
	check(builder.army.def_at(Vector2i(1, 0)) == null, "Right-click removes it")
	var knight_button: Button = builder._tray_buttons[KNIGHT]
	check(knight_button.get_node("Cost").color.a > 0.5, "Cost badge drawn")
	builder.free()

func test_king_has_a_swirled_frame_instead_of_a_badge() -> void:
	var builder := _builder(_fresh_library())
	var king_button: Button = builder._tray_buttons[KING]
	check(king_button.get_node_or_null("Cost") == null, "No cost badge on the king")
	var frame: KingFrame = king_button.get_node_or_null("KingFrame")
	check(frame != null, "A frame instead")
	check_eq(frame.team, Piece.Team.WHITE, "White to start")
	builder.toggle_team()
	check_eq(frame.team, Piece.Team.BLACK, "Follows the White/Black button")
	check(builder._tray_buttons[KNIGHT].get_node_or_null("KingFrame") == null, "Only the king has one")
	builder.free()
