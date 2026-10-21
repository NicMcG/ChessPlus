class_name PracticeBot
extends RefCounted

## The practice bot: picks a move for whoever's turn it is.
##
## How it thinks: it tries each move, then each reply, and so on a few moves deep
## ("search"), and scores the positions it reaches ("evaluate"): mostly the point
## value of the pieces each side has, plus small bonuses for central and
## developed pieces, advanced (especially central) pawns, and unbroken shields. It assumes both sides pick their best
## move, and skips lines it can already prove are worse ("alpha-beta"). At the
## end of the line it keeps looking at captures ("quiescence"), so it doesn't
## stop just before losing a piece.
##
## Levels: Easy looks 1 move ahead and adds a lot of randomness to its scores, so
## it makes human-like mistakes. Medium looks 2 moves ahead with a little
## randomness. Hard looks as deep as it can (up to 6) within its time limit.
## Plusfish: the game screen asks the Plusfish engine (res://engine/plusfish/,
## see PlusfishLink) for its best move instead; this class only plays as Hard
## for it when Plusfish can't run.

enum Level { EASY, MEDIUM, HARD, PLUSFISH }

const LEVEL_NAMES := ["Easy", "Medium", "Hard", "Plusfish"]
const SETTINGS := {
	Level.EASY: {"depth": 1, "noise": 150, "time_ms": 600},
	Level.MEDIUM: {"depth": 2, "noise": 25, "time_ms": 1200},
	Level.HARD: {"depth": 6, "noise": 0, "time_ms": 1500},
	Level.PLUSFISH: {"depth": 6, "noise": 0, "time_ms": 1500},
}
## Scores are in hundredths of a point ("centipawns"). Checkmate beats everything.
const MATE := 1000000
const INFINITY := 10000000
## How many captures deep the capture-only search may go.
const QUIESCENCE_DEPTH := 3

var level: Level
## Used instead of SETTINGS[level] when not empty (the balancing tool sets its
## own depth and time).
var settings_override := {}
## Piece values the evaluation uses instead of the pieces' costs: id -> points.
## Empty in real games; the balancing tool sets it to values it has measured, so
## the bot isn't biased towards the current costs.
static var value_overrides := {}
## Positions looked at during the last choose_move, and how many moves deep it
## got (for tests and tuning).
var nodes := 0
var depth_reached := 0
var _rng := RandomNumberGenerator.new()
## "Killer moves": for each depth in the search (ply), the last two quiet moves
## that refuted a line there. Trying them first in sibling positions usually
## refutes those quickly too, which saves a lot of searching.
var _killers: Array = []
var _deadline := 0
var _out_of_time := false

## `seed` makes the randomness repeatable (for tests); leave it out for real play.
func _init(p_level := Level.MEDIUM, seed := -1) -> void:
	level = p_level
	if seed >= 0:
		_rng.seed = seed
	else:
		_rng.randomize()

## The move to play, or null if there are no legal moves. The state is used to
## try moves out, but is exactly as it was when this returns.
func choose_move(state: GameState) -> Move:
	var settings: Dictionary = settings_override if not settings_override.is_empty() else SETTINGS[level]
	var moves := _ordered(state.moves())
	if moves.is_empty():
		return null
	nodes = 0
	depth_reached = 0
	_killers.clear()
	_out_of_time = false
	_deadline = Time.get_ticks_msec() + settings.time_ms
	var noise: int = settings.noise
	var best: Move = moves[0]
	# Look 1 move deep, then 2, and so on, keeping the best move from the last
	# depth that finished in time.
	for depth in range(1, settings.depth + 1):
		var depth_best: Move = null
		var depth_best_score := -INFINITY
		for move in moves:
			state.make_move(move)
			# With randomness, every move needs its own true score, so don't prune at the root.
			var alpha := -INFINITY if noise > 0 else depth_best_score
			var score := -_search(state, depth - 1, -INFINITY, -alpha, 1)
			state.undo_move(move)
			if _out_of_time:
				break
			if noise > 0:
				score += _rng.randi_range(-noise, noise)
			if score > depth_best_score:
				depth_best_score = score
				depth_best = move
		if _out_of_time and depth > 1:
			break
		if depth_best:
			best = depth_best
			if not _out_of_time:
				depth_reached = depth
			# Try the best move first next time: it makes the deeper search faster.
			moves.erase(best)
			moves.push_front(best)
		if _out_of_time:
			break
		# Found a forced checkmate: no need to look any deeper.
		if depth_best_score >= MATE - 100:
			break
	return best

