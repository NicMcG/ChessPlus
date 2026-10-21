class_name MoveList
extends VBoxContainer

## The game's moves as a vertical list, one turn per line:
##   1.  [pawn] e4     [pawn] e5
##   2.  [knight] f3   [knight] c6
## in picture notation (Notation.picture): small piece pictures and icons
## instead of letters. Move numbers are bold. Each move is a button: hovering
## highlights it, and
## tapping it asks to see the position after that move (move_tapped). The move
## being looked at stays highlighted. After a game, mistakes and blunders
## (MoveQuality) get an orange ? or a red ?? after the move.
##
## Side lines (moves tried from an earlier position, see the game screen) show
## as an indented box under the turn they branch from, e.g.
##   12.  [knight] f3   [knight] c6
##        [ 12... [pawn] d6  13. [bishop] c4  x ]
## Their moves are buttons too (line_tapped), and x removes the line.

## The player tapped a move: show the position after the first `moves_played` moves.
signal move_tapped(moves_played: int)
## The player tapped a move in side line `index`: show the position after its
## first `moves_played` moves.
signal line_tapped(index: int, moves_played: int)
## The player tapped a side line's remove button.
signal line_removed(index: int)

const FONT_SIZE := 26
const NUMBER_WIDTH := 56
const MOVE_WIDTH := 170
## Extra room for a mark after a move.
const MARK_WIDTH := 36
## Piece pictures in the list, and the smaller symbols (capture, check, ...).
const PIECE_ICON_SIZE := 40
const SYMBOL_ICON_SIZE := 30
## Piece pictures sit on a small tile in the board's light colour, so black
## pieces stand out against the dark background too.
const PIECE_TILE := Color("#F0D9B5")
const HOVER_BG := Color(1, 1, 1, 0.12)
const HOVER_TEXT := Color("#FFD75E")
const VIEWED_BG := Color("#B58863")
## Side lines: their box, how far in it starts, and their (smaller) moves.
const LINE_BG := Color(1, 1, 1, 0.07)
const LINE_INDENT := 40
const LINE_FONT_SIZE := 22
const LINE_ICON_SIZE := 32

var _tip: Label
## The main line's turns, in grids (split where a side line's box goes).
var _body: VBoxContainer
var _grids: Array[GridContainer] = []
var _result: Label
var _bold: FontVariation
## The move buttons, in order (button i shows the position after i + 1 moves).
var buttons: Array[Button] = []
## Each side line's move buttons, in order (side_buttons[line][i]: after i + 1
## of its moves).
var side_buttons: Array = []
## The highlighted move button (the position being looked at), or null.
var viewed_button: Button
## Marked moves: moves played (button i is i + 1) -> MoveQuality.Mark.
var marks := {}

func _init() -> void:
	_bold = FontVariation.new()
	_bold.base_font = ThemeDB.fallback_font
	_bold.variation_embolden = 0.9
	_tip = _make_label("")
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(_tip)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 2)
	add_child(_body)
	_result = _make_label("")
	_result.add_theme_font_override("font", _bold)
	add_child(_result)

## Show `entries` (from Notation.numbered_moves); `viewing` is the number of
## moves in the position being looked at (-1 for none). With no moves, shows `tip`.
## `side_lines`: [{"from": main-line moves before it, "entries": its moves as
## from Notation.numbered_moves}, ...]; `shown_line` / `shown_line_ply`: the
## side line and its move being looked at (-1: none).
func show_moves(entries: Array, result: String, viewing: int, tip: String,
		side_lines: Array = [], shown_line := -1, shown_line_ply := 0) -> void:
	_tip.text = tip
	_tip.visible = entries.is_empty() and side_lines.is_empty()
	if side_lines.is_empty():
		_show_main_line(entries, viewing)
	else:
		_rebuild(entries, viewing, side_lines, shown_line, shown_line_ply)
	set_marks(marks)
	_result.text = result
	_result.visible = result != ""

## The entries the list shows (main line only, see _show_main_line), and each
## one's controls (its turn number and a spacer if it starts a turn, then its
## button). Empty after a rebuild with side lines.
var _shown_entries: Array = []
var _entry_nodes: Array = []

