class_name PieceInfo
extends Control

## The piece guide card: picture, name, cost, a mini board showing how the piece
## moves, a legend for the markers, and its special rules in plain words.
## Open it with PieceInfo.open(parent, def, team, rules); tap Close or anywhere
## outside the card to close it.

signal closed

const SCENE_PATH := "res://scenes/common/piece_info.tscn"

## Legend lines, in the order they're listed: (flags to draw, text).
const LEGEND := [
	[PieceGuide.MOVE | PieceGuide.CAPTURE, "Moves or captures here"],
	[PieceGuide.MOVE, "Moves here, but can't capture here"],
	[PieceGuide.CAPTURE, "Captures here, but can't just move here"],
	[PieceGuide.MOVE | PieceGuide.FIRST_MOVE, "Only on its first move"],
	[PieceGuide.HOP_CAPTURE, "Captures here by jumping exactly one piece"],
]

var def: PieceDef
var team := Piece.Team.WHITE
var rules: GameRules

## Show the card for `def` on top of `parent` (usually the current screen).
static func open(parent: Node, p_def: PieceDef, p_team := Piece.Team.WHITE, p_rules: GameRules = null) -> PieceInfo:
	var info: PieceInfo = load(SCENE_PATH).instantiate()
	info.def = p_def
	info.team = p_team
	info.rules = p_rules if p_rules else StandardSetup.create_rules()
	parent.add_child(info)
	return info

func _ready() -> void:
	%Picture.texture = PieceArt.texture_for(def, team)
	%Name.text = def.display_name
	%Cost.text = cost_text(def, rules)
	%GuideBoard.show_piece(def, team)
	_fill_legend()
	%Rules.text = "\n\n".join(describe(def))
	%Close.pressed.connect(close)
	%Dim.gui_input.connect(func(event: InputEvent) -> void:
		var press := event as InputEventMouseButton
		if press and press.pressed:
			close())

func close() -> void:
	closed.emit()
	queue_free()

## E.g. "3 points · up to 2 per army".
static func cost_text(p_def: PieceDef, p_rules: GameRules) -> String:
	var points := "Free" if p_def.value == 0 else "%s point%s" % [Army.format_points(p_def.value), "" if is_equal_approx(p_def.value, 1.0) else "s"]
	var limit := Army.max_copies(p_def, p_rules)
	var how_many := "any number per army"
	if p_def.is_king_type():
		how_many = "exactly one per army"
	elif limit >= 0:
		how_many = "up to %d per army" % limit
	return "%s  ·  %s" % [points, how_many]

## The piece's special rules, one plain-English paragraph each.
static func describe(p_def: PieceDef) -> PackedStringArray:
	var lines: PackedStringArray = []
	if p_def.move_rules.any(func(r: MoveRule) -> bool: return r.captures_by_hopping):
		lines.append("Captures by jumping: it jumps over exactly one piece (either side's) in a straight line and takes the first enemy beyond it. With nothing to jump, it can't capture.")
	if p_def.is_king_type():
		lines.append("King: if it's checkmated, you lose. Every army has exactly one, starting in the middle of the back row. It can castle with a Castle piece in a back corner.")
	elif p_def.is_royal_type():
		lines.append("Royal: an army can have only one royal piece besides its king.")
	if p_def.is_pawn_type():
		lines.append("Pawn: any number per army. When it reaches the far end it must turn into another piece. It can capture, and be captured, en passant. Moving it resets the 50-move count.")
	if p_def.has_jump():
		lines.append("Jump: it leaps straight to its square, so pieces in between can't block it.")
	if p_def.has_castle():
		lines.append("Castle: the king can castle with it while it's still in its back corner.")
	if p_def.has_promote():
		lines.append("Promote: when it reaches the far end it must turn into another piece (any non-pawn, non-king piece that started the game).")
	if p_def.has_shield():
		lines.append("Shield: the first capture only breaks its shield, and the attacker stays where it was. The second capture takes it. The shield never comes back.")
	if lines.is_empty():
		lines.append("No special rules.")
	return lines

func _fill_legend() -> void:
	var used := PieceGuide.pattern(def).values()
	for entry in LEGEND:
		var flags: int = entry[0]
		if not used.any(func(f: int) -> bool: return _legend_matches(f, flags)):
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var icon := MarkerIcon.new()
		icon.flags = flags
		icon.custom_minimum_size = Vector2(40, 40)
		var label := Label.new()
		label.text = entry[1]
		label.add_theme_font_size_override("font_size", 22)
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		row.add_child(icon)
		row.add_child(label)
		%Legend.add_child(row)

## Does a square marked `square_flags` use the legend entry `legend_flags`?
static func _legend_matches(square_flags: int, legend_flags: int) -> bool:
	if legend_flags & PieceGuide.FIRST_MOVE:
		return square_flags & PieceGuide.FIRST_MOVE != 0
	if legend_flags == PieceGuide.HOP_CAPTURE:
		return square_flags & PieceGuide.HOP_CAPTURE != 0
	var plain := square_flags & (PieceGuide.MOVE | PieceGuide.CAPTURE)
	return square_flags & PieceGuide.FIRST_MOVE == 0 and plain == legend_flags

## One legend marker, drawn on a light square.
class MarkerIcon extends Control:
	var flags := 0

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, PieceGuideBoard.LIGHT_SQUARE)
		PieceGuideBoard.draw_marker(self, rect, flags)
