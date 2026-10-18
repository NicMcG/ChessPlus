class_name PieceDef
extends Resource

## The blueprint for one type of piece. One file per type, e.g. knight.tres.

## Bit values for `types`. A piece can have several, e.g. the king is KING + ROYAL.
enum Type { KING = 1, ROYAL = 2, PAWN = 4 }
## Bit values for `keywords`.
enum Keyword { JUMP = 1, CASTLE = 2, PROMOTE = 4, SHIELD = 8 }

@export var id: String = ""
@export var display_name: String = ""
## One or two capital letters for notation and saved positions, e.g. "N" for
## knight, "PD" for paladin. Must be unique across all pieces.
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
## Promote: promotes on the far rank, with the same choices as pawns.
## Shield: must be captured twice. The first capture only breaks the shield (the
##   attacker stays where it is and uses its turn); the shield never comes back.
@export_flags("Jump", "Castle", "Promote", "Shield") var keywords := 0

## Shown on the piece card under "Special Rule": anything about how it plays that
## its types, keywords and move picture can't show. Empty for most pieces.
@export_multiline var special_rule := ""
## Shown under "Special Ability": a once-per-game action that uses a turn. The
## name (e.g. "Crack Shot") and what it does. Empty for most pieces.
@export var ability_name := ""
@export_multiline var ability_text := ""

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

func has_promote() -> bool:
	return keywords & Keyword.PROMOTE != 0

func has_shield() -> bool:
	return keywords & Keyword.SHIELD != 0

## Pawn types and pieces with the Promote keyword promote on the far rank.
func can_promote() -> bool:
	return is_pawn_type() or has_promote()