## Without side lines: keep the buttons of the moves that are still the same,
## and only add (or take off) the ones at the end. Rebuilding the whole list
## after every move made hundreds of controls each time, which stalled the
## screen late in a long game.
func _show_main_line(entries: Array, viewing: int) -> void:
	if _shown_entries.is_empty():
		_clear()
	var same := 0
	var limit := mini(_shown_entries.size(), entries.size())
	while same < limit and _shown_entries[same] == entries[same]:
		same += 1
	if viewed_button:
		_style_button(viewed_button, false)
		viewed_button = null
	for i in range(_entry_nodes.size() - 1, same - 1, -1):
		for node: Node in _entry_nodes[i]:
			node.get_parent().remove_child(node)
			node.queue_free()
	_entry_nodes.resize(same)
	buttons.resize(same)
	var grid := _grids[0] if not _grids.is_empty() else _new_grid()
	for i in range(same, entries.size()):
		var nodes: Array[Control] = []
		var number: String = entries[i][0]
		# A turn starts with a number. If Black moved first, White's cell is empty.
		if number != "":
			nodes.append(_number_label(number))
			if number.ends_with("..."):
				nodes.append(Control.new())
		var moves_played := i + 1
		var button := _move_button(entries[i][2], entries[i][1], false, func() -> void: move_tapped.emit(moves_played))
		nodes.append(button)
		for node in nodes:
			grid.add_child(node)
		buttons.append(button)
		_entry_nodes.append(nodes)
	_shown_entries = entries
	if viewing > 0 and viewing <= buttons.size():
		viewed_button = buttons[viewing - 1]
		_style_button(viewed_button, true)

## Take everything out of the list.
func _clear() -> void:
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	_grids.clear()
	buttons.clear()
	side_buttons.clear()
	viewed_button = null
	_shown_entries = []
	_entry_nodes.clear()

## With side lines: build the whole list again.
func _rebuild(entries: Array, viewing: int, side_lines: Array, shown_line: int, shown_line_ply: int) -> void:
	_clear()
	side_buttons.resize(side_lines.size())
	# Each side line's box goes after the turn holding the move it replaces
	# (the last turn for one from the end of the game).
	var after_entry := {}
	for index in side_lines.size():
		var at := mini(int(side_lines[index]["from"]), entries.size() - 1)
		if not after_entry.has(at):
			after_entry[at] = []
		after_entry[at].append(index)
	var grid := _new_grid()
	for index: int in after_entry.get(-1, []):
		_body.add_child(_side_line_box(side_lines[index], index, shown_line_ply if index == shown_line else -1))
	var turn_start := 0
	for i in entries.size():
		var number: String = entries[i][0]
		# A turn starts with a number. If Black moved first, White's cell is empty.
		if number != "":
			turn_start = i
			grid.add_child(_number_label(number))
			if number.ends_with("..."):
				grid.add_child(Control.new())
		var viewed := i + 1 == viewing
		var moves_played := i + 1
		var button := _move_button(entries[i][2], entries[i][1], viewed, func() -> void: move_tapped.emit(moves_played))
		grid.add_child(button)
		buttons.append(button)
		if viewed:
			viewed_button = button
		# At the end of each turn: the side lines branching in it.
		if i < entries.size() - 1 and entries[i + 1][0] == "":
			continue
		var boxes: Array = []
		for j in range(turn_start, i + 1):
			boxes.append_array(after_entry.get(j, []))
		if boxes.is_empty():
			continue
		boxes.sort()
		for index: int in boxes:
			_body.add_child(_side_line_box(side_lines[index], index, shown_line_ply if index == shown_line else -1))
		grid = _new_grid()

## Mark mistakes and blunders (moves played -> MoveQuality.Mark; {} for none).
func set_marks(p_marks: Dictionary) -> void:
	marks = p_marks
	for i in buttons.size():
		var label: Label = buttons[i].get_meta("mark_label")
		var mark: MoveQuality.Mark = marks.get(i + 1, MoveQuality.Mark.NONE)
		label.text = MoveQuality.sign_of(mark)
		label.visible = mark != MoveQuality.Mark.NONE
		if label.visible:
			label.add_theme_color_override("font_color", MoveQuality.color_of(mark))
		buttons[i].custom_minimum_size.x = MOVE_WIDTH + (MARK_WIDTH if label.visible else 0)

