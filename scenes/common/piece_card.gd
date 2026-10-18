class_name PieceCard
extends VBoxContainer

## Everything about one piece type, in a compact card:
##   header: its picture(s), name, cost and type(s) (types in italics)
##   a mini board showing how it moves, with a legend
##   its keywords as coloured boxes (in capitals)
##   "Special": any rule the rest can't show (e.g. how the cannon captures)
## Hovering over a type or keyword (tapping, on a phone) shows a short
## explanation in a bubble.
## Used in the army builder (always showing the chosen piece) and in games
## (inside PieceInfo, when you hold a piece).

## Each keyword's box colour and text colour.
const KEYWORD_COLORS := {
	"Jump": [Color("#F2A51F"), Color("#2A1A00")],
	"Castle": [Color("#8C8C8C"), Color.WHITE],
	"Promote": [Color("#7B4BC9"), Color.WHITE],
	"Shield": [Color("#8FD0F5"), Color("#0B2A3D")],
}

## The short explanation shown for each type and keyword.
const EXPLANATIONS := {
	"King": "Your most important piece: if it's checkmated, you lose. Every army has exactly one, starting in the middle of the back row. It can castle.",
	"Royal": "An army can have only one royal piece besides its king.",
	"Pawn": "Any number per army. It must turn into another piece when it reaches the far end. It can capture, and be captured, en passant. Moving it resets the 50-move count.",
	"Jump": "Leaps straight to its square, so pieces in between can't block it.",
	"Castle": "The king can castle with it while it's still in its back corner.",
	"Promote": "Must turn into another piece when it reaches the far end (any non-pawn, non-king piece that started the game).",
	"Shield": "The first capture only breaks its shield, and the attacker stays where it was. The second capture takes it. The shield never comes back.",
}

const ITALIC_FONT := preload("res://art/fonts/OpenSans-Italic.ttf")

var def: PieceDef
var team := Piece.Team.WHITE
## How big the card is drawn: 1 = normal (the pop-up in games); the army builder
## uses more. Change it with set_zoom.
var zoom := 1.0
## The explanation bubble, and the type/keyword it's showing (null if hidden).
var tooltip: PanelContainer
var tooltip_owner: Control

## Show `p_def`. Safe to call before or after the card is on screen.
func show_piece(p_def: PieceDef, p_team := Piece.Team.WHITE) -> void:
	def = p_def
	team = p_team
	if is_node_ready():
		_refresh()

func _ready() -> void:
	_make_tooltip()
	_apply_zoom()
	if def:
		_refresh()

## Draw the card bigger (or smaller): 1.5 = everything half as big again.
func set_zoom(p_zoom: float) -> void:
	if is_equal_approx(p_zoom, zoom):
		return
	zoom = p_zoom
	if is_node_ready():
		_apply_zoom()
		if def:
			_refresh()

## A size at the current zoom.
func _z(value: float) -> int:
	return roundi(value * zoom)

## Sizes of the parts that come from the scene file.
func _apply_zoom() -> void:
	%Name.add_theme_font_size_override("font_size", _z(40))
	%GuideBoard.custom_minimum_size = Vector2(_z(220), _z(220))
	$Special/SpecialTitle.add_theme_font_size_override("font_size", _z(26))
	%SpecialText.add_theme_font_size_override("font_size", _z(22))
	var tip_label: Label = tooltip.get_child(0)
	tip_label.custom_minimum_size = Vector2(_z(420), 0)
	tip_label.add_theme_font_size_override("font_size", _z(22))

## E.g. "Free", "1 point", "3 points".
static func cost_text(p_def: PieceDef) -> String:
	if p_def.value == 0:
		return "Free"
	return "%s point%s" % [Army.format_points(p_def.value), "" if is_equal_approx(p_def.value, 1.0) else "s"]

static func type_names(p_def: PieceDef) -> PackedStringArray:
	var names: PackedStringArray = []
	if p_def.is_king_type():
		names.append("King")
	if p_def.is_royal_type():
		names.append("Royal")
	if p_def.is_pawn_type():
		names.append("Pawn")
	return names

static func keyword_names(p_def: PieceDef) -> PackedStringArray:
	var names: PackedStringArray = []
	if p_def.has_jump():
		names.append("Jump")
	if p_def.has_castle():
		names.append("Castle")
	if p_def.has_promote():
		names.append("Promote")
	if p_def.has_shield():
		names.append("Shield")
	return names

## Rules that the types, keywords and picture can't show.
static func special_rules(p_def: PieceDef) -> PackedStringArray:
	var rules: PackedStringArray = []
	if p_def.move_rules.any(func(r: MoveRule) -> bool: return r.captures_by_hopping):
		rules.append("Captures by jumping over exactly one piece (either side's) in a straight line, taking the first enemy beyond it. With nothing to jump over, it can't capture.")
	return rules

