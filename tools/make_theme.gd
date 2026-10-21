extends SceneTree

## Builds the app's look (the project theme, res://scenes/theme.tres) from the
## colours and fonts in UiStyle, and saves it. Every button, list, text box,
## switch and pop-up in the game picks it up. To change the look, change the
## numbers here or in UiStyle, then run this again:
##   "<godot console exe>" --headless --path . -s res://tools/make_theme.gd
##
## Besides the normal kinds of control, the theme has a few named styles
## ("type variations") that a control asks for with theme_type_variation:
##   AccentButton  the gold main button of a screen (Start, Save army...)
##   DangerButton  red text, for things that can't be undone (Delete)
##   ChoiceButton  a toggle that turns gold when on (On/Off, White/Black...)
##   GhostButton   no box until hovered (Back, Settings)
##   TitleLabel    a screen's title
##   HeadingLabel  the small grey label over a choice ("Opponent")
##   MutedLabel    small grey text (counts, tips, credits)
##   DialogTitle   a pop-up's heading
##   CardPanel     a box grouping things on a screen
## The small pictures (the arrow on lists, the switches, ticks, the close cross
## and the Back arrow) are drawn here as SVG, so they stay sharp at any size.

const OUT := "res://scenes/theme.tres"

var theme := Theme.new()

func _initialize() -> void:
	theme.default_font = UiStyle.font(UiStyle.MEDIUM)
	theme.default_font_size = 30
	_buttons()
	_option_button()
	_popup_menu()
	_check_button()
	_line_edit()
	_labels()
	_panels()
	_scroll_bars()
	_tooltip()
	_dialog_window()
	theme.set_icon("back", "UiIcons", _icon(BACK_SVG))
	var error := ResourceSaver.save(theme, OUT)
	print("Saved " + OUT if error == OK else "Could not save %s (error %d)" % [OUT, error])
	UiStyle.clear_cache()
	quit(1 if error != OK else 0)

# --- Buttons -----------------------------------------------------------------

func _buttons() -> void:
	_button_look("Button", UiStyle.SURFACE, UiStyle.SURFACE_HOVER, UiStyle.SURFACE_PRESSED, UiStyle.TEXT)
	theme.set_font("font", "Button", UiStyle.font(UiStyle.SEMIBOLD))
	theme.set_constant("h_separation", "Button", 12)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	# The gold main button.
	_variation("AccentButton", "Button")
	_button_look("AccentButton", UiStyle.ACCENT, UiStyle.ACCENT_HOVER, UiStyle.ACCENT_PRESSED, UiStyle.ON_ACCENT)
	theme.set_font("font", "AccentButton", UiStyle.font(UiStyle.BOLD))
	# Red writing for Delete, filling in red when touched.
	_variation("DangerButton", "Button")
	_button_look("DangerButton", UiStyle.SURFACE, UiStyle.DANGER.darkened(0.35), UiStyle.DANGER.darkened(0.5), UiStyle.DANGER_TEXT)
	for state in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(state, "DangerButton", UiStyle.TEXT)
	# A toggle that turns gold when on (a choice of several, or On/Off).
	_variation("ChoiceButton", "Button")
	_button_look("ChoiceButton", UiStyle.SURFACE, UiStyle.SURFACE_HOVER, UiStyle.ACCENT, UiStyle.TEXT)
	theme.set_stylebox("hover_pressed", "ChoiceButton", _box(UiStyle.ACCENT_HOVER, true))
	theme.set_stylebox("disabled", "ChoiceButton", _box(UiStyle.SURFACE_DISABLED))
	for state in ["font_pressed_color", "font_hover_pressed_color"]:
		theme.set_color(state, "ChoiceButton", UiStyle.ON_ACCENT)
	# No box until touched.
	_variation("GhostButton", "Button")
	_button_look("GhostButton", Color(1, 1, 1, 0), Color(1, 1, 1, 0.08), Color(1, 1, 1, 0.04), UiStyle.TEXT)
	theme.set_stylebox("disabled", "GhostButton", _box(Color(1, 1, 1, 0)))

## The boxes and text colours of a kind of button: normal, hovered, pressed
## (also a toggle that's on), and greyed out.
func _button_look(type: String, normal: Color, hover: Color, pressed: Color, text: Color) -> void:
	theme.set_stylebox("normal", type, _box(normal, true))
	theme.set_stylebox("hover", type, _box(hover, true))
	theme.set_stylebox("pressed", type, _box(pressed, true))
	theme.set_stylebox("hover_pressed", type, _box(pressed.lerp(hover, 0.5), true))
	theme.set_stylebox("disabled", type, _box(UiStyle.SURFACE_DISABLED))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, type, text)
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_hover_pressed_color", "icon_focus_color"]:
		theme.set_color(state, type, text)
	theme.set_color("font_disabled_color", type, UiStyle.TEXT_DISABLED)
	theme.set_color("icon_disabled_color", type, UiStyle.TEXT_DISABLED)

