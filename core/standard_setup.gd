class_name StandardSetup
extends RefCounted

## Builds the normal chess starting position.

const PAWN = preload("res://data/pieces/pawn.tres")
const KNIGHT = preload("res://data/pieces/knight.tres")
const BISHOP = preload("res://data/pieces/bishop.tres")
const ROOK = preload("res://data/pieces/rook.tres")
const QUEEN = preload("res://data/pieces/queen.tres")
const KING = preload("res://data/pieces/king.tres")

static func create_board() -> Board:
	var board := Board.new(8, 8)
	var back_rank := [ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK]
	for file in range(8):
		board.set_piece(Vector2i(file, 0), Piece.new(back_rank[file], Piece.Team.WHITE))
		board.set_piece(Vector2i(file, 1), Piece.new(PAWN, Piece.Team.WHITE))
		board.set_piece(Vector2i(file, 6), Piece.new(PAWN, Piece.Team.BLACK))
		board.set_piece(Vector2i(file, 7), Piece.new(back_rank[file], Piece.Team.BLACK))
	return board
