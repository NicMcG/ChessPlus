class_name MoveAnimation
extends RefCounted

## The plan for animating one move on the board: how each piece involved moves
## over time, the extra things drawn (a cannonball, an arrow, smoke, dust, a
## flash of light) and when each sound plays. BoardView plays it back and draws
## it; this only describes it (and never touches the game itself, which has
## already changed by the time the animation starts).
##
## Positions are in squares (file, rank as decimals, the middle of a1 = (0, 0)),
## so the plan doesn't care whether the board is drawn flipped. "Lift" is in
## squares too, straight up the screen (for pieces in the air).
##
## Mac's designs (Oct 2026): ordinary moves slide; moves that leap hop through
## the air; a piece dropped by dragging slams down with a puff of dust; a
## captured piece is knocked off the board; castling pieces both hop into place;
## promotion flashes and turns the pawn into the new piece; the cannon fires a
## cannonball over its screen, then rolls onto the square; Crack Shot's arrow
## impales the target, which sinks into the board; Raise Dead sinks the
## Necromancer into purple smoke and the raised piece rises out of it; check
## shakes the king with a red flash.

## Each piece's movements: Piece -> Array of segments (Dictionaries with "kind",
## "start", "end" in seconds, and whatever that kind needs).
var tracks := {}
## Pieces that aren't drawn at all until their first segment starts.
var hidden_before := {}
## Things drawn that aren't pieces: Dictionaries with "kind", "start", "end".
var extras: Array = []
## [seconds, GameSounds.Sound], in time order.
var cues: Array = []
## Seconds since it started.
var time := 0.0
## How long it lasts.
var length := 0.0
## Every time in the plan is multiplied by this (1 = normal speed).
var speed := 1.0

## How long the basic pieces of motion take, in seconds at normal speed.
const SLIDE := 0.3
const HOP := 0.32
const SLAM := 0.3
const KNOCK := 0.38
## A promoting piece glows white-gold (a captured piece flashes white then red).
const PROMOTION_GLOW := Color(1.0, 0.95, 0.7)

# --- Building a plan --------------------------------------------------------------

## The animation for `move`, just made in `state`. `dragged`: the player dropped
## the piece there by dragging (it's already in place, so it slams down).
## `p_speed` scales every duration (1 = normal).
static func for_move(move: Move, state: GameState, dragged: bool, p_speed := 1.0) -> MoveAnimation:
	var a := MoveAnimation.new()
	a.speed = p_speed
	if move.ability == PieceDef.Ability.RAISE_DEAD:
		a._raise_dead(move)
		a._activation(move)
	elif move.ability == PieceDef.Ability.CRACK_SHOT:
		a._crack_shot(move)
		a._activation(move)
	elif move.ability == PieceDef.Ability.SONG_OF_SLUMBER:
		a._song_of_slumber(move)
		a._activation(move)
	elif move.ability == PieceDef.Ability.FULL_MOON:
		a._full_moon(move)
		a._activation(move)
	elif move.ability == PieceDef.Ability.HAUNT:
		a._haunt(move)
	elif move.captured and is_cannon_shot(move) and move.decoy_piece == null:
		a._cannon(move, dragged)
	elif move.breaks_shield():
		a._shield_break(move, dragged)
	elif move.partner:
		a._castling(move, dragged)
	else:
		a._ordinary(move, state, dragged)
	if move.decoy_piece:
		a._jester_swap(move)
	# Check (but not checkmate, which the game screen shows its own way): once
	# everything has landed, the king shakes and flashes red.
	if state.is_in_check() and state.outcome() == GameState.Outcome.NONE:
		var at := a._end_of_plan()
		for square in royal_squares(state, state.side_to_move):
			var king := state.board.get_piece(square)
			a._add(king, {"kind": "shake", "at": Vector2(square), "start": at, "end": at + 0.45})
			a.extras.append({"kind": "red_flash", "at": Vector2(square), "start": at, "end": at + 0.6})
		a._cue(at + 0.001, GameSounds.Sound.CHECK)
	a._finish()
	return a

## Taking moves back: each piece slides back and captured pieces fade back in.
## `moves` are the undone moves, most recent first; `state` is after undoing.
static func for_undo(moves: Array[Move], state: GameState, p_speed := 1.0) -> MoveAnimation:
	var a := MoveAnimation.new()
	a.speed = p_speed
	for move in moves:
		var piece := state.board.get_piece(move.from)
		if piece and move.lands_on() != move.from:
			a._slide_back(piece, move.lands_on(), move.from)
		if move.partner:
			a._slide_back(move.partner, move.partner_to, move.partner_from)
		if move.captured:
			a._add(move.captured, {"kind": "fade_in", "at": Vector2(move.capture_square), "start": 0.0, "end": SLIDE})
	a._cue(0.0, GameSounds.Sound.MOVE)
	a._finish()
	return a