# --- Lists to choose from (OptionButton) --------------------------------------

func _option_button() -> void:
	var type := "OptionButton"
	# Looks like a box to fill in: an edge round it, the arrow at the right.
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var color: Color = {"normal": UiStyle.SURFACE, "hover": UiStyle.SURFACE_HOVER,
				"pressed": UiStyle.SURFACE_PRESSED, "disabled": UiStyle.SURFACE_DISABLED}[state]
		var box := _box(color)
		box.border_color = UiStyle.ACCENT if state == "pressed" else UiStyle.BORDER
		box.set_border_width_all(2 if state == "pressed" else 1)
		box.content_margin_left = 22
		box.content_margin_right = 22
		theme.set_stylebox(state, type, box)
		theme.set_stylebox(state + "_mirrored", type, box)
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_font("font", type, UiStyle.font(UiStyle.MEDIUM))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, type, UiStyle.TEXT)
	theme.set_color("font_disabled_color", type, UiStyle.TEXT_DISABLED)
	theme.set_icon("arrow", type, _icon(CHEVRON_SVG))
	theme.set_constant("arrow_margin", type, 18)
	theme.set_constant("modulate_arrow", type, 1)

## The list that opens from an OptionButton (also any other pop-up menu).
func _popup_menu() -> void:
	var type := "PopupMenu"
	var panel := UiStyle.dialog_box(10)
	panel.set_corner_radius_all(UiStyle.RADIUS)
	panel.shadow_size = 18
	theme.set_stylebox("panel", type, panel)
	var hover := _box(Color(UiStyle.ACCENT, 0.16))
	hover.set_corner_radius_all(10)
	theme.set_stylebox("hover", type, hover)
	var line := StyleBoxLine.new()
	line.color = UiStyle.BORDER
	line.thickness = 1
	line.grow_begin = -8
	line.grow_end = -8
	theme.set_stylebox("separator", type, line)
	theme.set_font("font", type, UiStyle.font(UiStyle.MEDIUM))
	theme.set_font_size("font_size", type, 30)
	theme.set_color("font_color", type, UiStyle.TEXT)
	theme.set_color("font_hover_color", type, UiStyle.TEXT)
	theme.set_color("font_disabled_color", type, UiStyle.TEXT_DISABLED)
	theme.set_constant("v_separation", type, 22)
	theme.set_constant("h_separation", type, 14)
	theme.set_constant("item_start_padding", type, 14)
	theme.set_constant("item_end_padding", type, 18)
	var on := _icon(RADIO_ON_SVG)
	var off := _icon(RADIO_OFF_SVG)
	for name in ["radio_checked", "checked"]:
		theme.set_icon(name, type, on)
		theme.set_icon(name + "_disabled", type, on)
	for name in ["radio_unchecked", "unchecked"]:
		theme.set_icon(name, type, off)
		theme.set_icon(name + "_disabled", type, off)

# --- Switches (CheckButton) ---------------------------------------------------

func _check_button() -> void:
	var type := "CheckButton"
	# A row with the words on the left and a gold switch on the right.
	theme.set_stylebox("normal", type, _box(Color(1, 1, 1, 0), false, 6))
	theme.set_stylebox("hover", type, _box(Color(1, 1, 1, 0.05), false, 6))
	theme.set_stylebox("pressed", type, _box(Color(1, 1, 1, 0), false, 6))
	theme.set_stylebox("hover_pressed", type, _box(Color(1, 1, 1, 0.05), false, 6))
	theme.set_stylebox("disabled", type, _box(Color(1, 1, 1, 0), false, 6))
	theme.set_stylebox("focus", type, StyleBoxEmpty.new())
	theme.set_font("font", type, UiStyle.font(UiStyle.MEDIUM))
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		theme.set_color(state, type, UiStyle.TEXT)
	theme.set_color("font_disabled_color", type, UiStyle.TEXT_DISABLED)
	var on := _icon(SWITCH_ON_SVG)
	var off := _icon(SWITCH_OFF_SVG)
	var on_greyed := _icon(SWITCH_ON_SVG.replace("<g>", "<g opacity=\"0.4\">"))
	var off_greyed := _icon(SWITCH_OFF_SVG.replace("<g>", "<g opacity=\"0.4\">"))
	for suffix in ["", "_mirrored"]:
		theme.set_icon("checked" + suffix, type, on)
		theme.set_icon("unchecked" + suffix, type, off)
		theme.set_icon("checked_disabled" + suffix, type, on_greyed)
		theme.set_icon("unchecked_disabled" + suffix, type, off_greyed)
	theme.set_constant("h_separation", type, 16)

