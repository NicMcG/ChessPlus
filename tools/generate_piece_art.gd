extends SceneTree

## Draws the piece art as SVG files: one per style, team and piece, e.g.
## res://art/pieces/classic/white_knight.svg, plus res://art/pieces/preview.html
## to compare the styles in a web browser.
##
## Run it with:
##   "<godot console exe>" --headless --path . -s res://tools/generate_piece_art.gd
## To tune a style, change its colours below and run it again.
##
## All drawings use a 100 x 100 canvas, y pointing down. SVG is vector art, so it
## stays sharp at any size; Godot turns it into a texture when importing.

const OUT_DIR := "res://art/pieces/"
const PIECES: Array[String] = ["pawn", "knight", "bishop", "rook", "queen", "king"]
const TEAMS: Array[String] = ["white", "black"]
## Pixel size Godot imports each SVG at. Big enough to stay crisp on phone screens.
const IMPORT_SIZE := 256

# --- Colours: tune these -------------------------------------------------------

const CLASSIC_COLORS := {
	"white": {"fill": "#F7F3E8", "line": "#222222", "detail": "#222222"},
	"black": {"fill": "#2F2F33", "line": "#111111", "detail": "#E8E2D4"},
}
const FLAT_COLORS := {
	"white": {"main": "#F4EAD5", "shade": "#DCCBA8", "detail": "#8A6E4B", "edge": "#7A5E3E"},
	"black": {"main": "#3E4656", "shade": "#2C3240", "detail": "#C9D1DE", "edge": "#1A1D24"},
}
const TOKEN_COLORS := {
	"white": {"disc": "#FBF7EE", "ring": "#B8892E", "emblem": "#2B2B2B"},
	"black": {"disc": "#26282E", "ring": "#B8892E", "emblem": "#F1E9D8"},
}
## Board colours used in the preview page (the classic light and dark squares).
const LIGHT_SQUARE := "#F0D9B5"
const DARK_SQUARE := "#B58863"

# --- Classic: traditional Staunton-style silhouettes with an outline -----------

const FOOT := '<path d="M22 90 L78 90 L78 85 C78 82 75 80 72 80 L28 80 C25 80 22 82 22 85 Z"/>'
const ROYAL_BODY := '<path d="M37 63 C36 70 32 75 30 80 L70 80 C68 75 64 70 63 63 Z"/>'
const ROYAL_BAND := '<rect x="31" y="58" width="38" height="5" rx="2.5"/>'

## Each piece: "parts" are filled shapes drawn back to front; "details" are small
## marks (eye, slit) drawn in the contrasting detail colour.
const CLASSIC_SHAPES := {
	"pawn": {
		"parts": [
			FOOT,
			'<path d="M40 45 C40 58 32 68 30 80 L70 80 C68 68 60 58 60 45 Z"/>',
			'<rect x="34" y="40" width="32" height="5" rx="2.5"/>',
			'<circle cx="50" cy="27" r="11"/>',
		],
		"details": [],
	},
	"rook": {
		"parts": [
			FOOT,
			'<path d="M35 37 L65 37 L68 80 L32 80 Z"/>',
			'<rect x="31" y="32" width="38" height="5" rx="1"/>',
			'<path d="M28 14 L38 14 L38 21 L45 21 L45 14 L55 14 L55 21 L62 21 L62 14 L72 14 L72 32 L28 32 Z"/>',
		],
		"details": [],
	},
	"bishop": {
		"parts": [
			FOOT,
			'<path d="M41 57 C41 66 34 72 31 80 L69 80 C66 72 59 66 59 57 Z"/>',
			'<rect x="36" y="52" width="28" height="5" rx="2.5"/>',
			'<path d="M50 17 C62 26 66 40 59 52 L41 52 C34 40 38 26 50 17 Z"/>',
			'<circle cx="50" cy="12" r="4.5"/>',
		],
		"details": [
			'<path d="M55 27 L46 40" fill="none" stroke-width="3" stroke-linecap="round"/>',
		],
	},
	"knight": {
		"parts": [
			FOOT,
			'<path d="M32 80 C33 68 38 60 45 52 C39 54 32 57 26 55 C20 53 17 47 21 42 C27 34 35 24 45 16 L49 7 L54 15 C65 20 73 34 72 52 C71 62 69 71 70 80 Z"/>',
		],
		"details": [
			'<circle cx="43" cy="26" r="2.6" stroke="none"/>',
			'<circle cx="24" cy="47" r="1.6" stroke="none"/>',
			'<path d="M57 19 C66 29 68 44 66 62" fill="none" stroke-width="2" stroke-linecap="round"/>',
		],
	},
	"queen": {
		"parts": [
			FOOT,
			ROYAL_BODY,
			ROYAL_BAND,
			'<path d="M30 58 L22 28 L32 44 L36 22 L43 42 L50 18 L57 42 L64 22 L68 44 L78 28 L70 58 Z"/>',
			'<circle cx="22" cy="26" r="4"/>',
			'<circle cx="36" cy="20" r="4"/>',
			'<circle cx="50" cy="15" r="4"/>',
			'<circle cx="64" cy="20" r="4"/>',
			'<circle cx="78" cy="26" r="4"/>',
		],
		"details": [],
	},
	"king": {
		"parts": [
			FOOT,
			ROYAL_BODY,
			ROYAL_BAND,
			'<path d="M31 58 C25 44 34 30 50 30 C66 30 75 44 69 58 Z"/>',
			'<path d="M47 6 L53 6 L53 12 L59 12 L59 18 L53 18 L53 27 L47 27 L47 18 L41 18 L41 12 L47 12 Z"/>',
		],
		"details": [],
	},
}

