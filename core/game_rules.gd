class_name GameRules
extends Resource

## Rules that apply to a whole game rather than to one type of piece.

## What a piece with the `promotes` flag may turn into when it reaches the far
## rank. If this is empty, promoting pieces just move there and stay as they are.
## For games built from armies, ArmySetup fills this in from the pieces on the board.
@export var promotion_options: Array[PieceDef] = []

## Castling is only allowed with a partner (rook) that is in a corner of its
## owner's back rank.
@export var castling_partner_in_corner := true

@export_group("Armies")
## How many points each army may spend.
@export var army_budget := 39.0
## How many rows, counted from each player's own edge, armies may start on.
@export var army_start_rows := 2
## The most copies of one piece type an army may have. Pawn types have no limit
## and an army has exactly one king type.
@export var army_max_copies := 2
## How many royal-type pieces an army may have besides its king.
@export var army_max_extra_royals := 1
