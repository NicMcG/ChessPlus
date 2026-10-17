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
			if piece.def.is_king_type() and not piece.has_moved:
				_add_castling_moves(board, state.rules, from, piece, moves)
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
## For a hopping rule, the first piece met is the screen, so look one piece further.
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
				var screen_found := false
				for distance in range(1, reach + 1):
					pos -= step
					if not board.in_bounds(pos):
						break
					var piece := board.get_piece(pos)
					if piece == null:
						continue
					if rule.captures_by_hopping and not screen_found:
						screen_found = true
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
					_append(state, en_passant, moves)
				elif rule.mode != MoveRule.Mode.CAPTURE_ONLY:
					var move := Move.new(from, to, piece)
					if piece.def.is_pawn_type():
						move.skipped_squares = passed.duplicate()
					_append(state, move, moves)
				passed.append(to)
				continue
			# Something is in the way. A hopping rule jumps it to look for a capture;
			# otherwise capture it if it's an enemy and the rule allows. Stop either way.
			if rule.captures_by_hopping:
				if rule.mode != MoveRule.Mode.MOVE_ONLY:
					_add_hop_capture(state, from, to, step, limit - i - 1, piece, moves)
			elif target.team != piece.team and rule.mode != MoveRule.Mode.MOVE_ONLY:
				_append(state, Move.new(from, to, piece, target), moves)
			break

## Having reached a screen at `screen`, keep going (up to `steps_left` more squares)
## and capture the first piece beyond it, if it's an enemy.
static func _add_hop_capture(state: GameState, from: Vector2i, screen: Vector2i, step: Vector2i, steps_left: int, piece: Piece, moves: Array[Move]) -> void:
	var to := screen
	for i in range(steps_left):
		to += step
		if not state.board.in_bounds(to):
			return
		var target := state.board.get_piece(to)
		if target == null:
			continue
		if target.team != piece.team:
			_append(state, Move.new(from, to, piece, target), moves)
		return

## Adds a move to the list. A promoting piece reaching the far rank must promote,
## so instead of the plain move this adds one move per promotion option.
static func _append(state: GameState, move: Move, moves: Array[Move]) -> void:
	var options := state.rules.promotion_options
	if not move.piece.def.is_pawn_type() or options.is_empty() or move.to.y != _far_rank(state.board, move.piece.team):
		moves.append(move)
		return
	for option in options:
		var promotion := Move.new(move.from, move.to, move.piece, move.captured)
		promotion.capture_square = move.capture_square
		promotion.promotion = option
		moves.append(promotion)

## The rank farthest from the team's side of the board.
static func _far_rank(board: Board, team: Piece.Team) -> int:
	return board.height - 1 if team == Piece.Team.WHITE else 0

## Castling: the king moves two squares toward an unmoved partner on the same rank,
## with only empty squares between them, and the partner lands on the square the
## king crossed. Not allowed out of check or across an attacked square. (Landing
## in check is ruled out by the normal legality filter.)
static func _add_castling_moves(board: Board, rules: GameRules, king_pos: Vector2i, king: Piece, moves: Array[Move]) -> void:
	var enemy := Piece.other_team(king.team)
	var enemy_defs: Array[PieceDef] = []
	var checked_for_check := false
	for dir in [-1, 1]:
		var partner_pos := _first_piece_along(board, king_pos, Vector2i(dir, 0))
		if partner_pos == Board.NO_SQUARE or absi(partner_pos.x - king_pos.x) < 3:
			continue
		var partner := board.get_piece(partner_pos)
		if partner.team != king.team or not partner.def.has_castle() or partner.has_moved:
			continue
		if rules.castling_partner_in_corner and not _is_back_corner(board, partner_pos, king.team):
			continue
		# Only look for attacks once castling is actually possible: it's slow-ish.
		if not checked_for_check:
			enemy_defs = _defs_on_board(board, enemy)
			if _is_attacked_by(board, king_pos, enemy, enemy_defs):
				return
			checked_for_check = true
		var crossed := king_pos + Vector2i(dir, 0)
		if _is_attacked_by(board, crossed, enemy, enemy_defs):
			continue
		var move := Move.new(king_pos, king_pos + Vector2i(dir * 2, 0), king)
		move.partner = partner
		move.partner_from = partner_pos
		move.partner_to = crossed
		moves.append(move)

## True if `square` is a corner of `team`'s back rank.
static func _is_back_corner(board: Board, square: Vector2i, team: Piece.Team) -> bool:
	var back_rank := 0 if team == Piece.Team.WHITE else board.height - 1
	return square.y == back_rank and (square.x == 0 or square.x == board.width - 1)

## The first occupied square from `from` (not counting it) in direction `step`,
## or NO_SQUARE if there's nothing before the edge of the board.
static func _first_piece_along(board: Board, from: Vector2i, step: Vector2i) -> Vector2i:
	var pos := from + step
	while board.in_bounds(pos):
		if not board.is_empty(pos):
			return pos
		pos += step
	return Board.NO_SQUARE

## If moving to the empty square `to` would capture en passant, returns that
## capture, otherwise null. Both pieces must be pawn types.
static func _en_passant_capture(state: GameState, from: Vector2i, to: Vector2i, piece: Piece, rule: MoveRule) -> Move:
	if rule.mode == MoveRule.Mode.MOVE_ONLY or not piece.def.is_pawn_type():
		return null
	if not state.en_passant_squares.has(to):
		return null
	var victim := state.board.get_piece(state.en_passant_victim)
	if victim == null or victim.team == piece.team or not victim.def.is_pawn_type():
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
			if piece and piece.team == team and piece.def.is_king_type():
				squares.append(Vector2i(file, rank))
	return squares
