extends SceneTree

## Turns hand-drawn piece SVGs into PNGs that match the Cburnett pieces, e.g.
## res://art/source/pieces/white_elephant.svg -> res://art/pieces/standard/white_elephant.png
## The SVGs use the Cburnett canvas (45 x 45) and are rendered at 320 x 320, the
## same size as the pieces cut from the sprite sheet.
##
## Run it with:
##   "<godot console exe>" --headless --path . -s res://tools/render_piece_svg.gd

const SOURCE_DIR := "res://art/source/pieces/"
const OUT_DIR := "res://art/pieces/standard/"
const SVG_SIZE := 45.0
const PNG_SIZE := 320.0

func _initialize() -> void:
	var source := ProjectSettings.globalize_path(SOURCE_DIR)
	for file in DirAccess.get_files_at(source):
		if not file.ends_with(".svg"):
			continue
		var image := Image.new()
		var error := image.load_svg_from_string(FileAccess.get_file_as_string(source + file), PNG_SIZE / SVG_SIZE)
		if error != OK:
			push_error("Couldn't render " + file)
			continue
		var path := OUT_DIR + file.get_basename() + ".png"
		image.save_png(path)
		print("Saved ", path)
	quit()
