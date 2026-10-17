class_name Move
extends RefCounted

## One move: which piece goes from where to where, and what (if anything) it takes.

var from: Vector2i
var to: Vector2i
var piece: Piece
## The piece being taken, or null if the move doesn't capture.
var captured: Piece
## Where the captured piece stands. The same as `to`, except for en passant.
var capture_square: Vector2i
## Squares this move skips over that the opponent may capture onto en passant
## next turn. Only set for multi-step moves by pieces with the en_passant flag.
var skipped_squares: Array[Vector2i] = []
## What the piece turns into, or null if this move doesn't promote.
var promotion: PieceDef
## For castling: the partner piece (rook) that moves too, and where it goes.
var partner: Piece
var partner_from: Vector2i
var partner_to: Vector2i

# Filled in by GameState.make_move so undo_move can put things back exactly.
var piece_had_moved: bool
var prev_halfmove_clock: int
## The new piece created by a promotion. Made once and reused if the move is
## replayed, so later moves that refer to it still find the same piece.
var promoted_piece: Piece
var partner_had_moved: bool
var prev_en_passant_squares: Array[Vector2i]
var prev_en_passant_victim: Vector2i

func _init(p_from: Vector2i, p_to: Vector2i, p_piece: Piece, p_captured: Piece = null) -> void:
	from = p_from
	to = p_to
	piece = p_piece
	captured = p_captured
	capture_square = p_to

func is_capture() -> bool:
	return captured != null

func is_castling() -> bool:
	return partner != null

## Simple text like "e2-e4", "e4xd5" or "e7-e8=Q". Used for testing, not real notation.
func to_text() -> String:
	var joiner := "x" if is_capture() else "-"
	var text := Board.square_name(from) + joiner + Board.square_name(to)
	if promotion:
		text += "=" + promotion.symbol.to_upper()
	return text
