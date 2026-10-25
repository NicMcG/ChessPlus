extends TestSuite

## Mac's two first-move rules (25 Oct 2026): a piece must have moved once
## before it can promote (reaching the far rank on its first move, it just
## stands there), and White may not attack on its first move of a game (no
## capture, no shield break; Black's first move is free). The second applies
## to games played from the start, not to positions set up from FEN or in
## testing mode.

const KING = preload("res://data/pieces/king.tres")
const LANCE = preload("res://data/pieces/lance.tres")
const ROOK = preload("res://data/pieces/rook.tres")
const PAWN = preload("res://data/pieces/pawn.tres")
const PALADIN = preload("res://data/pieces/paladin.tres")

func _army(pieces: Array) -> Army:
	var army := Army.new()
	for entry: Array in pieces:
		army.place(entry[0], entry[1])
	return army

func _game(white: Array, black: Array) -> GameState:
	return ArmySetup.create_game(_army(white), _army(black), StandardSetup.create_rules())

func _texts(state: GameState) -> Array:
	return state.moves().map(func(m: Move) -> String: return m.to_text())

func test_a_lance_cannot_promote_on_its_first_move() -> void:
	# White's Lance on d2 looks up an empty d-file; Black's rook is on a7, away from it.
	var state := _game([[KING, Vector2i(4, 0)], [LANCE, Vector2i(3, 1)]], [[KING, Vector2i(3, 0)], [ROOK, Vector2i(0, 1)]])
	var texts := _texts(state)
	check(texts.has("d2-d8"), "The Lance may slide to the far rank: " + str(texts))
	check(not texts.has("d2-d8=R") and not texts.has("d2-d8=L"), "...but not promote on its first move")
	state.make_move(state.find_move("d2-d8"))
	check_eq(state.board.get_piece(Vector2i(3, 7)).def, LANCE, "It stands on d8 as a Lance")

func test_a_moved_lance_promotes() -> void:
	var state := _game([[KING, Vector2i(4, 0)], [LANCE, Vector2i(3, 1)]], [[KING, Vector2i(3, 0)], [ROOK, Vector2i(0, 1)]])
	state.make_move(state.find_move("d2-d3"))
	state.make_move(state.find_move("e8-f8"))
	var texts := _texts(state)
	check(texts.has("d3-d8=R"), "After one move it promotes on reaching the far rank: " + str(texts))
	check(not texts.has("d3-d8"), "...and must (no plain move there)")

func test_white_may_not_attack_on_its_first_move() -> void:
	# Black's army is mirrored, so its rook on file 4 lands on d7, straight up White's Lance's file.
	var state := _game([[KING, Vector2i(4, 0)], [LANCE, Vector2i(3, 1)]], [[KING, Vector2i(3, 0)], [ROOK, Vector2i(4, 1)]])
	check(state.board.get_piece(Vector2i(3, 6)) != null and state.board.get_piece(Vector2i(3, 6)).def == ROOK, "Black's rook stands on d7")
	check(state.white_quiet_first_move_applies(), "The rule applies to White's first move of an army game")
	var texts := _texts(state)
	check(not texts.has("d2xd7"), "White can't capture on move 1: " + str(texts))
	check(texts.has("d2-d3"), "...but may move")
	var capture := Move.new(Vector2i(3, 1), Vector2i(3, 6), state.board.get_piece(Vector2i(3, 1)), state.board.get_piece(Vector2i(3, 6)))
	capture.capture_square = Vector2i(3, 6)
	check(not MoveGenerator.is_legal(state, capture), "is_legal says no too")
	state.make_move(state.find_move("e1-f1"))
	check(not state.white_quiet_first_move_applies(), "Black's first move is free")
	check(_texts(state).has("d7xd2"), "Black may capture at once: " + str(_texts(state)))
	state.undo_move(state.history.back())
	check(not _texts(state).has("d2xd7"), "Undo back to the start: the rule applies again")
	state.make_move(state.find_move("d2-d3"))
	state.make_move(state.find_move("e8-f8"))
	check(_texts(state).has("d3xd7"), "From White's second move on, captures are allowed")

func test_a_shield_break_counts_as_an_attack() -> void:
	var state := _game([[KING, Vector2i(4, 0)], [LANCE, Vector2i(3, 1)]], [[KING, Vector2i(3, 0)], [PALADIN, Vector2i(4, 1)]])
	check(state.board.get_piece(Vector2i(3, 6)).def == PALADIN, "Black's Paladin stands on d7")
	check(not _texts(state).has("d2xd7"), "No shield break on White's first move: " + str(_texts(state)))

func test_positions_and_standard_chess_are_not_affected() -> void:
	var fen := Fen.parse("4k3/3r4/8/8/8/8/3L4/4K3 w - - 0 1", PieceCatalog.all_defs(), StandardSetup.create_rules())
	check(fen.from_position and not fen.white_quiet_first_move_applies(), "A FEN position isn't a game's start")
	check(_texts(fen).has("d2xd7"), "...so White may capture: " + str(_texts(fen)))
	var setup := TestingPosition.new()
	setup.pieces[Board.parse_square("e1")] = [KING, Piece.Team.WHITE]
	setup.pieces[Board.parse_square("e8")] = [KING, Piece.Team.BLACK]
	setup.pieces[Board.parse_square("d2")] = [LANCE, Piece.Team.WHITE]
	setup.pieces[Board.parse_square("d7")] = [ROOK, Piece.Team.BLACK]
	var testing := setup.create_state()
	check(testing.from_position and _texts(testing).has("d2xd7"), "Testing mode neither")
	var chess := StandardSetup.create_game()
	check(chess.white_quiet_first_move_applies() and chess.moves().size() == 20, "Standard chess: the rule applies and changes nothing (20 moves)")

func test_prices() -> void:
	check_eq(preload("res://data/pieces/grunt.tres").value, 1.0, "Grunt 1 (Mac, 25 Oct 2026)")
	check_eq(preload("res://data/pieces/abatis.tres").value, 0.5, "Abatis 0.5")
	check_eq(LANCE.value, 3.0, "Lance 3")
	check_eq(preload("res://data/pieces/werewolf.tres").value, 3.0, "Werewolf 3")
	check_eq(preload("res://data/pieces/forms/werewolf_wolf.tres").value, 3.0, "...and its wolf form")
