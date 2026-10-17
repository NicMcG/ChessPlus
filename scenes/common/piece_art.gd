class_name PieceArt
extends RefCounted

## Finds the picture for a piece type:
## res://art/pieces/<style>/<team>_<piece id>.png (or .svg), e.g. white_knight.png.
## A variant picks another picture of the same piece, e.g. "wounded" gives
## white_paladin_wounded.png (a paladin whose shield is broken).

const DEFAULT_STYLE := "standard"

static var _cache := {}  # Image path (without extension) -> Texture2D, or null if none.

## The image for a piece, or null if there isn't one.
static func texture_for(def: PieceDef, team: Piece.Team, style := DEFAULT_STYLE, variant := "") -> Texture2D:
	var team_name := "white" if team == Piece.Team.WHITE else "black"
	var base := "res://art/pieces/%s/%s_%s" % [style, team_name, def.id]
	if not variant.is_empty():
		base += "_" + variant
	if not _cache.has(base):
		_cache[base] = null
		for extension in [".png", ".svg"]:
			if ResourceLoader.exists(base + extension):
				_cache[base] = load(base + extension)
				break
	return _cache[base]