## A capture made by hopping over a screen (the cannon's way of capturing).
static func is_cannon_shot(move: Move) -> bool:
	return move.piece.def.move_rules.any(func(rule: MoveRule) -> bool: return rule.captures_by_hopping)

## A move that leaps rather than travels: a Jump piece going further than one
## square (the knight, elephant, the Wizard's and Rogue's leaps). Its one-square
## steps still slide.
static func is_leap(move: Move) -> bool:
	var distance := maxi(absi(move.to.x - move.from.x), absi(move.to.y - move.from.y))
	return move.piece.def.has_jump() and distance > 1

static func royal_squares(state: GameState, team: Piece.Team) -> Array[Vector2i]:
	var squares: Array[Vector2i] = []
	var pieces := state.board.pieces_of(team)
	for square: Vector2i in pieces:
		if pieces[square].def.is_king_type():
			squares.append(square)
	return squares

## The piece goes from its square to where it lands, then whatever it captured
## is knocked off; a promoted pawn flashes and turns into its new piece; a Ram
## that captured vanishes afterwards.
func _ordinary(move: Move, state: GameState, dragged: bool) -> void:
	var from := Vector2(move.from)
	var landed := Vector2(move.lands_on())
	var arrived := _travel(move.piece, from, landed, dragged, is_leap(move))
	# Wood scraping along the board as it slides (Mac).
	if not dragged and from != landed and not is_leap(move):
		_cue(0.0, GameSounds.Sound.SCRAPE)
	if move.captured and move.capture_square != move.to:
		_en_passant(move, arrived, dragged)
	elif move.captured:
		_knock_off(move.captured, Vector2(move.capture_square), landed - from, arrived)
		_impact(move.piece, landed, landed - from, arrived)
		_cue(arrived, GameSounds.Sound.CAPTURE)
	elif not dragged and from != landed:
		_cue(arrived, GameSounds.Sound.LAND if is_leap(move) else GameSounds.Sound.MOVE)
	if move.gained_shield:
		# A Vampire bites: a spray of blood, and it gains its dark red aura.
		_cue(arrived, GameSounds.Sound.BITE)
		extras.append({"kind": "blood", "at": Vector2(move.capture_square), "start": arrived, "end": arrived + 0.6})
	if move.promotion:
		_promotion(move, state.board.get_piece(move.lands_on()), landed, arrived)
	if move.attacker_died:
		# A Ram that dies charging (Mac: with a sheep's baa).
		_add(move.piece, {"kind": "fade_out", "at": landed, "start": arrived + 0.15, "end": arrived + 0.6})
		_cue(arrived + 0.15, GameSounds.Sound.SHEEP)

## Promotion (Mac's design): the pawn rises towards the player, growing and
## spinning faster and faster, glowing white, among sparkles; edge-on at the top
## there's a burst of light and it turns into the new piece, which finishes the
## turn, hangs there a moment and drops back onto its square.
func _promotion(move: Move, promoted: Piece, at: Vector2, arrived: float) -> void:
	const RISE := 0.9
	const AFTER := 1.0
	var swap := arrived + RISE
	_add(move.piece, {"kind": "promote_rise", "at": at, "start": arrived, "end": swap})
	_add(move.piece, {"kind": "fade_out", "at": at, "start": swap, "end": swap})
	_add(promoted, {"kind": "promote_reveal", "at": at, "start": swap, "end": swap + AFTER})
	hidden_before[promoted] = true
	extras.append({"kind": "sparkles", "at": at, "start": arrived + 0.1, "end": swap + 0.45})
	# Anime power-up (Mac: more effects): a whirl of light round it as it spins,
	# energy rising up into it, then a burst of light and a shockwave as it
	# becomes the new piece.
	extras.append({"kind": "swirl", "at": at, "start": arrived, "end": swap + 0.1, "lift": 0.55})
	extras.append({"kind": "energy", "at": at, "start": arrived, "end": swap})
	extras.append({"kind": "light", "at": at + Vector2(0, -0.0), "start": swap, "end": swap + 0.5, "size": 2.2, "lift": 0.55})
	extras.append({"kind": "shockwave", "at": at, "start": swap, "end": swap + 0.55, "lift": 0.55})
	_cue(arrived, GameSounds.Sound.PROMOTE)
	# A holy choir behind it all (Mac).
	_cue(arrived, GameSounds.Sound.CHOIR)
	# A whoosh for each turn, faster and faster as it spins up.
	for when in [0.18, 0.45, 0.63, 0.75, 0.84]:
		_cue(arrived + when, GameSounds.Sound.SPIN)
	_cue(swap, GameSounds.Sound.SPARKLE)
	_cue(swap + AFTER, GameSounds.Sound.LAND)