# --- Text boxes ---------------------------------------------------------------

func _line_edit() -> void:
	var type := "LineEdit"
	var field := _box(UiStyle.FIELD)
	field.border_color = UiStyle.BORDER
	field.set_border_width_all(1)
	field.content_margin_left = 20
	field.content_margin_right = 20
	theme.set_stylebox("normal", type, field)
	var read_only := field.duplicate() as StyleBoxFlat
	read_only.bg_color = UiStyle.SURFACE_DISABLED
	theme.set_stylebox("read_only", type, read_only)
	# While typing: a gold edge.
	var focus := StyleBoxFlat.new()
	focus.draw_center = false
	focus.border_color = UiStyle.ACCENT
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(UiStyle.RADIUS)
	focus.anti_aliasing = true
	theme.set_stylebox("focus", type, focus)
	theme.set_font("font", type, UiStyle.font(UiStyle.MEDIUM))
	theme.set_color("font_color", type, UiStyle.TEXT)
	theme.set_color("font_placeholder_color", type, Color("#7E7E86"))
	theme.set_color("font_selected_color", type, UiStyle.TEXT)
	theme.set_color("font_uneditable_color", type, UiStyle.TEXT_MUTED)
	theme.set_color("caret_color", type, UiStyle.ACCENT)
	theme.set_color("selection_color", type, Color(UiStyle.ACCENT, 0.35))
	theme.set_color("clear_button_color", type, UiStyle.TEXT_MUTED)
	theme.set_constant("caret_width", type, 2)

# --- Text ---------------------------------------------------------------------

func _labels() -> void:
	theme.set_color("font_color", "Label", UiStyle.TEXT)
	_variation("TitleLabel", "Label")
	theme.set_font("font", "TitleLabel", UiStyle.font(UiStyle.BOLD))
	theme.set_font_size("font_size", "TitleLabel", 42)
	_variation("HeadingLabel", "Label")
	theme.set_font("font", "HeadingLabel", UiStyle.font(UiStyle.SEMIBOLD))
	theme.set_font_size("font_size", "HeadingLabel", 25)
	theme.set_color("font_color", "HeadingLabel", UiStyle.TEXT_MUTED)
	_variation("MutedLabel", "Label")
	theme.set_font_size("font_size", "MutedLabel", 24)
	theme.set_color("font_color", "MutedLabel", UiStyle.TEXT_MUTED)
	_variation("DialogTitle", "Label")
	theme.set_font("font", "DialogTitle", UiStyle.font(UiStyle.BOLD))
	theme.set_font_size("font_size", "DialogTitle", 38)

# --- Boxes --------------------------------------------------------------------

func _panels() -> void:
	# Plain boxes are pop-ups (piece cards, the promotion choice...).
	theme.set_stylebox("panel", "PanelContainer", UiStyle.dialog_box(24))
	theme.set_stylebox("panel", "Panel", UiStyle.dialog_box(24))
	_variation("CardPanel", "PanelContainer")
	var card := _box(UiStyle.CARD, true, 0)
	card.set_corner_radius_all(UiStyle.RADIUS_LARGE)
	card.set_content_margin_all(22)
	theme.set_stylebox("panel", "CardPanel", card)

func _scroll_bars() -> void:
	# Thin rounded bars that don't get in the way.
	for type in ["VScrollBar", "HScrollBar"]:
		var track := StyleBoxFlat.new()
		track.bg_color = Color(1, 1, 1, 0.03)
		track.set_corner_radius_all(5)
		track.set_content_margin_all(5)
		theme.set_stylebox("scroll", type, track)
		theme.set_stylebox("scroll_focus", type, track)
		for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
			var alpha: float = {"grabber": 0.2, "grabber_highlight": 0.3, "grabber_pressed": 0.4}[state]
			var grabber := StyleBoxFlat.new()
			grabber.bg_color = Color(1, 1, 1, alpha)
			grabber.set_corner_radius_all(5)
			grabber.set_content_margin_all(5)
			theme.set_stylebox(state, type, grabber)
	theme.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())

