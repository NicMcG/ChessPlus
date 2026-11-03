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
	_bold = UiStyle.bold()
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
##
## Only what changed is made again: the moves still the same keep their
## buttons, a side line that grew gets buttons for its new moves only, and the
## rest are just put in order. Building the whole list again whenever a side
## line showed (hundreds of controls in a long game, for every move tried in a
## side line) took a quarter of a second or more.
func show_moves(entries: Array, result: String, viewing: int, tip: String,
		side_lines: Array = [], shown_line := -1, shown_line_ply := 0) -> void:
	_tip.text = tip
	_tip.visible = entries.is_empty() and side_lines.is_empty()
	_sync_entries(entries)
	_sync_boxes(side_lines)
	_arrange(entries, side_lines)
	_show_viewed(viewing, shown_line, shown_line_ply)
	set_marks(marks)
	_result.text = result
	_result.visible = result != ""

## The main line's entries the list shows, and each one's controls (its turn
## number and a spacer if it starts a turn, then its button).
var _shown_entries: Array = []
var _entry_nodes: Array = []

## Keep the controls of the entries that are still the same, and make (or take
## off) the ones at the end. _arrange puts them in place.
func _sync_entries(entries: Array) -> void:
	var same := 0
	var limit := mini(_shown_entries.size(), entries.size())
	while same < limit and _shown_entries[same] == entries[same]:
		same += 1
	for i in range(_entry_nodes.size() - 1, same - 1, -1):
		for node: Node in _entry_nodes[i]:
			_free(node)
	_entry_nodes.resize(same)
	buttons.resize(same)
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
		buttons.append(button)
		_entry_nodes.append(nodes)
	_shown_entries = entries

## Each side line's box as shown: {"line" (the side line it shows), "from",
## "entries" (the ones shown), "row" (their buttons), "node" (the box), "flow"
## (holding its moves), "remove" (its x button)}.
var _boxes: Array = []

## Keep each side line's box if it shows the start of that line, adding
## buttons for its new moves; otherwise make it again. Boxes go with their
## line, so removing one side line leaves the others' boxes as they are.
func _sync_boxes(side_lines: Array) -> void:
	var old := _boxes
	_boxes = []
	for line: Dictionary in side_lines:
		var box: Dictionary = {}
		for i in old.size():
			if is_same(old[i]["line"], line):
				box = old[i]
				old.remove_at(i)
				break
		if not box.is_empty() and not _box_shows_start_of(box, line):
			_free(box["node"])
			box = {}
		if box.is_empty():
			box = _side_line_box()
			box["line"] = line
			box["from"] = line["from"]
		_boxes.append(box)
		var entries: Array = line["entries"]
		var row: Array[Button] = box["row"]
		var flow: HFlowContainer = box["flow"]
		for i in range(box["entries"].size(), entries.size()):
			if entries[i][0] != "":
				var number := _number_label(entries[i][0])
				number.custom_minimum_size.x = 0
				number.add_theme_font_size_override("font_size", LINE_FONT_SIZE)
				flow.add_child(number)
			var moves_played := i + 1
			var button := _move_button(entries[i][2], entries[i][1], false, func() -> void: line_tapped.emit(_box_index(box), moves_played), true)
			button.set_meta("number", entries[i][0])
			flow.add_child(button)
			row.append(button)
		flow.move_child(box["remove"], -1)
		box["entries"] = entries.duplicate()
	for box: Dictionary in old:
		_free(box["node"])
	side_buttons = _boxes.map(func(box: Dictionary) -> Array[Button]: return box["row"])

## Which side line `box` shows now (its index), or -1.
func _box_index(box: Dictionary) -> int:
	for i in _boxes.size():
		if is_same(_boxes[i], box):
			return i
	return -1

static func _box_shows_start_of(box: Dictionary, line: Dictionary) -> bool:
	var shown: Array = box["entries"]
	var entries: Array = line["entries"]
	if box["from"] != line["from"] or shown.size() > entries.size():
		return false
	for i in shown.size():
		if shown[i] != entries[i]:
			return false
	return true

