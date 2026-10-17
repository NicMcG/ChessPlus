class_name GameState
extends RefCounted

## A game in progress: the board plus everything else the rules need to know.
## Moves are played with make_move and taken back with undo_move. Undo must
## happen in reverse order (last move made is the first one undone).

var board: Board
var side_to_move: Piece.Team = Piece.Team.WHITE
## Squares the last move's piece skipped over, where it can be captured en passant.
var en_passant_squares: Array[Vector2i] = []
## Where that piece now stands (the piece removed by an en passant capture).
var en_passant_victim: Vector2i = Board.NO_SQUARE
## Moves since the last capture or pawn-type move (for the 50-move rule).
var halfmove_clock: int = 0
## Starts at 1 and goes up after each Black move, as in FEN and PGN.
var fullmove_number: int = 1

func _init(p_board: Board) -> void:
	board = p_board

## The legal moves for whoever's turn it is.
func moves() -> Array[Move]:
	return MoveGenerator.legal_moves(self)

## True if the side to move has a royal piece under attack.
func is_in_check() -> bool:
	return MoveGenerator.is_in_check(board, side_to_move)

func make_move(move: Move) -> void:
	move.piece_had_moved = move.piece.has_moved
	board.set_piece(move.from, null)
	board.set_piece(move.to, move.piece)  # Replaces any captured piece.
	move.piece.has_moved = true
	if side_to_move == Piece.Team.BLACK:
		fullmove_number += 1
	side_to_move = Piece.other_team(side_to_move)

func undo_move(move: Move) -> void:
	side_to_move = Piece.other_team(side_to_move)
	if side_to_move == Piece.Team.BLACK:
		fullmove_number -= 1
	move.piece.has_moved = move.piece_had_moved
	board.set_piece(move.to, move.captured)  # null if nothing was captured.
	board.set_piece(move.from, move.piece)

## The available move whose to_text() matches, e.g. "e2-e4", or null. For tests.
func find_move(text: String) -> Move:
	for move in moves():
		if move.to_text() == text:
			return move
	return null
