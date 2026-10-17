class_name GameState
extends RefCounted

## A game in progress: the board plus everything else the rules need to know.
## Moves are played with make_move and taken back with undo_move. Undo must
## happen in reverse order (last move made is the first one undone).

var board: Board
var side_to_move: Piece.Team = Piece.Team.WHITE

func _init(p_board: Board) -> void:
	board = p_board

## The moves available to whoever's turn it is.
func moves() -> Array[Move]:
	return MoveGenerator.pseudo_legal_moves(board, side_to_move)

func make_move(move: Move) -> void:
	move.piece_had_moved = move.piece.has_moved
	board.set_piece(move.from, null)
	board.set_piece(move.to, move.piece)  # Replaces any captured piece.
	move.piece.has_moved = true
	side_to_move = Piece.other_team(side_to_move)

func undo_move(move: Move) -> void:
	side_to_move = Piece.other_team(side_to_move)
	move.piece.has_moved = move.piece_had_moved
	board.set_piece(move.to, move.captured)  # null if nothing was captured.
	board.set_piece(move.from, move.piece)

## The available move whose to_text() matches, e.g. "e2-e4", or null. For tests.
func find_move(text: String) -> Move:
	for move in moves():
		if move.to_text() == text:
			return move
	return null
