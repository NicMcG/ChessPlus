extends Control

## "My armies": every saved army with its cost. Tap one to edit it, "Delete" to
## remove it (after asking), or "New army" to build one (up to the limit). The
## White / Black buttons mark an army as the default for that side (Mac's
## design): used when a player leaves the army choice on "Default".

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
## Where shared armies come from (null = the real server; tests use a MemoryBackend).
var backend: OnlineBackend
var import_button: Button
## The Import army pop-up (null when not showing).
var import_panel: ModalPanel

func _ready() -> void:
	new_button.pressed.connect(func() -> void: edit_requested.emit(null))
	# Import army sits beside New army.
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	new_button.get_parent().add_child(bottom)
	new_button.get_parent().move_child(bottom, new_button.get_index())
	new_button.reparent(bottom, false)
	new_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_button = Button.new()
	import_button.text = "Import army"
	import_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	import_button.custom_minimum_size.y = new_button.custom_minimum_size.y
	import_button.pressed.connect(ask_import)
	bottom.add_child(import_button)
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
	new_button.text = "New army" if not new_button.disabled else "Full: delete one"
	if import_button:
		import_button.disabled = new_button.disabled

## The Import army pop-up: type a friend's army code, or paste the army text
## they copied (ArmyShare.to_text).
func ask_import() -> void:
	import_panel = ModalPanel.new("Import army")
	import_panel.add_text("Type the code your friend got from Share:")
	var code_edit := LineEdit.new()
	code_edit.name = "CodeEdit"
	code_edit.placeholder_text = "Code"
	code_edit.max_length = OnlineSession.CODE_LENGTH
	code_edit.alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_edit.custom_minimum_size.y = 80
	code_edit.add_theme_font_size_override("font_size", 40)
	import_panel.column.add_child(code_edit)
	var go := import_panel.add_button("Import", func() -> void: pass)
	go.pressed.connect(func() -> void: import_code(code_edit.text))
	import_panel.add_text("Or paste the army text your friend copied:")
	var text_edit := LineEdit.new()
	text_edit.name = "TextEdit"
	text_edit.placeholder_text = ArmyShare.TEXT_START + " ..."
	text_edit.custom_minimum_size.y = 80
	import_panel.column.add_child(text_edit)
	var go_text := import_panel.add_button("Import text", func() -> void: pass)
	go_text.pressed.connect(func() -> void: import_text(text_edit.text))
	var message := import_panel.add_text("")
	message.name = "Message"
	message.add_theme_color_override("font_color", Color("#ff8a80"))
	import_panel.add_button("Cancel", import_panel.close)
	add_child(import_panel)
	PhoneTextInput.attach(code_edit, "Army code")
	PhoneTextInput.attach(text_edit, "Army text")
	code_edit.text_changed.connect(func(text: String) -> void:
		var caret := code_edit.caret_column
		code_edit.text = text.to_upper()
		code_edit.caret_column = caret)

## Fetch the army shared under `code` and add it to the saved armies.
func import_code(code: String) -> void:
	var message: Label = import_panel.find_child("Message", true, false) if import_panel else null
	if message:
		message.add_theme_color_override("font_color", Color("#e6e6e6"))
		message.text = "Importing..."
	var server := backend if backend else _real_server()
	var error: String = await ArmyShare.import_army(server, library, code)
	_import_done(error)

## Read pasted army text and add the army to the saved armies.
func import_text(text: String) -> void:
	_import_done(ArmyShare.import_text(library, text))

## Close the pop-up after an import, or show what went wrong.
func _import_done(error: String) -> void:
	if not is_instance_valid(import_panel):
		return
	if error != "":
		var message: Label = import_panel.find_child("Message", true, false)
		message.add_theme_color_override("font_color", Color("#ff8a80"))
		message.text = error
		return
	import_panel.close()
	refresh()

func _real_server() -> OnlineBackend:
	var server := SupabaseBackend.new()
	add_child(server)
	return server

func ask_delete(army: Army) -> void:
	_pending_delete = army
	confirm_delete.dialog_text = "Delete \"%s\"?" % army.army_name
	confirm_delete.popup_centered()

func _delete_pending() -> void:
	if _pending_delete:
		for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
			if UserSettings.default_army(team) == _pending_delete.library_path:
				UserSettings.set_default_army(team, "")
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
	for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
		row.add_child(_default_button(army, team))
	row.add_child(delete)
	return row

## A toggle marking `army` as the default for `team`; gold while it is.
func _default_button(army: Army, team: Piece.Team) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.text = "White" if team == Piece.Team.WHITE else "Black"
	button.tooltip_text = "Use this army by default when playing %s" % button.text
	button.custom_minimum_size = Vector2(110, 90)
	button.add_theme_font_size_override("font_size", 24)
	button.button_pressed = UserSettings.default_army(team) == army.library_path
	var on := StyleBoxFlat.new()
	on.bg_color = Color("#8a6d1f")
	on.border_color = Color("#FFD75E")
	on.set_border_width_all(3)
	on.set_corner_radius_all(6)
	button.add_theme_stylebox_override("pressed", on)
	button.add_theme_stylebox_override("hover_pressed", on)
	button.toggled.connect(func(pressed: bool) -> void:
		set_default(army, team, pressed))
	return button

## Make `army` the default for `team` (or stop it being, if `on` is false).
func set_default(army: Army, team: Piece.Team, on: bool) -> void:
	if on:
		UserSettings.set_default_army(team, army.library_path)
	elif UserSettings.default_army(team) == army.library_path:
		UserSettings.set_default_army(team, "")
	refresh()
