class_name PieceCard
extends VBoxContainer

## Everything about one piece type, in a compact card:
##   header: its picture(s), name, cost and type(s)
##   a mini board showing how it moves, with a legend
##   its keywords as coloured boxes
##   "Special": any rule the rest can't show (e.g. how the cannon captures)
## Used in the army builder (always showing the chosen piece) and in games
## (inside PieceInfo, when you hold a piece).

## Each keyword's box colour.
const KEYWORD_COLORS := {
	"Jump": Color("#2F6FD6"),
	"Castle": Color("#B86E1F"),
	"Promote": Color("#2E9E4F"),
	"Shield": Color("#7B4BC9"),
}

var def: PieceDef
var team := Piece.Team.WHITE

## Show `p_def`. Safe to call before or after the card is on screen.
func show_piece(p_def: PieceDef, p_team := Piece.Team.WHITE) -> void:
	def = p_def
	team = p_team
	if is_node_ready():
		_refresh()

func _ready() -> void:
	if def:
		_refresh()

## E.g. "Free  ·  King, Royal" or "3 points".
static func details_text(p_def: PieceDef) -> String:
	var points := "Free"
	if p_def.value != 0:
		points = "%s point%s" % [Army.format_points(p_def.value), "" if is_equal_approx(p_def.value, 1.0) else "s"]
	var types := type_names(p_def)
	return points if types.is_empty() else "%s  ·  %s" % [points, ", ".join(types)]

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

func _refresh() -> void:
	for child in %Pictures.get_children():
		child.queue_free()
	for texture in PieceArt.all_textures(def, team):
		var picture := TextureRect.new()
		picture.texture = texture
		picture.custom_minimum_size = Vector2(88, 88)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		%Pictures.add_child(picture)
	%Name.text = def.display_name
	%Details.text = details_text(def)
	%GuideBoard.show_piece(def, team)
	_fill_legend()
	_fill_keywords()
	var special := special_rules(def)
	%Special.visible = not special.is_empty()
	%SpecialText.text = "\n".join(special)

func _fill_legend() -> void:
	for child in %Legend.get_children():
		child.queue_free()
	for kind in PieceGuideBoard.legend_kinds(PieceGuide.guide(def)):
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		var icon := LegendIcon.new()
		icon.kind = kind
		icon.custom_minimum_size = Vector2(36, 36)
		var label := Label.new()
		label.text = PieceGuideBoard.LEGEND[kind]
		label.add_theme_font_size_override("font_size", 20)
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
		var box := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = KEYWORD_COLORS[keyword]
		style.set_corner_radius_all(8)
		style.content_margin_left = 14
		style.content_margin_right = 14
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		box.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = keyword
		label.add_theme_font_size_override("font_size", 22)
		box.add_child(label)
		%Keywords.add_child(box)

## One legend icon.
class LegendIcon extends Control:
	var kind := ""

	func _draw() -> void:
		PieceGuideBoard.draw_legend_icon(self, Rect2(Vector2.ZERO, size), kind)
