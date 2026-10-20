extends Control

## Testing mode's setup screen (Mac's design, Oct 2026): set up any position with
## any pieces, choose pieces that are already captured and who moves first, then
## start a two-player game from it (with the eval bar on).
##
## Pick a piece in the tray (White or Black, switched at the top), then tap
## squares to put it there; tap a square holding that same piece to take it off
## again. "Remove" in the tray takes off whatever is tapped. Pieces can also be
## dragged from the tray onto the board, or from square to square; right-click
## (PC) removes. "Add to captured" puts the chosen piece among the captured.
## "Load armies" sets up a saved army, the Standard set or pasted army text
## (ArmyShare.to_text) for either side, where it would start in a real game.

signal back_pressed
signal start_pressed(position: TestingPosition)

var setup := TestingPosition.standard()
## The piece type chosen in the tray (null = Remove).
var chosen: PieceDef
## Which colour the tray places.
var tray_team := Piece.Team.WHITE

var board: SetupBoard
var colour_button: Button
var white_first: Button
var black_first: Button
var captured_box: HFlowContainer
var add_captured_button: Button
var tray: GridContainer
var problems_label: Label
var start_button: Button
var load_button: Button
## The saved armies "Load armies" offers (null = only Standard and pasted text).
var library: ArmyLibrary
## The Load armies pop-up (null when not showing).
var load_panel: ModalPanel
## Tray buttons, by piece type (null = Remove).
var _tray_buttons := {}
var _tray_group := ButtonGroup.new()
var _layout: BoxContainer
var _side: VBoxContainer
var _board_area: AspectRatioContainer
var _top: HBoxContainer

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color(0.17, 0.17, 0.18)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 14)
	add_child(margin)
	_layout = VBoxContainer.new()
	_layout.add_theme_constant_override("separation", 12)
	margin.add_child(_layout)
	_build_top_bar()
	_board_area = AspectRatioContainer.new()
	_board_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board = SetupBoard.new()
	board.square_tapped.connect(tap_square)
	board.square_right_clicked.connect(func(square: Vector2i) -> void:
		setup.remove_at(square)
		_refresh())
	board.piece_dropped.connect(func(def: PieceDef, square: Vector2i) -> void:
		setup.place(square, def, tray_team)
		_refresh())
	board.piece_moved.connect(func(from: Vector2i, to: Vector2i) -> void:
		var entry := setup.get_at(from)
		setup.remove_at(from)
		setup.place(to, entry[0], entry[1])
		_refresh())
	_board_area.add_child(board)
	_side = VBoxContainer.new()
	_side.add_theme_constant_override("separation", 12)
	_side.size_flags_vertical = Control.SIZE_SHRINK_END
	_build_controls()
	_layout.add_child(_board_area)
	_layout.add_child(_side)
	resized.connect(fit_layout)
	fit_layout()
	board.show_position(setup)
	_refresh()

func _build_top_bar() -> void:
	_top = HBoxContainer.new()
	_top.add_theme_constant_override("separation", 12)
	var back := _button("Back", func() -> void: back_pressed.emit())
	_top.add_child(back)
	var title := Label.new()
	title.text = "Testing mode"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 36)
	_top.add_child(title)
	colour_button = _button("", toggle_tray_team)
	colour_button.custom_minimum_size.x = 210
	_top.add_child(colour_button)
	_top.add_child(VolumeControl.make_room())
	_layout.add_child(_top)

func _build_controls() -> void:
	# Who moves first, and ways to start over.
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var to_move := Label.new()
	to_move.text = "To move:"
	row.add_child(to_move)
	var first_group := ButtonGroup.new()
	white_first = _button("White", func() -> void: set_side_to_move(Piece.Team.WHITE))
	black_first = _button("Black", func() -> void: set_side_to_move(Piece.Team.BLACK))
	for button in [white_first, black_first]:
		button.toggle_mode = true
		button.button_group = first_group
		button.custom_minimum_size.x = 120
		_show_selection(button)
		row.add_child(button)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)
	row.add_child(_button("Clear", clear_board))
	row.add_child(_button("Standard", func() -> void:
		setup = TestingPosition.standard()
		board.show_position(setup)
		_refresh()))
	_side.add_child(row)
	# Captured pieces.
	var captured_row := HBoxContainer.new()
	captured_row.add_theme_constant_override("separation", 10)
	var captured_label := Label.new()
	captured_label.text = "Captured:"
	captured_row.add_child(captured_label)
	captured_box = HFlowContainer.new()
	captured_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	captured_row.add_child(captured_box)
	add_captured_button = _button("Add", add_captured)
	captured_row.add_child(add_captured_button)
	_side.add_child(captured_row)
	# The tray of pieces.
	tray = GridContainer.new()
	tray.columns = 8
	tray.add_theme_constant_override("h_separation", 6)
	tray.add_theme_constant_override("v_separation", 6)
	_side.add_child(tray)
	_build_tray()
	problems_label = Label.new()
	problems_label.add_theme_color_override("font_color", Color("#ff6b6b"))
	problems_label.add_theme_font_size_override("font_size", 24)
	problems_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_side.add_child(problems_label)
	# Load armies sits beside Start game.
	var start_row := HBoxContainer.new()
	start_row.add_theme_constant_override("separation", 12)
	load_button = _button("Load armies", ask_load_armies)
	load_button.custom_minimum_size = Vector2(220, 90)
	start_row.add_child(load_button)
	start_button = _button("Start game", func() -> void: start_pressed.emit(setup.copy()))
	start_button.custom_minimum_size.y = 90
	start_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_row.add_child(start_button)
	_side.add_child(start_row)

