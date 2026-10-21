extends TestSuite

## The app's look: the theme, the screens' backgrounds and the shared buttons.

const SCREENS := [
	"res://scenes/menu/main_menu.tscn",
	"res://scenes/menu/match_setup.tscn",
	"res://scenes/armies/army_list.tscn",
	"res://scenes/armies/army_builder.tscn",
	"res://scenes/online/online_lobby.tscn",
	"res://scenes/game/game.tscn",
]

func _open(scene: Node) -> Node:
	(Engine.get_main_loop() as SceneTree).root.add_child(scene)
	return scene

func test_theme_uses_inter_and_has_the_named_styles() -> void:
	var theme := ThemeDB.get_project_theme()
	var inter: Font = UiStyle.INTER
	check(theme.default_font is FontVariation and (theme.default_font as FontVariation).base_font == inter, "Text is Inter")
	for name in ["AccentButton", "DangerButton", "ChoiceButton", "CompactButton", "GhostButton",
			"TitleLabel", "HeadingLabel", "StrongLabel", "MutedLabel", "DialogTitle", "CardPanel"]:
		check(theme.get_type_variation_base(name) != &"", "%s is in the theme" % name)
	check(theme.has_icon("back", "UiIcons"), "The Back arrow is in the theme")
	check(theme.get_icon("arrow", "OptionButton") is DPITexture, "Lists have a sharp arrow")

func test_every_screen_has_the_backdrop() -> void:
	for path: String in SCREENS:
		var screen: Node = load(path).instantiate()
		check(screen.get_node_or_null("Background") is Backdrop, "%s has the shared background" % path.get_file())
		screen.free()

func test_main_menu_makes_the_top_button_gold() -> void:
	SavedGame.delete_saved()
	var menu: Node = _open(load("res://scenes/menu/main_menu.tscn").instantiate())
	check_eq(menu.get_node("%Play").theme_type_variation, &"AccentButton", "Play local is the main button")
	check_eq(menu.get_node("%Online").theme_type_variation, &"", "The others are plain")
	menu.free()

func test_back_button_has_its_arrow() -> void:
	var back: BackButton = _open(BackButton.new())
	check(back.icon != null, "Arrow shown")
	check_eq(back.text, "Back", "Says Back")
	check_eq(back.theme_type_variation, &"GhostButton", "No box until touched")
	back.free()

## Something wider than the room it's given used to make WidthLimit's margins
## grow without end (stack overflow on wide windows).
func test_width_limit_with_wide_contents() -> void:
	var holder := Control.new()
	holder.size = Vector2(1000, 400)
	_open(holder)
	var limit := WidthLimit.new()
	limit.max_width = 300
	limit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var wide := Control.new()
	wide.custom_minimum_size = Vector2(600, 10)
	limit.add_child(wide)
	holder.add_child(limit)
	await (Engine.get_main_loop() as SceneTree).process_frame
	var margins := limit.get_theme_constant("margin_left") + limit.get_theme_constant("margin_right")
	check(margins <= 400, "Margins leave room for the contents (%d)" % margins)
	check(limit.size.x <= 1000.5, "Not pushed wider than the room (%.0f)" % limit.size.x)
	holder.free()
