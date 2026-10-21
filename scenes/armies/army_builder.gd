extends Control

## The army builder: name an army, buy pieces with the points budget and place
## them on your two starting rows. Tap a piece type in the tray, then tap squares
## to place it; tap a placed piece to remove it. The card under the tray shows
## the last piece type you tapped. Any rule problems are listed in red, and the
## army can only be saved once it's legal. The White/Black button only changes
## how the pieces look; armies work for either side.

signal closed
signal saved(army: Army)

const BOARD_WIDTH := 8
const NAME_MAX_LENGTH := 20

## Where the tray was scrolled to when a button was pressed.
var _scroll_at_press := 0

## How big the piece card is drawn (see PieceCard.zoom) on wide and tall screens.
## Wide: as big as its column allows, keeping the in-game pop-up's proportions
## (the whole legend needs room beside the mini board), within these limits.
const CARD_ZOOM_WIDE := 1.5
const CARD_ZOOM_WIDE_MIN := 0.7
const CARD_ZOOM_TALL := 0.95
## The range of widths for the piece-type buttons in the tray.
const TRAY_BUTTON_MIN := 100.0
const TRAY_BUTTON_MAX := 170.0

@onready var name_edit: LineEdit = %NameEdit
@onready var points_label: Label = %Points
@onready var army_board: ArmyBoard = %ArmyBoard
@onready var problems_label: Label = %Problems
@onready var tray: GridContainer = %Tray
@onready var card: PieceCard = %Card
@onready var team_button: Button = %TeamToggle
@onready var save_button: Button = %Save
@onready var back_button: Button = %Back
@onready var _layout: VBoxContainer = $Margin/Layout
@onready var _card_scroll: ScrollContainer = %Card.get_parent()
## The piece-type buttons scroll inside this, so on a phone the card below them
## always fits whole.
@onready var _tray_scroll: ScrollContainer = %Tray.get_parent()
## On wide screens the piece card goes beside everything else, in this.
var _wide_box: HBoxContainer
var wide := false

var rules := StandardSetup.create_rules()
var library: ArmyLibrary
## The army being edited: a copy, so leaving without saving changes nothing.
var army: Army
## The piece type chosen in the tray (null if none).
var selected: PieceDef
## Which colour the pieces are drawn in.
var team := Piece.Team.WHITE
var _tray_buttons := {}  # PieceDef -> Button

## Call before adding the screen to the tree. `existing` is null for a new army.
## Where shared armies go (null = the real server; tests use a MemoryBackend).
var backend: OnlineBackend
var share_button: Button
## The pop-up showing a shared army's code (null when not showing).
var share_panel: ModalPanel

func setup(p_library: ArmyLibrary, existing: Army = null) -> void:
	library = p_library
	army = existing.copy() if existing else Army.new()

func _ready() -> void:
	if army == null:
		army = Army.new()
	name_edit.max_length = NAME_MAX_LENGTH
	name_edit.text = army.army_name
	name_edit.text_changed.connect(func(text: String) -> void:
		army.army_name = text
		_refresh())
	PhoneTextInput.attach(name_edit, "Army name")
	# Room for the volume button in the top-right corner.
	%TeamToggle.get_parent().add_child(VolumeControl.make_room())
	army_board.columns = BOARD_WIDTH
	army_board.rows = rules.army_start_rows
	army_board.show_army(army)
	army_board.square_tapped.connect(tap_square)
	army_board.square_right_clicked.connect(remove_at)
	army_board.piece_dropped.connect(drop_piece)
	team_button.pressed.connect(toggle_team)
	save_button.pressed.connect(save)
	# Share sits beside Save (Mac's choice).
	var save_row := HBoxContainer.new()
	save_row.add_theme_constant_override("separation", 12)
	save_button.get_parent().add_child(save_row)
	save_button.get_parent().move_child(save_row, save_button.get_index())
	save_button.reparent(save_row, false)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	share_button = Button.new()
	share_button.text = "Share"
	share_button.custom_minimum_size = Vector2(170, save_button.custom_minimum_size.y)
	share_button.pressed.connect(share)
	save_row.add_child(share_button)
	back_button.pressed.connect(func() -> void: closed.emit())
	_build_tray()
	_wide_box = HBoxContainer.new()
	_wide_box.add_theme_constant_override("separation", 32)
	_wide_box.hide()
	_layout.get_parent().add_child(_wide_box)
	resized.connect(fit_layout)
	army_board.resized.connect(_fit_army_board)
	card.minimum_size_changed.connect(_fit_card)
	resized.connect(_fit_tray)
	_tray_scroll.resized.connect(_fit_tray)
	fit_layout()
	# Start by showing the king (every army needs one).
	var first: PieceDef = _tray_buttons.keys()[0]
	for def: PieceDef in _tray_buttons:
		if def.is_king_type():
			first = def
			break
	card.show_piece(first, team)
	_refresh()

