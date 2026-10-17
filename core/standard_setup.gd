class_name StandardSetup
extends RefCounted

## Everything needed for a game of standard chess.

const PAWN = preload("res://data/pieces/pawn.tres")
const KNIGHT = preload("res://data/pieces/knight.tres")
const BISHOP = preload("res://data/pieces/bishop.tres")
const ROOK = preload("res://data/pieces/rook.tres")
const QUEEN = preload("res://data/pieces/queen.tres")
const KING = preload("res://data/pieces/king.tres")

## Every piece type in standard chess, e.g. for the FEN loader.
static func piece_defs() -> Array[PieceDef]:
	return [PAWN, KNIGHT, BISHOP, ROOK, QUEEN, KING]

## Standard chess rules: pawns promote to a queen, rook, bishop or knight.
static func create_rules() -> GameRules:
	var rules := GameRules.new()
	rules.promotion_options = [QUEEN, ROOK, BISHOP, KNIGHT]
	return rules

## A new game from the starting position.
static func create_game() -> GameState:
	return GameState.new(create_board(), create_rules())

## A standard-chess game from a FEN position. Returns null if the FEN can't be read.
static func from_fen(fen: String) -> GameState:
	return Fen.parse(fen, piece_defs(), create_rules())

## The standard set of pieces as an army (it costs exactly 39).
static func army() -> Army:
	var result := Army.new()
	result.army_name = "Standard"
	var back_rank := [ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK]
	for file in range(8):
		result.place(back_rank[file], Vector2i(file, 0))
		result.place(PAWN, Vector2i(file, 1))
	return result

## The normal starting position.
static func create_board() -> Board:
	var board := Board.new(8, 8)
	var back_rank := [ROOK, KNIGHT, BISHOP, QUEEN, KING, BISHOP, KNIGHT, ROOK]
	for file in range(8):
		board.set_piece(Vector2i(file, 0), Piece.new(back_rank[file], Piece.Team.WHITE))
		board.set_piece(Vector2i(file, 1), Piece.new(PAWN, Piece.Team.WHITE))
		board.set_piece(Vector2i(file, 6), Piece.new(PAWN, Piece.Team.BLACK))
		board.set_piece(Vector2i(file, 7), Piece.new(back_rank[file], Piece.Team.BLACK))
	return board
