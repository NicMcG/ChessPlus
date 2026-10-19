extends Control

## Before a match. Choose the opponent: another player on this device, or the
## practice bot (with its difficulty and which side you play: White, Black or
## Random). Then each side picks an army (see ArmyChoices: their default for
## that side, a random one of their own, Standard or a saved one), and Start.

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
## What both army lists offer (see ArmyChoices).
var choices: ArmyChoices
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
	choices = ArmyChoices.new(library, rules)
	choices.rng = rng
	for pick in [first_pick, second_pick]:
		choices.fill(pick)
	eval_check = CheckButton.new()
	eval_check.text = "Show the eval bar"
	eval_check.custom_minimum_size.y = 70
	second_pick.get_parent().add_child(eval_check)
	second_pick.get_parent().move_child(eval_check, second_pick.get_index() + 1)
	opponent_pick.item_selected.connect(func(_index: int) -> void: _update_labels())
	start_button.pressed.connect(start)
	back_button.pressed.connect(func() -> void: closed.emit())
	_update_labels()

## The eval bar option (two players on this device; against the bot it's always on).
var eval_check: CheckButton

func eval_bar_wanted() -> bool:
	return is_bot_game() or (eval_check != null and eval_check.button_pressed)

func is_bot_game() -> bool:
	return opponent_pick.selected == PRACTICE_BOT

func start() -> void:
	if not is_bot_game():
		start_requested.emit(choices.army_for(first_pick.selected, Piece.Team.WHITE),
				choices.army_for(second_pick.selected, Piece.Team.BLACK), -1, 0)
		return
	# In a bot game the first list is your army and the second is the bot's.
	var you_play_white := side_pick.selected == SIDE_WHITE
	if side_pick.selected == SIDE_RANDOM:
		you_play_white = rng.randi_range(0, 1) == 0
	var you := Piece.Team.WHITE if you_play_white else Piece.Team.BLACK
	var yours := choices.army_for(first_pick.selected, you)
	var bots := choices.army_for(second_pick.selected, Piece.other_team(you))
	if you_play_white:
		start_requested.emit(yours, bots, Piece.Team.BLACK, level_pick.selected)
	else:
		start_requested.emit(bots, yours, Piece.Team.WHITE, level_pick.selected)

func _update_labels() -> void:
	bot_options.visible = is_bot_game()
	if eval_check:
		eval_check.visible = not is_bot_game()
	first_label.text = "Your army" if is_bot_game() else "White plays with"
	second_label.text = "Bot's army" if is_bot_game() else "Black plays with"
