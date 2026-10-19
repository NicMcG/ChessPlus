extends SceneTree

## Shows, with the game's own engine, that two legal armies can start with
## Black's king attacked, so White's first move can capture it.
##   godot --headless --path <ChessPlus> -s res://tools/king_capture_demo.gd

func _init() -> void:
	var white := StandardSetup.army()
	# White swaps the e-pawn for a Lance (Promote keyword, slides forward).
	white.place(load("res://data/pieces/lance.tres"), Vector2i(4, 1))
	white.remove_at(Vector2i(6, 0))  # and drops the g1 knight to stay in budget
	var black := StandardSetup.army()
	# Black leaves e7 empty (one pawn fewer; still a legal army).
	black.remove_at(Vector2i(4, 1))
	print("White army problems: ", white.problems(GameRules.new(), 8), "  cost ", white.cost())
	print("Black army problems: ", black.problems(GameRules.new(), 8), "  cost ", black.cost())
	var state := ArmySetup.create_game(white, black, StandardSetup.create_rules())
	print(state.board.to_text())
	var captures := []
	for move in state.moves():
		if move.captured and move.captured.def.is_king_type():
			captures.append(move.to_text())
	print("White's legal moves that capture the king: ", captures)
	state.make_move(state.find_move(captures[0]))
	print(state.board.to_text())
	print("Black in check now? ", state.is_in_check(), "   outcome: ", state.outcome(), " (0 = game goes on)")
	# Black has no king, so it can never be checkmated: play on a bit.
	print("Black legal moves: ", state.moves().size())
	quit()