## Choose a piece type in the tray (null to choose nothing). The card switches
## to it; choosing nothing leaves the card as it was.
func select(def: PieceDef) -> void:
	selected = def
	for tray_def in _tray_buttons:
		_tray_buttons[tray_def].set_pressed_no_signal(tray_def == def)
	if def:
		card.show_piece(def, team)
	_refresh()

## The picture on a piece's tray button: a piece that changes form shows the
## form it changes into (Mac: the Werewolf's button shows the wolf); the board
## still shows the piece as it starts.
static func tray_texture(def: PieceDef, team: Piece.Team) -> Texture2D:
	if def.transforms_into:
		return PieceArt.texture_for(def.transforms_into, team)
	return PieceArt.texture_for(def, team)

## Switch the pictures between White and Black.
func toggle_team() -> void:
	team = Piece.Team.BLACK if team == Piece.Team.WHITE else Piece.Team.WHITE
	team_button.text = "White" if team == Piece.Team.WHITE else "Black"
	for def in _tray_buttons:
		_tray_buttons[def].icon = tray_texture(def, team)
		var frame: KingFrame = _tray_buttons[def].get_node_or_null("KingFrame")
		if frame:
			frame.team = team
	army_board.team = team
	if card.def:
		card.show_piece(card.def, team)
	_refresh()

## Tapping a square: an empty square gets the selected piece; a square holding
## the selected type (or any piece, when nothing is selected) is cleared; a
## square holding a different type gets swapped to the selected type.
## Right-clicking a placed piece (PC) takes it out of the army.
func remove_at(square: Vector2i) -> void:
	army.remove_at(square)
	_refresh()

## A piece type dragged from the tray onto a square: it becomes the chosen type
## and goes there (replacing whatever was there).
func drop_piece(def: PieceDef, square: Vector2i) -> void:
	select(def)
	army.place(def, square)
	_refresh()

## On touch screens a drag that starts on a tray button scrolls the tray, so
## dragging a piece out needs a short hold first (milliseconds).
const DRAG_HOLD_MS := 250
## When the current press on a tray button started.
var _press_ms := 0

## What dragging a tray button carries (null = don't drag; scroll instead).
func _tray_drag(def: PieceDef, button: Button) -> Variant:
	if DisplayServer.is_touchscreen_available() and Time.get_ticks_msec() - _press_ms < DRAG_HOLD_MS:
		return null
	if absi(_tray_scroll.scroll_vertical - _scroll_at_press) > 4:
		return null
	# The piece's picture follows the pointer, centred on it.
	var holder := Control.new()
	var picture := TextureRect.new()
	picture.texture = tray_texture(def, team)
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var side := army_board.size.y / army_board.rows
	picture.size = Vector2(side, side)
	picture.position = -picture.size / 2
	holder.add_child(picture)
	button.set_drag_preview(holder)
	return {"tray_piece": def}

