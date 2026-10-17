class_name ArmyPiece
extends Resource

## One piece in an army: what it is and where it starts.

@export var def: PieceDef
## (file, row) counted from the owner's own edge of the board: row 0 is the back
## row, row 1 the row in front of it. Files are not mirrored for Black, so a
## queen on file 3 starts on d1 for White and d8 for Black, as in normal chess.
@export var square: Vector2i

static func make(p_def: PieceDef, p_square: Vector2i) -> ArmyPiece:
	var piece := ArmyPiece.new()
	piece.def = p_def
	piece.square = p_square
	return piece
