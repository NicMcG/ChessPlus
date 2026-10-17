extends SceneTree

## Cuts a sheet of piece pictures into one PNG per piece, e.g.
## res://art/pieces/standard/white_knight.png.
## The sheet has 6 pieces across (king, queen, bishop, knight, rook, pawn),
## White on the top row and Black on the bottom row, in equal-sized cells.
##
## Run it with:
##   "<godot console exe>" --headless --path . -s res://tools/slice_piece_sprite.gd
##
## The sheet lives in res://art/source/, which has a .gdignore file so Godot
## doesn't import it into the game; only the cut-out pieces are used.

const SHEET := "res://art/source/chess_pieces_sprite.webp"
const OUT_DIR := "res://art/pieces/standard/"
const COLUMNS: Array[String] = ["king", "queen", "bishop", "knight", "rook", "pawn"]
const ROWS: Array[String] = ["white", "black"]

func _initialize() -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path(SHEET))
	if sheet == null:
		push_error("Couldn't load " + SHEET)
		quit(1)
		return
	var cell := Vector2i(sheet.get_width() / COLUMNS.size(), sheet.get_height() / ROWS.size())
	DirAccess.make_dir_recursive_absolute(OUT_DIR)
	for row in ROWS.size():
		for column in COLUMNS.size():
			var piece := sheet.get_region(Rect2i(Vector2i(column, row) * cell, cell))
			var path := OUT_DIR + "%s_%s.png" % [ROWS[row], COLUMNS[column]]
			piece.save_png(path)
			print("Saved ", path)
	quit()