## The mark shown after each move: "?", "??" or "" (for tests).
func mark_signs() -> PackedStringArray:
	var signs: PackedStringArray = []
	for button in buttons:
		var label: Label = button.get_meta("mark_label")
		signs.append(label.text if label.visible else "")
	return signs

func _new_grid() -> GridContainer:
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 2)
	_body.add_child(grid)
	_grids.append(grid)
	return grid

## One side line: its moves in a box (wrapping onto more rows if it's long),
## then a remove button. `shown_ply`: its move being looked at (-1: none).
func _side_line_box(line: Dictionary, index: int, shown_ply: int) -> Control:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", LINE_INDENT)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.mouse_filter = Control.MOUSE_FILTER_PASS
	var box := PanelContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := _box(LINE_BG)
	style.set_content_margin_all(4)
	box.add_theme_stylebox_override("panel", style)
	margin.add_child(box)
	var flow := HFlowContainer.new()
	flow.add_theme_constant_override("h_separation", 2)
	flow.add_theme_constant_override("v_separation", 2)
	flow.mouse_filter = Control.MOUSE_FILTER_PASS
	box.add_child(flow)
	var row: Array[Button] = []
	var entries: Array = line["entries"]
	for i in entries.size():
		if entries[i][0] != "":
			var number := _number_label(entries[i][0])
			number.custom_minimum_size.x = 0
			number.add_theme_font_size_override("font_size", LINE_FONT_SIZE)
			flow.add_child(number)
		var viewed := i + 1 == shown_ply
		var moves_played := i + 1
		var button := _move_button(entries[i][2], entries[i][1], viewed, func() -> void: line_tapped.emit(index, moves_played), true)
		button.set_meta("number", entries[i][0])
		flow.add_child(button)
		row.append(button)
		if viewed:
			viewed_button = button
	var remove := Button.new()
	remove.name = "Remove"
	remove.text = "×"
	remove.tooltip_text = "Remove this side line"
	remove.focus_mode = Control.FOCUS_NONE
	remove.flat = true
	remove.add_theme_font_size_override("font_size", FONT_SIZE)
	remove.custom_minimum_size = Vector2(LINE_ICON_SIZE + 8, LINE_ICON_SIZE + 8)
	remove.mouse_filter = Control.MOUSE_FILTER_PASS
	remove.pressed.connect(func() -> void: line_removed.emit(index))
	flow.add_child(remove)
	side_buttons[index] = row
	return margin

## Side line `index` as plain text, e.g. "12... d6 13. Bc4" (for tests).
func side_line_text(index: int) -> String:
	var parts: PackedStringArray = []
	for button: Button in side_buttons[index]:
		var number: String = button.get_meta("number", "")
		if number != "":
			parts.append(number)
		parts.append(button.get_meta("notation"))
	return " ".join(parts)

## A side line's remove button (for tests).
func remove_button(index: int) -> Button:
	if side_buttons[index].is_empty():
		return null
	return side_buttons[index][0].get_parent().get_node("Remove")

## Each line of the list as plain text, e.g. ["1. e4 e5", "2. Nf3"] (for tests;
## each move button keeps its text notation as "notation" metadata).
func lines() -> PackedStringArray:
	var result: PackedStringArray = []
	var line := ""
	var children: Array[Node] = []
	for grid in _grids:
		children.append_array(grid.get_children())
	for child in children:
		var text := ""
		if child is Label:
			if line != "":
				result.append(line.strip_edges())
			line = ""
			text = child.text
		elif child is Button:
			text = child.get_meta("notation")
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

