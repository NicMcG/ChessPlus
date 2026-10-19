# Plusfish Elo log

Every engine change is measured against the build before it with
`plusfish enginematch` (random army pairs, each played twice from the same
opening with colours swapped; Elo from pair results, ±95%). Regimes:

* **nodes**: fixed nodes per move (6,000 unless noted), the self-play and
  eval-bar regime: strength per node.
* **time**: a clock per game (e.g. 10+0.1 s), so speed counts too.

Calibration: 12,000 vs 6,000 nodes = +112.5 ±14.4 (1000 games). Doubling
the nodes is worth roughly 110 Elo here, so a 2x speed-up at fixed time
should be worth about as much.

| # | Change | Regime | Games | Elo ±95% | Kept? |
|---|--------|--------|-------|----------|-------|
| 1 | Bad captures (rough exchange estimate; Ram counts as lost): ordered after killers, skipped in quiescence | nodes 6k | 982 | +33.4 ±13.8 | kept |
| 2 | History: penalties for quiet moves that didn't cut off, bounded updates; LMR reduces less for good history | nodes 6k | 8000 | +4.5 ±4.6 | kept (marginal) |
| 3 | Transposition table in quiescence (probe, cutoffs, store, hash move first) | nodes 6k | 1290 | +21.3 ±10.8 | kept |
| 4 | Internal iterative reduction (depth-1 when no hash move, depth >= 4) | nodes 6k | 8000 | +2.1 ±4.0 | reverted (no gain shown; retry deep) |
| 5 | Lazy SMP (shared hash table, helpers own history; odd helpers one ply deeper). UCI option Threads, analyse --threads | time 5+0.05, 4 threads vs 1 | 300 | +102.5 ±24.1 | kept |
| 6 | Counter-move ordering (quiet reply that last refuted the previous move) | nodes 6k | 7394 | +5.9 ±4.5 | kept |
| 7 | Null move reduction grows with (eval - beta)/200, up to +3 | nodes 6k | 6608 | +0.7 ±3.4 | reverted (SPRT H0) |
| 8 | Mobility with ray bit masks instead of square-by-square walks (same eval) | speed (bench nps) | - | 0.94x with default target, 1.05x with x86-64-v2 | reverted for now |
| 9 | "Improving" (static eval vs two plies ago): reverse futility and late-move pruning adapt | nodes 6k | 3998 | +9.0 ±6.5 | kept |
