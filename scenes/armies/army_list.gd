extends Control

## "My armies": every saved army with its cost. Tap one to edit it, "Delete" to
## remove it (after asking), or "New army" to build one (up to the limit).

signal closed
## `army` is null for a brand-new army.
signal edit_requested(army: Army)

@onready var list: VBoxContainer = %List
@onready var count_label: Label = %Count
@onready var new_button: Button = %NewArmy
@onready var back_button: Button = %Back
@onready var confirm_delete: ConfirmationDialog = %ConfirmDelete

var library: ArmyLibrary
var _pending_delete: Army

func _ready() -> void:
	new_button.pressed.connect(func() -> void: edit_requested.emit(null))
	back_button.pressed.connect(func() -> void: closed.emit())
	confirm_delete.confirmed.connect(_delete_pending)
	refresh()

## Rebuild the list from the saved files.
func refresh() -> void:
	for child in list.get_children():
		child.queue_free()
	var armies := library.armies()
	for army in armies:
		list.add_child(_row_for(army))
	count_label.text = "%d of %d saved" % [armies.size(), ArmyLibrary.MAX_ARMIES]
	new_button.disabled = armies.size() >= ArmyLibrary.MAX_ARMIES
	new_button.text = "New army" if not new_button.disabled else "Full: delete one to make another"

func ask_delete(army: Army) -> void:
	_pending_delete = army
	confirm_delete.dialog_text = "Delete \"%s\"?" % army.army_name
	confirm_delete.popup_centered()

func _delete_pending() -> void:
	if _pending_delete:
		library.delete(_pending_delete)
		_pending_delete = null
		refresh()

func _row_for(army: Army) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var open := Button.new()
	open.text = "%s  (%s pts)" % [army.army_name, Army.format_points(army.cost())]
	open.alignment = HORIZONTAL_ALIGNMENT_LEFT
	open.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	open.custom_minimum_size = Vector2(0, 90)
	open.clip_text = true
	open.pressed.connect(func() -> void: edit_requested.emit(army))
	var delete := Button.new()
	delete.text = "Delete"
	delete.custom_minimum_size = Vector2(150, 90)
	delete.pressed.connect(func() -> void: ask_delete(army))
	row.add_child(open)
	row.add_child(delete)
	return row
