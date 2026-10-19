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
