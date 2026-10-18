extends TestSuite

## The practice bot. Seeds make Easy/Medium's randomness repeatable.

func _parse(fen: String) -> GameState:
	return Fen.parse(fen, PieceCatalog.all_defs(), StandardSetup.create_rules())

func _bot(level: PracticeBot.Level) -> PracticeBot:
	return PracticeBot.new(level, 7)

func test_takes_a_free_queen() -> void:
	# White's rook can take the undefended black queen.
	var state := _parse("4k3/8/8/3q4/8/8/8/3RK3 w - - 0 1")
	for level in [PracticeBot.Level.MEDIUM, PracticeBot.Level.HARD]:
		var move := _bot(level).choose_move(state)
		check_eq(move.to_text(), "d1xd5", "Level %d takes the queen" % level)

func test_finds_mate_in_one() -> void:
	# Scholar's mate: Qxf7 is checkmate.
	var state := _parse("r1bqkbnr/pppp1ppp/2n5/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4")
	check_eq(_bot(PracticeBot.Level.HARD).choose_move(state).to_text(), "h5xf7", "Hard mates")
	check_eq(_bot(PracticeBot.Level.MEDIUM).choose_move(state).to_text(), "h5xf7", "Medium mates")

func test_does_not_hang_its_queen() -> void:
	# Taking the pawn on e5 with the queen would lose her to the d6 pawn.
	var state := _parse("4k3/8/3p4/4p3/8/8/4Q3/4K3 w - - 0 1")
	var move := _bot(PracticeBot.Level.HARD).choose_move(state)
	check(move.to_text() != "e2xe5", "Hard doesn't take a defended pawn with the queen")

func test_leaves_the_state_unchanged() -> void:
	var state := StandardSetup.create_game()
	var before := Fen.write(state)
	_bot(PracticeBot.Level.HARD).choose_move(state)
	check_eq(Fen.write(state), before, "Position")
	check_eq(state.history.size(), 0, "History")

func test_easy_picks_legal_moves() -> void:
	_check_legal_moves([PracticeBot.Level.EASY])

func slow_test_every_level_picks_legal_moves() -> void:
	_check_legal_moves([PracticeBot.Level.EASY, PracticeBot.Level.MEDIUM, PracticeBot.Level.HARD])

func _check_legal_moves(levels: Array) -> void:
	for level in levels:
		var state := StandardSetup.create_game()
		var bot := _bot(level)
		for i in 6:
			var move := bot.choose_move(state)
			check(move != null, "Level %d found a move" % level)
			if move == null:
				break
			var legal := state.moves().map(func(m: Move) -> String: return m.to_text())
			check(legal.has(move.to_text()), "Legal: " + move.to_text())
			state.make_move(move)

func test_no_moves_means_null() -> void:
	var state := _parse("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
	check(_bot(PracticeBot.Level.HARD).choose_move(state) == null, "Stalemated: no move")

func test_stays_within_its_time_limit() -> void:
	var state := _parse(PerftTest.KIWIPETE)
	var start := Time.get_ticks_msec()
	_bot(PracticeBot.Level.HARD).choose_move(state)
	var took := Time.get_ticks_msec() - start
	check(took < PracticeBot.SETTINGS[PracticeBot.Level.HARD].time_ms + 800, "Took %d ms" % took)

func test_handles_custom_pieces() -> void:
	# A cannon can only take the rook by hopping over the pawn.
	var state := _parse("k3r3/8/8/8/4p3/8/8/K3C3 w - - 0 1")
	check_eq(_bot(PracticeBot.Level.MEDIUM).choose_move(state).to_text(), "e1xe8", "Cannon hops to win the rook")

# --- How it scores positions -------------------------------------------------------

func test_pieces_score_more_where_they_reach_more() -> void:
	var knight: PieceDef = load("res://data/pieces/knight.tres")
	var board := Board.new(8, 8)
	check_eq(PracticeBot.reach(knight, Vector2i(0, 0), Piece.Team.WHITE, board), 2, "Knight in the corner")
	check_eq(PracticeBot.reach(knight, Vector2i(3, 3), Piece.Team.WHITE, board), 8, "Knight in the centre")
	var centre := _parse("4k3/8/8/8/3N4/8/8/4K3 w - - 0 1")
	var corner := _parse("4k3/8/8/8/8/8/8/N3K3 w - - 0 1")
	check(PracticeBot.evaluate(centre) > PracticeBot.evaluate(corner), "Central knight is better")

func test_king_safety_while_pieces_remain() -> void:
	# Same pieces; in one the king sits behind its pawns in the corner, in the
	# other it has walked out into the middle.
	var safe := _parse("r2qk2r/8/8/8/8/8/5PPP/3Q1RK1 w - - 0 1")
	var exposed := _parse("r2qk2r/8/8/8/8/4K3/5PPP/3Q1R2 w - - 0 1")
	check(PracticeBot.evaluate(safe) > PracticeBot.evaluate(exposed), "Sheltered king is better")

func test_being_in_check_counts_against_you() -> void:
	var checked := _parse("4k3/8/8/8/8/8/4r3/4K3 w - - 0 1")
	var not_checked := _parse("4k3/8/8/8/8/8/3r4/4K3 w - - 0 1")
	check(PracticeBot.evaluate(checked) < PracticeBot.evaluate(not_checked), "Check is a little worse")

func test_wins_material_with_a_fork() -> void:
	# Nc7+ forks the king and the rook on a8.
	var state := _parse("r3k3/8/8/1N6/8/8/8/4K3 w - - 0 1")
	check_eq(_bot(PracticeBot.Level.HARD).choose_move(state).to_text(), "b5-c7", "Hard finds the knight fork")
