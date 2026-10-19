class_name CapturedRow
extends Control

## One player's captures, shown above or below the board (Mac's design): small
## pictures of every enemy piece that's off the board (whoever or whatever took
## it, e.g. a Ram that died capturing counts too), most valuable first, grouped
## by type with copies overlapping; then "+3" if this player is ahead on material
## (the value of the pieces each side still has on the board, kings left out).

## Pieces shown, and this player's material lead in points (0 or less = none shown).
var pieces: Array[Piece] = []
var advantage := 0.0
## A captured Ghost whose player is choosing where it comes back (Haunt): it's
## drawn with a ghostly aura rising off it. Null the rest of the time.
var haunting: Piece:
	set(value):
		haunting = value
		set_process(value != null)
		queue_redraw()

## How far in from the left to start, so the row lines up with the board's edge.
var inset := 0.0:
	set(value):
		inset = value
		queue_redraw()

const ICON_SHARE := 0.9   # Icon size as a share of the row's height.
const OVERLAP := 0.45      # How far the next copy of the same type sits along.

func _init() -> void:
	custom_minimum_size.y = 38
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)

func _process(_delta: float) -> void:
	queue_redraw()

## The haunting Ghost's aura: pale blue light pulsing round it, with wisps
## drifting up off it and fading.
func _draw_aura(rect: Rect2) -> void:
	var seconds := Time.get_ticks_msec() / 1000.0
	var center := rect.get_center()
	var r := rect.size.x * 0.5
	var pulse := 0.5 + 0.5 * sin(seconds * 3.0)
	for ring in 4:
		var k := 1.0 + ring * 0.28 + pulse * 0.12
		draw_circle(center, r * k, Color(0.65, 0.85, 1.0, 0.16 - ring * 0.03))
	for wisp in 5:
		var t := fmod(seconds * 0.6 + wisp * 0.2, 1.0)
		var x := center.x + r * 0.9 * sin(wisp * 2.3 + t * 4.0)
		var y := center.y - r * 0.3 - t * r * 2.2
		draw_circle(Vector2(x, y), r * (0.22 - 0.12 * t), Color(0.8, 0.92, 1.0, 0.5 * sin(PI * t)))

## Show what `team` has captured in `state`.
func show_for(state: GameState, team: Piece.Team) -> void:
	var enemy := Piece.other_team(team)
	pieces.assign(state.lost[enemy].duplicate())
	pieces.sort_custom(func(a: Piece, b: Piece) -> bool:
		if a.def.value != b.def.value:
			return a.def.value > b.def.value
		return a.def.id < b.def.id)
	advantage = material(state, team) - material(state, enemy)
	queue_redraw()

## The points' worth of `team`'s pieces on the board (kings aren't counted).
static func material(state: GameState, team: Piece.Team) -> float:
	var total := 0.0
	for piece: Piece in state.board.pieces_of(team).values():
		if not piece.def.is_king_type():
			total += piece.def.value
	return total

## "+3", "+1.5", or "" when not ahead.
func advantage_text() -> String:
	if advantage <= 0.001:
		return ""
	return "+" + Army.format_points(advantage)

func _draw() -> void:
	var icon := size.y * ICON_SHARE
	var x := inset + 4.0
	var top := (size.y - icon) / 2
	var last_id := ""
	# A light tile behind the pictures, so black pieces show on the dark screen.
	if not pieces.is_empty():
		var width := icon
		var previous := ""
		for piece in pieces:
			if previous != "":
				width += icon * (OVERLAP if piece.def.id == previous else 0.85)
			previous = piece.def.id
		var tile := StyleBoxFlat.new()
		tile.bg_color = Color("#F0D9B5")
		tile.set_corner_radius_all(6)
		draw_style_box(tile, Rect2(inset, 0, width + 8, size.y))
	for piece in pieces:
		if last_id != "":
			x += icon * (OVERLAP if piece.def.id == last_id else 0.85)
		last_id = piece.def.id
		var texture := PieceArt.texture_for(piece.def, piece.team)
		if piece == haunting:
			_draw_aura(Rect2(x, top, icon, icon))
		if texture:
			draw_texture_rect(texture, Rect2(x, top, icon, icon), false)
		else:
			draw_string(ThemeDB.fallback_font, Vector2(x, top + icon * 0.8), piece.def.symbol, HORIZONTAL_ALIGNMENT_LEFT, -1, int(icon * 0.7), Color.WHITE)
	if not pieces.is_empty():
		x += icon + 14
	var text := advantage_text()
	if text != "":
		var font := ThemeDB.fallback_font
		var font_size := int(size.y * 0.62)
		draw_string(font, Vector2(x, size.y / 2 + font_size * 0.36), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color("#e6e6e6"))
