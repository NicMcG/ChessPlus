class_name GameState
extends RefCounted

## A game in progress: the board plus everything else the rules need to know.
## Moves are played with make_move and taken back with undo_move. Undo must
## happen in reverse order (last move made is the first one undone).

## How the game has ended, if it has. See outcome().
enum Outcome { NONE, CHECKMATE, STALEMATE, FIFTY_MOVES, REPETITION, INSUFFICIENT_MATERIAL }

var board: Board
var rules: GameRules
var side_to_move: Piece.Team = Piece.Team.WHITE
## Squares the last move's piece skipped over, where it can be captured en passant.
var en_passant_squares: Array[Vector2i] = []
## Where that piece now stands (the piece removed by an en passant capture).
var en_passant_victim: Vector2i = Board.NO_SQUARE
## Half-moves since the last capture or pawn-type move (100 = 50 moves each).
var halfmove_clock: int = 0
## Starts at 1 and goes up after each Black move, as in FEN and PGN.
var fullmove_number: int = 1
## Every move made so far, oldest first. undo_move takes the last one off.
var history: Array[Move] = []
## Each team's attack table (see MoveGenerator.attack_table), worked out the first
## time it's needed. It covers every piece type that team has at that point plus
## every promotion choice, so it stays right for the rest of the game.
var _attack_tables: Array = [null, null]

func _init(p_board: Board, p_rules: GameRules) -> void:
	board = p_board
	rules = p_rules

## The legal moves for whoever's turn it is.
func moves() -> Array[Move]:
	return MoveGenerator.legal_moves(self)

## `team`'s attack table: the lines its pieces can capture along (cached).
func attack_table(team: Piece.Team) -> Array:
	if _attack_tables[team] == null:
		var defs: Array[PieceDef] = []
		for piece: Piece in board.pieces_of(team).values():
			if not defs.has(piece.def):
				defs.append(piece.def)
		for def in rules.promotion_options:
			if not defs.has(def):
				defs.append(def)
		_attack_tables[team] = MoveGenerator.attack_table(team, defs)
	return _attack_tables[team]

## True if the side to move has a royal piece under attack.
func is_in_check() -> bool:
	return MoveGenerator.is_in_check(board, side_to_move)

## How the game has ended, or Outcome.NONE if it's still going. For CHECKMATE,
## the side to move is the one that lost; every other outcome is a draw.
## Checkmate counts even if the mating move was also the 50th move.
func outcome() -> Outcome:
	if moves().is_empty():
		return Outcome.CHECKMATE if is_in_check() else Outcome.STALEMATE
	if _checkmate_impossible():
		return Outcome.INSUFFICIENT_MATERIAL
	if halfmove_clock >= 100:
		return Outcome.FIFTY_MOVES
	if _repetition_count() >= 3:
		return Outcome.REPETITION
	return Outcome.NONE

## The result as written in PGN: "1-0", "0-1", "1/2-1/2", or "*" if not over.
func result_text() -> String:
	match outcome():
		Outcome.NONE:
			return "*"
		Outcome.CHECKMATE:
			return "0-1" if side_to_move == Piece.Team.WHITE else "1-0"
	return "1/2-1/2"

func make_move(move: Move) -> void:
	move.piece_had_moved = move.piece.has_moved
	move.prev_en_passant_squares = en_passant_squares
	move.prev_en_passant_victim = en_passant_victim
	move.prev_halfmove_clock = halfmove_clock
	if move.is_capture() or move.piece.def.is_pawn_type():
		halfmove_clock = 0
	else:
		halfmove_clock += 1
	history.append(move)
	if move.breaks_shield():
		# Nothing moves: the shielded piece just loses its shield.
		move.shield_target.shield_broken = true
		en_passant_squares = []
		en_passant_victim = Board.NO_SQUARE
		_next_turn()
		return
	board.set_piece(move.from, null)
	board.set_piece(move.capture_square, null)
	if move.promotion:
		if move.promoted_piece == null:
			move.promoted_piece = Piece.new(move.promotion, move.piece.team)
			move.promoted_piece.has_moved = true
		board.set_piece(move.to, move.promoted_piece)
	else:
		board.set_piece(move.to, move.piece)
	move.piece.has_moved = true
	if move.is_castling():
		move.partner_had_moved = move.partner.has_moved
		board.set_piece(move.partner_from, null)
		board.set_piece(move.partner_to, move.partner)
		move.partner.has_moved = true
	# En passant is only possible on the very next move.
	en_passant_squares = move.skipped_squares
	en_passant_victim = move.to if not move.skipped_squares.is_empty() else Board.NO_SQUARE
	_next_turn()

