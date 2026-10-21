class_name ArmyPicker
extends ColorRect

## A pop-up list of armies to choose from (see ArmyChoices: Default, Random,
## Standard, every saved army that's legal, then the ones that break the rules,
## greyed out), and (if asked for) which side to
## play: White, Black or Random. Emits `chosen` with the army (an Army, or a
## Callable(team) -> Army for Default/Random, as the side may not be known yet)
## and side (an OnlineSession.SIDE_* value; SIDE_RANDOM when no side was asked
## for), or `cancelled`.

signal chosen(army: Variant, side: int)
signal cancelled

## What's offered, in order.
var choices: ArmyChoices

## The side choice (only when `ask_side`).
var side_pick: OptionButton

## `library` holds the saved armies (null = only Standard).
func _init(library: ArmyLibrary = null, title := "Choose your army", ask_side := false) -> void:
	color = UiStyle.SCRIM
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	choices = ArmyChoices.new(library)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 520
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.theme_type_variation = &"DialogTitle"
	column.add_child(heading)
	if ask_side:
		var side_label := Label.new()
		side_label.text = "You play"
		side_label.theme_type_variation = &"HeadingLabel"
		column.add_child(side_label)
		side_pick = OptionButton.new()
		for side in ["White", "Black", "Random"]:
			side_pick.add_item(side)
		side_pick.custom_minimum_size.y = 80
		column.add_child(side_pick)
		var army_label := Label.new()
		army_label.text = "With"
		army_label.theme_type_variation = &"HeadingLabel"
		column.add_child(army_label)
	for index in choices.entries.size():
		var entry: Dictionary = choices.entries[index]
		var button := Button.new()
		button.text = entry.label
		button.clip_text = true
		button.custom_minimum_size.y = 80
		if not choices.can_pick(index):
			button.disabled = true
			button.tooltip_text = "
".join(entry.problems) + "
Fix it in My armies."
		button.pressed.connect(func() -> void:
			var army: Variant = entry.army if entry.kind == ArmyChoices.ARMY else choices.resolver(index)
			chosen.emit(army, side_pick.selected if side_pick else OnlineSession.SIDE_RANDOM)
			queue_free())
		column.add_child(button)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.theme_type_variation = &"GhostButton"
	cancel.custom_minimum_size.y = 70
	cancel.pressed.connect(func() -> void:
		cancelled.emit()
		queue_free())
	column.add_child(cancel)
