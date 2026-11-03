class_name PieceCatalog
extends RefCounted

## Every piece type in the game: one PieceDef per .tres file in res://data/pieces/.
## Used wherever piece types are looked up by letter (FEN) and, later, by the
## army builder.

const PIECES_DIR := "res://data/pieces/"

## Read from the folder once (each call used to list it and look up every
## file again), then handed out as a fresh list callers may sort.
static func all_defs() -> Array[PieceDef]:
	if _defs.is_empty():
		for file in ResourceLoader.list_directory(PIECES_DIR):
			if file.ends_with(".tres"):
				var def := load(PIECES_DIR + file) as PieceDef
				if def:
					_defs.append(def)
	return _defs.duplicate()

static var _defs: Array[PieceDef] = []

## Forget the piece types (the test runner does this before quitting).
static func clear_cache() -> void:
	_defs.clear()
