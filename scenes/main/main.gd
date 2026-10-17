extends Control

## The whole app. Shows one screen at a time and moves between them:
## main menu -> my armies -> army builder, and main menu -> choose armies -> game.

const MAIN_MENU := preload("res://scenes/menu/main_menu.tscn")
const ARMY_LIST := preload("res://scenes/armies/army_list.tscn")
const ARMY_BUILDER := preload("res://scenes/armies/army_builder.tscn")
const MATCH_SETUP := preload("res://scenes/menu/match_setup.tscn")
const GAME := preload("res://scenes/game/game.tscn")

var library := ArmyLibrary.new()
## The screen currently showing.
var screen: Node

func _ready() -> void:
	show_main_menu()

func show_main_menu() -> void:
	var menu := MAIN_MENU.instantiate()
	menu.play_pressed.connect(show_match_setup)
	menu.armies_pressed.connect(show_army_list)
	_show(menu)

func show_army_list() -> void:
	var army_list := ARMY_LIST.instantiate()
	army_list.library = library
	army_list.closed.connect(show_main_menu)
	army_list.edit_requested.connect(show_army_builder)
	_show(army_list)

## `army` is null to start a new one.
func show_army_builder(army: Army) -> void:
	var builder := ARMY_BUILDER.instantiate()
	builder.setup(library, army)
	builder.closed.connect(show_army_list)
	builder.saved.connect(func(_army: Army) -> void: show_army_list())
	_show(builder)

func show_match_setup() -> void:
	var setup := MATCH_SETUP.instantiate()
	setup.library = library
	setup.closed.connect(show_main_menu)
	setup.start_requested.connect(start_game)
	_show(setup)

func start_game(white: Army, black: Army) -> void:
	var game := GAME.instantiate()
	game.white_army = white
	game.black_army = black
	game.menu_requested.connect(show_main_menu)
	_show(game)

## Replace the current screen with `new_screen`.
func _show(new_screen: Node) -> void:
	if screen:
		# queue_free: the old screen may still be in the middle of handling the
		# button press that brought us here, so free it once that's finished.
		screen.queue_free()
	screen = new_screen
	add_child(new_screen)
