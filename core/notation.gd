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
##     [pawn] a8 [arrow] [queen], [bishop] [crossed swords] d5 [jester] c6 (the
##     attacker chose the Jester on c6 to take the hit),
##     then a warning-triangle icon for check or a skull and crossbones for mate.

const NO_LETTER_SYMBOL := "P"

## The SAN for `move`, which must be a legal move in `state`'s current position.
static func san(state: GameState, move: Move) -> String:
	return _san(move, _check_suffix(state, move), _detail(state, move))

## san() with its check mark ("+", "#" or "") and _detail already worked out.
static func _san(move: Move, check_suffix: String, detail: String) -> String:
	var text := ""
	if move.ability == PieceDef.Ability.RAISE_DEAD:
		# Text only (for tests and saving): NC!=Q
		return move.piece.def.symbol.to_upper() + "!=" + move.raised.def.symbol.to_upper() + check_suffix
	# Text only too: G@e3 (Haunt), BDc1~g5 (Song of Slumber), WWe4! (Full Moon).
	var letters := move.piece.def.symbol.to_upper()
	if move.ability == PieceDef.Ability.HAUNT:
		return letters + "@" + Board.square_name(move.to) + check_suffix
	if move.ability == PieceDef.Ability.SONG_OF_SLUMBER:
		return letters + Board.square_name(move.from) + "~" + Board.square_name(move.to) + check_suffix
	if move.ability == PieceDef.Ability.FULL_MOON:
		return letters + Board.square_name(move.from) + "!" + check_suffix
	if move.is_castling():
		text = "O-O" if move.to.x > move.from.x else "O-O-O"
	else:
		var letter := move.piece.def.symbol.to_upper()
		# A letterless capture names the file it came from (exd5); other pieces
		# may need a file or rank (Nbd2).
		text = detail if letter == NO_LETTER_SYMBOL else letter + detail
		if move.is_capture():
			text += "x"
		text += Board.square_name(move.to)
		if move.promotion:
			text += "=" + move.promotion.symbol.to_upper()
		# A capture that only broke a Shield (the piece is still there): Rxd5*.
		# Nothing moves, so it can never give check: there's never a + after it.
		if move.breaks_shield():
			text += "*"
		# Crack Shot (text only): Axd5!
		if move.ability == PieceDef.Ability.CRACK_SHOT:
			text += "!"
		# The attacker chose which Jester takes the hit: Bxd5/c6.
		text += move.decoy_text()
	return text + check_suffix

## Which piece of its type made the move, when it isn't obvious from the
## square it went to: a pawn capturing names its file (exd5); other pieces add a
## file or rank only if needed (Nbd2). "" for castling and abilities that don't
## write it. Shared by san() and picture(), so it's only worked out once.
static func _detail(state: GameState, move: Move) -> String:
	if move.is_castling() or (move.ability != PieceDef.Ability.NONE and move.ability != PieceDef.Ability.CRACK_SHOT):
		return ""
	if move.piece.def.symbol.to_upper() == NO_LETTER_SYMBOL:
		return Board.FILE_LETTERS[move.from.x] if move.is_capture() else ""
	return _disambiguation(state, move)

## Icon names for picture notation (pictures in res://art/icons/).
const CAPTURE_ICON := "capture"
const SHIELD_BREAK_ICON := "shield_break"
const CHECK_ICON := "check"
const CHECKMATE_ICON := "checkmate"
const ABILITY_ICON := "ability"
const PROMOTE_ICON := "promote"

## `move` (legal in `state`) in picture notation: a list of parts, each one of
##   {"piece": PieceDef, "team": Piece.Team}  a small picture of that piece
##   {"icon": name}                           a small symbol (see the *_ICON names)
##   {"text": "e4"}                           text (squares, files, castling)
## e.g. Nxd5+ is [knight, capture icon, "d5", check icon].
static func picture(state: GameState, move: Move) -> Array:
	return _picture(move, _check_suffix(state, move), _detail(state, move))