## En passant (my design, Mac's timing): the pawn sweeps diagonally past the
## pawn it captures, a slash streaking across it as it goes by; the passed pawn
## stands frozen for a beat, like an anime swordsman's victim, then topples over
## and hits the board.
func _en_passant(move: Move, arrived: float, dragged: bool) -> void:
	var victim := Vector2(move.capture_square)
	var hit := 0.0 if dragged else arrived * 0.55
	var fall := arrived + 0.45
	extras.append({"kind": "slash", "at": victim, "dir": Vector2(move.to - move.from), "start": hit, "end": hit + 0.28})
	_add(move.captured, {"kind": "hold", "at": victim, "start": 0.0, "end": hit})
	_add(move.captured, {"kind": "stun", "at": victim, "start": hit, "end": fall})
	var side := 1.0 if move.capture_square.x >= move.from.x else -1.0
	_add(move.captured, {"kind": "topple", "at": victim, "side": side, "start": fall, "end": fall + 0.5})
	_cue(0.0 if dragged else hit * 0.4, GameSounds.Sound.SWIPE)
	_cue(fall + 0.32, GameSounds.Sound.FALL)

## Castling (with any piece that has the Castle keyword; Mac's anime design):
## the king and its partner dash past each other in a flash, trailing speed
## lines, then both slam down with a heavy crack and a puff of dust.
func _castling(move: Move, _dragged: bool) -> void:
	const DASH := 0.16
	var pieces := [[move.piece, Vector2(move.from), Vector2(move.to)], [move.partner, Vector2(move.partner_from), Vector2(move.partner_to)]]
	for entry: Array in pieces:
		_add(entry[0], {"kind": "dash", "from": entry[1], "to": entry[2], "start": 0.0, "end": DASH})
		_add(entry[0], {"kind": "slam", "at": entry[2], "start": DASH, "end": DASH + SLAM})
		extras.append({"kind": "speed_lines", "from": entry[1], "to": entry[2], "start": 0.0, "end": DASH + 0.15})
		extras.append({"kind": "dust", "at": entry[2], "start": DASH, "end": DASH + 0.45})
		extras.append({"kind": "impact", "at": entry[2] + Vector2(0, -0.35), "start": DASH, "end": DASH + 0.3})
	_cue(0.0, GameSounds.Sound.CASTLE)
	_cue(DASH, GameSounds.Sound.CASTLE_SLAM)

## A shield breaks (Mac's design): the attacker charges as if to capture,
## crashes into the shielded piece with a crack and a cloud of dust, and is
## thrown back to its own square; the target is left without its shield (a
## Paladin's picture changes, a Vampire's dark red aura goes).
func _shield_break(move: Move, dragged: bool) -> void:
	var from := Vector2(move.from)
	var target := Vector2(move.to)
	var toward := (target - from).normalized()
	var hit := 0.0
	if not dragged:
		hit = 0.2
		var reach := target - toward * 0.55
		_add(move.piece, {"kind": "slide", "from": from, "to": reach, "start": 0.0, "end": hit})
		_add(move.piece, {"kind": "slide", "from": reach, "to": from, "start": hit, "end": hit + 0.32})
		_cue(0.0, GameSounds.Sound.SCRAPE)
	# Shown with its shield until the crash, then shaken.
	_add(move.shield_target, {"kind": "hold", "at": target, "start": 0.0, "end": hit, "intact": true})
	_add(move.shield_target, {"kind": "stun", "at": target, "start": hit, "end": hit + 0.4})
	extras.append({"kind": "impact", "at": target - toward * 0.3, "start": hit, "end": hit + 0.3})
	extras.append({"kind": "dust", "at": target, "start": hit, "end": hit + 0.5})
	_cue(hit, GameSounds.Sound.SHIELD_BREAK)
	if move.attacker_died:
		_add(move.piece, {"kind": "fade_out", "at": from, "start": hit + 0.35, "end": hit + 0.75})
		_cue(hit + 0.35, GameSounds.Sound.SHEEP)

## The cannon recoils as it fires; the cannonball arcs over the screen piece
## onto the target, which is blasted off in a puff of smoke; then the cannon
## rolls onto the square it captured.
func _cannon(move: Move, dragged: bool) -> void:
	var from := Vector2(move.from)
	var target := Vector2(move.capture_square)
	var direction := (target - from).normalized()
	var impact := 0.5
	_add(move.piece, {"kind": "recoil", "at": from, "dir": direction, "start": 0.0, "end": 0.18})
	extras.append({"kind": "smoke", "at": from + direction * 0.35, "start": 0.03, "end": 0.6, "color": Color(0.85, 0.85, 0.85), "size": 0.3})
	extras.append({"kind": "ball", "from": from + direction * 0.3, "to": target, "start": 0.08, "end": impact})
	_knock_off(move.captured, target, direction, impact)
	extras.append({"kind": "smoke", "at": target, "start": impact, "end": impact + 0.7, "color": Color(0.55, 0.55, 0.55), "size": 0.5})
	_add(move.piece, {"kind": "slide", "from": from, "to": Vector2(move.to), "start": impact + 0.2, "end": impact + 0.2 + 0.32})
	_cue(0.03, GameSounds.Sound.CANNON_FIRE)
	_cue(impact, GameSounds.Sound.CANNON_HIT)

