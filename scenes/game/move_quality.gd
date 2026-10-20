class_name MoveQuality
extends RefCounted

## Judges the moves of a finished game from Plusfish's evaluations: a move that
## throws away a big part of the mover's chances is a mistake, a bigger one a
## blunder.
##
## Points alone are a poor guide (going from +9 to +6 changes nothing, from +1 to
## -2 changes everything), so each evaluation is first turned into winning
## chances, and the judgement is how much of them the move lost. This is the
## way the lichess.org website judges moves, with its numbers.

enum Mark { NONE, MISTAKE, BLUNDER }

## How much of the mover's chances (on a scale from -1, lost, to +1, won) a move
## must lose to count as a mistake or a blunder.
const MISTAKE_DROP := 0.2
const BLUNDER_DROP := 0.3

## How quickly the chances grow with the score (per hundredth of a point).
const CHANCE_SCALE := 0.00368208

## White's chances in a position Plusfish evaluated (PlusfishLink's result):
## -1 = Black wins, 0 = even (or a draw), +1 = White wins.
static func white_chances(result: Dictionary) -> float:
	var cp := float(result.get("cp", 0))
	var outcome: String = result.get("outcome", "none")
	if outcome in ["checkmate", "king_exposed"]:
		return signf(cp)
	if outcome != "none":
		return 0.0  # A draw.
	var mate: Variant = result.get("mate")
	if mate != null:
		return signf(cp)
	return 2.0 / (1.0 + exp(-CHANCE_SCALE * cp)) - 1.0

## The marks for a game's moves: ply (moves played after it, so move i of the
## game is ply i + 1) -> Mark, for marked moves only. `results` = ply -> result
## (positions not evaluated yet are skipped); `moves` = the moves as
## Move.to_text(); `movers` = the side that played each move.
## A move Plusfish itself would have played is never marked: the two positions
## were searched separately, so their numbers can differ a little.
static func marks(results: Dictionary, moves: Array, movers: Array) -> Dictionary:
	var found := {}
	for i in moves.size():
		var before: Dictionary = results.get(i, {})
		var after: Dictionary = results.get(i + 1, {})
		if before.is_empty() or after.is_empty():
			continue
		if before.get("best", "") == moves[i]:
			continue
		var mark := judge(before, after, movers[i])
		if mark != Mark.NONE:
			found[i + 1] = mark
	return found

## The mark for one move by `mover`, from the evaluations before and after it.
static func judge(before: Dictionary, after: Dictionary, mover: int) -> Mark:
	var side := 1.0 if mover == Piece.Team.WHITE else -1.0
	var lost := side * (white_chances(before) - white_chances(after))
	if lost >= BLUNDER_DROP:
		return Mark.BLUNDER
	if lost >= MISTAKE_DROP:
		return Mark.MISTAKE
	return Mark.NONE

## The mark's name for the screen ("" for none).
static func name_of(mark: Mark) -> String:
	match mark:
		Mark.MISTAKE:
			return "Mistake"
		Mark.BLUNDER:
			return "Blunder"
	return ""

## The usual chess sign for it: ? for a mistake, ?? for a blunder.
static func sign_of(mark: Mark) -> String:
	match mark:
		Mark.MISTAKE:
			return "?"
		Mark.BLUNDER:
			return "??"
	return ""

## The colour marks are drawn in (the move list, the graph, the status line).
static func color_of(mark: Mark) -> Color:
	return Color("#E8443A") if mark == Mark.BLUNDER else Color("#F0A030")