## Every piece type, plus changed forms (the wolf), alphabetical; Remove first.
static func tray_defs() -> Array[PieceDef]:
	var defs: Array[PieceDef] = []
	for def in PieceCatalog.all_defs():
		defs.append(def)
		if def.transforms_into:
			defs.append(def.transforms_into)
	defs.sort_custom(func(a: PieceDef, b: PieceDef) -> bool:
		return a.display_name + a.id < b.display_name + b.id)
	return defs

func _build_tray() -> void:
	var remove := _tray_button(null)
	remove.text = "Remove"
	remove.add_theme_font_size_override("font_size", 18)
	for def in tray_defs():
		_tray_button(def)
	_tray_buttons[null].button_pressed = true

func _tray_button(def: PieceDef) -> Button:
	var button := Button.new()
	button.toggle_mode = true
	button.button_group = _tray_group
	button.custom_minimum_size = Vector2(76, 76)
	button.expand_icon = true
	button.focus_mode = Control.FOCUS_NONE
	_show_selection(button)
	button.tooltip_text = def.display_name if def else "Take pieces off"
	button.pressed.connect(func() -> void: choose(def))
	if def:
		# Drag a piece from the tray straight onto the board.
		button.set_drag_forwarding(func(_at: Vector2) -> Variant:
			choose(def)
			button.button_pressed = true
			var preview := TextureRect.new()
			preview.texture = PieceArt.texture_for(def, tray_team)
			preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			preview.size = Vector2(76, 76)
			preview.position = -preview.size / 2
			var holder := Control.new()
			holder.add_child(preview)
			set_drag_preview(holder)
			return {"tray_piece": def}, Callable(), Callable())
	_tray_buttons[def] = button
	tray.add_child(button)
	return button

## A chosen toggle button gets a gold border, so it's clear which one is on.
static func _show_selection(button: Button) -> void:
	var on := StyleBoxFlat.new()
	on.bg_color = Color(0.25, 0.25, 0.27)
	on.border_color = Color("#E8B83A")
	on.set_border_width_all(4)
	on.set_corner_radius_all(6)
	on.set_content_margin_all(6)
	button.add_theme_stylebox_override("pressed", on)
	button.add_theme_stylebox_override("hover_pressed", on)