## Crack Shot: an arrow flies from the Archer and impales the target, which then
## slowly sinks into the board and fades away. If it only breaks a shield, the
## target shakes and the arrow drops away.
func _crack_shot(move: Move) -> void:
	var from := Vector2(move.from)
	var target := Vector2(move.to)
	var hit := 0.28
	extras.append({"kind": "arrow", "from": from, "to": target, "start": 0.0, "end": hit,
			"stuck_to": move.captured, "until": hit + 1.0 if move.captured else hit + 0.35,
			"trail": move.piece.def.ability_gradient()[1]})
	# Magic humming under the whole shot, the bow's twang with a laser bolt
	# (Mac), the whoosh of flight.
	_cue(0.0, GameSounds.Sound.MAGIC_HUM)
	_cue(0.0, GameSounds.Sound.BOW)
	_cue(0.0, GameSounds.Sound.LASER)
	_cue(0.02, GameSounds.Sound.ARROW_WHOOSH)
	_cue(hit, GameSounds.Sound.ARROW_HIT)
	# An anime impact frame as it strikes: a flash of stark light and lines.
	extras.append({"kind": "impact_frame", "at": target, "start": hit, "end": hit + 0.16})
	if move.captured:
		_add(move.captured, {"kind": "hold", "at": target, "start": 0.0, "end": hit + 0.2})
		_add(move.captured, {"kind": "sink", "at": target, "start": hit + 0.2, "end": hit + 1.0})
	else:
		_shake_target(move.to, hit)
		_cue(hit, GameSounds.Sound.SHIELD_BREAK)

## Using a special ability builds up first (Mac's design): the piece rises
## towards the player a little, glowing in its ability's colour, as the
## activation sound plays; then it settles and the ability's own effect plays
## (a bit slower than other animations, to let it breathe).
func _activation(move: Move) -> void:
	const WAIT := 0.75
	const SLOWER := 1.3
	for segments: Array in tracks.values():
		for segment: Dictionary in segments:
			segment.start = segment.start * SLOWER + WAIT
			segment.end = segment.end * SLOWER + WAIT
	for extra: Dictionary in extras:
		extra.start = extra.start * SLOWER + WAIT
		extra.end = extra.end * SLOWER + WAIT
		if extra.has("until"):
			extra.until = extra.until * SLOWER + WAIT
	for cue: Array in cues:
		cue[0] = cue[0] * SLOWER + WAIT
	# The Bard's build-up is gentle (Mac): no electricity and no slam; it just
	# strums as it rises, and settles softly.
	var gentle := move.ability == PieceDef.Ability.SONG_OF_SLUMBER
	var charge := {"kind": "charge", "at": Vector2(move.from), "start": 0.0, "end": WAIT, "gentle": gentle}
	if move.ability == PieceDef.Ability.FULL_MOON:
		# Still a Werewolf while it builds up (the game already has it as a wolf).
		charge.as_def = move.piece.base_def
	# Before the ability's own segments, so it plays first.
	if not tracks.has(move.piece):
		tracks[move.piece] = []
	tracks[move.piece].push_front(charge)
	if gentle:
		_cue(0.0, GameSounds.Sound.STRUM)
	else:
		# Crackling electricity as it powers up, then it slams back down onto
		# the board (Mac): a thump, dust and a ring bursting out.
		_cue(0.0, GameSounds.Sound.ABILITY)
		const LANDS := WAIT * 0.97
		_cue(LANDS, GameSounds.Sound.GROUND_SLAM)
		extras.append({"kind": "dust", "at": Vector2(move.from), "start": LANDS, "end": LANDS + 0.45})
		extras.append({"kind": "shockwave", "at": Vector2(move.from), "start": LANDS, "end": LANDS + 0.4})
	var glow: Color = move.piece.def.ability_gradient()[1].lerp(Color.WHITE, 0.3)
	extras.append({"kind": "light", "at": Vector2(move.from), "start": 0.0, "end": WAIT + 0.15, "color": glow})

