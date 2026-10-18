extends Control

## Before a match. Choose the opponent: another player on this device, or the
## practice bot (with its difficulty and which side you play: White, Black or
## Random). Then each side picks an army ("Standard" or a saved one), and Start.

signal closed
## `bot_team` is the bot's Piece.Team, or -1 for a two-player game.
signal start_requested(white: Army, black: Army, bot_team: int, bot_level: int)

const TWO_PLAYERS := 0
const PRACTICE_BOT := 1
const SIDE_WHITE := 0
const SIDE_BLACK := 1
const SIDE_RANDOM := 2

@onready var opponent_pick: OptionButton = %Opponent
@onready var bot_options: Control = %BotOptions
@onready var level_pick: OptionButton = %Difficulty
@onready var side_pick: OptionButton = %Side
@onready var first_label: Label = %FirstLabel
@onready var second_label: Label = %SecondLabel
@onready var first_pick: OptionButton = %FirstArmy
@onready var second_pick: OptionButton = %SecondArmy
@onready var start_button: Button = %Start
@onready var back_button: Button = %Back

var library: ArmyLibrary
var rules := StandardSetup.create_rules()
## The armies in the order they appear in both army lists.
var choices: Array[Army] = []
## Decides "Random" sides. Tests give it a seed.
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	opponent_pick.add_item("Two players")
	opponent_pick.add_item("Practice bot")
	for level_name in PracticeBot.LEVEL_NAMES:
		level_pick.add_item(level_name)
	level_pick.select(PracticeBot.Level.MEDIUM)
	for side in ["White", "Black", "Random"]:
		side_pick.add_item(side)
	choices = [StandardSetup.army()]
	# Only legal armies (one could have become illegal if the rules changed).
	choices.append_array(library.armies().filter(func(a: Army) -> bool: return a.is_valid(rules, 8)))
	for pick in [first_pick, second_pick]:
		for army in choices:
			pick.add_item("%s  (%s pts)" % [army.army_name, Army.format_points(army.cost())])
		pick.select(0)
	opponent_pick.item_selected.connect(func(_index: int) -> void: _update_labels())
	start_button.pressed.connect(start)
	back_button.pressed.connect(func() -> void: closed.emit())
	_update_labels()

func is_bot_game() -> bool:
	return opponent_pick.selected == PRACTICE_BOT

func start() -> void:
	var first := choices[first_pick.selected]
	var second := choices[second_pick.selected]
	if not is_bot_game():
		start_requested.emit(first, second, -1, 0)
		return
	# In a bot game the first list is your army and the second is the bot's.
	var you_play_white := side_pick.selected == SIDE_WHITE
	if side_pick.selected == SIDE_RANDOM:
		you_play_white = rng.randi_range(0, 1) == 0
	if you_play_white:
		start_requested.emit(first, second, Piece.Team.BLACK, level_pick.selected)
	else:
		start_requested.emit(second, first, Piece.Team.WHITE, level_pick.selected)

func _update_labels() -> void:
	bot_options.visible = is_bot_game()
	first_label.text = "Your army" if is_bot_game() else "White plays with"
	second_label.text = "Bot's army" if is_bot_game() else "Black plays with"
