extends TestSuite

## The plans for animating moves (MoveAnimation): which pieces slide, hop, slam
## or get knocked off, the extras (cannonball, arrow, smoke, ...) and the sounds.

const Sound = GameSounds.Sound

func _game(fen: String) -> GameState:
	return Fen.parse(fen, PieceCatalog.all_defs(), StandardSetup.create_rules())

## Make the move written `san` and return its animation (dropped = dragged there).
func _animate(state: GameState, san: String, dropped := false) -> MoveAnimation:
	var move := Notation.find_move(state, san)
	check(move != null, "Legal: " + san)
	state.make_move(move)
	return MoveAnimation.for_move(move, state, dropped)

func _ability_move(state: GameState, ability: PieceDef.Ability) -> Move:
	for move in state.moves():
		if move.ability == ability:
			return move
	return null

func _sounds(animation: MoveAnimation) -> Array:
	return animation.all_sounds()

func test_ordinary_move_slides() -> void:
	var state := StandardSetup.create_game()
	var pawn := state.board.get_piece(Vector2i(4, 1))
	var animation := _animate(state, "e4")
	check(animation.has_segment(pawn, "slide"), "The pawn slides")
	check_eq(_sounds(animation), [Sound.SCRAPE, Sound.MOVE], "Scraping along the board, then a knock")
	check(is_equal_approx(animation.length, MoveAnimation.SLIDE), "As long as a slide")

func test_knight_hops_and_lands() -> void:
	var state := StandardSetup.create_game()
	var knight := state.board.get_piece(Vector2i(6, 0))
	var animation := _animate(state, "Nf3")
	check(animation.has_segment(knight, "hop"), "The knight hops")
	check(not animation.has_segment(knight, "slide"), "Doesn't slide")
	check_eq(_sounds(animation), [Sound.LAND], "Lands with a knock")
	# Halfway through it's up in the air.
	animation.time = animation.length / 2
	check(animation.pose(knight).lift > 0.3, "In the air")

func test_capture_knocks_the_piece_off() -> void:
	var state := StandardSetup.from_fen("4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1")
	var victim := state.board.get_piece(Vector2i(3, 4))
	var animation := _animate(state, "exd5")
	check(animation.has_segment(victim, "knock"), "Knocked off")
	check_eq(_sounds(animation), [Sound.SCRAPE, Sound.CAPTURE], "Scrape, then the capture's crash")
	var attacker := state.board.get_piece(Vector2i(3, 4))
	check(animation.has_segment(attacker, "impact"), "The attacker feels the hit")
	check(animation.has_extra("impact"), "Sparks where they meet")
	animation.time = MoveAnimation.SLIDE + 0.02
	check(animation.pose(victim).flash > 0.5, "The captured piece flashes")
	animation.time = animation.length
	check(not animation.pose(victim).visible, "Gone at the end")

func test_dropped_piece_slams_with_dust() -> void:
	var state := StandardSetup.create_game()
	var pawn := state.board.get_piece(Vector2i(4, 1))
	var animation := _animate(state, "e4", true)
	check(animation.has_segment(pawn, "slam"), "Slams down")
	check(not animation.has_segment(pawn, "slide"), "No slide")
	check(animation.has_extra("dust"), "Puff of dust")
	check_eq(_sounds(animation), [Sound.SLAM], "A heavy thud")

func test_castling_dashes_then_slams() -> void:
	var state := StandardSetup.from_fen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	var king := state.board.get_piece(Vector2i(4, 0))
	var rook := state.board.get_piece(Vector2i(7, 0))
	var animation := _animate(state, "O-O")
	for piece in [king, rook]:
		check(animation.has_segment(piece, "dash"), "Dashes into place")
		check(animation.has_segment(piece, "slam"), "Slams down")
	check(animation.has_extra("speed_lines"), "Speed lines")
	check(animation.has_extra("dust"), "Dust")
	check_eq(_sounds(animation), [Sound.CASTLE, Sound.CASTLE_SLAM], "A swish, then a heavy slam")

func test_promotion_flashes_into_the_new_piece() -> void:
	var state := StandardSetup.from_fen("8/P6k/8/8/8/8/8/K7 w - - 0 1")
	var pawn := state.board.get_piece(Vector2i(0, 6))
	var animation := _animate(state, "a8=Q")
	var queen := state.board.get_piece(Vector2i(0, 7))
	check(animation.has_segment(pawn, "promote_rise"), "The pawn rises and spins")
	check(animation.has_segment(queen, "promote_reveal"), "The queen appears and settles")
	check(animation.has_extra("light"), "Burst of light")
	check(animation.has_extra("sparkles"), "Sparkles")
	check_eq(_sounds(animation), [Sound.SCRAPE, Sound.MOVE, Sound.PROMOTE, Sound.SPARKLE, Sound.LAND], "Scrape, swell, sparkle, thud")
	animation.time = MoveAnimation.SLIDE + 0.45
	var pose: Dictionary = animation.pose(pawn)
	check(pose.lift > 0.3 and absf(pose.scale.y) > 1.5, "Up close to the player")
	check(not animation.pose(queen).visible, "Queen not shown at first")