## A Jester taking the hit: first the Jester and the piece it protects swap
## places with a swish, then the capture happens as planned (on the Jester).
func _jester_swap(move: Move) -> void:
	const SWAP := 0.12
	for segments: Array in tracks.values():
		for segment: Dictionary in segments:
			segment.start += SWAP
			segment.end += SWAP
	for extra: Dictionary in extras:
		extra.start += SWAP
		extra.end += SWAP
		if extra.has("until"):
			extra.until += SWAP
	for cue: Array in cues:
		cue[0] += SWAP
	var jester_from := Vector2(move.decoy_square)
	var target_at := Vector2(move.capture_square)
	# Mac's design: a mischievous giggle, and the two swap places almost at once,
	# like ninjas, in a blur of speed lines.
	_add(move.captured, {"kind": "dash", "from": jester_from, "to": target_at, "start": 0.0, "end": SWAP})
	_add(move.decoy_piece, {"kind": "dash", "from": target_at, "to": jester_from, "start": 0.0, "end": SWAP})
	for pair in [[jester_from, target_at], [target_at, jester_from]]:
		extras.append({"kind": "speed_lines", "from": pair[0], "to": pair[1], "start": 0.0, "end": SWAP + 0.12})
	_cue(0.0, GameSounds.Sound.GIGGLE)
	_cue(0.0, GameSounds.Sound.SWIPE)
	# Taking the hit, the Jester bursts like a balloon in a shower of confetti.
	for segment: Dictionary in tracks[move.captured]:
		if segment.kind == "knock":
			segment.kind = "burst"
			segment.end = segment.start + 0.18
			extras.append({"kind": "confetti", "at": target_at, "start": segment.start, "end": segment.start + 1.1})
			_cue(segment.start, GameSounds.Sound.POP)

## Song of Slumber: golden music notes drift from the Bard to its target, which
## sways drowsily as a soft lullaby plays (and then shows "Zz" while asleep).
func _song_of_slumber(move: Move) -> void:
	extras.append({"kind": "notes", "from": Vector2(move.from), "to": Vector2(move.to), "start": 0.0, "end": 1.0})
	extras.append({"kind": "light", "at": Vector2(move.to), "start": 0.7, "end": 1.3, "color": Color(1.0, 0.8, 0.35), "size": 0.9})
	_add(move.frozen, {"kind": "drowse", "at": Vector2(move.to), "start": 0.7, "end": 1.5})
	# The strum came as the Bard rose (see _activation); the notes as they fly.
	_cue(0.0, GameSounds.Sound.LULLABY)

## Full Moon: like a promotion, the Werewolf rises spinning in a silvery
## moonlit glow, howling, and comes back down as the wolf.
func _full_moon(move: Move) -> void:
	const RISE := 0.6
	const AFTER := 0.75
	var at := Vector2(move.from)
	_add(move.piece, {"kind": "promote_rise", "at": at, "start": 0.0, "end": RISE, "as_def": move.piece.base_def, "glow": MOON_GLOW})
	_add(move.piece, {"kind": "promote_reveal", "at": at, "start": RISE, "end": RISE + AFTER, "glow": MOON_GLOW})
	extras.append({"kind": "light", "at": at, "start": RISE, "end": RISE + 0.6, "size": 2.0, "lift": 0.55, "color": MOON_GLOW})
	# A great full moon fades in behind it (in front of the board), and fades
	# once it's a wolf. It starts with the build-up (see _activation).
	extras.append({"kind": "moon", "at": at, "start": -0.75 / 1.3, "end": RISE + AFTER + 0.3})
	# The howl starts as it rises in the moonlight (Mac).
	# A growl, then the howl (Mac).
	_cue(0.0, GameSounds.Sound.GROWL)
	_cue(0.5, GameSounds.Sound.HOWL)
	_cue(RISE, GameSounds.Sound.SPARKLE)
	_cue(RISE + AFTER, GameSounds.Sound.LAND)

## The Werewolf's moonlight.
const MOON_GLOW := Color(0.85, 0.9, 1.0)

## Haunt (Mac's design): a gothic bell tolls over a low boom, white-blue smoke
## rises up out of the square with a howling wind, and the Ghost slowly rises
## with it.
func _haunt(move: Move) -> void:
	var at := Vector2(move.to)
	extras.append({"kind": "rising_smoke", "at": at, "start": 0.0, "end": 2.4, "color": Color(0.85, 0.93, 1.0)})
	extras.append({"kind": "light", "at": at, "start": 0.0, "end": 1.2, "color": Color(0.75, 0.9, 1.0)})
	_add(move.piece, {"kind": "rise", "at": at, "start": 0.5, "end": 2.0})
	hidden_before[move.piece] = true
	_cue(0.0, GameSounds.Sound.HAUNT)
	# Then a howling wind rises with the smoke (Mac).
	_cue(0.3, GameSounds.Sound.WIND)