## Put everything in order: the main line's turns in grids, split after each
## turn holding a move a side line replaces, with that side line's box there
## (the last turn for one from the end of the game).
func _arrange(entries: Array, side_lines: Array) -> void:
	var after_entry := {}
	for index in side_lines.size():
		var at := mini(int(side_lines[index]["from"]), entries.size() - 1)
		if not after_entry.has(at):
			after_entry[at] = []
		after_entry[at].append(index)
	# The list's parts in order: side lines (their index) and runs of the main
	# line's entries (Vector2i(first, end)).
	var parts: Array = []
	parts.append_array(after_entry.get(-1, []))
	var run_start := 0
	var turn_start := 0
	for i in entries.size():
		if entries[i][0] != "":
			turn_start = i
		# At the end of each turn: the side lines branching in it.
		if i < entries.size() - 1 and entries[i + 1][0] == "":
			continue
		var boxes: Array = []
		for j in range(turn_start, i + 1):
			boxes.append_array(after_entry.get(j, []))
		if boxes.is_empty():
			continue
		boxes.sort()
		parts.append(Vector2i(run_start, i + 1))
		parts.append_array(boxes)
		run_start = i + 1
	parts.append(Vector2i(run_start, entries.size()))
	var wanted: Array[Node] = []
	var grid_count := 0
	for part: Variant in parts:
		if part is Vector2i:
			if grid_count == _grids.size():
				_grids.append(_new_grid())
			_fill_grid(_grids[grid_count], part.x, part.y)
			wanted.append(_grids[grid_count])
			grid_count += 1
		else:
			wanted.append(_boxes[part]["node"])
	for k in range(_grids.size() - 1, grid_count - 1, -1):
		_free(_grids[k])
	_grids.resize(grid_count)
	for i in wanted.size():
		var node := wanted[i]
		if node.get_parent() != _body:
			if node.get_parent():
				node.get_parent().remove_child(node)
			_body.add_child(node)
		if node.get_index() != i:
			_body.move_child(node, i)

## Give `grid` the controls of entries first .. end - 1, keeping the ones
## already in place.
func _fill_grid(grid: GridContainer, first: int, end: int) -> void:
	var wanted: Array[Node] = []
	for i in range(first, end):
		wanted.append_array(_entry_nodes[i])
	var children := grid.get_children()
	var same := 0
	var limit := mini(children.size(), wanted.size())
	while same < limit and children[same] == wanted[same]:
		same += 1
	for k in range(children.size() - 1, same - 1, -1):
		grid.remove_child(children[k])
	for k in range(same, wanted.size()):
		var node := wanted[k]
		if node.get_parent():
			node.get_parent().remove_child(node)
		grid.add_child(node)

## Highlight the move being looked at (and only that one).
func _show_viewed(viewing: int, shown_line: int, shown_line_ply: int) -> void:
	var button: Button = null
	if shown_line >= 0 and shown_line < side_buttons.size():
		var row: Array = side_buttons[shown_line]
		if shown_line_ply > 0 and shown_line_ply <= row.size():
			button = row[shown_line_ply - 1]
	elif viewing > 0 and viewing <= buttons.size():
		button = buttons[viewing - 1]
	if button == viewed_button:
		return
	if is_instance_valid(viewed_button):
		_style_button(viewed_button, false)
	viewed_button = button
	if button:
		_style_button(button, true)

static func _free(node: Node) -> void:
	if node.get_parent():
		node.get_parent().remove_child(node)
	node.queue_free()

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
	return grid

## One side line's box (wrapping onto more rows if it's long), empty but for
## its remove button: _sync_boxes adds the moves before that.
func _side_line_box() -> Dictionary:
	var row: Array[Button] = []
	var result := {"entries": [], "row": row}
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
	var remove := Button.new()
	remove.name = "Remove"
	remove.text = "×"
	remove.tooltip_text = "Remove this side line"
	remove.focus_mode = Control.FOCUS_NONE
	remove.flat = true
	remove.add_theme_font_size_override("font_size", FONT_SIZE)
	remove.custom_minimum_size = Vector2(LINE_ICON_SIZE + 8, LINE_ICON_SIZE + 8)
	remove.mouse_filter = Control.MOUSE_FILTER_PASS
	remove.pressed.connect(func() -> void: line_removed.emit(_box_index(result)))
	flow.add_child(remove)
	result["node"] = margin
	result["flow"] = flow
	result["remove"] = remove
	return result

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
