class_name MoveGenerator
extends RefCounted

## Works out which moves are possible in a position.
## Driven entirely by each piece's MoveRule data; no piece is special-cased by name.

## The moves the side to move can actually play: pseudo-legal moves that don't
## leave any of its royal pieces attacked.
static func legal_moves(state: GameState) -> Array[Move]:
	var board := state.board
	var team := state.side_to_move
	var enemy := Piece.other_team(team)
	var enemy_defs := _defs_on_board(board, enemy)
	var royals := _royal_squares(board, team)
	var legal: Array[Move] = []
	for move in pseudo_legal_moves(state):
		state.make_move(move)
		var safe := true
		for square in royals:
			var now_at := move.to if square == move.from else square
			if _is_attacked_by(board, now_at, enemy, enemy_defs):
				safe = false
				break
		state.undo_move(move)
		if safe:
			legal.append(move)
	return legal

## Every move the side to move's pieces can make by their movement rules,
## without checking whether it leaves their royal piece attacked.
static func pseudo_legal_moves(state: GameState) -> Array[Move]:
	var board := state.board
	var moves: Array[Move] = []
	for rank in range(board.height):
		for file in range(board.width):
			var from := Vector2i(file, rank)
			var piece := board.get_piece(from)
			if piece == null or piece.team != state.side_to_move:
				continue
			for rule in piece.def.move_rules:
				_add_rule_moves(state, from, piece, rule, moves)
	return moves

## True if any of `team`'s royal pieces is attacked.
static func is_in_check(board: Board, team: Piece.Team) -> bool:
	var enemy := Piece.other_team(team)
	var enemy_defs := _defs_on_board(board, enemy)
	for square in _royal_squares(board, team):
		if _is_attacked_by(board, square, enemy, enemy_defs):
			return true
	return false

## True if a piece of `by_team` could capture on `square`.
static func is_attacked(board: Board, square: Vector2i, by_team: Piece.Team) -> bool:
	return _is_attacked_by(board, square, by_team, _defs_on_board(board, by_team))

## Works backwards from the square: for each kind of attacking piece, walk each of
## its capture directions in reverse. If the first piece met is that kind of piece,
## on the attacking team, and close enough for its step limit, it attacks the square.
static func _is_attacked_by(board: Board, square: Vector2i, by_team: Piece.Team, defs: Array[PieceDef]) -> bool:
	var board_size := maxi(board.width, board.height)
	for def in defs:
		for rule in def.move_rules:
			if rule.mode == MoveRule.Mode.MOVE_ONLY:
				continue
			# The farthest this rule could ever reach, moved or not.
			var reach := board_size if rule.max_steps == 0 else rule.max_steps
			reach = maxi(reach, rule.first_move_max_steps)
			for dir in rule.directions:
				var step := _orient(dir, by_team)
				var pos := square
				for distance in range(1, reach + 1):
					pos -= step
					if not board.in_bounds(pos):
						break
					var piece := board.get_piece(pos)
					if piece == null:
						continue
					if piece.def == def and piece.team == by_team and distance <= _step_limit(rule, piece, board):
						return true
					break
	return false

## Walks each direction of one rule, one step at a time, adding moves as it goes.
static func _add_rule_moves(state: GameState, from: Vector2i, piece: Piece, rule: MoveRule, moves: Array[Move]) -> void:
	var board := state.board
	var limit := _step_limit(rule, piece, board)
	for dir in rule.directions:
		var step := _orient(dir, piece.team)
		var to := from
		var passed: Array[Vector2i] = []  # Empty squares walked over so far.
		for i in range(limit):
			to += step
			if not board.in_bounds(to):
				break
			var target := board.get_piece(to)
			if target == null:
				var en_passant := _en_passant_capture(state, from, to, piece, rule)
				if en_passant:
					moves.append(en_passant)
				elif rule.mode != MoveRule.Mode.CAPTURE_ONLY:
					var move := Move.new(from, to, piece)
					if piece.def.en_passant:
						move.skipped_squares = passed.duplicate()
					moves.append(move)
				passed.append(to)
				continue
			# Something is in the way: capture it if it's an enemy and the rule allows,
			# then stop either way.
			if target.team != piece.team and rule.mode != MoveRule.Mode.MOVE_ONLY:
				moves.append(Move.new(from, to, piece, target))
			break

## If moving to the empty square `to` would capture en passant, returns that
## capture, otherwise null. Both pieces need the en_passant flag.
static func _en_passant_capture(state: GameState, from: Vector2i, to: Vector2i, piece: Piece, rule: MoveRule) -> Move:
	if rule.mode == MoveRule.Mode.MOVE_ONLY or not piece.def.en_passant:
		return null
	if not state.en_passant_squares.has(to):
		return null
	var victim := state.board.get_piece(state.en_passant_victim)
	if victim == null or victim.team == piece.team or not victim.def.en_passant:
		return null
	var move := Move.new(from, to, piece, victim)
	move.capture_square = state.en_passant_victim
	return move

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

## Each kind of piece the team has on the board, listed once.
static func _defs_on_board(board: Board, team: Piece.Team) -> Array[PieceDef]:
	var defs: Array[PieceDef] = []
	for rank in range(board.height):
		for file in range(board.width):
			var piece := board.get_piece(Vector2i(file, rank))
			if piece and piece.team == team and not defs.has(piece.def):
				defs.append(piece.def)
	return defs

static func _royal_squares(board: Board, team: Piece.Team) -> Array[Vector2i]:
	var squares: Array[Vector2i] = []
	for rank in range(board.height):
		for file in range(board.width):
			var piece := board.get_piece(Vector2i(file, rank))
			if piece and piece.team == team and piece.def.is_royal:
				squares.append(Vector2i(file, rank))
	return squares
