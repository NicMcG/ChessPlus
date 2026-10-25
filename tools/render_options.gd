extends SceneTree

## Renders art options (SVGs in a folder) to PNGs beside them and one contact
## sheet for Mac to choose from:
##   "<godot console exe>" --headless --path . -s res://tools/render_options.gd -- <folder> <sheet.png> [columns] [size]
## Options come as pairs white_<code>_<name>.svg / black_<code>_<name>.svg (a
## lone white_ file is shown on its own). Each option is drawn on four board
## squares (the white piece on a light and a dark square, the black piece
## likewise) with its code (e.g. "G3") written under it, so an option can be
## named without guessing. `size` is one square's width in pixels (default 110).
## The SVGs use the Cburnett canvas (45 x 45).

const SVG_SIZE := 45.0
const PAD := 14
const LABEL := 26
const LIGHT := Color("#F0D9B5")
const DARK := Color("#B58863")
const BACKGROUND := Color(0.17, 0.17, 0.18)
const INK := Color(0.95, 0.95, 0.95)
## A 5x7 pixel font for the labels (only what the codes need).
const GLYPHS := {
	"0": ["01110", "10001", "10011", "10101", "11001", "10001", "01110"],
	"1": ["00100", "01100", "00100", "00100", "00100", "00100", "01110"],
	"2": ["01110", "10001", "00001", "00010", "00100", "01000", "11111"],
	"3": ["11111", "00010", "00100", "00010", "00001", "10001", "01110"],
	"4": ["00010", "00110", "01010", "10010", "11111", "00010", "00010"],
	"5": ["11111", "10000", "11110", "00001", "00001", "10001", "01110"],
	"6": ["00110", "01000", "10000", "11110", "10001", "10001", "01110"],
	"7": ["11111", "00001", "00010", "00100", "01000", "01000", "01000"],
	"8": ["01110", "10001", "10001", "01110", "10001", "10001", "01110"],
	"9": ["01110", "10001", "10001", "01111", "00001", "00010", "01100"],
	"A": ["01110", "10001", "10001", "11111", "10001", "10001", "10001"],
	"G": ["01110", "10001", "10000", "10111", "10001", "10001", "01111"],
	"V": ["10001", "10001", "10001", "10001", "10001", "01010", "00100"],
	"W": ["10001", "10001", "10001", "10101", "10101", "10101", "01010"],
}

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 2:
		push_error("Usage: render_options.gd -- <folder> <sheet.png> [columns] [size]")
		quit(1)
		return
	var folder: String = args[0]
	var sheet_path: String = args[1]
	var cols := int(args[2]) if args.size() > 2 else 3
	var size := int(args[3]) if args.size() > 3 else 110
	var names: Array[String] = []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".svg") and file.begins_with("white_"):
			names.append(file.trim_prefix("white_").trim_suffix(".svg"))
	names.sort()
	var tile := Vector2i(size * 2, size * 2 + LABEL)
	var rows := ceili(names.size() / float(cols))
	var sheet := Image.create((tile.x + PAD) * cols + PAD, (tile.y + PAD) * maxi(rows, 1) + PAD, false, Image.FORMAT_RGBA8)
	sheet.fill(BACKGROUND)
	for i in names.size():
		var origin := Vector2i(PAD + (i % cols) * (tile.x + PAD), PAD + (i / cols) * (tile.y + PAD))
		var pictures := [_render(folder.path_join("white_" + names[i] + ".svg"), size), _render(folder.path_join("black_" + names[i] + ".svg"), size)]
		for row in 2:
			for col in 2:
				var at := origin + Vector2i(col * size, row * size)
				sheet.fill_rect(Rect2i(at, Vector2i(size, size)), LIGHT if (row + col) % 2 == 0 else DARK)
				var picture: Image = pictures[row]
				if picture:
					sheet.blend_rect(picture, Rect2i(0, 0, picture.get_width(), picture.get_height()), at)
		_label(sheet, names[i].get_slice("_", 0), origin + Vector2i(0, size * 2 + 5), tile.x)
	sheet.save_png(sheet_path)
	print("Saved ", sheet_path, " (", names.size(), " options)")
	quit()

func _render(path: String, size: int) -> Image:
	if not FileAccess.file_exists(path):
		return null
	var image := Image.new()
	if image.load_svg_from_string(FileAccess.get_file_as_string(path), size / SVG_SIZE) != OK:
		push_error("Couldn't render " + path)
		return null
	image.convert(Image.FORMAT_RGBA8)
	image.save_png(path.get_basename() + ".png")
	return image

## Writes `text` in the pixel font, centred in a strip `width` wide at `at`.
func _label(sheet: Image, text: String, at: Vector2i, width: int) -> void:
	var scale := 3
	var text_width := text.length() * 6 * scale
	var x := at.x + (width - text_width) / 2
	for ch in text:
		var rows: Array = GLYPHS.get(ch, GLYPHS["0"])
		for r in rows.size():
			for c in 5:
				if rows[r][c] == "1":
					sheet.fill_rect(Rect2i(x + c * scale, at.y + r * scale, scale, scale), INK)
		x += 6 * scale
