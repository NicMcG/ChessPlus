class_name GameRules
extends Resource

## Rules that apply to a whole game rather than to one type of piece.

## What a piece with the `promotes` flag may turn into when it reaches the far
## rank. If this is empty, promoting pieces just move there and stay as they are.
@export var promotion_options: Array[PieceDef] = []