func _tooltip() -> void:
	var box := _box(Color("#18181B"), false, 14, 10)
	box.border_color = UiStyle.BORDER
	box.set_border_width_all(1)
	box.set_corner_radius_all(10)
	theme.set_stylebox("panel", "TooltipPanel", box)
	theme.set_color("font_color", "TooltipLabel", UiStyle.TEXT)
	theme.set_font_size("font_size", "TooltipLabel", 24)

## Godot's own question boxes (e.g. "Delete this army?").
func _dialog_window() -> void:
	var title_height := 64
	var frame := UiStyle.dialog_box(0)
	frame.expand_margin_left = 20
	frame.expand_margin_right = 20
	frame.expand_margin_bottom = 20
	frame.expand_margin_top = title_height + 12
	theme.set_stylebox("embedded_border", "Window", frame)
	theme.set_stylebox("embedded_unfocused_border", "Window", frame)
	theme.set_font("title_font", "Window", UiStyle.font(UiStyle.BOLD))
	theme.set_font_size("title_font_size", "Window", 32)
	theme.set_color("title_color", "Window", UiStyle.TEXT)
	theme.set_constant("title_height", "Window", title_height)
	var close := _icon(CLOSE_SVG)
	theme.set_icon("close", "Window", close)
	theme.set_icon("close_pressed", "Window", close)
	theme.set_constant("close_h_offset", "Window", 30)
	theme.set_constant("close_v_offset", "Window", 44)
	var inside := StyleBoxEmpty.new()
	inside.set_content_margin_all(12)
	theme.set_stylebox("panel", "AcceptDialog", inside)
	theme.set_constant("buttons_separation", "AcceptDialog", 16)
	theme.set_constant("buttons_min_width", "AcceptDialog", 180)
	theme.set_constant("buttons_min_height", "AcceptDialog", 72)

# --- Helpers ------------------------------------------------------------------

func _variation(name: String, base: String) -> void:
	theme.set_type_variation(name, base)

## A rounded box with room inside; `edge` adds a faint outline that keeps dark
## buttons from melting into the background.
func _box(color: Color, edge := false, margin_y := 12.0, margin_x := 20.0) -> StyleBoxFlat:
	var box := UiStyle.box(color, UiStyle.RADIUS, margin_x, margin_y)
	if edge and color.a > 0:
		box.border_color = UiStyle.BORDER_SOFT
		box.set_border_width_all(1)
	return box

## A sharp picture from SVG text, redrawn at whatever size the screen needs.
func _icon(svg: String) -> DPITexture:
	return DPITexture.create_from_string(svg)

static func _hex(color: Color) -> String:
	return "#" + color.to_html(false)

# --- Pictures (SVG) -----------------------------------------------------------

var CHEVRON_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">
<path d="M8 11 L14 17 L20 11" fill="none" stroke="%s" stroke-width="2.6" stroke-linecap="round" stroke-linejoin="round"/>
</svg>""" % _hex(UiStyle.TEXT_MUTED)

var BACK_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28">
<path d="M17 6.5 L9.5 14 L17 21.5" fill="none" stroke="#FFFFFF" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>
</svg>"""

var CLOSE_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="26" height="26" viewBox="0 0 26 26">
<path d="M7 7 L19 19 M19 7 L7 19" fill="none" stroke="%s" stroke-width="2.6" stroke-linecap="round"/>
</svg>""" % _hex(UiStyle.TEXT_MUTED)

var SWITCH_OFF_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="72" height="42" viewBox="0 0 72 42"><g>
<rect x="2" y="3" width="68" height="36" rx="18" fill="#4D4D54"/>
<circle cx="21" cy="21" r="14" fill="#D9D9DE"/>
</g></svg>"""

var SWITCH_ON_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="72" height="42" viewBox="0 0 72 42"><g>
<rect x="2" y="3" width="68" height="36" rx="18" fill="%s"/>
<circle cx="51" cy="21" r="14" fill="#FFFFFF"/>
</g></svg>""" % _hex(UiStyle.ACCENT)

var RADIO_ON_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 30 30">
<circle cx="15" cy="15" r="11" fill="none" stroke="%s" stroke-width="2.5"/>
<circle cx="15" cy="15" r="6" fill="%s"/>
</svg>""" % [_hex(UiStyle.ACCENT), _hex(UiStyle.ACCENT)]

var RADIO_OFF_SVG := """<svg xmlns="http://www.w3.org/2000/svg" width="30" height="30" viewBox="0 0 30 30">
<circle cx="15" cy="15" r="11" fill="none" stroke="%s" stroke-width="2"/>
</svg>""" % _hex(UiStyle.TEXT_DISABLED)