func test_cannon_fires_then_rolls_over() -> void:
	var state := _game("4k3/4p3/8/8/8/4P3/8/K3C3 w - - 0 1")
	var cannon := state.board.get_piece(Vector2i(4, 0))
	var victim := state.board.get_piece(Vector2i(4, 6))
	var animation := _animate(state, "Cxe7")
	check(animation.has_segment(cannon, "recoil"), "Recoils")
	check(animation.has_segment(cannon, "slide"), "Rolls onto the square")
	check(animation.has_extra("ball"), "Cannonball")
	check(animation.has_extra("smoke"), "Smoke")
	check(animation.has_segment(victim, "knock"), "Target blasted off")
	check_eq(_sounds(animation), [Sound.CANNON_FIRE, Sound.CANNON_HIT], "Boom, then the hit")

func test_crack_shot_arrow_and_sink() -> void:
	var state := _game("4k3/8/8/8/8/2n5/8/A3K3 w - - 0 1")
	var victim := state.board.get_piece(Vector2i(2, 2))
	var move := _ability_move(state, PieceDef.Ability.CRACK_SHOT)
	state.make_move(move)
	var animation := MoveAnimation.for_move(move, state, false)
	check(animation.has_extra("arrow"), "An arrow flies")
	check(animation.has_segment(victim, "sink"), "The target sinks into the board")
	check_eq(_sounds(animation), [Sound.ABILITY, Sound.MAGIC_HUM, Sound.BOW, Sound.ARROW_WHOOSH, Sound.ARROW_HIT], "Activation, magic, the bow, whoosh, then thwack")

func test_raise_dead_sinks_and_rises() -> void:
	var state := _game("k7/8/8/8/8/8/3(NC)4/4K3 w - - 0 1")
	state.lost[Piece.Team.WHITE].append(Piece.new(load("res://data/pieces/queen.tres"), Piece.Team.WHITE))
	var necromancer := state.board.get_piece(Vector2i(3, 1))
	var move := _ability_move(state, PieceDef.Ability.RAISE_DEAD)
	state.make_move(move)
	var animation := MoveAnimation.for_move(move, state, false)
	check(animation.has_segment(necromancer, "sink"), "Necromancer sinks")
	check(animation.has_segment(move.raised, "rise"), "The raised piece rises")
	check(animation.has_extra("smoke"), "Purple smoke")
	check_eq(_sounds(animation), [Sound.ABILITY, Sound.THUNDER, Sound.RAISE_DEAD, Sound.CREAK, Sound.CREAK], "Activation, thunder, the swell, creaking")
	check(animation.has_extra("lightning"), "Lightning strikes")

func test_check_shakes_the_king_last() -> void:
	var state := StandardSetup.from_fen("4k3/8/8/8/8/8/8/4K2R w - - 0 1")
	var animation := _animate(state, "Rh8+")
	var king := state.board.get_piece(Vector2i(4, 7))
	check(animation.has_segment(king, "shake"), "The king shakes")
	check(animation.has_extra("red_flash"), "Red flash")
	check_eq(_sounds(animation), [Sound.SCRAPE, Sound.MOVE, Sound.CHECK], "Move, then the check sound")

func test_checkmate_leaves_the_king_to_the_game_screen() -> void:
	var state := StandardSetup.from_fen("6k1/5ppp/8/8/8/8/8/R5K1 w - - 0 1")
	var animation := _animate(state, "Ra8#")
	var king := state.board.get_piece(Vector2i(6, 7))
	check(not animation.has_segment(king, "shake"), "No check shake")
	check(not Sound.CHECK in _sounds(animation), "No check sound")

func test_shield_break_shakes_the_target() -> void:
	var state := _game("4k3/8/8/8/3(pd)4/8/8/3RK3 w - - 0 1")
	var rook := state.board.get_piece(Vector2i(3, 0))
	var move: Move = null
	for candidate in state.moves():
		if candidate.breaks_shield():
			move = candidate
	state.make_move(move)
	var animation := MoveAnimation.for_move(move, state, false)
	check(animation.has_segment(rook, "slide"), "The attacker charges in and back")
	var paladin := move.shield_target
	animation.time = 0.05
	check(animation.pose(paladin).get("intact", false), "Still shown with its shield before the crash")
	animation.time = 0.3
	check(not animation.pose(paladin).get("intact", false), "Shieldless after it")
	check(animation.has_segment(paladin, "stun"), "It reels from the crash")
	check(animation.has_extra("dust"), "A cloud of dust")
	check(Sound.SHIELD_BREAK in _sounds(animation), "Crack")
	animation.time = animation.length
	check_eq(animation.pose(rook).pos, Vector2(3, 0), "The attacker is back on its square")

