class_name ArmySetup
extends RefCounted

## Builds a game from two armies.

## A new game with `white` starting on ranks 1-2 and `black` on ranks 8-7 (each
## army's row 0 is its owner's back row). Black's army is turned round (files
## mirrored too) unless it says otherwise (Army.mirror_for_black), so it looks
## from Black's side as it was built. Every piece starts unmoved.
static func create_game(white: Army, black: Army, base_rules: GameRules, width := 8, height := 8) -> GameState:
	var board := Board.new(width, height)
	for piece in white.pieces:
		board.set_piece(board_square(white, piece, Piece.Team.WHITE, width, height), Piece.new(piece.def, Piece.Team.WHITE))
	for piece in black.pieces:
		board.set_piece(board_square(black, piece, Piece.Team.BLACK, width, height), Piece.new(piece.def, Piece.Team.BLACK))
	var rules: GameRules = base_rules.duplicate()
	rules.promotion_options = promotion_options_for(board)
	return GameState.new(board, rules)

## Where one of `army`'s pieces starts on the board when `team` plays it.
static func board_square(army: Army, piece: ArmyPiece, team: Piece.Team, width := 8, height := 8) -> Vector2i:
	if team == Piece.Team.WHITE:
		return piece.square
	var file := width - 1 - piece.square.x if army.mirror_for_black else piece.square.x
	return Vector2i(file, height - 1 - piece.square.y)

## What pawn-type pieces may promote to: each piece type on the board at the
## start, from either army, except king types (a second king would break the
## game) and pawn types (promoting into one would be pointless).
static func promotion_options_for(board: Board) -> Array[PieceDef]:
	var options: Array[PieceDef] = []
	for rank in range(board.height):
		for file in range(board.width):
			var piece := board.get_piece(Vector2i(file, rank))
			if piece and not piece.def.is_king_type() and not piece.def.is_pawn_type() and not options.has(piece.def):
				options.append(piece.def)
	# Most valuable first, so the promotion picker shows the likely choice first.
	options.sort_custom(func(a: PieceDef, b: PieceDef) -> bool: return a.value > b.value)
	return options