## Raise Dead (Mac's design): the Necromancer sinks into fog of its colour;
## once it's gone under, a snap of lightning and thunder with an impact flash,
## and the raised piece rises out of the fog with a zombie's groan.
func _raise_dead(move: Move) -> void:
	var at := Vector2(move.from)
	var fog: Color = move.piece.def.ability_gradient()[0]
	# The Necromancer goes under first; then the lightning strikes (Mac) and the
	# raised piece rises with a groan.
	const STRIKE := 0.8
	_add(move.piece, {"kind": "sink", "at": at, "start": 0.0, "end": 0.75})
	extras.append({"kind": "smoke", "at": at, "start": 0.0, "end": 2.0, "color": fog, "size": 0.75})
	extras.append({"kind": "lightning", "at": at, "start": STRIKE, "end": STRIKE + 0.28, "color": fog.lerp(Color.WHITE, 0.6)})
	extras.append({"kind": "impact_frame", "at": at, "start": STRIKE, "end": STRIKE + 0.12})
	_add(move.raised, {"kind": "rise", "at": at, "start": STRIKE + 0.15, "end": STRIKE + 0.95})
	hidden_before[move.raised] = true
	_cue(0.0, GameSounds.Sound.RAISE_DEAD)
	_cue(STRIKE, GameSounds.Sound.THUNDER)
	_cue(STRIKE + 0.15, GameSounds.Sound.GROAN)

## Move `piece` from `from` to `to`: dropped there by dragging (a slam, with a
## thud and a puff of dust), leaping (a hop) or sliding. Returns when it arrives.
func _travel(piece: Piece, from: Vector2, to: Vector2, dragged: bool, leap: bool) -> float:
	if dragged:
		_add(piece, {"kind": "slam", "at": to, "start": 0.0, "end": SLAM})
		extras.append({"kind": "dust", "at": to, "start": 0.0, "end": 0.45})
		_cue(0.0, GameSounds.Sound.SLAM)
		return 0.0
	if from == to:
		return 0.0
	if leap:
		_add(piece, {"kind": "hop", "from": from, "to": to, "start": 0.0, "end": HOP})
		return HOP
	_add(piece, {"kind": "slide", "from": from, "to": to, "start": 0.0, "end": SLIDE})
	return SLIDE

## The capturing piece feels the hit: it squashes and bounces back a little,
## and a burst of sparks flies out where the pieces meet.
func _impact(piece: Piece, at: Vector2, direction: Vector2, when: float) -> void:
	var dir := direction.normalized() if direction != Vector2.ZERO else Vector2(0, 1)
	_add(piece, {"kind": "impact", "at": at, "dir": dir, "start": when, "end": when + 0.28})
	extras.append({"kind": "impact", "at": at + dir * 0.3, "start": when, "end": when + 0.3})

## The captured piece stays put until `at` seconds, then is knocked away in the
## direction of the hit, spinning and fading, flashing white then red as it's hit.
func _knock_off(piece: Piece, square: Vector2, direction: Vector2, at: float) -> void:
	var dir := direction.normalized() if direction != Vector2.ZERO else Vector2(0, 1)
	if at > 0:
		_add(piece, {"kind": "hold", "at": square, "start": 0.0, "end": at})
	_add(piece, {"kind": "knock", "at": square, "dir": dir, "start": at, "end": at + KNOCK,
			"spin": 1.0 if dir.x >= 0 else -1.0})

## The shielded piece on `square` shakes from `at` seconds (its shield cracking).
## It's still on the board, so it's found there when the plan is played (see
## shake_squares).
func _shake_target(square: Vector2i, at: float) -> void:
	extras.append({"kind": "shake_square", "at": Vector2(square), "start": at, "end": at + 0.35})

func _slide_back(piece: Piece, leaving: Vector2i, going_to: Vector2i) -> void:
	if tracks.has(piece):
		var last: Dictionary = tracks[piece].back()
		last["to"] = Vector2(going_to)
		return
	_add(piece, {"kind": "slide", "from": Vector2(leaving), "to": Vector2(going_to), "start": 0.0, "end": SLIDE})

func _add(piece: Piece, segment: Dictionary) -> void:
	if piece == null:
		return
	if not tracks.has(piece):
		tracks[piece] = []
	tracks[piece].append(segment)

func _cue(at: float, sound: GameSounds.Sound) -> void:
	cues.append([at, sound])

## When everything planned so far has finished.
func _end_of_plan() -> float:
	var end := 0.0
	for segments: Array in tracks.values():
		for segment: Dictionary in segments:
			end = maxf(end, segment.end)
	for extra: Dictionary in extras:
		end = maxf(end, extra.get("until", extra.end))
	return end

## Apply the speed, sort the sounds and work out the length.
func _finish() -> void:
	for segments: Array in tracks.values():
		segments.sort_custom(func(x: Dictionary, y: Dictionary) -> bool: return x.start < y.start)
		for segment: Dictionary in segments:
			segment.start *= speed
			segment.end *= speed
	for extra: Dictionary in extras:
		extra.start *= speed
		extra.end *= speed
		if extra.has("until"):
			extra.until *= speed
	for cue: Array in cues:
		cue[0] *= speed
	cues.sort_custom(func(x: Array, y: Array) -> bool: return x[0] < y[0])
	length = _end_of_plan()
	for cue: Array in cues:
		length = maxf(length, cue[0])

