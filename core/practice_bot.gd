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
## randomness. Hard looks as deep as it can (up to 4) within its time limit.

enum Level { EASY, MEDIUM, HARD }

const LEVEL_NAMES := ["Easy", "Medium", "Hard"]
const SETTINGS := {
	Level.EASY: {"depth": 1, "noise": 150, "time_ms": 600},
	Level.MEDIUM: {"depth": 2, "noise": 25, "time_ms": 1200},
	Level.HARD: {"depth": 4, "noise": 0, "time_ms": 1500},
}
## Scores are in hundredths of a point ("centipawns"). Checkmate beats everything.
const MATE := 1000000
const INFINITY := 10000000
## How many captures deep the capture-only search may go.
const QUIESCENCE_DEPTH := 3

var level: Level
## Positions looked at during the last choose_move, and how many moves deep it
## got (for tests and tuning).
var nodes := 0
var depth_reached := 0
var _rng := RandomNumberGenerator.new()
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
	var settings: Dictionary = SETTINGS[level]
	var moves := _ordered(state.moves())
	if moves.is_empty():
		return null
	nodes = 0
	depth_reached = 0
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

## How good the position is for the side to move (positive = good).
static func evaluate(state: GameState) -> int:
	var board := state.board
	var center := Vector2((board.width - 1) / 2.0, (board.height - 1) / 2.0)
	var score := 0
	for rank in range(board.height):
		for file in range(board.width):
			var piece := board.get_piece(Vector2i(file, rank))
			if piece == null:
				continue
			var value := int(piece.def.value * 100)
			if piece.has_active_shield():
				value += int(piece.def.value * 50)
			var row := rank if piece.team == Piece.Team.WHITE else board.height - 1 - rank
			if piece.def.can_promote():
				# Pawn-like pieces: worth more the further they get, especially in
				# the centre files (where they fight for the middle of the board).
				var central := absf(file - center.x) < 1.0
				value += row * (10 if central else 4)
			elif not piece.def.is_king_type():
				# Other pieces: better in the middle of the board, and once they've
				# left the back row ("developed").
				var distance := absf(file - center.x) + absf(rank - center.y)
				value += int((7.0 - distance) * 3)
				if row > 0:
					value += 12
			score += value if piece.team == state.side_to_move else -value
	return score

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
	for move in _ordered(MoveGenerator.pseudo_legal_moves(state)):
		state.make_move(move)
		if MoveGenerator.is_in_check(state.board, mover):
			state.undo_move(move)
			continue
		any_legal = true
		var score := -_search(state, depth - 1, -beta, -alpha, ply + 1)
		state.undo_move(move)
		if _out_of_time:
			return 0
		if score >= beta:
			return score
		alpha = maxi(alpha, score)
	if not any_legal:
		# Checkmate (sooner is worse for the loser) or stalemate (a draw).
		return -MATE + ply if MoveGenerator.is_in_check(state.board, mover) else 0
	return alpha

## Only look at captures, until things are quiet, so the score isn't fooled by a
## capture that's about to happen.
func _quiesce(state: GameState, alpha: int, beta: int, depth: int) -> int:
	var stand_pat := evaluate(state)
	if stand_pat >= beta or depth == 0:
		return stand_pat
	alpha = maxi(alpha, stand_pat)
	var mover := state.side_to_move
	var captures := MoveGenerator.pseudo_legal_moves(state).filter(func(m: Move) -> bool: return m.is_capture())
	for move in _ordered(captures):
		if _tick():
			return 0
		state.make_move(move)
		if MoveGenerator.is_in_check(state.board, mover):
			state.undo_move(move)
			continue
		var score := -_quiesce(state, -beta, -alpha, depth - 1)
		state.undo_move(move)
		if score >= beta:
			return score
		alpha = maxi(alpha, score)
	return alpha

## Count a position; true once the time limit has passed.
func _tick() -> bool:
	nodes += 1
	if nodes % 128 == 0 and Time.get_ticks_msec() > _deadline:
		_out_of_time = true
	return _out_of_time

## Most promising moves first (promotions, then taking valuable pieces with
## cheap ones), which makes the pruning work much better.
static func _ordered(moves: Array) -> Array[Move]:
	var scored: Array = []
	for move: Move in moves:
		var priority := 0.0
		if move.promotion:
			priority += 1000 + move.promotion.value * 10
		if move.captured:
			priority += 100 + move.captured.def.value * 10 - move.piece.def.value
		elif move.breaks_shield():
			priority += 50 + move.shield_target.def.value * 5
		scored.append([priority, move])
	scored.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var ordered: Array[Move] = []
	for entry in scored:
		ordered.append(entry[1])
	return ordered