## Show the explanation bubble for `tag` (a type or keyword) just below `item`.
## Showing it again for the same item hides it (so a second tap closes it).
func show_tooltip(item: Control, tag: String) -> void:
	if tooltip_owner == item and tooltip.visible:
		hide_tooltip()
		return
	tooltip_owner = item
	tooltip.get_child(0).text = EXPLANATIONS[tag]
	tooltip.reset_size()
	tooltip.visible = true
	# Below the type/keyword, kept inside the screen; above it if there's no room.
	var screen := get_viewport_rect().size
	var pos := item.global_position + Vector2(0, item.size.y + 6)
	pos.x = clampf(pos.x, 8, screen.x - tooltip.size.x - 8)
	if pos.y + tooltip.size.y > screen.y - 8:
		pos.y = item.global_position.y - tooltip.size.y - 6
	tooltip.global_position = pos

func hide_tooltip() -> void:
	tooltip_owner = null
	if tooltip:
		tooltip.visible = false

func _make_tooltip() -> void:
	tooltip = PanelContainer.new()
	tooltip.top_level = true  # Drawn over everything, not squeezed into the card.
	tooltip.z_index = 100
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.09, 0.96)
	style.border_color = Color(0.6, 0.6, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(12)
	tooltip.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(420, 0)
	label.add_theme_font_size_override("font_size", 22)
	tooltip.add_child(label)
	add_child(tooltip)

## Make `item` show `tag`'s explanation on hover, and on tap (for phones).
func _explain_on_hover(item: Control, tag: String) -> void:
	item.mouse_filter = Control.MOUSE_FILTER_STOP
	item.mouse_entered.connect(func() -> void:
		if tooltip_owner != item:
			show_tooltip(item, tag))
	item.mouse_exited.connect(func() -> void:
		if tooltip_owner == item:
			hide_tooltip())
	item.gui_input.connect(func(event: InputEvent) -> void:
		var press := event as InputEventMouseButton
		if press and press.pressed and press.button_index == MOUSE_BUTTON_LEFT:
			show_tooltip(item, tag))

func _refresh() -> void:
	hide_tooltip()
	for child in %Pictures.get_children():
		child.queue_free()
	for texture in PieceArt.all_textures(def, team):
		var picture := TextureRect.new()
		picture.texture = texture
		picture.custom_minimum_size = Vector2(_z(88), _z(88))
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		%Pictures.add_child(picture)
	%Name.text = def.display_name
	_fill_details()
	%GuideBoard.show_piece(def, team)
	_fill_legend()
	_fill_keywords()
	var special := special_rules(def)
	%Special.visible = not special.is_empty()
	%SpecialText.text = "\n".join(special)

## "3 points" followed by the types in italics, e.g. "Free · King, Royal".
func _fill_details() -> void:
	for child in %Details.get_children():
		child.queue_free()
	%Details.add_child(_detail_label(cost_text(def)))
	var types := type_names(def)
	if types.is_empty():
		return
	%Details.add_child(_detail_label("·"))
	for i in types.size():
		var label := _detail_label(types[i] + ("," if i < types.size() - 1 else ""))
		label.add_theme_font_override("font", _italic_font())
		_explain_on_hover(label, types[i])
		%Details.add_child(label)

func _detail_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", _z(24))
	label.add_theme_color_override("font_color", Color(0.78, 0.78, 0.78))
	return label

## Open Sans Italic (res://art/fonts/, the italic partner of Godot's built-in
## font), at the same semi-bold weight as the normal text. Bundled, so it looks
## the same on PC, phones and in browsers. (Slanting the normal font made the
## letters jiggle instead.)
func _italic_font() -> Font:
	var italic := FontVariation.new()
	italic.base_font = ITALIC_FONT
	italic.variation_opentype = {"wght": 600}
	return italic

func _fill_legend() -> void:
	for child in %Legend.get_children():
		child.queue_free()
	for kind in PieceGuideBoard.legend_kinds(PieceGuide.guide(def)):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon := LegendIcon.new()
		icon.kind = kind
		icon.custom_minimum_size = Vector2(_z(36), _z(36))
		var label := Label.new()
		label.text = PieceGuideBoard.LEGEND[kind]
		label.add_theme_font_size_override("font_size", _z(20))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon)
		row.add_child(label)
		%Legend.add_child(row)

func _fill_keywords() -> void:
	for child in %Keywords.get_children():
		child.queue_free()
	var names := keyword_names(def)
	%Keywords.visible = not names.is_empty()
	for keyword in names:
		var colors: Array = KEYWORD_COLORS[keyword]
		var box := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = colors[0]
		style.set_corner_radius_all(8)
		style.content_margin_left = _z(14)
		style.content_margin_right = _z(14)
		style.content_margin_top = _z(4)
		style.content_margin_bottom = _z(4)
		box.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = keyword.to_upper()
		label.add_theme_font_size_override("font_size", _z(22))
		label.add_theme_color_override("font_color", colors[1])
		box.add_child(label)
		_explain_on_hover(box, keyword)
		%Keywords.add_child(box)

## One legend icon.
class LegendIcon extends Control:
	var kind := ""

	func _draw() -> void:
		PieceGuideBoard.draw_legend_icon(self, Rect2(Vector2.ZERO, size), kind)