## picture() with its check mark and _detail already worked out.
static func _picture(move: Move, check_suffix: String, detail: String) -> Array:
	var parts := [{"piece": move.piece.def, "team": move.piece.team}]
	if move.ability != PieceDef.Ability.NONE:
		# A special ability: [piece] [lightning bolt] [the piece it targets or brings back].
		parts.append({"icon": ABILITY_ICON})
		if move.ability == PieceDef.Ability.RAISE_DEAD:
			parts.append({"piece": move.raised.def, "team": move.raised.team})
		elif move.ability == PieceDef.Ability.HAUNT:
			# [ghost] [lightning bolt] e3: where it came back.
			parts.append({"text": Board.square_name(move.to)})
		elif move.ability == PieceDef.Ability.FULL_MOON:
			# [werewolf] [lightning bolt] [wolf].
			parts.append({"piece": move.piece.def.transforms_into, "team": move.piece.team})
		elif move.ability == PieceDef.Ability.SONG_OF_SLUMBER:
			parts.append({"piece": move.frozen.def, "team": move.frozen.team})
		else:
			var target := move.captured if move.captured else move.shield_target
			parts.append({"piece": target.def, "team": target.team})
			if move.breaks_shield():
				parts.append({"icon": SHIELD_BREAK_ICON})
			if move.decoy_choice:
				# Which Jester took the shot: [archer] [lightning bolt] [jester] c6.
				parts.append({"text": Board.square_name(move.decoy_square)})
	elif move.is_castling():
		parts.append({"text": "O-O" if move.to.x > move.from.x else "O-O-O"})
	else:
		# Which piece of that type moved, when it isn't obvious (see _detail).
		if detail != "":
			parts.append({"text": detail})
		if move.breaks_shield():
			parts.append({"icon": SHIELD_BREAK_ICON})
		elif move.is_capture():
			parts.append({"icon": CAPTURE_ICON})
		parts.append({"text": Board.square_name(move.to)})
		if move.promotion:
			parts.append({"icon": PROMOTE_ICON})
			parts.append({"piece": move.promotion, "team": move.piece.team})
		if move.decoy_choice:
			# Which Jester the attacker chose to take the hit: ... d5 [jester] c6.
			parts.append({"piece": move.captured.def, "team": move.captured.team})
			parts.append({"text": Board.square_name(move.decoy_square)})
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
## moved first; the picture is from picture(). With `first`, only the moves
## from that one on (a side line starting there: "12..." if Black moves first).
static func numbered_moves(state: GameState, first := 0) -> Array:
	# Step back to where the list starts, then replay, writing each move as we go.
	var moves := state.history.duplicate()
	var marks := state.position_marks()
	for i in range(moves.size() - 1, first - 1, -1):
		state.undo_move(moves[i])
	var entries := []
	for i in range(first, moves.size()):
		var move: Move = moves[i]
		var number := ""
		if state.side_to_move == Piece.Team.WHITE:
			number = "%d." % state.fullmove_number
		elif i == first:
			number = "%d..." % state.fullmove_number
		var suffix := _check_suffix(state, move)
		var detail := _detail(state, move)
		entries.append([number, _san(move, suffix, detail), _picture(move, suffix, detail)])
		state.make_move(move)
	state.same_position_again(marks)
	return entries

## Extra file and/or rank needed when another piece of the same type could also
## move to the same square: file if that's enough (Nbd2), otherwise rank (R1a2),
## otherwise both (Qa1b2).
static func _disambiguation(state: GameState, move: Move) -> String:
	# Usually no other piece of the type can get there at all: checking that
	# among the moves the pieces can make is quick, and the legal moves (each
	# checked for leaving the king attacked) are only needed if one can.
	var candidates := _rival_moves(MoveGenerator.pseudo_legal_moves(state), move)
	if candidates.is_empty():
		return ""
	# Only the rivals' own moves need checking for leaving the king attacked.
	var rivals: Array[Vector2i] = []
	for other in candidates:
		if not rivals.has(other.from) and MoveGenerator.is_legal(state, other):
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

## The moves among `moves` by other pieces of `move`'s type to the same square.
static func _rival_moves(moves: Array[Move], move: Move) -> Array[Move]:
	var rivals: Array[Move] = []
	for other in moves:
		if other.to == move.to and other.from != move.from and other.piece.def == move.piece.def:
			rivals.append(other)
	return rivals

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
