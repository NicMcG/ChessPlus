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
| 10 | Futility pruning of quiet moves (static eval + 100 + 120*depth <= alpha, depth <= 3) | nodes 6k | 1266 | +22.0 ±11.5 | kept |
| 11 | Prune bad captures in the main search (gain < -120*depth, depth <= 4) | nodes 6k | 1200 | -18.0 ±11.5 | reverted |
| 12 | LMR: +1 when not improving, -1 for killers/counter-moves | nodes 6k | 4258 | -3.0 ±6.0 | reverted (SPRT H0) |
| 13 | Eval: "threatened" term, pieces attacked by a cheaper enemy piece (-30 mg / -25 eg, hand-set) | nodes 6k | 1122 | +21.7 ±12.1 | kept |
| 14 | Use a root move from an unfinished iteration if it was fully searched and beat the window | nodes 6k | 5128 | +6.0 ±4.7 | kept |
| 15 | Eval: extra term for threatened pieces of the side not to move | nodes 6k | 8000 | +1.6 ±4.4 | reverted |
| 16 | Eval: king-zone attacks squared (-1.5 mg) | nodes 6k | 8000 | +1.3 ±4.4 | reverted |
| 17 | Time management: soft target (left/35 + 3/4 inc), hard limit up to 4x; stop early when the best move is stable, later when it keeps changing | time 10+0.1 | 512 | +30.6 ±17.1 | kept |
| 18 | Static exchange evaluation (full capture sequence on the square, least valuable first; cannons' screens, Rams, shields, leapers) replaces the rough estimate; see-check command compares it with brute force (99.3% same sign, the rest pins/checks) | nodes 6k | 1298 | +20.6 ±10.8 | kept |
| 19 | Prune captures with SEE < -120*depth near the leaves (retry of #11 with the real SEE) | nodes 6k | 6900 | +6.3 ±4.7 | kept |
| 20 | Prune quiet moves whose SEE < -50*depth^2 near the leaves | nodes 6k | 5218 | +6.3 ±5.4 | kept |
| 21 | Bound quiescence check chains (evasions only in the first 6 quiescence plies) + node-limit safety net at depth 1; ported from plusfish-army-pool (it fixes a hang) | nodes 6k, random / pool | 4000 / 2000 | 0.0 ±4.7 / +2.6 ±4.2 | kept (safety fix) |

## Checkpoint: build after #20 vs the starting engine (base1)

| Regime | Games | Elo ±95% |
|--------|-------|----------|
| 6,000 nodes/move (self-play) | 2000 | +114.1 ±10.9 |
| 20,000 nodes/move (web eval bar) | 2000 | +106.4 ±10.1 |
| 150,000 nodes/move (PC eval bar) | 800 | +84.6 ±14.4 |
| clock 10+0.1 s, 1 thread | 800 | +81.8 ±14.1 |

Lazy SMP adds to the clock result on top: 4 threads vs 1 = +102.5 ±24.1 (#5).
| 22 | Hash table in buckets of two entries (replace the shallower/older one) | time 10+0.1 | 800 | +14.8 ±12.5 | kept (SPRT undecided at the game limit; range excludes 0) |
