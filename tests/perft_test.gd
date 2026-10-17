class_name PerftTest
extends TestSuite

## Perft ("performance test") counts every possible sequence of moves to a given
## depth. The right totals are known for many positions, so any mistake in the
## move generator shows up as a wrong count.

const KIWIPETE := "r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1"
## "Position 3" from the Chess Programming Wiki: lots of en passant and pins.
const POSITION_3 := "8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1"
## Positions 4 and 5 from the Chess Programming Wiki: promotions galore.
const POSITION_4 := "r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1"
const POSITION_5 := "rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8"

static func perft(state: GameState, depth: int) -> int:
	var moves := state.moves()
	if depth == 1:
		return moves.size()
	var total := 0
	for move in moves:
		state.make_move(move)
		total += perft(state, depth - 1)
		state.undo_move(move)
	return total

## For debugging a wrong count: prints the count after each first move, to compare
## line by line with a trusted engine and find which move goes wrong.
static func divide(state: GameState, depth: int) -> void:
	for move in state.moves():
		state.make_move(move)
		print(move.to_text(), ": ", perft(state, depth - 1) if depth > 1 else 1)
		state.undo_move(move)

func _check_perft(fen: String, expected: Array[int]) -> void:
	var state := StandardSetup.from_fen(fen)
	var before := Fen.write(state)
	for i in range(expected.size()):
		check_eq(perft(state, i + 1), expected[i], "Depth %d" % (i + 1))
	check_eq(Fen.write(state), before, "Position after perft (make/undo must undo everything)")

func test_start_position() -> void:
	_check_perft(Fen.STANDARD_START, [20, 400, 8902])

func slow_test_start_position_depth_4() -> void:
	_check_perft(Fen.STANDARD_START, [20, 400, 8902, 197281])

func test_kiwipete() -> void:
	_check_perft(KIWIPETE, [48, 2039])

func slow_test_kiwipete_depth_3() -> void:
	_check_perft(KIWIPETE, [48, 2039, 97862])
func test_position_3() -> void:
	_check_perft(POSITION_3, [14, 191, 2812])

func slow_test_position_3_depth_5() -> void:
	_check_perft(POSITION_3, [14, 191, 2812, 43238, 674624])

func test_position_4() -> void:
	_check_perft(POSITION_4, [6, 264, 9467])

func slow_test_position_4_depth_4() -> void:
	_check_perft(POSITION_4, [6, 264, 9467, 422333])

func test_position_5() -> void:
	_check_perft(POSITION_5, [44, 1486])

func slow_test_position_5_depth_3() -> void:
	_check_perft(POSITION_5, [44, 1486, 62379])
