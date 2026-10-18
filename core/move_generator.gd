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
	var table := state.attack_table(enemy)
	var royals := _royal_squares(board, team)
	var legal: Array[Move] = []
	for move in pseudo_legal_moves(state):
		state.make_move(move)
		var safe := true
		for square in royals:
			var now_at := move.lands_on() if square == move.from else square
			if attacked_with(board, now_at, enemy, table):
				safe = false
				break
		state.undo_move(move)
		if safe:
			legal.append(move)
	return legal

## Every move the side to move's pieces can make by their movement rules,
## without checking whether it leaves their royal piece attacked. With
## `captures_only`, just the captures (and shield breaks): the practice bot uses
## that to look at captures without paying for every quiet move too.
static func pseudo_legal_moves(state: GameState, captures_only := false) -> Array[Move]:
	var board := state.board
	var moves: Array[Move] = []
	var pieces := board.pieces_of(state.side_to_move)
	for from: Vector2i in pieces:
		var piece: Piece = pieces[from]
		for rule in piece.def.move_rules:
			_add_rule_moves(state, from, piece, rule, moves, captures_only)
		if not captures_only and piece.def.is_king_type() and not piece.has_moved:
			_add_castling_moves(board, state.rules, from, piece, moves)
	return moves

## True if any of `team`'s royal pieces is attacked, using the game's saved
## attack table (faster than is_in_check, which works it out from the board).
static func in_check(state: GameState, team: Piece.Team) -> bool:
	var enemy := Piece.other_team(team)
	var table := state.attack_table(enemy)
	for square in _royal_squares(state.board, team):
		if attacked_with(state.board, square, enemy, table):
			return true
	return false

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

static func _is_attacked_by(board: Board, square: Vector2i, by_team: Piece.Team, defs: Array[PieceDef]) -> bool:
	return attacked_with(board, square, by_team, attack_table(by_team, defs))

## The lines `by_team`'s piece types (`defs`) can capture along, grouped by
## direction so each line only has to be walked once. Each entry is
## [step, farthest reach, [[piece type, rule], ...], any hopping rule?].
## Build it once and reuse it (GameState.attack_table does).
static func attack_table(by_team: Piece.Team, defs: Array[PieceDef]) -> Array:
	var by_step := {}
	for def in defs:
		for rule in def.move_rules:
			if rule.mode == MoveRule.Mode.MOVE_ONLY:
				continue
			var reach := UNLIMITED if rule.max_steps == 0 else maxi(rule.max_steps, rule.first_move_max_steps)
			for dir in rule.directions:
				var step := _orient(dir, by_team)
				if not by_step.has(step):
					by_step[step] = [step, 0, [], false]
				var entry: Array = by_step[step]
				entry[1] = maxi(entry[1], reach)
				entry[2].append([def, rule])
				if rule.captures_by_hopping:
					entry[3] = true
	return by_step.values()

## Further than any board is wide: "slides until blocked".
const UNLIMITED := 1000

## True if a piece of `by_team` could capture on `square`. Works backwards from
## the square: walk each line in `table` (from attack_table) and look at the
## first piece met. If it's an attacking piece type for that line, on the right
## team and close enough for its step limit, the square is attacked. For a
## hopping rule the first piece met is the screen, so look one piece further.
static func attacked_with(board: Board, square: Vector2i, by_team: Piece.Team, table: Array) -> bool:
	for entry: Array in table:
		var step: Vector2i = entry[0]
		var reach: int = entry[1]
		var attackers: Array = entry[2]
		var has_hop: bool = entry[3]
		var pos := square
		var screens := 0
		for distance in range(1, reach + 1):
			pos -= step
			if not board.in_bounds(pos):
				break
			var piece := board.get_piece(pos)
			if piece == null:
				continue
			if piece.team == by_team:
				for attacker: Array in attackers:
					var rule: MoveRule = attacker[1]
					if piece.def == attacker[0] and rule.captures_by_hopping == (screens == 1) \
							and distance <= _step_limit(rule, piece, board):
						return true
			screens += 1
			if screens > 1 or not has_hop:
				break
	return false

## Walks each direction of one rule, one step at a time, adding moves as it goes.
static func _add_rule_moves(state: GameState, from: Vector2i, piece: Piece, rule: MoveRule, moves: Array[Move], captures_only := false) -> void:
	var board := state.board
	var limit := _step_limit(rule, piece, board)
	# Worked out once per rule rather than on every square.
	var pawn_like := piece.def.is_pawn_type()
	var can_en_passant := pawn_like and rule.mode != MoveRule.Mode.MOVE_ONLY and not state.en_passant_squares.is_empty()
	var quiet_moves := rule.mode != MoveRule.Mode.CAPTURE_ONLY and not captures_only
	for dir in rule.directions:
		var step := _orient(dir, piece.team)
		var to := from
		# Empty squares walked over so far (only pawn-like pieces need them, for
		# en passant).
		var passed: Array[Vector2i] = Move.NO_SQUARES
		if pawn_like:
			passed = []
		for i in range(limit):
			to += step
			if not board.in_bounds(to):
				break
			var target := board.get_piece(to)
			if target == null:
				var en_passant: Move = _en_passant_capture(state, from, to, piece, rule) if can_en_passant else null
				if en_passant:
					_append(state, en_passant, moves)
				elif quiet_moves:
					var move := Move.new(from, to, piece)
					if not passed.is_empty():
						move.skipped_squares = passed.duplicate()
					_append(state, move, moves)
				if pawn_like:
					passed.append(to)
				continue
			# Something is in the way. A hopping rule jumps it to look for a capture;
			# otherwise capture it if it's an enemy and the rule allows. Stop either way.
			if rule.captures_by_hopping:
				if rule.mode != MoveRule.Mode.MOVE_ONLY:
					_add_hop_capture(state, from, to, step, limit - i - 1, piece, moves)
			elif target.team != piece.team and rule.mode != MoveRule.Mode.MOVE_ONLY:
				_append(state, _capture(from, to, piece, target), moves)
			break

## A capture of `target`, or just a shield break if it still has a Shield.
static func _capture(from: Vector2i, to: Vector2i, piece: Piece, target: Piece) -> Move:
	if target.has_active_shield():
		var hit := Move.new(from, to, piece)
		hit.shield_target = target
		return hit
	return Move.new(from, to, piece, target)

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
			_append(state, _capture(from, to, piece, target), moves)
		return

## Adds a move to the list. A promoting piece reaching the far rank must promote,
## so instead of the plain move this adds one move per promotion option.
static func _append(state: GameState, move: Move, moves: Array[Move]) -> void:
	var options := state.rules.promotion_options
	# A shield break doesn't move the piece, so it can't promote.
	if not move.piece.def.can_promote() or move.breaks_shield() or options.is_empty() \
			or move.to.y != _far_rank(state.board, move.piece.team):
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
	for piece: Piece in board.pieces_of(team).values():
		if not defs.has(piece.def):
			defs.append(piece.def)
	return defs

static func _royal_squares(board: Board, team: Piece.Team) -> Array[Vector2i]:
	var squares: Array[Vector2i] = []
	var pieces := board.pieces_of(team)
	for square: Vector2i in pieces:
		if pieces[square].def.is_king_type():
			squares.append(square)
	return squares
