class_name ArmyChoices
extends RefCounted

## The armies a player can pick from before a game, in the order shown (Mac's
## design):
##   "Default"  - their default army for whichever side they end up playing (set
##                in My armies; the Standard army if none is set)
##   "Random"   - one of their own saved armies, picked at random (never
##                Standard); only offered if they have any
##   "Standard", then each saved army that's legal
##   then each saved army that breaks the rules (e.g. over the budget after a
##                price change), greyed out with the reason: it can't be picked
##                until it's fixed in My armies (Mac, Oct 2026)
## The side isn't always known when the choice is made (online with a random
## side, or joining a friend's game), so a choice is turned into an army later,
## with army_for() or resolver().

const DEFAULT := "default"
const RANDOM := "random"
const ARMY := "army"
const BROKEN := "broken"

## {"kind": DEFAULT / RANDOM / ARMY / BROKEN, "army": Army (ARMY and BROKEN),
## "label": String, "problems": PackedStringArray (BROKEN only)}
var entries: Array[Dictionary] = []
var library: ArmyLibrary
var rules: GameRules
var rng := RandomNumberGenerator.new()
## The saved armies that are legal (what Random picks from).
var saved: Array[Army] = []
## The saved armies that break the rules (shown, but can't be picked).
var broken: Array[Army] = []

func _init(p_library: ArmyLibrary, p_rules: GameRules = null) -> void:
	library = p_library
	rules = p_rules if p_rules else StandardSetup.create_rules()
	rng.randomize()
	if library:
		for army in library.armies():
			(saved if army.is_valid(rules, 8) else broken).append(army)
	entries.append({"kind": DEFAULT, "label": _default_label()})
	if not saved.is_empty():
		entries.append({"kind": RANDOM, "label": "Random (one of my armies)"})
	for army: Army in [StandardSetup.army()] + saved:
		entries.append({"kind": ARMY, "army": army, "label": label_for(army)})
	for army in broken:
		entries.append({"kind": BROKEN, "army": army, "label": broken_label(army, rules),
				"problems": army.problems(rules, 8)})

## "Name  (39 pts)".
static func label_for(army: Army) -> String:
	return "%s  (%s pts)" % [army.army_name, Army.format_points(army.cost())]

## "Name  (41.5 pts) – over budget" or "Name  (39 pts) – breaks the rules".
static func broken_label(army: Army, p_rules: GameRules) -> String:
	var why := "over budget" if army.cost() > p_rules.army_budget else "breaks the rules"
	return "%s – %s" % [label_for(army), why]

## True if choice `index` can be picked (not an army that breaks the rules).
func can_pick(index: int) -> bool:
	return entries[index].kind != BROKEN

## Fill an OptionButton with the choices, "Default" selected; armies that break
## the rules are greyed out, with what's wrong as their tooltip.
func fill(pick: OptionButton) -> void:
	pick.clear()
	# Long army names are cut short rather than widening the screen.
	pick.clip_text = true
	pick.custom_minimum_size.x = 0
	# Greyed out, but still easy to read (the theme's grey is too faint).
	pick.get_popup().add_theme_color_override("font_disabled_color", Color(0.62, 0.62, 0.62))
	for index in entries.size():
		var entry: Dictionary = entries[index]
		pick.add_item(entry.label)
		if entry.kind == BROKEN:
			pick.set_item_disabled(index, true)
			pick.set_item_tooltip(index, "
".join(entry.problems) + "
Fix it in My armies.")
	pick.select(0)

## The army choice `index` gives a player of `team`.
func army_for(index: int, team: Piece.Team) -> Army:
	var entry: Dictionary = entries[index]
	match entry.kind:
		DEFAULT:
			return default_army(team)
		RANDOM:
			return saved[rng.randi_range(0, saved.size() - 1)]
		BROKEN:
			# Can't be picked (greyed out); never used for a game.
			return default_army(team)
		_:
			return entry.army

## A Callable(team) -> Army for choice `index`, for when the side is decided later.
func resolver(index: int) -> Callable:
	return func(team: Piece.Team) -> Army: return army_for(index, team)

## The player's default army for `team`: the saved army they marked (if it still
## exists and is legal), otherwise Standard.
func default_army(team: Piece.Team) -> Army:
	var path := UserSettings.default_army(team)
	for army in saved:
		if path != "" and army.library_path == path:
			return army
	return StandardSetup.army()

## E.g. "Default (Knights / Standard)": White's default, then Black's.
func _default_label() -> String:
	var white := default_army(Piece.Team.WHITE).army_name
	var black := default_army(Piece.Team.BLACK).army_name
	if white == black:
		return "Default (%s)" % white
	return "Default (%s / %s)" % [white, black]

## Turns what an army choice gives (an Army, or a Callable(team) -> Army from
## resolver) into the army for `team`.
static func resolve(army_or_resolver: Variant, team: Piece.Team) -> Army:
	if army_or_resolver is Callable:
		return (army_or_resolver as Callable).call(team)
	return army_or_resolver
