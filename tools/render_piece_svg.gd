extends SceneTree

## Turns hand-drawn piece (and icon) SVGs into PNGs that match the Cburnett pieces, e.g.
## res://art/source/pieces/white_elephant.svg -> res://art/pieces/standard/white_elephant.png
## The SVGs use the Cburnett canvas (45 x 45) and are rendered at 320 x 320, the
## same size as the pieces cut from the sprite sheet.
##
## Run it with:
##   "<godot console exe>" --headless --path . -s res://tools/render_piece_svg.gd

## [source folder, output folder, PNG size] for each kind of picture: pieces, and
## the small icons used in the move list (capture, check, ...).
const JOBS := [
	["res://art/source/pieces/", "res://art/pieces/standard/", 320.0],
	["res://art/source/icons/", "res://art/icons/", 128.0],
]
const SVG_SIZE := 45.0

func _initialize() -> void:
	for job in JOBS:
		_render_folder(job[0], job[1], job[2])
	quit()

func _render_folder(source_dir: String, out_dir: String, png_size: float) -> void:
	var source := ProjectSettings.globalize_path(source_dir)
	for file in DirAccess.get_files_at(source):
		if not file.ends_with(".svg"):
			continue
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(source + file), png_size / SVG_SIZE)
		if error != OK:
			push_error("Couldn't render " + file)
			continue
		var path := out_dir + file.get_basename() + ".png"
		image.save_png(path)
		print("Saved ", path)
