class_name UiStyle
extends RefCounted

## The look of the whole app in one place: its colours and fonts. The project
## theme (res://scenes/theme.tres, made from these by tools/make_theme.gd) uses
## them for every button, list and box; screens and pop-ups built in code use
## them too, so everything matches.

## The dark grey background behind every screen (Mac likes it), with the
## gentle light-to-dark fade drawn over it (see Backdrop).
const BACKGROUND := Color("#2B2B2E")
const BACKGROUND_TOP := Color("#323236")
const BACKGROUND_BOTTOM := Color("#242427")
## Buttons, lists and boxes: a step lighter than the background.
const SURFACE := Color("#3A3A3F")
const SURFACE_HOVER := Color("#45454B")
const SURFACE_PRESSED := Color("#323236")
const SURFACE_DISABLED := Color("#303033")
## Grouped settings on a screen (a "card").
const CARD := Color("#333337")
## Pop-ups (results, questions, piece cards): lighter still, above everything.
const DIALOG := Color("#38383D")
## Text boxes are sunk into the page: darker than it.
const FIELD := Color("#212124")
## Thin edges round boxes.
const BORDER := Color("#4A4A50")
const BORDER_SOFT := Color(1, 1, 1, 0.06)
## Behind pop-ups, the screen is dimmed by this.
const SCRIM := Color(0.04, 0.04, 0.05, 0.66)

const TEXT := Color("#F2F2F4")
const TEXT_MUTED := Color("#A9A9B1")
const TEXT_DISABLED := Color("#6C6C73")

## The gold accent (Mac's choice): main buttons, switches, what's selected.
const ACCENT := Color("#F2C14E")
const ACCENT_HOVER := Color("#F7CF6E")
const ACCENT_PRESSED := Color("#D9A836")
## Dark text on gold.
const ON_ACCENT := Color("#2A2108")
## Gold text on the dark background (also used for highlights in the move list).
const ACCENT_TEXT := Color("#FFD75E")

## Warnings and things that can't be undone (Delete, Resign).
const DANGER := Color("#E5534B")
const DANGER_TEXT := Color("#FF8A80")

## Rounded corners: buttons and boxes, then pop-ups.
const RADIUS := 14
const RADIUS_LARGE := 20

## The app's font (Mac's choice): Inter, one file holding every weight.
const INTER := preload("res://art/fonts/Inter-Variable.ttf")
const REGULAR := 400
const MEDIUM := 500
const SEMIBOLD := 600
const BOLD := 700
const EXTRABOLD := 800

static var _fonts := {}

## Inter at `weight` (400 regular ... 800 extra bold). The same font object
## comes back for the same weight.
static func font(weight := MEDIUM) -> FontVariation:
	if not _fonts.has(weight):
		var variation := FontVariation.new()
		variation.base_font = INTER
		variation.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_fonts[weight] = variation
	return _fonts[weight]

## Forget the fonts made so far (the test runner empties every cache before
## quitting, so anything left over is a real leak).
static func clear_cache() -> void:
	_fonts.clear()

## The bold font, for headings and move numbers.
static func bold() -> FontVariation:
	return font(BOLD)

## Draw text the same way the project's default font does on this computer:
## project.godot asks Windows for its sharper (LCD) text smoothing. That
## setting only reaches Godot's built-in font, so it's copied to Inter here.
static func apply_font_smoothing() -> void:
	var inter: FontFile = INTER
	inter.antialiasing = ProjectSettings.get_setting("gui/theme/default_font_antialiasing", TextServer.FONT_ANTIALIASING_GRAY)
	inter.hinting = ProjectSettings.get_setting("gui/theme/default_font_hinting", TextServer.HINTING_LIGHT)

## A rounded box: the shape of every button and panel.
static func box(color: Color, radius := RADIUS, margin_x := 20.0, margin_y := 12.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = margin_x
	style.content_margin_right = margin_x
	style.content_margin_top = margin_y
	style.content_margin_bottom = margin_y
	style.anti_aliasing = true
	return style

## The boxes for a button that shows a piece's picture (the army builder's and
## testing mode's trays): little room inside, so the picture fills it.
## The chosen one gets a gold outline.
static func picture_button(button: Button) -> void:
	var looks := {"normal": SURFACE, "hover": SURFACE_HOVER, "disabled": SURFACE_DISABLED}
	for state: String in looks:
		var box := box(looks[state], RADIUS, 4, 4)
		box.border_color = BORDER_SOFT
		box.set_border_width_all(1)
		button.add_theme_stylebox_override(state, box)
	var chosen := box(SURFACE_HOVER, RADIUS, 4, 4)
	chosen.border_color = ACCENT
	chosen.set_border_width_all(4)
	button.add_theme_stylebox_override("pressed", chosen)
	button.add_theme_stylebox_override("hover_pressed", chosen)

## A pop-up's box: lighter than the screen, a thin edge and a soft shadow.
static func dialog_box(margin := 28.0) -> StyleBoxFlat:
	var style := box(DIALOG, RADIUS_LARGE, margin, margin)
	style.border_color = BORDER
	style.set_border_width_all(1)
	style.shadow_color = Color(0, 0, 0, 0.45)
	style.shadow_size = 28
	style.shadow_offset = Vector2(0, 10)
	return style
