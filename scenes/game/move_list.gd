class_name MoveList
extends VBoxContainer

## The game's moves as a vertical list, one turn per line:
##   1.  e4    e5
##   2.  Nf3   Nc6
## Move numbers are bold. Each move is a button: hovering highlights it, and
## tapping it asks to see the position after that move (move_tapped). The move
## being looked at stays highlighted.

## The player tapped a move: show the position after the first `moves_played` moves.
signal move_tapped(moves_played: int)

const FONT_SIZE := 26
const NUMBER_WIDTH := 56
const MOVE_WIDTH := 120
const HOVER_BG := Color(1, 1, 1, 0.12)
const HOVER_TEXT := Color("#FFD75E")
const VIEWED_BG := Color("#B58863")

var _tip: Label
var _grid: GridContainer
var _result: Label
var _bold: FontVariation
## The move buttons, in order (button i shows the position after i + 1 moves).
var buttons: Array[Button] = []

func _init() -> void:
	_bold = FontVariation.new()
	_bold.base_font = ThemeDB.fallback_font
	_bold.variation_embolden = 0.9
	_tip = _make_label("")
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_tip)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 2)
	add_child(_grid)
	_result = _make_label("")
	_result.add_theme_font_override("font", _bold)
	add_child(_result)

## Show `entries` (from Notation.numbered_moves); `viewing` is the number of
## moves in the position being looked at (-1 for none). With no moves, shows `tip`.
func show_moves(entries: Array, result: String, viewing: int, tip: String) -> void:
	_tip.text = tip
	_tip.visible = entries.is_empty()
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	buttons.clear()
	for i in entries.size():
		var number: String = entries[i][0]
		# A turn starts with a number. If Black moved first, White's cell is empty.
		if number != "":
			_grid.add_child(_number_label(number))
			if number.ends_with("..."):
				_grid.add_child(Control.new())
		var button := _move_button(entries[i][1], i + 1, i + 1 == viewing)
		_grid.add_child(button)
		buttons.append(button)
	_result.text = result
	_result.visible = result != ""

## Each line of the list as plain text, e.g. ["1. e4 e5", "2. Nf3"] (for tests).
func lines() -> PackedStringArray:
	var result: PackedStringArray = []
	var line := ""
	for child in _grid.get_children():
		var text := ""
		if child is Label:
			if line != "":
				result.append(line.strip_edges())
			line = ""
			text = child.text
		elif child is Button:
			text = child.text
		if text != "":
			line += text + " "
	if line != "":
		result.append(line.strip_edges())
	return result

func _make_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	return label

func _number_label(text: String) -> Label:
	var label := _make_label(text)
	label.add_theme_font_override("font", _bold)
	label.custom_minimum_size.x = NUMBER_WIDTH
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	return label

func _move_button(text: String, moves_played: int, viewed: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size.x = MOVE_WIDTH
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	button.add_theme_stylebox_override("normal", _box(VIEWED_BG if viewed else Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _box(VIEWED_BG if viewed else HOVER_BG))
	button.add_theme_stylebox_override("pressed", _box(HOVER_BG))
	button.add_theme_stylebox_override("hover_pressed", _box(HOVER_BG))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", HOVER_TEXT)
	button.add_theme_color_override("font_pressed_color", HOVER_TEXT)
	button.pressed.connect(func() -> void: move_tapped.emit(moves_played))
	return button

## A button background: a rounded box in `color`.
static func _box(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(6)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 2
	box.content_margin_bottom = 2
	return box