func _button(text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 70
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(on_pressed)
	return button

## Board on the left and everything else on the right on wide screens; one
## column on tall ones.
func fit_layout() -> void:
	var wide := ScreenShape.is_wide(size)
	if wide and _side.get_parent() == _layout:
		var row := HBoxContainer.new()
		row.name = "Wide"
		row.add_theme_constant_override("separation", 20)
		row.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_layout.add_child(row)
		_board_area.reparent(row, false)
		_side.reparent(row, false)
		_side.custom_minimum_size.x = 640
		_side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	elif not wide and _side.get_parent() != _layout:
		var row := _side.get_parent()
		_board_area.reparent(_layout, false)
		_side.reparent(_layout, false)
		row.queue_free()
		_side.custom_minimum_size.x = 0
		_side.size_flags_vertical = Control.SIZE_SHRINK_END

# --- Actions (public, so tests can use them) -----------------------------------------

func choose(def: PieceDef) -> void:
	chosen = def
	_tray_buttons[def].button_pressed = true
	_refresh()

func toggle_tray_team() -> void:
	tray_team = Piece.other_team(tray_team)
	_refresh()

func set_side_to_move(team: Piece.Team) -> void:
	setup.side_to_move = team
	_refresh()

func clear_board() -> void:
	setup.clear()
	_refresh()

## A tap on the board: put the chosen piece there, or take off what's there
## (Remove chosen, or the same piece tapped again).
func tap_square(square: Vector2i) -> void:
	var there := setup.get_at(square)
	if chosen == null or (not there.is_empty() and there[0] == chosen and there[1] == tray_team):
		setup.remove_at(square)
	else:
		setup.place(square, chosen, tray_team)
	_refresh()

## Put `white` and `black` on the board where they'd start in a real game (null
## = leave that side's pieces as they are).
func load_armies(white: Army, black: Army) -> void:
	if white:
		setup.load_army(white, Piece.Team.WHITE)
	if black:
		setup.load_army(black, Piece.Team.BLACK)
	_refresh()

## The choices for each side in Load armies, in order: "Leave as it is", then
## "Standard", the saved armies, and "Paste army text".
func army_choices() -> PackedStringArray:
	var names := PackedStringArray([LEAVE_CHOICE, "Standard"])
	for army in _saved_armies():
		names.append(army.army_name)
	names.append(PASTE_CHOICE)
	return names

const LEAVE_CHOICE := "Leave as it is"
const PASTE_CHOICE := "Paste army text"

func _saved_armies() -> Array[Army]:
	if library == null:
		return []
	return library.armies()

## The Load armies pop-up: an army for each side.
func ask_load_armies() -> void:
	load_panel = ModalPanel.new("Load armies")
	load_panel.add_text("Choose an army for each side. It goes where it would start in a real game, replacing that side's pieces.")
	for team_name in ["White", "Black"]:
		var label := load_panel.add_text("%s's army:" % team_name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		var pick := OptionButton.new()
		pick.name = team_name + "Pick"
		pick.custom_minimum_size.y = 70
		for choice in army_choices():
			pick.add_item(choice)
		load_panel.column.add_child(pick)
		var text_edit := LineEdit.new()
		text_edit.name = team_name + "Text"
		text_edit.placeholder_text = ArmyShare.TEXT_START + " ..."
		text_edit.custom_minimum_size.y = 70
		text_edit.hide()
		load_panel.column.add_child(text_edit)
		pick.item_selected.connect(func(index: int) -> void:
			text_edit.visible = index == pick.item_count - 1)
	var message := load_panel.add_text("")
	message.name = "Message"
	message.add_theme_color_override("font_color", Color("#ff8a80"))
	load_panel.add_button("Load", load_chosen_armies)
	load_panel.add_button("Cancel", load_panel.close)
	add_child(load_panel)
	for team_name in ["White", "Black"]:
		PhoneTextInput.attach(load_panel.find_child(team_name + "Text", true, false), "%s's army" % team_name)

## Load what's chosen in the pop-up and close it, or say what's wrong.
func load_chosen_armies() -> void:
	var armies := {}
	for team_name in ["White", "Black"]:
		var pick: OptionButton = load_panel.find_child(team_name + "Pick", true, false)
		var text_edit: LineEdit = load_panel.find_child(team_name + "Text", true, false)
		var found := _chosen_army(pick, text_edit.text)
		if found.error != "":
			var message: Label = load_panel.find_child("Message", true, false)
			message.text = "%s's army: %s" % [team_name, found.error]
			return
		armies[team_name] = found.army
	load_armies(armies["White"], armies["Black"])
	load_panel.close()

## The army chosen in `pick` ({"army": Army or null for "leave", "error": ""}),
## going by position in army_choices() (a saved army could have any name).
func _chosen_army(pick: OptionButton, pasted: String) -> Dictionary:
	if pick.selected <= 0:
		return {"army": null, "error": ""}
	if pick.selected == pick.item_count - 1:
		if pasted.strip_edges().is_empty():
			return {"army": null, "error": "Paste the army text first."}
		return ArmyShare.from_text(pasted)
	if pick.selected == 1:
		return {"army": StandardSetup.army(), "error": ""}
	return {"army": _saved_armies()[pick.selected - 2], "error": ""}

func add_captured() -> void:
	if chosen == null:
		return
	setup.captured.append([chosen, tray_team])
	_refresh()

func remove_captured(index: int) -> void:
	setup.captured.remove_at(index)
	_refresh()

func _refresh() -> void:
	colour_button.text = "White pieces" if tray_team == Piece.Team.WHITE else "Black pieces"
	for def: PieceDef in _tray_buttons:
		if def:
			var button: Button = _tray_buttons[def]
			button.icon = PieceArt.texture_for(def, tray_team)
			button.text = "" if button.icon else def.symbol
	(white_first if setup.side_to_move == Piece.Team.WHITE else black_first).button_pressed = true
	for child in captured_box.get_children():
		child.queue_free()
	# White's captured pieces first, then Black's; tap one to put it back.
	var order := range(setup.captured.size())
	order.sort_custom(func(a: int, b: int) -> bool: return setup.captured[a][1] < setup.captured[b][1] or (setup.captured[a][1] == setup.captured[b][1] and a < b))
	for index: int in order:
		var entry: Array = setup.captured[index]
		var icon := Button.new()
		icon.icon = PieceArt.texture_for(entry[0], entry[1])
		if icon.icon == null:
			icon.text = entry[0].symbol
		icon.expand_icon = true
		icon.custom_minimum_size = Vector2(52, 52)
		icon.focus_mode = Control.FOCUS_NONE
		icon.tooltip_text = "Tap to un-capture"
		var tile := StyleBoxFlat.new()
		tile.bg_color = Color("#F0D9B5")
		tile.set_corner_radius_all(6)
		icon.add_theme_stylebox_override("normal", tile)
		icon.pressed.connect(remove_captured.bind(index))
		captured_box.add_child(icon)
	if setup.captured.is_empty():
		var none := Label.new()
		none.text = "none"
		none.add_theme_color_override("font_color", Color("#9a9a9a"))
		captured_box.add_child(none)
	add_captured_button.disabled = chosen == null
	var problems := setup.problems()
	problems_label.text = "\n".join(problems)
	problems_label.visible = not problems.is_empty()
	start_button.disabled = not problems.is_empty()
	board.queue_redraw()
