class_name Notation
extends RefCounted

## Standard algebraic notation (SAN) for moves, e.g. e4, Nf3, exd5, Nbd2, O-O,
## e8=Q, Qh4#. Piece letters come from PieceDef.symbol and are uppercase for both
## teams. The piece whose symbol is "P" gets no letter, as pawns do in chess.

const NO_LETTER_SYMBOL := "P"

## The SAN for `move`, which must be a legal move in `state`'s current position.
static func san(state: GameState, move: Move) -> String:
	var text := ""
	if move.is_castling():
		text = "O-O" if move.to.x > move.from.x else "O-O-O"
	else:
		var letter := move.piece.def.symbol.to_upper()
		if letter == NO_LETTER_SYMBOL:
			# A letterless capture names the file it came from: exd5.
			if move.is_capture():
				text = Board.FILE_LETTERS[move.from.x]
		else:
			text = letter + _disambiguation(state, move)
		if move.is_capture():
			text += "x"
		text += Board.square_name(move.to)
		if move.promotion:
			text += "=" + move.promotion.symbol.to_upper()
	return text + _check_suffix(state, move)

## The legal move whose SAN matches `text`, or null. Check marks (+, #) are optional.
static func find_move(state: GameState, text: String) -> Move:
	var wanted := _strip_check(text.strip_edges())
	for move in state.moves():
		if _strip_check(san(state, move)) == wanted:
			return move
	return null

## The game so far as a numbered move list, e.g. "1. e4 e5 2. Nf3 Nc6", with the
## result on the end if the game is over.
static func move_list(state: GameState) -> String:
	# Step back to the first position, then replay, writing each move as we go.
	var moves := state.history.duplicate()
	for i in range(moves.size() - 1, -1, -1):
		state.undo_move(moves[i])
	var parts: PackedStringArray = []
	for i in range(moves.size()):
		var move: Move = moves[i]
		if state.side_to_move == Piece.Team.WHITE:
			parts.append("%d." % state.fullmove_number)
		elif i == 0:
			parts.append("%d..." % state.fullmove_number)
		parts.append(san(state, move))
		state.make_move(move)
	var result := state.result_text()
	if result != "*":
		parts.append(result)
	return " ".join(parts)

## Extra file and/or rank needed when another piece of the same type could also
## move to the same square: file if that's enough (Nbd2), otherwise rank (R1a2),
## otherwise both (Qa1b2).
static func _disambiguation(state: GameState, move: Move) -> String:
	var rivals: Array[Vector2i] = []
	for other in state.moves():
		if other.to == move.to and other.from != move.from and other.piece.def == move.piece.def:
			if not rivals.has(other.from):
				rivals.append(other.from)
	if rivals.is_empty():
		return ""
	var file_clash := rivals.any(func(pos: Vector2i) -> bool: return pos.x == move.from.x)
	var rank_clash := rivals.any(func(pos: Vector2i) -> bool: return pos.y == move.from.y)
	var file_text: String = Board.FILE_LETTERS[move.from.x]
	var rank_text := str(move.from.y + 1)
	if not file_clash:
		return file_text
	if not rank_clash:
		return rank_text
	return file_text + rank_text

## "+" if the move gives check, "#" if it's checkmate, otherwise "".
static func _check_suffix(state: GameState, move: Move) -> String:
	state.make_move(move)
	var suffix := ""
	if state.is_in_check():
		suffix = "#" if state.moves().is_empty() else "+"
	state.undo_move(move)
	return suffix

static func _strip_check(text: String) -> String:
	return text.rstrip("+#")
