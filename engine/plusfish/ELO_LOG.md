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
| 23 | Re-tune the per-piece weights (material, mobility per piece type, shield, ability) on 20,680 self-play games with all 30 pieces (`tune --only mat,mob,shield,ability`); the 11 new pieces had only cost-based values and every mobility weight was the same 3.1 | nodes 6k / nodes 20k | 2000 / 500 | +74.6 ±11.0 / +100.7 ±23.2 | kept |
| 24 | Eval: per-piece "worth while the armies are whole" term (fades out over the first 8 captures), tuned with the rest | start-check (below) | - | no better than #23 | reverted |
| 25 | Full re-tune (every feature) instead of #23 | start-check (below) | - | same on random armies, worse on the pool; pawn-advance weights came out jagged | not used |

## Judging the starting position (`start-check`)

186 army pairings played 40 times each (20 per colour, 6,000 nodes) for the
truth: 150 random pairs drawn from all 30 pieces, plus the old 8-army pool
with Standard. Correlation of each engine's start score (both colours
averaged) with the real result; the noise ceiling is 0.98.

| Weights | random pairs @1 node | @20,000 | right army when clear (@20k) | pool + Standard @20,000 |
|---|---|---|---|---|
| before #23 | 0.55 | 0.62 | 78% | 0.59 |
| #23 (kept) | 0.77 | 0.84 | 97% | 0.61 |
| #24 (+ opening term) | 0.76 | 0.84 | 97% | 0.52 |
| #25 (full re-tune) | 0.77 | 0.83 | 97% | 0.50 |

With only the 19 old pieces, the starting engine (base1) and the build after
#22 judged random pairs the same (0.84 vs 0.85 at 20,000 nodes): the search
work didn't change opening judgement; valuing the new pieces did.

## The eval-bar meta pool (`meta`, reports/META_POOL.md)

10 armies grown by `plusfish meta` with the #23 weights. #23 against the
build before it, on that pool: **+107.5 ±19.0** (6,000 nodes, 1000 games).
start-check on the pool + Standard (55 pairings, 40 games each): correlation
0.79 at 20,000 nodes with #23, 0.41 before it.
