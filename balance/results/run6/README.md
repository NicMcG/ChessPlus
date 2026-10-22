# Balance run 6: the Front-row rule with strong armies (AWS sims server, 22 October 2026)

Run 5 showed the Front-row rule (no piece may start able to capture anything
on the opponent's two starting rows) brings random armies to chess level. This
run checks it with the strongest armies, and at more search depth. Tested in
Plusfish only, not in the game: on branch `experiment/front-row-rule` (commit
2a93f06, which includes Nicholas's PR #26) Plusfish's army check enforces the
rule when given `--front-row-rule=true`. Full tables in `report.md`
(`tools/balance/run6_analyse.py`).

| Part | What | Settings |
|---|---|---|
| 1 | Meta pool regrown under the rule (`meta_pool.txt`, `meta.log`) | `meta --wide 64 --game-climb --king-exposed reject --rounds 15 --seed 1` (run 2's settings), from the old pool: all 10 old members broke the rule, so it grew from Standard |
| 2 | Round robin of the new pool + Standard, Mac's success test | run 3's settings: 40 games a pairing, 8,000 nodes, `--random-plies 4`, seeds 3000-3054 |
| 3 | Each pool army against itself | `plusfish analyse`, 2,000,000 nodes, 8 threads (`mirror.txt`) |
| 4 | Random armies following the rule at 32,000 nodes | 10,000 games, seed 202, compared with run 2's 32k games |

- Server: `chessplus-sims` (c8g.16xlarge, 64 cores), 20:30-21:39 UTC for this
  run (run 7 followed in the same session; ~$4.85 real for both, including a
  few minutes restarted for the new Plusfish), stopped through AWS. Game files:
  `Documents\ChessPlusSims\run6\`.
- The new pool is kept as `engine/plusfish/reports/meta_pool_front_row.txt`.

## Results

| | Run 3 (old pool, no rule) | Run 7 (new pool, no rule) | **Run 6 (pool under the rule)** |
|---|---|---|---|
| White's score in the round robin | 62.7% | 59.4% | **51.0%** |
| White won both of a swapped pair (chess 23%) | 16.7% | 12.5% | **8.8%** |
| Biggest White-minus-Black gap of a pool army | +41.0 | +31.2 | **+14.5** (most within ±7) |
| Pairings with White at 80%+ | 7 | 3 | **1** (82.5%, 95% range about 68-91%) |
| Army against itself (chess +0.29) | up to +4.6 | up to +4.1 | mostly 0.0 to +0.56; one +2.80 |

- **Success test: failed by one pairing.** No pool army's gap is over 30
  points (all under 15), but Wide 5a vs Wide 10a had White at 82.5% (33 of 40
  points), just over the 80% line; with 40 games its range easily includes
  under 80%.
- The one high army against itself, Wide 5a (+2.80), opens 1. Ab5+: a check
  on move 1, not a capture, so the rule allows it. It's also the pool army
  with the biggest gap (+14.5).
- **At 32,000 nodes the rule holds:** random armies White 51.4% (50.6-52.3)
  against 56.6% without it; White winning both of a swapped pair 8.2% against
  13.0%. Only 3.5% of games start with a capture or ability on White's first
  move (Full Moon and the like; captures are impossible).
