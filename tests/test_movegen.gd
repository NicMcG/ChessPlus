extends Node

## Step 1 check: in the starting position each side should have 20 moves.

func _ready() -> void:
	var board := StandardSetup.create_board()
	_check(board, Piece.Team.WHITE, "White")
	_check(board, Piece.Team.BLACK, "Black")
	get_tree().quit()

func _check(board: Board, team: Piece.Team, label: String) -> void:
	var moves := MoveGenerator.pseudo_legal_moves(board, team)
	var texts: PackedStringArray = []
	for move in moves:
		texts.append(move.to_text())
	print(label, " moves (", moves.size(), "): ", ", ".join(texts))
	print("  PASS" if moves.size() == 20 else "  FAIL (expected 20)")
