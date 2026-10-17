extends Control

## Before a match: each player picks an army ("Standard" or one of the saved
## armies), then Start.

signal closed
signal start_requested(white: Army, black: Army)

@onready var white_pick: OptionButton = %WhiteArmy
@onready var black_pick: OptionButton = %BlackArmy
@onready var start_button: Button = %Start
@onready var back_button: Button = %Back

var library: ArmyLibrary
var rules := StandardSetup.create_rules()
## The armies in the order they appear in both lists.
var choices: Array[Army] = []

func _ready() -> void:
	choices = [StandardSetup.army()]
	# Only legal armies (one could have become illegal if the rules changed).
	choices.append_array(library.armies().filter(func(a: Army) -> bool: return a.is_valid(rules, 8)))
	for pick in [white_pick, black_pick]:
		for army in choices:
			pick.add_item("%s  (%s pts)" % [army.army_name, Army.format_points(army.cost())])
		pick.select(0)
	start_button.pressed.connect(start)
	back_button.pressed.connect(func() -> void: closed.emit())

func start() -> void:
	start_requested.emit(choices[white_pick.selected], choices[black_pick.selected])
