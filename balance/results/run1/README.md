# Balance run 1 (Mac, AWS server, 20 October 2026)

Two Plusfish self-play balance reports (job 1 in `engine/plusfish/HOW_TO.md`),
run by Mac on an AWS server.

| Report | Game version | Games | Nodes per move | Seed |
|---|---|---|---|---|
| `report_8k_seed101.txt` / `.html` | 0c1c7bb | 20,000 | 8,000 | 101 |
| `report_32k_seed202.txt` / `.html` | 0c1c7bb | 20,000 | 32,000 | 202 |

- **Game version 0c1c7bb** is the commit the runs used: the new Squire rule
  (protects Knights anywhere in its move range, even through pieces) and the
  Berserker's 2-then-1 L-moves, with Plusfish knowing both (PR #22). Piece
  costs as they were then: see the `cost` column.
- Random armies of all 29 pieces, as in Plusfish's `selfplay`.
- The `.html` files are the same reports as charts (open them in a browser).
- The raw game records (`games_8k_seed101.jsonl`, `games_32k_seed202.jsonl`,
  about 17 MB each) are not in the repo. They're on Mac's PC in
  `Documents\ChessPlusSims\run1\`. They're only needed to
  re-make a report or to retrain Plusfish (job 2 in the HOW_TO).

## How to read them

"worth (army)" is what one extra piece of that type at the start of a game is
worth, judged from game results, on the same scale as the costs. The `±` is
the uncertainty. The two runs use different search depths and different
random seeds, so where they agree, the result doesn't depend on either.

What both runs agree on (all at least 0.5 away from the cost, in both):

- Priced too low: Vampire (4, worth ~6.7), Queen (9, ~10.0-10.3),
  Princess (7, ~8.4), Squire (3, ~4.1).
- Priced too high: Assassin (2, worth ~0.4), Galleon (4.5, ~3.2),
  Elephant (1.5, ~0.9), Paladin (2, ~1.4-1.5).
- White scores 55.8% and 56.9%; the first-move edge with equal armies is
  +55 and +71 Elo.

These are engine-vs-engine results, not human play: strong hints, not proof.
Balancing decisions are Mac's, discussed in normal Claude chat.