# --- Flat: simple geometric shapes, shaded on the right half, thin edge ---------

const FLAT_BASE := '<rect x="24" y="78" width="52" height="10" rx="4"/>'

const FLAT_SHAPES := {
	"pawn": {
		"parts": [
			FLAT_BASE,
			'<polygon points="39,48 61,48 68,78 32,78"/>',
			'<circle cx="50" cy="33" r="13"/>',
		],
		"details": [],
	},
	"rook": {
		"parts": [
			FLAT_BASE,
			'<rect x="34" y="34" width="32" height="44"/>',
			'<polygon points="28,16 39,16 39,24 45,24 45,16 55,16 55,24 61,24 61,16 72,16 72,34 28,34"/>',
		],
		"details": [],
	},
	"bishop": {
		"parts": [
			FLAT_BASE,
			'<polygon points="40,56 60,56 68,78 32,78"/>',
			'<ellipse cx="50" cy="37" rx="14" ry="18"/>',
			'<circle cx="50" cy="14" r="5"/>',
		],
		"details": [
			'<path d="M57 27 L45 41" fill="none" stroke-width="4" stroke-linecap="round"/>',
		],
	},
	"knight": {
		"parts": [
			FLAT_BASE,
			'<polygon points="32,78 37,58 27,58 20,48 32,34 42,24 44,10 52,18 62,22 70,36 72,52 68,78"/>',
		],
		"details": [
			'<circle cx="42" cy="32" r="3" stroke="none"/>',
		],
	},
	"queen": {
		"parts": [
			FLAT_BASE,
			'<polygon points="36,56 64,56 70,78 30,78"/>',
			'<polygon points="30,57 20,26 34,42 42,18 50,40 58,18 66,42 80,26 70,57"/>',
			'<circle cx="20" cy="24" r="4.5"/>',
			'<circle cx="42" cy="16" r="4.5"/>',
			'<circle cx="58" cy="16" r="4.5"/>',
			'<circle cx="80" cy="24" r="4.5"/>',
		],
		"details": [],
	},
	"king": {
		"parts": [
			FLAT_BASE,
			'<polygon points="38,54 62,54 69,78 31,78"/>',
			'<rect x="31" y="28" width="38" height="27" rx="8"/>',
			'<rect x="46" y="6" width="8" height="22"/>',
			'<rect x="39" y="11" width="22" height="7"/>',
		],
		"details": [],
	},
}

# --------------------------------------------------------------------------------

func _initialize() -> void:
	var styles := {
		"classic": _classic,
		"flat": _flat,
		"token": _token,
	}
	for style in styles:
		DirAccess.make_dir_recursive_absolute(OUT_DIR + style)
		for team in TEAMS:
			for piece in PIECES:
				var body: String = styles[style].call(piece, team)
				_write(_piece_path(style, team, piece), _svg(body))
	_write(OUT_DIR + "preview.html", _preview_html(styles.keys()))
	print("Piece art written to ", OUT_DIR)
	quit()