## How good the position is for the side to move (positive = good), in
## hundredths of a point. Made of:
##   material: each piece's point value (an unbroken shield adds half again)
##   control: pieces score more where they reach more squares, and once they've
##     left the back row; pawn-like pieces score more as they advance, most of
##     all in the centre files
##   king safety: while the opponent still has plenty of pieces, the king likes
##     its back row, a corner, and its own pieces in front of it
##   check: being in check counts a little against you
static func evaluate(state: GameState) -> int:
	var board := state.board
	var center_x := (board.width - 1) / 2.0
	var mover := state.side_to_move
	# First pass: how much non-pawn material each side has (for king safety), and
	# what's needed to tell whether the side to move is in check.
	var pieces_value := {Piece.Team.WHITE: 0.0, Piece.Team.BLACK: 0.0}
	var own_royals: Array[Vector2i] = []
	for rank in range(board.height):
		for file in range(board.width):
			var piece := board.get_piece(Vector2i(file, rank))
			if piece == null:
				continue
			if not piece.def.is_pawn_type():
				pieces_value[piece.team] += piece_value(piece.def)
			if piece.team == mover and piece.def.is_king_type():
				own_royals.append(Vector2i(file, rank))
	var score := 0
	for rank in range(board.height):
		for file in range(board.width):
			var square := Vector2i(file, rank)
			var piece := board.get_piece(square)
			if piece == null:
				continue
			var points := piece_value(piece.def)
			var value := int(points * 100)
			if piece.has_active_shield():
				value += int(points * 50)
			var forward := 1 if piece.team == Piece.Team.WHITE else -1
			var row := rank if piece.team == Piece.Team.WHITE else board.height - 1 - rank
			if piece.def.is_king_type():
				if pieces_value[Piece.other_team(piece.team)] >= KING_SAFETY_MATERIAL:
					value += _king_safety(board, piece, square, row, forward)
			elif piece.def.can_promote():
				var central := absf(file - center_x) < 1.0
				value += row * (10 if central else 4)
			else:
				value += reach(piece.def, square, piece.team, board) * 2
				if row > 0:
					value += 12
			score += value if piece.team == mover else -value
	var enemy := Piece.other_team(mover)
	var table := state.attack_table(enemy)
	for royal in own_royals:
		if MoveGenerator.attacked_with(board, royal, enemy, table):
			score -= CHECK_PENALTY
			break
	return score

## What the bot thinks a piece is worth: its cost, unless value_overrides says otherwise.
static func piece_value(def: PieceDef) -> float:
	if value_overrides.is_empty():
		return def.value
	return value_overrides.get(def.id, def.value)

## The opponent's pieces (not counting pawns) must be worth at least this many
## points for king safety to matter; with less, the king should join in.
const KING_SAFETY_MATERIAL := 10.0
const CHECK_PENALTY := 35

static func _king_safety(board: Board, king: Piece, square: Vector2i, row: int, forward: int) -> int:
	var bonus := 20 if row == 0 else -25 * row
	if square.x <= 2 or square.x >= board.width - 3:
		bonus += 15
	for dx in [-1, 0, 1]:
		var guard := board.get_piece(square + Vector2i(dx, forward))
		if guard and guard.team == king.team:
			bonus += 10
	return bonus

## How many squares a piece would reach from `square` on an empty board: a
## simple measure of how much it controls from there. Worked out once per piece
## type and side (and board size), then looked up.
static var _reach_cache := {}  # PieceDef -> [White's counts, Black's counts]

## Forget the worked-out reach counts (the test runner does this before quitting).
static func clear_cache() -> void:
	_reach_cache.clear()

static func reach(def: PieceDef, square: Vector2i, team: Piece.Team, board: Board) -> int:
	var tables: Array = _reach_cache.get(def, [])
	if tables.is_empty() or tables[0].size() != board.width * board.height:
		tables = [_reach_table(def, Piece.Team.WHITE, board), _reach_table(def, Piece.Team.BLACK, board)]
		_reach_cache[def] = tables
	return tables[0 if team == Piece.Team.WHITE else 1][square.y * board.width + square.x]

static func _reach_table(def: PieceDef, team: Piece.Team, board: Board) -> PackedInt32Array:
	var counts := PackedInt32Array()
	counts.resize(board.width * board.height)
	for rank in range(board.height):
		for file in range(board.width):
			counts[rank * board.width + file] = _count_reach(def, Vector2i(file, rank), team, board)
	return counts

