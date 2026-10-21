class_name MoveRule
extends Resource

## One way a piece can move. A piece can have several of these.

enum Mode { MOVE_OR_CAPTURE, MOVE_ONLY, CAPTURE_ONLY }

## Directions as (files, ranks) from the owner's point of view.
## Positive ranks = toward the opponent.
@export var directions: Array[Vector2i] = []

## How many times the step repeats in a straight line.
## 1 = a single step or leap. 0 = unlimited (slides until blocked).
@export var max_steps: int = 1

## If above 0, replaces max_steps while the piece hasn't moved yet.
@export var first_move_max_steps: int = 0

@export var mode: Mode = Mode.MOVE_OR_CAPTURE

## Captures only by hopping, like the cannon in Chinese chess: the first piece in
## the way (of either side) is a "screen" that can't be captured; the piece jumps
## over it and captures the first enemy piece beyond. Plain moves (no capture)
## stop at the screen as usual.
@export var captures_by_hopping := false

## Leaping (the Wizard, the Rogue's hop): the first `leap_steps` squares of each
## line are jumped over. The piece can't stop on them and they can't block it;
## after them the line carries on as usual (blocked by the first piece met).
@export var leap_steps := 0

enum LeapOver { ANYTHING, OWN_PIECE }
## What the leapt squares must hold: ANYTHING (empty or not), or OWN_PIECE (each
## must hold one of the mover's own pieces, like the Rogue hopping a friend).
@export var leap_over: LeapOver = LeapOver.ANYTHING

## A bent route instead of straight lines (the Cavalry's L, the Barbarian's outer
## squares): one-square steps from the owner's point of view, e.g. [(1,0), (1,0),
## (0,1)] = two right then one forward. Every square on the way must be empty;
## the last one is where it lands. When set, `directions` isn't used.
@export var path: Array[Vector2i] = []
## Also allow the path mirrored left-right / forward-back.
@export var mirror_files := false
@export var mirror_ranks := false

## Every version of `path` (with its mirror images), each listed once.
func path_variants() -> Array:
	var variants := []
	for flip_x in ([1, -1] if mirror_files else [1]):
		for flip_y in ([1, -1] if mirror_ranks else [1]):
			var steps: Array[Vector2i] = []
			for step in path:
				steps.append(Vector2i(step.x * flip_x, step.y * flip_y))
			if not variants.has(steps):
				variants.append(steps)
	return variants

## Where `path` (or one of its variants) ends up, relative to the start.
static func path_offset(steps: Array) -> Vector2i:
	var total := Vector2i.ZERO
	for step: Vector2i in steps:
		total += step
	return total

## True if this rule can't be checked by walking straight lines back from a
## square (the attack table's fast way), so attacks are worked out from the piece.
func is_unusual() -> bool:
	return leap_steps > 0 or not path.is_empty()