func tap_square(square: Vector2i) -> void:
	var current := army.def_at(square)
	if current != null and (selected == null or current == selected):
		army.remove_at(square)
	elif selected != null:
		army.place(selected, square)
	_refresh()

## Everything stopping the army from being saved (empty = ready to save).
func problems() -> PackedStringArray:
	var found := army.problems(rules, BOARD_WIDTH)
	if army.army_name.strip_edges().is_empty():
		found.append("Give the army a name.")
	if library and army.library_path.is_empty() and library.is_full():
		found.append("You already have %d saved armies; delete one first." % ArmyLibrary.MAX_ARMIES)
	return found

func save() -> void:
	if not problems().is_empty():
		return
	army.army_name = army.army_name.strip_edges()
	if library.save(army) == OK:
		saved.emit(army)

## Share: choose between a code (the army is uploaded to the server) and
## text to send yourself (nothing is uploaded).
func share() -> void:
	if share_button.disabled:
		return
	share_panel = ModalPanel.new("Share army")
	share_panel.add_text("Get a short code for your friend to type in (the army is uploaded to the game's server), or copy the army as text to send them yourself.")
	share_panel.add_button("Get a code", func() -> void:
		share_panel.close()
		share_code())
	share_panel.add_button("Copy as text", func() -> void:
		share_panel.close()
		share_text())
	share_panel.add_button("Cancel", share_panel.close, &"GhostButton")
	add_child(share_panel)

## The army as it is now, named as it will be saved.
func _army_to_share() -> Army:
	var copy := army.copy()
	copy.army_name = army.army_name.strip_edges()
	return copy

## Show the army as a line of text (ArmyShare.to_text), with a Copy button.
func share_text() -> void:
	share_panel = ModalPanel.new("Share army")
	share_panel.add_text("Send this to your friend. They tap Import army in My armies and paste it in:")
	var text := ArmyShare.to_text(_army_to_share(), rules, BOARD_WIDTH)
	var shown := share_panel.add_text(text, 24)
	shown.name = "ArmyText"
	var copy_button := share_panel.add_button("Copy text", func() -> void: DisplayServer.clipboard_set(text), &"AccentButton")
	copy_button.pressed.connect(func() -> void: copy_button.text = "Copied!")
	share_panel.add_button("Done", share_panel.close, &"GhostButton")
	add_child(share_panel)

## Upload the army as it is now and show its code, for a friend to import.
func share_code() -> void:
	share_panel = ModalPanel.new("Share army")
	var message := share_panel.add_text("Uploading...")
	add_child(share_panel)
	var server := backend if backend else _real_server()
	var result: Dictionary = await ArmyShare.share(server, _army_to_share())
	if not is_instance_valid(share_panel):
		return
	if not result.ok:
		message.text = "Couldn't share the army: " + result.error
		share_panel.add_button("Close", share_panel.close, &"GhostButton")
		return
	message.text = "Your friend taps Import army in My armies and types this code:"
	var code := share_panel.add_text(result.code, 64)
	code.name = "Code"
	var copy_button := share_panel.add_button("Copy code", func() -> void: DisplayServer.clipboard_set(result.code), &"AccentButton")
	copy_button.pressed.connect(func() -> void: copy_button.text = "Copied!")
	share_panel.add_button("Done", share_panel.close, &"GhostButton")

func _real_server() -> OnlineBackend:
	var server := SupabaseBackend.new()
	add_child(server)
	return server

## The card beside the builder on a wide screen, below it on a tall one.
func fit_layout() -> void:
	var now_wide := ScreenShape.is_wide(size)
	if now_wide != wide:
		wide = now_wide
		if wide:
			ScreenShape.move_to([_layout, _card_scroll], _wide_box)
			_layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_card_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		else:
			ScreenShape.move_to([_layout], _wide_box.get_parent())
			ScreenShape.move_to([_card_scroll], _layout)
			_layout.move_child(_card_scroll, save_button.get_parent().get_index())
		_wide_box.visible = wide
	_fit_card()
	# The piece card: bigger beside the board (there's room), a little bigger below it.
	card.set_zoom(_wide_card_zoom() if wide else CARD_ZOOM_TALL)
	_fit_tray()

