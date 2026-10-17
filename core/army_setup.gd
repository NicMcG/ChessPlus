class_name ArmySetup
extends RefCounted

## Builds a game from two armies.

## A new game with `white` starting on ranks 1-2 and `black` on ranks 8-7 (each
## army's row 0 is its owner's back row). Every piece starts unmoved.
static func create_game(white: Army, black: Army, base_rules: GameRules, width := 8, height := 8) -> GameState:
	var board := Board.new(width, height)
	for piece in white.pieces:
		board.set_piece(piece.square, Piece.new(piece.def, Piece.Team.WHITE))
	for piece in black.pieces:
		board.set_piece(Vector2i(piece.square.x, height - 1 - piece.square.y), Piece.new(piece.def, Piece.Team.BLACK))
	var rules: GameRules = base_rules.duplicate()
	rules.promotion_options = promotion_options_for(board)
	return GameState.new(board, rules)

## What promoting pieces may become: each piece type on the board at the start,
## from either army, except royal types (a second king would break the game) and
## pawn types (promoting into one would be pointless).
static func promotion_options_for(board: Board) -> Array[PieceDef]:
	var options: Array[PieceDef] = []
	for rank in range(board.height):
		for file in range(board.width):
			var piece := board.get_piece(Vector2i(file, rank))
			if piece and not piece.def.is_royal and not piece.def.promotes and not options.has(piece.def):
				options.append(piece.def)
	# Most valuable first, so the promotion picker shows the likely choice first.
	options.sort_custom(func(a: PieceDef, b: PieceDef) -> bool: return a.value > b.value)
	return options