## A move: a button showing its picture notation (`text`, its text notation,
## is kept as metadata for tests). Tapping it calls `on_tap`. Side lines' moves
## are `small`.
func _move_button(parts: Array, text: String, viewed: bool, on_tap: Callable, small := false) -> Button:
	var button := Button.new()
	button.set_meta("notation", text)
	button.focus_mode = Control.FOCUS_NONE
	var icon_size := LINE_ICON_SIZE if small else PIECE_ICON_SIZE
	button.custom_minimum_size = Vector2(0 if small else MOVE_WIDTH, icon_size + 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 6
	row.alignment = BoxContainer.ALIGNMENT_BEGIN
	for part: Dictionary in parts:
		row.add_child(_part(part, small))
	# A mistake's ? or a blunder's ?? (hidden until set_marks).
	var mark := _make_label("")
	mark.add_theme_font_override("font", _bold)
	mark.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mark.hide()
	mark.set_meta("keep_color", true)
	row.add_child(mark)
	button.set_meta("mark_label", mark)
	button.add_child(row)
	if small:
		# The row is drawn over the button, so the button takes its width (known
		# once the row's text has its font, in the tree).
		row.minimum_size_changed.connect(func() -> void:
			button.custom_minimum_size.x = row.get_combined_minimum_size().x + 14)
	button.mouse_entered.connect(func() -> void: _tint(row, HOVER_TEXT))
	button.mouse_exited.connect(func() -> void: _tint(row, Color.WHITE))
	_style_button(button, viewed)
	button.add_theme_stylebox_override("pressed", _box(HOVER_BG))
	button.add_theme_stylebox_override("hover_pressed", _box(HOVER_BG))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", HOVER_TEXT)
	button.add_theme_color_override("font_pressed_color", HOVER_TEXT)
	# A drag that starts on a move scrolls the list (the button passes it on to
	# the scroll container around the list); a press that turned into a scroll
	# doesn't count as a tap.
	button.mouse_filter = Control.MOUSE_FILTER_PASS
	button.button_down.connect(func() -> void: _scroll_at_press = _scrolled())
	button.pressed.connect(func() -> void:
		if absi(_scrolled() - _scroll_at_press) > 4:
			return
		on_tap.call())
	return button

## A move button's background: highlighted if it's the move being looked at.
func _style_button(button: Button, viewed: bool) -> void:
	button.add_theme_stylebox_override("normal", _box(VIEWED_BG if viewed else Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _box(VIEWED_BG if viewed else HOVER_BG))

## Where the list was scrolled to when a move was pressed.
var _scroll_at_press := 0

## How far the scroll container holding the list is scrolled (0 if there's none).
func _scrolled() -> int:
	var scroll := get_parent() as ScrollContainer
	return scroll.scroll_vertical if scroll else 0

## One part of a move's picture notation as a control (`small` in side lines).
func _part(part: Dictionary, small: bool) -> Control:
	var icon_size := LINE_ICON_SIZE if small else PIECE_ICON_SIZE
	if part.has("text"):
		var label := _make_label(part.text)
		if small:
			label.add_theme_font_size_override("font_size", LINE_FONT_SIZE)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return label
	var picture := TextureRect.new()
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	picture.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if part.has("icon"):
		picture.texture = load("res://art/icons/%s.png" % part.icon)
		var symbol_size := SYMBOL_ICON_SIZE * icon_size / PIECE_ICON_SIZE
		picture.custom_minimum_size = Vector2(symbol_size, symbol_size)
		return picture
	picture.texture = PieceArt.texture_for(part.piece, part.team)
	if picture.texture == null:
		# No picture for this piece yet: its letter(s).
		picture.free()
		var label := _make_label(part.piece.symbol)
		label.add_theme_font_override("font", _bold)
		if small:
			label.add_theme_font_size_override("font_size", LINE_FONT_SIZE)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return label
	picture.custom_minimum_size = Vector2(icon_size, icon_size)
	var tile := PanelContainer.new()
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tile.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var style := StyleBoxFlat.new()
	style.bg_color = PIECE_TILE
	style.set_corner_radius_all(6)
	tile.add_theme_stylebox_override("panel", style)
	tile.add_child(picture)
	return tile

## Hovering turns the text parts gold (not a mistake's or blunder's mark).
static func _tint(row: HBoxContainer, color: Color) -> void:
	for child in row.get_children():
		if child is Label and not child.has_meta("keep_color"):
			child.add_theme_color_override("font_color", color)

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
