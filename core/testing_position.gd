class_name TestingPosition
extends RefCounted

## A position set up by hand in Testing mode (Mac's design, Oct 2026): any pieces
## on any squares, pieces already captured, and who moves first. A game starts
## from it with create_state(); it can be built again the same way any time
## (New game, looking back through the moves).

var width := 8
var height := 8
## What stands where: square -> [PieceDef, Piece.Team].
var pieces := {}
## Pieces already captured: [PieceDef, Piece.Team] each (the team that lost it).
var captured: Array = []
var side_to_move := Piece.Team.WHITE

func get_at(square: Vector2i) -> Array:
	return pieces.get(square, [])

func place(square: Vector2i, def: PieceDef, team: Piece.Team) -> void:
	pieces[square] = [def, team]

func remove_at(square: Vector2i) -> void:
	pieces.erase(square)

func clear() -> void:
	pieces.clear()
	captured.clear()
	side_to_move = Piece.Team.WHITE

## Take all of `team`'s pieces off and set up `army` for that side instead,
## where it would start in a real game (ArmySetup). Its pieces replace anything
## of the other side's standing on their squares.
func load_army(army: Army, team: Piece.Team) -> void:
	for square: Vector2i in pieces.keys():
		if pieces[square][1] == team:
			pieces.erase(square)
	for piece in army.pieces:
		place(ArmySetup.board_square(army, piece, team, width, height), piece.def, team)

## A copy that can be changed without changing this one.
func copy() -> TestingPosition:
	var other := TestingPosition.new()
	other.width = width
	other.height = height
	other.pieces = pieces.duplicate()
	other.captured = captured.duplicate()
	other.side_to_move = side_to_move
	return other

## The standard chess starting position.
static func standard() -> TestingPosition:
	var position := TestingPosition.new()
	var board := StandardSetup.create_board()
	for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
		var on_board := board.pieces_of(team)
		for square: Vector2i in on_board:
			position.place(square, on_board[square].def, team)
	return position

## A new game from this position. Every piece starts unmoved (pawns may make
## their double step, kings may castle with partners in their corners), with
## its shield and ability; the captured pieces are already in each side's lost
## pieces (so Raise Dead and Haunt can use them). Pawns promote to any piece
## type on the board, as in army games.
func create_state() -> GameState:
	var board := Board.new(width, height)
	for square: Vector2i in pieces:
		var entry: Array = pieces[square]
		board.set_piece(square, _new_piece(entry[0], entry[1]))
	var rules: GameRules = StandardSetup.create_rules().duplicate()
	rules.promotion_options = ArmySetup.promotion_options_for(board)
	var state := GameState.new(board, rules)
	state.side_to_move = side_to_move
	for entry: Array in captured:
		state.lost[entry[1]].append(_new_piece(entry[0], entry[1]))
	return state

## A piece of `def`. A changed form (the wolf) remembers what it started as.
static func _new_piece(def: PieceDef, team: Piece.Team) -> Piece:
	var piece := Piece.new(def, team)
	for other: PieceDef in PieceCatalog.all_defs():
		if other.transforms_into == def:
			piece.base_def = other
			piece.ability_used = true
	return piece

## Why a game can't start from this position, in plain English (empty = it can).
func problems() -> PackedStringArray:
	var found: PackedStringArray = []
	for team in [Piece.Team.WHITE, Piece.Team.BLACK]:
		var name := "White" if team == Piece.Team.WHITE else "Black"
		var kings := 0
		for square: Vector2i in pieces:
			var entry: Array = pieces[square]
			var def: PieceDef = entry[0]
			if entry[1] != team:
				continue
			if def.is_king_type():
				kings += 1
			var far_rank := height - 1 if team == Piece.Team.WHITE else 0
			if def.is_pawn_type() and square.y == far_rank:
				found.append("%s's %s can't start on the far row." % [name, def.display_name])
		if kings != 1:
			found.append("%s needs exactly one King." % name)
	if found.is_empty():
		# The side not to move mustn't start in check: the side to move would just
		# win (see GameState.Outcome.KING_EXPOSED).
		var waiting := Piece.other_team(side_to_move)
		if MoveGenerator.is_in_check(create_state().board, waiting):
			var name := "White" if waiting == Piece.Team.WHITE else "Black"
			found.append("%s's King is in check, but it's %s's move." % [name, "Black" if waiting == Piece.Team.WHITE else "White"])
	return found
