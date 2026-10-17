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

@onready var name_edit: LineEdit = %NameEdit
@onready var points_label: Label = %Points
@onready var army_board: ArmyBoard = %ArmyBoard
@onready var problems_label: Label = %Problems
@onready var tray: GridContainer = %Tray
@onready var card: PieceCard = %Card
@onready var team_button: Button = %TeamToggle
@onready var save_button: Button = %Save
@onready var back_button: Button = %Back

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
	army_board.columns = BOARD_WIDTH
	army_board.rows = rules.army_start_rows
	army_board.show_army(army)
	army_board.square_tapped.connect(tap_square)
	team_button.pressed.connect(toggle_team)
	save_button.pressed.connect(save)
	back_button.pressed.connect(func() -> void: closed.emit())
	_build_tray()
	# Start by showing the first piece in the tray (the king).
	card.show_piece(_tray_buttons.keys()[0], team)
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

## Switch the pictures between White and Black.
func toggle_team() -> void:
	team = Piece.Team.BLACK if team == Piece.Team.WHITE else Piece.Team.WHITE
	team_button.text = "White" if team == Piece.Team.WHITE else "Black"
	for def in _tray_buttons:
		_tray_buttons[def].icon = PieceArt.texture_for(def, team)
	army_board.team = team
	if card.def:
		card.show_piece(card.def, team)
	_refresh()

## Tapping a square: an empty square gets the selected piece; a square holding
## the selected type (or any piece, when nothing is selected) is cleared; a
## square holding a different type gets swapped to the selected type.
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

func _build_tray() -> void:
	var defs := PieceCatalog.all_defs()
	# King first, then the most expensive pieces.
	defs.sort_custom(func(a: PieceDef, b: PieceDef) -> bool:
		if a.is_king_type() != b.is_king_type():
			return a.is_king_type()
		return a.value > b.value)
	# The chosen piece type gets a gold border, so it's obvious what you're placing.
	var chosen_style := StyleBoxFlat.new()
	chosen_style.bg_color = Color(0.25, 0.25, 0.27)
	chosen_style.set_border_width_all(4)
	chosen_style.border_color = Color(0.95, 0.75, 0.2)
	for def in defs:
		var button := Button.new()
		button.toggle_mode = true
		button.add_theme_stylebox_override("pressed", chosen_style)
		button.add_theme_stylebox_override("hover_pressed", chosen_style)
		button.icon = PieceArt.texture_for(def, team)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.custom_minimum_size = Vector2(106, 118)
		button.add_theme_font_size_override("font_size", 17)
		button.toggled.connect(func(on: bool) -> void: select(def if on else null))
		tray.add_child(button)
		_tray_buttons[def] = button

func _refresh() -> void:
	points_label.text = "Points: %s / %s" % [Army.format_points(army.cost()), Army.format_points(rules.army_budget)]
	var found := problems()
	problems_label.text = "\n".join(found)
	problems_label.visible = not found.is_empty()
	save_button.disabled = not found.is_empty()
	for def in _tray_buttons:
		_tray_buttons[def].text = _tray_detail(def)
	army_board.highlighted = _allowed_squares()
	army_board.queue_redraw()

## The cost and how many more can be added, e.g. "3 pts · 1 left".
func _tray_detail(def: PieceDef) -> String:
	var points := "%s pt%s" % [Army.format_points(def.value), "" if is_equal_approx(def.value, 1.0) else "s"]
	var limit := Army.max_copies(def, rules)
	if limit < 0:
		return points
	return "%s · %d left" % [points, maxi(limit - army.count_of(def), 0)]

## Where the selected piece type may go (only the king is restricted).
func _allowed_squares() -> Array[Vector2i]:
	var squares: Array[Vector2i] = []
	if selected and selected.is_king_type():
		for file in Army.king_files(BOARD_WIDTH):
			squares.append(Vector2i(file, 0))
	return squares
