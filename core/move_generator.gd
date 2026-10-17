class_name MoveGenerator
extends RefCounted

## Works out which moves are possible in a position.
## Driven entirely by each piece's MoveRule data; no piece is special-cased by name.

## Every move the team's pieces can make by their movement rules,
## without yet checking whether it leaves their royal piece in check.
static func pseudo_legal_moves(board: Board, team: Piece.Team) -> Array[Move]:
	var moves: Array[Move] = []
	for rank in range(board.height):
		for file in range(board.width):
			var from := Vector2i(file, rank)
			var piece := board.get_piece(from)
			if piece == null or piece.team != team:
				continue
			for rule in piece.def.move_rules:
				_add_rule_moves(board, from, piece, rule, moves)
	return moves

## Walks each direction of one rule, one step at a time, adding moves as it goes.
static func _add_rule_moves(board: Board, from: Vector2i, piece: Piece, rule: MoveRule, moves: Array[Move]) -> void:
	var limit := _step_limit(rule, piece, board)
	for dir in rule.directions:
		var step := _orient(dir, piece.team)
		var to := from
		for i in range(limit):
			to += step
			if not board.in_bounds(to):
				break
			var target := board.get_piece(to)
			if target == null:
				if rule.mode != MoveRule.Mode.CAPTURE_ONLY:
					moves.append(Move.new(from, to, piece))
				continue
			# Something is in the way: capture it if it's an enemy and the rule allows,
			# then stop either way.
			if target.team != piece.team and rule.mode != MoveRule.Mode.MOVE_ONLY:
				moves.append(Move.new(from, to, piece, target))
			break

## How many steps this rule allows right now. 0 in the data means "unlimited",
## which on a finite board is never more than the board's longest side.
static func _step_limit(rule: MoveRule, piece: Piece, board: Board) -> int:
	var steps := rule.max_steps
	if rule.first_move_max_steps > 0 and not piece.has_moved:
		steps = rule.first_move_max_steps
	if steps == 0:
		steps = maxi(board.width, board.height)
	return steps

## Directions are written from the owner's point of view. Black faces the other way,
## so its rank direction is flipped.
static func _orient(dir: Vector2i, team: Piece.Team) -> Vector2i:
	if team == Piece.Team.BLACK:
		return Vector2i(dir.x, -dir.y)
	return dir
