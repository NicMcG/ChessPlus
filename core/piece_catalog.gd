class_name PieceCatalog
extends RefCounted

## Every piece type in the game: one PieceDef per .tres file in res://data/pieces/.
## Used wherever piece types are looked up by letter (FEN) and, later, by the
## army builder.

const PIECES_DIR := "res://data/pieces/"

static func all_defs() -> Array[PieceDef]:
	var defs: Array[PieceDef] = []
	for file in ResourceLoader.list_directory(PIECES_DIR):
		if file.ends_with(".tres"):
			var def := load(PIECES_DIR + file) as PieceDef
			if def:
				defs.append(def)
	return defs