static func _count_reach(def: PieceDef, from: Vector2i, team: Piece.Team, board: Board) -> int:
	var reached := {}
	var flip := 1 if team == Piece.Team.WHITE else -1
	for rule in def.move_rules:
		if not rule.path.is_empty():
			for steps: Array in rule.path_variants():
				var offset := MoveRule.path_offset(steps)
				var landing := from + Vector2i(offset.x, offset.y * flip)
				if board.in_bounds(landing):
					reached[landing] = true
			continue
		var steps := rule.max_steps if rule.max_steps > 0 else maxi(board.width, board.height)
		for dir in rule.directions:
			var step := Vector2i(dir.x, dir.y * flip)
			var pos := from
			for i in range(steps):
				pos += step
				if not board.in_bounds(pos):
					break
				# Leapt-over squares can't be reached.
				if i >= rule.leap_steps:
					reached[pos] = true
	return reached.size()

## The best score the side to move can get, looking `depth` moves ahead.
## For speed it starts from the possible moves (ignoring check) and skips any
## that turn out to leave its own king in check, instead of first building the
## full legal list.
func _search(state: GameState, depth: int, alpha: int, beta: int, ply: int) -> int:
	if _tick():
		return 0
	if depth <= 0:
		return _quiesce(state, alpha, beta, QUIESCENCE_DEPTH)
	var mover := state.side_to_move
	var any_legal := false
	for move in _ordered(MoveGenerator.pseudo_legal_moves(state), _killers_at(ply)):
		state.make_move(move)
		if MoveGenerator.in_check(state, mover):
			state.undo_move(move)
			continue
		any_legal = true
		var score := -_search(state, depth - 1, -beta, -alpha, ply + 1)
		state.undo_move(move)
		if _out_of_time:
			return 0
		if score >= beta:
			if not move.is_capture():
				_remember_killer(move, ply)
			return score
		alpha = maxi(alpha, score)
	if not any_legal:
		# Checkmate (sooner is worse for the loser) or stalemate (a draw).
		return -MATE + ply if MoveGenerator.in_check(state, mover) else 0
	return alpha

## Only look at captures, until things are quiet, so the score isn't fooled by a
## capture that's about to happen.
func _quiesce(state: GameState, alpha: int, beta: int, depth: int) -> int:
	var stand_pat := evaluate(state)
	if stand_pat >= beta or depth == 0:
		return stand_pat
	alpha = maxi(alpha, stand_pat)
	var mover := state.side_to_move
	for move in _ordered(MoveGenerator.pseudo_legal_moves(state, true)):
		if _tick():
			return 0
		state.make_move(move)
		if MoveGenerator.in_check(state, mover):
			state.undo_move(move)
			continue
		var score := -_quiesce(state, -beta, -alpha, depth - 1)
		state.undo_move(move)
		if score >= beta:
			return score
		alpha = maxi(alpha, score)
	return alpha

## A number that identifies a move by its squares (for comparing killers).
static func _move_key(move: Move) -> int:
	return move.from.x + move.from.y * 64 + move.to.x * 4096 + move.to.y * 262144

func _killers_at(ply: int) -> Array:
	return _killers[ply] if ply < _killers.size() else []

func _remember_killer(move: Move, ply: int) -> void:
	while _killers.size() <= ply:
		_killers.append([])
	var key := _move_key(move)
	var list: Array = _killers[ply]
	if list.has(key):
		return
	list.push_front(key)
	if list.size() > 2:
		list.pop_back()

## Stop searching as soon as possible (from another thread: the game screen
## searches on one, and stops it if the screen closes). choose_move then
## returns the best move found so far.
func stop() -> void:
	_deadline = 0

## Count a position; true once the time limit has passed.
func _tick() -> bool:
	nodes += 1
	if nodes % 128 == 0 and Time.get_ticks_msec() > _deadline:
		_out_of_time = true
	return _out_of_time

## Most promising moves first (promotions, then taking valuable pieces with
## cheap ones, then this depth's killer moves), which makes the pruning work
## much better.
static func _ordered(moves: Array, killers: Array = []) -> Array[Move]:
	# Only the promising moves need sorting; quiet moves keep their order after them.
	var scored: Array = []
	var quiet: Array[Move] = []
	for move: Move in moves:
		var priority := 0.0
		if not killers.is_empty() and killers.has(_move_key(move)):
			priority += 10
		if move.promotion:
			priority += 1000 + move.promotion.value * 10
		if move.captured:
			priority += 100 + move.captured.def.value * 10 - move.piece.def.value
		elif move.breaks_shield():
			priority += 50 + move.shield_target.def.value * 5
		if priority == 0.0:
			quiet.append(move)
		else:
			scored.append([priority, move])
	if scored.is_empty():
		return quiet
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var ordered: Array[Move] = []
	for entry in scored:
		ordered.append(entry[1])
	ordered.append_array(quiet)
	return ordered