func _classic(piece: String, team: String) -> String:
	var c: Dictionary = CLASSIC_COLORS[team]
	var shape: Dictionary = CLASSIC_SHAPES[piece]
	return ('<g fill="%s" stroke="%s" stroke-width="2.8" stroke-linejoin="round">%s</g>' % [c.fill, c.line, "".join(shape.parts)]
			+ '<g fill="%s" stroke="%s">%s</g>' % [c.detail, c.detail, "".join(shape.details)])

func _flat(piece: String, team: String) -> String:
	var c: Dictionary = FLAT_COLORS[team]
	var shape: Dictionary = FLAT_SHAPES[piece]
	var parts := "".join(shape.parts)
	# A soft shadow, the piece, the same shapes again in the darker shade but only
	# on the right half (the clip path), then a thin edge so light pieces still
	# stand out on light squares.
	return ('<defs><clipPath id="right"><rect x="50" y="0" width="50" height="100"/></clipPath></defs>'
			+ '<ellipse cx="50" cy="91" rx="30" ry="3.5" fill="#000000" fill-opacity="0.18"/>'
			+ '<g fill="%s">%s</g>' % [c.main, parts]
			+ '<g fill="%s" clip-path="url(#right)">%s</g>' % [c.shade, parts]
			+ '<g fill="none" stroke="%s" stroke-width="2" stroke-linejoin="round">%s</g>' % [c.edge, parts]
			+ '<g fill="%s" stroke="%s">%s</g>' % [c.detail, c.detail, "".join(shape.details)])

## A round coin with the classic silhouette shrunk inside it.
func _token(piece: String, team: String) -> String:
	var c: Dictionary = TOKEN_COLORS[team]
	var shape: Dictionary = CLASSIC_SHAPES[piece]
	return ('<circle cx="50" cy="50" r="45" fill="%s" stroke="%s" stroke-width="4"/>' % [c.disc, c.ring]
			+ '<circle cx="50" cy="50" r="38" fill="none" stroke="%s" stroke-width="1.5"/>' % c.ring
			+ '<g transform="translate(50 51) scale(0.6) translate(-50 -50)">'
			+ '<g fill="%s">%s</g>' % [c.emblem, "".join(shape.parts)]
			+ '<g fill="%s" stroke="%s">%s</g>' % [c.disc, c.disc, "".join(shape.details)]
			+ '</g>')

func _svg(body: String) -> String:
	return ('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 100 100">' % [IMPORT_SIZE, IMPORT_SIZE]
			+ body + '</svg>\n')

static func _piece_path(style: String, team: String, piece: String) -> String:
	return OUT_DIR + style + "/" + team + "_" + piece + ".svg"

func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Couldn't write " + path)
		return
	file.store_string(text)

## A web page showing each style on board squares, large and at phone size.
func _preview_html(styles: Array) -> String:
	var html := ('<!doctype html><html><head><meta charset="utf-8"><title>Piece styles</title><style>'
			+ 'body{font-family:sans-serif;background:#2b2b2b;color:#eee;margin:24px}'
			+ 'h2{margin:28px 0 8px}.row{display:flex}.sq{display:flex;align-items:center;justify-content:center}'
			+ '.big .sq{width:88px;height:88px}.small .sq{width:40px;height:40px}.sq img{width:100%;height:100%}'
			+ 'p{color:#aaa;margin:6px 0}</style></head><body><h1>Chess Plus piece styles</h1>')
	for style in styles:
		html += "<h2>%s</h2>" % style
		for team_index in TEAMS.size():
			html += '<div class="row big">'
			for i in PIECES.size():
				html += _preview_square(style, TEAMS[team_index], PIECES[i], (i + team_index) % 2 == 0)
			html += "</div>"
		html += '<p>Phone size (40 px squares):</p><div class="row small">'
		var i := 0
		for team in TEAMS:
			for piece in PIECES:
				html += _preview_square(style, team, piece, i % 2 == 0)
				i += 1
		html += "</div>"
	return html + "</body></html>\n"

func _preview_square(style: String, team: String, piece: String, light: bool) -> String:
	var svg := FileAccess.get_file_as_string(_piece_path(style, team, piece))
	var data := Marshalls.utf8_to_base64(svg)
	return '<div class="sq" style="background:%s"><img src="data:image/svg+xml;base64,%s"></div>' % [
			LIGHT_SQUARE if light else DARK_SQUARE, data]
