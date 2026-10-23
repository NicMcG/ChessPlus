# Balance run 8: cheaper pawns (AWS sims server, 23 October 2026)

The idea (Mac): pawns measure about 0.7 against a cost of 1, so armies skip
the pawn wall that closes lines in chess. If pawns are cheaper, do strong
armies build walls on their own? Two prices, **Pawn 0.75** and **Pawn 0.5**;
nothing else changed. Tested in Plusfish only, on branch
`experiment/cheap-pawns` (commit 665aac8: `data/pieces/pawn.tres` at 0.75; the
0.5 price is a copy of the pieces folder with only that number changed, made
on the server). Plusfish itself is main's (de87b38, unchanged since runs 6-7).
Full tables in `report.md` (`tools/balance/run8_9_analyse.py`).

For each price (`p075/`, `p050/`):

| Part | What | Settings |
|---|---|---|
| 1 | Meta pool grown under that price (`meta_pool.txt`, `meta.log`) | `meta --wide 64 --game-climb --king-exposed reject --rounds 15 --seed 1` (run 2's settings), from `engine/plusfish/reports/meta_pool.txt` (run 7's pool) plus Standard |
| 2 | Round robin of that pool + Standard | run 3's settings: 40 games a pairing (20 per colour), 8,000 nodes, `--random-plies 4`, seeds 3000-3054 |
| 3 | Random-army self-play and its balance report (`report_8k.txt` / `.html`) | 20,000 games, 8,000 nodes, seed 101, selfplay defaults |

- **Server:** `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores). Pawn 0.75
  ran 17:25-18:21 UTC, Pawn 0.5 18:21-19:07, after run 9 in the same session
  (see run 9's README for the time and cost of both runs, and the idle
  switch-off that interrupted the first attempt). Stopped through AWS.
- **Baseline:** run 9's control (the same random-army self-play with the Pawn
  at 1 on today's Plusfish) and run 7 (today's pool round robin).
- Scripts: `tools/balance/run8_server.sh`, `run8_run9_driver.sh`,
  `run8_run9_resume.sh` (branch `experiment/cheap-pawns`). Game files (not in
  the repo): `Documents\ChessPlusSims\run8\`.

## Result: cheaper pawns don't build walls, and White's edge grows a little

| | Control (Pawn 1) | Pawn 0.75 | Pawn 0.5 |
|---|---|---|---|
| Random armies: White's score | 55.7% | 56.1% | 56.5% |
| ... White's first move a capture or ability | 23.7% | 24.8% | 26.0% |
| ... White won both of a swapped pair | 12.3% | 12.6% | 13.6% |
| Pawn's measured worth (on that run's cost scale) | 0.73 ±0.04 | 0.72 ±0.04 | 0.72 ±0.04 |
| Pool armies: pawns each (average) | 1.1 (run 7's pool) | 2.2 | 4.5 |
| ... in the front row | 0.4 | 0.3 | 0.8 |
| ... armies with 4+ pawns in the front row | 0 of 10 | 0 of 10 | 0 of 10 |
| Round robin: White's score | 59.4% (run 7) | 64.2% | 62.3% |
| ... pool armies with a gap over 30 points | 1 | 5 (biggest +41.8) | 3 (biggest +40.2) |
| ... pairings with either colour at 80%+ | 3 | 8 | 9 |
| Piece types in the pool (not the King) | 22 | 22 | 20 |

- **No walls.** At Pawn 0.5 every pool army has pawns (4.5 on average), but
  they go on the back row, behind the pieces, not in front of them. That
  leaves the long-range front-row pieces free to capture on move 1, and
  first-move captures happen even more often than with run 7's pool (White's
  first move a capture or ability in 72% and 66% of round-robin games, against
  59%). Note: any unmoved pawn gets its double step, even from the back row.
- **The Pawn's worth didn't move** (0.72-0.73) as its price fell: on each
  run's own scale it stays a weak piece.
- **Success test: failed at both prices**, by a wide margin (random armies
  56-57%, round robin 62-64%, several gaps over 30 and 8-9 pairings at 80%+).
- The pools have two different armies both named "Wide 10a" (at Pawn 0.75), a
  naming clash in Plusfish's meta command; their numbers are kept apart.

The comparison with every run so far (2, 4, 5, 6, 7, 8 and 9) is the table in
`balance/results/run9/README.md`.

These are engine-vs-engine results, not human play: strong hints, not proof.
Balancing decisions are Mac's.
