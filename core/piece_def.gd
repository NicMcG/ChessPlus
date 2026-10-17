class_name PieceDef
extends Resource

## The blueprint for one type of piece. One file per type, e.g. knight.tres.

## Bit values for `types`. A piece can have several, e.g. the king is KING + ROYAL.
enum Type { KING = 1, ROYAL = 2, PAWN = 4 }
## Bit values for `keywords`.
enum Keyword { JUMP = 1, CASTLE = 2 }

@export var id: String = ""
@export var display_name: String = ""
## Short letter for text output and notation, e.g. "N" for knight.
@export var symbol: String = ""
@export var value: float = 0.0
@export var move_rules: Array[MoveRule] = []

## King: the piece you must protect; if it's checkmated you lose. Each army has
##   exactly one, starting in the middle of its back row. It can castle.
## Royal: an army may have at most one royal piece besides its king.
## Pawn: any number allowed. Promotes on the far rank, takes part in en passant,
##   and moving it resets the 50-move count.
@export_flags("King", "Royal", "Pawn") var types := 0
## Jump: its moves are single leaps, so it can't be blocked (a label for players;
##   the leaping comes from its move rules).
## Castle: the king can castle with it.
@export_flags("Jump", "Castle") var keywords := 0

func is_king_type() -> bool:
	return types & Type.KING != 0

func is_royal_type() -> bool:
	return types & Type.ROYAL != 0

func is_pawn_type() -> bool:
	return types & Type.PAWN != 0

func has_jump() -> bool:
	return keywords & Keyword.JUMP != 0

func has_castle() -> bool:
	return keywords & Keyword.CASTLE != 0