# --- Playing it back --------------------------------------------------------------

## True once it has finished.
func is_done() -> bool:
	return time >= length

## Move on by `delta` seconds; returns the sounds whose time has come.
func advance(delta: float) -> Array:
	time = minf(time + delta, length)
	var due := []
	while _next_cue < cues.size() and cues[_next_cue][0] <= time:
		due.append(cues[_next_cue][1])
		_next_cue += 1
	return due

## The first sound not played yet.
var _next_cue := 0

## Every sound, for when animations are switched off.
func all_sounds() -> Array:
	return cues.map(func(cue: Array) -> GameSounds.Sound: return cue[1])

## How `piece` is drawn now: {"visible", "pos", "lift", "scale", "angle",
## "alpha", "sunk"} ("sunk" = how much of it, 0..1, has gone down into the board).
## Null if this plan doesn't move it (it's drawn normally, on its square).
func pose(piece: Piece) -> Variant:
	if not tracks.has(piece):
		return null
	var segments: Array = tracks[piece]
	var first: Dictionary = segments[0]
	if time < first.start:
		if hidden_before.has(piece):
			return {"visible": false}
		return segment_pose(first, 0.0)
	var current: Dictionary = first
	for segment: Dictionary in segments:
		if segment.start <= time:
			current = segment
	var span: float = current.end - current.start
	var t := clampf((time - current.start) / span, 0.0, 1.0) if span > 0 else 1.0
	return segment_pose(current, t)

