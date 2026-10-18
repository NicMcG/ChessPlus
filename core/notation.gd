class_name Notation
extends RefCounted

## Two ways of writing moves:
##   Text (standard algebraic notation, SAN): e4, Nf3, exd5, Nbd2, O-O, e8=Q,
##     Qh4#. A capture that only breaks a Shield ends in *, e.g. Rxd5*. Piece
##     letters come from PieceDef.symbol, uppercase for both teams; the piece
##     whose symbol is "P" gets no letter. Used for tests and saved text.
##   Pictures (what players see, Mac's design): picture() gives a list of parts
##     (piece pictures, small icons and bits of text) that the move list draws:
##     [piece] e4, [piece] [crossed swords] d5, [piece] [cracked shield] d5,
##     then a warning-triangle icon for check or a skull and crossbones for mate.

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
		# A capture that only broke a Shield (the piece is still there): Rxd5*.
		# Nothing moves, so it can never give check: there's never a + after it.
		if move.breaks_shield():
			text += "*"
	return text + _check_suffix(state, move)

## Icon names for picture notation (pictures in res://art/icons/).
const CAPTURE_ICON := "capture"
const SHIELD_BREAK_ICON := "shield_break"
const CHECK_ICON := "check"
const CHECKMATE_ICON := "checkmate"
const ABILITY_ICON := "ability"

## `move` (legal in `state`) in picture notation: a list of parts, each one of
##   {"piece": PieceDef, "team": Piece.Team}  a small picture of that piece
##   {"icon": name}                           a small symbol (see the *_ICON names)
##   {"text": "e4"}                           text (squares, files, castling)
## e.g. Nxd5+ is [knight, capture icon, "d5", check icon].
static func picture(state: GameState, move: Move) -> Array:
	return _picture(state, move, _check_suffix(state, move))

static func _picture(state: GameState, move: Move, check_suffix: String) -> Array:
	var parts := [{"piece": move.piece.def, "team": move.piece.team}]
	if move.is_castling():
		parts.append({"text": "O-O" if move.to.x > move.from.x else "O-O-O"})
	else:
		# Which piece of that type moved, when it isn't obvious: a pawn capturing
		# names its file (exd5); others add a file or rank only if needed (Nbd2).
		var detail := ""
		if move.piece.def.symbol.to_upper() == NO_LETTER_SYMBOL:
			if move.is_capture():
				detail = Board.FILE_LETTERS[move.from.x]
		else:
			detail = _disambiguation(state, move)
		if detail != "":
			parts.append({"text": detail})
		if move.breaks_shield():
			parts.append({"icon": SHIELD_BREAK_ICON})
		elif move.is_capture():
			parts.append({"icon": CAPTURE_ICON})
		parts.append({"text": Board.square_name(move.to)})
		if move.promotion:
			parts.append({"text": "="})
			parts.append({"piece": move.promotion, "team": move.piece.team})
	if check_suffix == "+":
		parts.append({"icon": CHECK_ICON})
	elif check_suffix == "#":
		parts.append({"icon": CHECKMATE_ICON})
	return parts

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
	var parts: PackedStringArray = []
	for entry in numbered_moves(state):
		if entry[0] != "":
			parts.append(entry[0])
		parts.append(entry[1])
	var result := state.result_text()
	if result != "*":
		parts.append(result)
	return " ".join(parts)

## Every move played, oldest first, as [move number, notation, picture]: the
## number is "1." before White's moves, "" before Black's, or "1..." if Black
## moved first; the picture is from picture().
static func numbered_moves(state: GameState) -> Array:
	# Step back to the first position, then replay, writing each move as we go.
	var moves := state.history.duplicate()
	for i in range(moves.size() - 1, -1, -1):
		state.undo_move(moves[i])
	var entries := []
	for i in range(moves.size()):
		var move: Move = moves[i]
		var number := ""
		if state.side_to_move == Piece.Team.WHITE:
			number = "%d." % state.fullmove_number
		elif i == 0:
			number = "%d..." % state.fullmove_number
		var text := san(state, move)
		var suffix := text.substr(text.length() - 1) if text.ends_with("+") or text.ends_with("#") else ""
		entries.append([number, text, _picture(state, move, suffix)])
		state.make_move(move)
	return entries

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