## The card's zoom in its own column on a wide screen: shaped like the in-game
## pop-up (PieceInfo.CARD_WIDTH wide at zoom 1), in steps of 0.05 so resizing
## the window doesn't re-measure the card for every pixel.
func _wide_card_zoom() -> float:
	return clampf(snappedf(_column_width() / PieceInfo.CARD_WIDTH, 0.05), CARD_ZOOM_WIDE_MIN, CARD_ZOOM_WIDE)

## The width of one column: the whole screen inside the margins, or half of it
## on a wide screen. Measured from the screen, not from what's inside (that
## grows with the tray buttons and the card, so it would feed back on itself).
func _column_width() -> float:
	var margin: MarginContainer = _wide_box.get_parent()
	var column := size.x - margin.get_theme_constant("margin_left") - margin.get_theme_constant("margin_right")
	if wide:
		column = (column - _wide_box.get_theme_constant("separation")) / 2
	return column

## The army board's squares are sized by the space it's given: make it tall
## enough for square squares across the full width (within limits).
func _fit_army_board() -> void:
	var square := army_board.size.x / army_board.columns
	army_board.custom_minimum_size.y = clampf(square * army_board.rows, 150, 400)

## Tall screens: the card gets all the height it needs (no scrolling) and the
## tray above it scrolls instead. The height is the tallest any piece's card
## gets, so the card stays one size whichever piece is shown. Wide screens: the
## card has its own column.
func _fit_card() -> void:
	if wide:
		_card_scroll.custom_minimum_size.y = 0
		_card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		_card_scroll.custom_minimum_size.y = maxf(_card_height, card.get_combined_minimum_size().y)
		_card_scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_measure_card.call_deferred()

## The tallest card for the current width and zoom (0 until measured).
var _card_height := 0.0
var _measured_for := ""

func _measure_card() -> void:
	var width := card.size.x
	if width <= 0:
		return
	var key := "%d|%.2f" % [roundi(width), card.zoom]
	if key == _measured_for:
		return
	_measured_for = key
	var tallest := await PieceCard.tallest_height(self, _tray_buttons.keys(), width, card.zoom)
	if key != _measured_for or not is_inside_tree():
		return
	_card_height = tallest
	if not wide:
		_card_scroll.custom_minimum_size.y = maxf(_card_height, card.get_combined_minimum_size().y)

## The piece-type buttons share the column's width equally (within limits), so
## they're as big as the space allows.
func _fit_tray() -> void:
	# Leave room for the tray's scroll bar.
	var column := _column_width() - _tray_scroll.get_v_scroll_bar().get_combined_minimum_size().x - 4
	var gap := tray.get_theme_constant("h_separation")
	var width := floorf((column - gap * (tray.columns - 1)) / tray.columns)
	width = clampf(width, TRAY_BUTTON_MIN, TRAY_BUTTON_MAX)
	# Tall screens: buttons a little shorter if that lets two whole rows show
	# above the card (Mac's request), but never squatter than 3:4.
	var height := width * 1.1
	if not wide:
		var two_rows := (_tray_scroll.size.y - tray.get_theme_constant("v_separation")) / 2
		height = clampf(floorf(two_rows), width * 0.75, width * 1.1)
	for button: Button in _tray_buttons.values():
		button.custom_minimum_size = Vector2(width, height)
		button.add_theme_font_size_override("font_size", roundi(width * 0.14))
		var cost: CostBadge = button.get_node_or_null("Cost")
		if cost == null:
			continue
		cost.font_size = roundi(width * 0.18)
		_place_cost(cost)