func test_sounds_come_at_their_moments() -> void:
	var state := _game("4k3/4p3/8/8/8/4P3/8/K3C3 w - - 0 1")
	var animation := _animate(state, "Cxe7")
	check_eq(animation.advance(0.01), [], "Nothing yet")
	check_eq(animation.advance(0.1), [Sound.CANNON_FIRE], "Boom")
	check_eq(animation.advance(0.1), [], "Ball in the air")
	check_eq(animation.advance(1.0), [Sound.CANNON_HIT], "Hit")
	check(animation.is_done(), "Finished")

func test_speed_scales_everything() -> void:
	var state := StandardSetup.create_game()
	var move := Notation.find_move(state, "Nf3")
	state.make_move(move)
	var normal := MoveAnimation.for_move(move, state, false)
	var slow := MoveAnimation.for_move(move, state, false, 2.0)
	check(is_equal_approx(slow.length, normal.length * 2), "Twice as long")

func test_undo_slides_back_and_fades_in() -> void:
	var state := StandardSetup.from_fen("4k3/8/8/3p4/4P3/8/8/4K3 w - - 0 1")
	var move := Notation.find_move(state, "exd5")
	state.make_move(move)
	state.undo_move(move)
	var undone: Array[Move] = [move]
	var animation := MoveAnimation.for_undo(undone, state)
	check(animation.has_segment(move.piece, "slide"), "Slides back")
	check(animation.has_segment(move.captured, "fade_in"), "Captured piece returns")

func test_ability_builds_up_first() -> void:
	var state := _game("4k3/8/8/8/8/2n5/8/A3K3 w - - 0 1")
	var archer := state.board.get_piece(Vector2i(0, 0))
	var move := _ability_move(state, PieceDef.Ability.CRACK_SHOT)
	state.make_move(move)
	var animation := MoveAnimation.for_move(move, state, false)
	check(animation.has_segment(archer, "charge"), "The archer rises first")
	animation.time = 0.5
	var pose: Dictionary = animation.pose(archer)
	check(pose.scale.x > 1.2 and pose.lift > 0.1, "Up towards the player")
	check(animation.active_extras().all(func(e: Dictionary) -> bool: return e.kind != "arrow"), "No arrow yet")

func test_en_passant_swipe() -> void:
	var state := StandardSetup.from_fen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	var victim := state.board.get_piece(Vector2i(3, 4))
	var animation := _animate(state, "exd6")
	check(animation.has_extra("slash"), "A slash across it")
	check(animation.has_segment(victim, "stun"), "It stands frozen for a beat")
	check(animation.has_segment(victim, "topple"), "Then topples over")
	check_eq(_sounds(animation), [Sound.SCRAPE, Sound.SWIPE, Sound.FALL], "Swipe, then it falls")

func test_vampire_bites_and_ram_bleats() -> void:
	var state := _game("4k3/8/8/3p4/2V5/8/8/4K3 w - - 0 1")
	var animation := _animate(state, "Vxd5")
	check(Sound.BITE in _sounds(animation), "The Vampire bites")
	check(animation.has_extra("blood"), "A spray of blood")
	state = _game("4k3/8/8/3p4/8/8/8/3(RM)K3 w - - 0 1")
	animation = _animate(state, "RMxd5")
	check(Sound.SHEEP in _sounds(animation), "A Ram dying from its own charge bleats")

func test_full_moon_haunt_and_crack_shot_extras() -> void:
	var state := _game("4k3/8/8/8/3(WW)4/8/8/4K3 w - - 0 1")
	var animation := MoveAnimation.for_move(_play_ability(state, PieceDef.Ability.FULL_MOON), state, false)
	check(animation.has_extra("moon"), "A great moon behind the Werewolf")
	state = _game("3rk3/8/8/8/3G4/8/8/4K3 b - - 0 1")
	state.make_move(state.find_move("d8xd4"))
	animation = MoveAnimation.for_move(_play_ability(state, PieceDef.Ability.HAUNT), state, false)
	check(animation.has_extra("rising_smoke"), "Smoke rises with the Ghost")
	check(Sound.HAUNT in _sounds(animation), "The gothic bell")
	state = _game("4k3/8/8/8/8/2n5/8/A3K3 w - - 0 1")
	animation = MoveAnimation.for_move(_play_ability(state, PieceDef.Ability.CRACK_SHOT), state, false)
	var arrows := animation.extras.filter(func(e: Dictionary) -> bool: return e.kind == "arrow")
	check(arrows[0].has("trail"), "The arrow leaves a trail in the ability's colour")

func _play_ability(state: GameState, ability: PieceDef.Ability) -> Move:
	var move := _ability_move(state, ability)
	state.make_move(move)
	return move

func test_every_sound_loads() -> void:
	for sound: int in GameSounds.LAYERS:
		for stream in GameSounds.streams_for(sound):
			check(stream != null, "Sound %s loads" % GameSounds.Sound.keys()[sound])