## A segment's pose `t` of the way (0..1) through it.
static func segment_pose(segment: Dictionary, t: float) -> Dictionary:
	var pose := {"visible": true, "pos": segment.get("at", Vector2.ZERO), "lift": 0.0,
			"scale": Vector2.ONE, "angle": 0.0, "alpha": 1.0, "sunk": 0.0, "flash": 0.0, "shadow": 0.0}
	if segment.has("as_def"):
		pose.as_def = segment.as_def
	# Drawn as it was before its shield broke (until the crash).
	if segment.get("intact", false):
		pose.intact = true
	match segment.kind:
		"slide":
			pose.pos = (segment.from as Vector2).lerp(segment.to, ease_out(t))
		"hop":
			var from: Vector2 = segment.from
			var to: Vector2 = segment.to
			var height := 0.35 + 0.12 * from.distance_to(to)
			pose.pos = from.lerp(to, smoothstep(0.0, 1.0, t))
			pose.lift = 4.0 * height * t * (1.0 - t)
			pose.scale = Vector2.ONE * (1.0 + 0.18 * sin(PI * t))
		"slam":
			# Squashed flat as it lands, then springs back.
			var wobble := exp(-5.0 * t) * cos(13.0 * t)
			pose.scale = Vector2(1.0 + 0.22 * wobble, 1.0 - 0.28 * wobble)
		"knock":
			var dir: Vector2 = segment.dir
			pose.pos = (segment.at as Vector2) + dir * 1.1 * ease_out(t)
			pose.lift = 0.5 * sin(PI * t)
			pose.angle = segment.spin * 2.6 * t
			pose.alpha = 1.0 - t * t
			pose.scale = Vector2.ONE * (1.0 - 0.25 * t)
			pose.flash = clampf(1.0 - t * 2.5, 0.0, 1.0)
			if t >= 1.0:
				pose.visible = false
		"fade_out":
			pose.alpha = 1.0 - t
			if t >= 1.0:
				pose.visible = false
		"fade_in":
			pose.alpha = t
		"pop":
			pose.scale = Vector2.ONE * (1.0 + 0.3 * (1.0 - ease_out(t)))
		"shake":
			pose.pos = (segment.at as Vector2) + Vector2(shake_offset(t), 0)
		"charge":
			# Rises towards the player, holds there, then slams back down
			# (falling faster and faster), or, if gentle, settles softly.
			var fall := clampf((t - 0.84) / 0.13, 0.0, 1.0)
			var down := smoothstep(0.8, 1.0, t) if segment.get("gentle", false) else fall * fall
			var up := smoothstep(0.0, 0.45, t) * (1.0 - down)
			pose.scale = Vector2.ONE * (1.0 + 0.35 * up)
			pose.lift = 0.18 * up
			pose.shadow = up
		"promote_rise":
			# Up towards the player, growing, spinning round faster and faster
			# (turning about its upright axis, so it shows edge-on), glowing.
			var up := smoothstep(0.0, 0.6, t)
			var turn := 2.5 * PI * pow(t, 1.6)
			pose.scale = Vector2(cos(turn), 1.0) * (1.0 + 0.8 * up)
			pose.lift = 0.55 * up
			pose.flash = smoothstep(0.55, 1.0, t)
			pose.flash_color = segment.get("glow", PROMOTION_GLOW)
			pose.shadow = up
		"promote_reveal":
			# The new piece: finishes the turn, glow fading, then drops back down.
			var turn := 2.5 * PI + 1.5 * PI * ease_out(minf(1.0, t / 0.45))
			var up := 1.0 - smoothstep(0.55, 1.0, t)
			pose.scale = Vector2(cos(turn), 1.0) * (1.0 + 0.8 * up)
			pose.lift = 0.55 * up
			pose.flash = 1.0 - smoothstep(0.0, 0.35, t)
			pose.flash_color = segment.get("glow", PROMOTION_GLOW)
			pose.shadow = up
		"impact":
			# Squashed by the hit, then springs back, pushed back a touch.
			var wobble := exp(-6.0 * t) * cos(15.0 * t)
			pose.scale = Vector2(1.0 + 0.12 * wobble, 1.0 - 0.16 * wobble)
			pose.pos = (segment.at as Vector2) - (segment.dir as Vector2) * 0.12 * sin(PI * t) * (1.0 - t)
		"recoil":
			pose.pos = (segment.at as Vector2) - (segment.dir as Vector2) * 0.18 * sin(PI * t)
		"bump":
			pose.pos = (segment.at as Vector2) + (segment.dir as Vector2).normalized() * 0.35 * sin(PI * t)
		"sink":
			pose.sunk = t
			pose.alpha = 1.0 - t * 0.7
			if t >= 1.0:
				pose.visible = false
		"rise":
			pose.sunk = 1.0 - ease_out(t)
			pose.alpha = minf(1.0, t * 1.5)
		"dash":
			# Very fast, with a little stretch along the way.
			pose.pos = (segment.from as Vector2).lerp(segment.to, smoothstep(0.0, 1.0, t))
			pose.scale = Vector2(1.0 + 0.25 * sin(PI * t), 1.0 - 0.1 * sin(PI * t))
		"stun":
			# Hit: a white flash and a quick tremble, then stillness.
			pose.flash = clampf(1.0 - t * 4.0, 0.0, 1.0)
			pose.flash_color = Color.WHITE
			pose.pos = (segment.at as Vector2) + Vector2(shake_offset(minf(1.0, t * 2.0)) * 0.6, 0)
		"topple":
			# Tips over sideways and drops, fading out as it hits the board.
			var side: float = segment.get("side", 1.0)
			var fall := t * t
			pose.angle = side * 1.5 * fall
			pose.pos = (segment.at as Vector2) + Vector2(side * 0.25 * fall, -0.15 * fall)
			pose.alpha = 1.0 - smoothstep(0.7, 1.0, t)
			if t >= 1.0:
				pose.visible = false
		"burst":
			# Swells for an instant, then is gone.
			pose.scale = Vector2.ONE * (1.0 + 0.4 * t)
			pose.flash = t
			pose.flash_color = Color.WHITE
			if t >= 1.0:
				pose.visible = false
		"drowse":
			# Nodding off: a slow sway that dies away, sinking a touch.
			pose.angle = 0.18 * sin(t * TAU * 1.5) * (1.0 - t)
			pose.scale = Vector2(1.0, 1.0 - 0.06 * sin(PI * t))
	return pose

## The squares whose pieces are shaking now (shields cracking), with how far
## (0..1) each shake has got.
func shake_squares() -> Dictionary:
	var shaking := {}
	for extra: Dictionary in extras:
		if extra.kind == "shake_square" and time >= extra.start and time < extra.end:
			shaking[Vector2i(extra.at)] = (time - extra.start) / (extra.end - extra.start)
	return shaking

## The extras showing now, each with how far (0..1) it has got as "t".
func active_extras() -> Array:
	var showing := []
	for extra: Dictionary in extras:
		var until: float = extra.get("until", extra.end)
		if time >= extra.start and time <= until:
			var copy := extra.duplicate()
			copy["t"] = clampf((time - extra.start) / maxf(extra.end - extra.start, 0.0001), 0.0, 1.0)
			showing.append(copy)
	return showing

## True if the plan moves `piece` with a segment of this kind (for tests).
func has_segment(piece: Piece, kind: String) -> bool:
	return tracks.has(piece) and tracks[piece].any(func(s: Dictionary) -> bool: return s.kind == kind)

func has_extra(kind: String) -> bool:
	return extras.any(func(e: Dictionary) -> bool: return e.kind == kind)

## Starts fast and slows down as it arrives.
static func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3)

## Sideways wobble (in squares) that dies away.
static func shake_offset(t: float) -> float:
	return sin(t * TAU * 3) * 0.08 * (1.0 - t)
