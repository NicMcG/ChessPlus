class_name ArmyPicker
extends ColorRect

## A pop-up list of armies to choose from: "Standard" plus every saved army
## that's legal. Emits `chosen` with the army, or `cancelled`.

signal chosen(army: Army)
signal cancelled

## The armies offered, in order.
var armies: Array[Army] = []

## `library` holds the saved armies (null = only Standard).
func _init(library: ArmyLibrary = null, title := "Choose your army") -> void:
	color = Color(0, 0, 0, 0.6)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_index = 20
	var rules := StandardSetup.create_rules()
	armies = [StandardSetup.army()]
	if library:
		armies.append_array(library.armies().filter(func(a: Army) -> bool: return a.is_valid(rules, 8)))
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.14)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size.x = 520
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	var heading := Label.new()
	heading.text = title
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_font_size_override("font_size", 40)
	column.add_child(heading)
	for army in armies:
		var button := Button.new()
		button.text = "%s  (%s pts)" % [army.army_name, Army.format_points(army.cost())]
		button.custom_minimum_size.y = 80
		button.pressed.connect(func() -> void:
			chosen.emit(army)
			queue_free())
		column.add_child(button)
	var cancel := Button.new()
	cancel.text = "Cancel"
	cancel.custom_minimum_size.y = 70
	cancel.pressed.connect(func() -> void:
		cancelled.emit()
		queue_free())
	column.add_child(cancel)
