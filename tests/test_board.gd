extends Node

func _ready() -> void:
	var board := StandardSetup.create_board()
	print(board.to_text())
	print("Piece on e1: ", board.get_piece(Vector2i(4, 0)).def.display_name)
	print("e4 is empty: ", board.is_empty(Vector2i(4, 3)))
	print("(4, 3) is called: ", Board.square_name(Vector2i(4, 3)))
