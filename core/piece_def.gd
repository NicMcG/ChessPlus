class_name PieceDef
extends Resource

## The blueprint for one type of piece. One file per type, e.g. knight.tres.

@export var id: String = ""
@export var display_name: String = ""
## Short letter for text output and notation, e.g. "N" for knight.
@export var symbol: String = ""
@export var value: float = 0.0
@export var move_rules: Array[MoveRule] = []

@export_group("Special Rules")
## If this piece is checkmated, its owner loses.
@export var is_royal: bool = false
## Promotes on reaching the far rank.
@export var promotes: bool = false
## Can capture en passant, and can be captured en passant.
@export var en_passant: bool = false
## Can start castling (the king).
@export var can_castle: bool = false
## Can be castled with (the rook).
@export var castle_partner: bool = false
## Moving this piece resets the 50-move count, as captures do (the pawn).
@export var resets_fifty_moves: bool = false
