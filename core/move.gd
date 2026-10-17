class_name Move
extends RefCounted

## One move: which piece goes from where to where, and what (if anything) it takes.

var from: Vector2i
var to: Vector2i
var piece: Piece
## The piece being taken, or null if the move doesn't capture.
var captured: Piece

func _init(p_from: Vector2i, p_to: Vector2i, p_piece: Piece, p_captured: Piece = null) -> void:
	from = p_from
	to = p_to
	piece = p_piece
	captured = p_captured

func is_capture() -> bool:
	return captured != null

## Simple text like "e2-e4" or "e4xd5". Used for testing, not real notation.
func to_text() -> String:
	var joiner := "x" if is_capture() else "-"
	return Board.square_name(from) + joiner + Board.square_name(to)
