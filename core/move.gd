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
## An empty list that moves share until they need a list of their own (making a
## new empty list for every move is surprisingly slow). Never add to it.
const NO_SQUARES: Array[Vector2i] = []

## Squares this move skips over that the opponent may capture onto en passant
## next turn. Only set for multi-step moves by pawn-type pieces.
var skipped_squares: Array[Vector2i] = NO_SQUARES
## For a move that breaks a Shield: the shielded piece. The attacker stays on
## `from` and the shielded piece stays on `to`; only the shield is lost.
var shield_target: Piece
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
var prev_en_passant_squares: Array[Vector2i] = NO_SQUARES
var prev_en_passant_victim: Vector2i

func _init(p_from: Vector2i, p_to: Vector2i, p_piece: Piece, p_captured: Piece = null) -> void:
	from = p_from
	to = p_to
	piece = p_piece
	captured = p_captured
	capture_square = p_to

## The special ability this move uses (PieceDef.Ability), NONE for ordinary moves.
## A Crack Shot is a capture (or shield break) where the Archer stays put; a Raise
## Dead has from == to (the Necromancer's square) and `raised` set.
var ability: PieceDef.Ability = PieceDef.Ability.NONE
## Raise Dead: the piece that comes back (a fresh piece of a lost piece's type),
## and the lost piece it stands for (taken off the lost list while it's back).
var raised: Piece
var raised_from_lost: Piece
## Filled in by make_move: where raised_from_lost was in the lost list, and
## whether the moving piece died (a Ram capturing).
var raised_lost_index := -1
var attacker_died := false

## A Jester swap: the piece the capture was aimed at (it moves to the Jester's
## square, `decoy_square`, and `captured` is the Jester instead).
var decoy_piece: Piece
var decoy_square: Vector2i
var decoy_piece_had_moved := false
## Filled in by make_move: the shield the capture broke was one the target gained
## (Vampire), and the capturing piece gained a shield by this capture.
var broke_gained_shield := false
var gained_shield := false

## True for captures and for shield breaks (both are written with "x").
func is_capture() -> bool:
	return captured != null or breaks_shield()

func breaks_shield() -> bool:
	return shield_target != null

## Where the moving piece ends up: `to`, or `from` if it only broke a shield or
## used Crack Shot (it shoots from where it stands).
func lands_on() -> Vector2i:
	return from if breaks_shield() or ability == PieceDef.Ability.CRACK_SHOT else to

func is_castling() -> bool:
	return partner != null

## Simple text like "e2-e4", "e4xd5" or "e7-e8=Q". Used for testing, not real notation.
func to_text() -> String:
	# Abilities: "c1!g5" (Crack Shot on g5), "d1!=Q" (Raise Dead bringing back a queen).
	if ability == PieceDef.Ability.RAISE_DEAD:
		return Board.square_name(from) + "!=" + raised.def.symbol.to_upper()
	if ability == PieceDef.Ability.CRACK_SHOT:
		return Board.square_name(from) + "!" + Board.square_name(to)
	var joiner := "x" if is_capture() else "-"
	var text := Board.square_name(from) + joiner + Board.square_name(to)
	if promotion:
		text += "=" + promotion.symbol.to_upper()
	return text