func _build_tray() -> void:
	var defs := PieceCatalog.all_defs()
	# Alphabetical (Mac's choice).
	defs.sort_custom(func(a: PieceDef, b: PieceDef) -> bool: return a.display_name < b.display_name)
	for def in defs:
		var button := Button.new()
		button.toggle_mode = true
		# Kings on gold, royal pieces on royal purple, pawn types on green (Mac's
		# design); the chosen type gets a bright border, so it's obvious what
		# you're placing.
		# The chosen type gets a gold border, so it's obvious what you're placing;
		# little room inside, so the picture is as big as it can be (Mac).
		UiStyle.picture_button(button)
		button.set_drag_forwarding(func(_at: Vector2) -> Variant: return _tray_drag(def, button), Callable(), Callable())
		button.icon = tray_texture(def, team)
		button.expand_icon = true
		# The text never makes the button wider than the size it's given.
		button.clip_text = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.custom_minimum_size = Vector2(TRAY_BUTTON_MIN, roundf(TRAY_BUTTON_MIN * 1.1))
		button.add_theme_font_size_override("font_size", 17)
		# Drags that start on a button scroll the tray (the button passes them on);
		# a press that turned into a scroll doesn't select the piece.
		button.mouse_filter = Control.MOUSE_FILTER_PASS
		button.button_down.connect(func() -> void:
			_scroll_at_press = _tray_scroll.scroll_vertical
			_press_ms = Time.get_ticks_msec())
		button.toggled.connect(func(on: bool) -> void:
			if absi(_tray_scroll.scroll_vertical - _scroll_at_press) > 4:
				button.set_pressed_no_signal(not on)
				return
			select(def if on else null))
		_add_cost_label(button, def)
		tray.add_child(button)
		_tray_buttons[def] = button

func _refresh() -> void:
	points_label.text = "Points: %s / %s" % [Army.format_points(army.cost()), Army.format_points(rules.army_budget)]
	var found := problems()
	problems_label.text = "\n".join(found)
	problems_label.visible = not found.is_empty()
	save_button.disabled = not found.is_empty()
	if share_button:
		# Only legal, named armies can be shared (being full doesn't matter here).
		share_button.disabled = not army.problems(rules, BOARD_WIDTH).is_empty() or army.army_name.strip_edges().is_empty()
	for def in _tray_buttons:
		var button: Button = _tray_buttons[def]
		# No picture yet: show the piece's name too.
		button.text = def.display_name if button.icon == null else ""
		# None left to add: faded out.
		var limit := Army.max_copies(def, rules)
		button.modulate.a = 0.4 if limit >= 0 and army.count_of(def) >= limit else 1.0
	army_board.highlighted = _allowed_squares()
	army_board.queue_redraw()

## The cost in the button's bottom-right corner, e.g. "3", on a small dark
## badge. Kings (free, exactly one per army) have no badge: their box gets a
## swirled border instead (KingFrame, Mac's design).
func _add_cost_label(button: Button, def: PieceDef) -> void:
	if def.is_king_type():
		var frame := KingFrame.new()
		frame.name = "KingFrame"
		frame.team = team
		button.add_child(frame)
		return
	var cost := CostBadge.new()
	cost.name = "Cost"
	cost.text = Army.format_points(def.value)
	button.add_child(cost)
	_place_cost(cost)

## Keep the badge in the button's bottom-right corner (after it changes size).
static func _place_cost(cost: CostBadge) -> void:
	cost.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 5)
	cost.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	cost.grow_vertical = Control.GROW_DIRECTION_BEGIN

## Where the selected piece type may go (only the king is restricted).
func _allowed_squares() -> Array[Vector2i]:
	var squares: Array[Vector2i] = []
	if selected and selected.is_king_type():
		for file in Army.king_files(BOARD_WIDTH):
			squares.append(Vector2i(file, 0))
	return squares
