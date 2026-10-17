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