func _next_turn() -> void:
	if side_to_move == Piece.Team.BLACK:
		fullmove_number += 1
	side_to_move = Piece.other_team(side_to_move)

func undo_move(move: Move) -> void:
	assert(not history.is_empty() and history.back() == move, "Moves must be undone last-first")
	history.pop_back()
	halfmove_clock = move.prev_halfmove_clock
	side_to_move = Piece.other_team(side_to_move)
	if side_to_move == Piece.Team.BLACK:
		fullmove_number -= 1
	move.piece.has_moved = move.piece_had_moved
	en_passant_squares = move.prev_en_passant_squares
	en_passant_victim = move.prev_en_passant_victim
	if move.breaks_shield():
		move.shield_target.shield_broken = false
		return
	if move.is_castling():
		move.partner.has_moved = move.partner_had_moved
		board.set_piece(move.partner_to, null)
		board.set_piece(move.partner_from, move.partner)
	board.set_piece(move.to, null)
	board.set_piece(move.capture_square, move.captured)  # null if nothing was captured.
	board.set_piece(move.from, move.piece)

## How many times the current position has occurred, counting now. "Same position"
## means the same pieces on the same squares, same side to move, same castling
## rights and same en passant possibilities. Only positions since the last capture
## or pawn-type move can match, so it steps back that far (undoing moves
## to look, then replaying them).
func _repetition_count() -> int:
	var key := _position_key()
	var count := 1
	var undone: Array[Move] = []
	for i in range(mini(halfmove_clock, history.size())):
		var move: Move = history.back()
		undo_move(move)
		undone.append(move)
		if _position_key() == key:
			count += 1
	for i in range(undone.size() - 1, -1, -1):
		make_move(undone[i])
	return count

## Text that is identical for two positions exactly when they count as the same
## position for repetition.
func _position_key() -> String:
	var fields := Fen.write(self).split(" ")
	var key := " ".join([fields[0], fields[1], fields[2]])
	# The en passant square only matters if an en passant capture can really be made.
	if not en_passant_squares.is_empty():
		for move in moves():
			if move.capture_square != move.to:
				key += " " + Board.square_name(move.to)
	return key

## True if neither side could ever checkmate. Worked out from the pieces' move data,
## not their names. Recognises: only royal pieces left; royals plus a single
## knight-style leaper (it can't attack the squares next to itself); royals plus
## pieces that stay on one square color (like bishops), all on the same color.
## Custom pieces will need more thought here later.
func _checkmate_impossible() -> bool:
	var others: Array[Piece] = []
	var square_colors := {}
	for rank in range(board.height):
		for file in range(board.width):
			var piece := board.get_piece(Vector2i(file, rank))
			if piece == null or piece.def.is_king_type():
				continue
			if piece.def.is_pawn_type():
				return false
			others.append(piece)
			square_colors[(file + rank) % 2] = true
	if others.is_empty():
		return true
	if others.size() == 1 and _is_distant_leaper(others[0].def):
		return true
	for piece in others:
		if not _stays_on_one_color(piece.def):
			return false
	return square_colors.size() == 1

## A piece whose every move is a single jump of 3+ squares' distance (|x| + |y|),
## like a knight. Such a piece can't guard the squares around itself.
static func _is_distant_leaper(def: PieceDef) -> bool:
	for rule in def.move_rules:
		if rule.is_unusual() or rule.max_steps != 1 or rule.first_move_max_steps > 1:
			return false
		for dir in rule.directions:
			if absi(dir.x) + absi(dir.y) < 3:
				return false
	return true

## True if every move keeps the piece on the same square color, like a bishop.
static func _stays_on_one_color(def: PieceDef) -> bool:
	for rule in def.move_rules:
		if not rule.path.is_empty():
			for steps: Array in rule.path_variants():
				var offset := MoveRule.path_offset(steps)
				if (offset.x + offset.y) % 2 != 0:
					return false
			continue
		for dir in rule.directions:
			if (dir.x + dir.y) % 2 != 0:
				return false
	return true

## The available move whose to_text() matches, e.g. "e2-e4" or "e7-e8=Q", or null.
## For tests.
func find_move(text: String) -> Move:
	for move in moves():
		if move.to_text() == text:
			return move
	return null
