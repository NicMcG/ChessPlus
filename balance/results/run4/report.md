# Balance run 4: the Quiet first move rule (report)

Made by `tools/balance/run4_analyse.py`. "Before" = the same measurement without the rule (run 3's pool round robin, run 2's 8k self-play); "after" = with the rule (Plusfish `--quiet-first-move=true`). Points = percentage points.

## Part 1: meta pool round robin (same armies, seeds and settings)

| | Before | After |
|---|---|---|
| White's score, all 2,200 games | 62.7% | 63.1% |
| White won both games of a swapped pair | 16.7% (14.6%-19.0%) | 18.5% (16.4%-21.0%) |
| Pairings with White at 80%+ | 7 | 8 |

**Each army's gap (White score minus Black score, points; 95% range for after)**

| Army | Before | After | As White / as Black after |
|---|---|---|---|
| Wide 15b | +20.2 | +33.5 (+26.3 to +40.7) | 76.0% / 42.5% |
| Wide 14b | +29.0 | +22.3 (+14.8 to +29.7) | 68.0% / 45.8% |
| Wide 15c | +23.2 | +59.2 (+52.4 to +66.1) | 89.0% / 29.8% |
| Wide 14c | +23.0 | +18.5 (+11.3 to +25.7) | 61.0% / 42.5% |
| Wide 14a | +26.3 | +15.0 (+8.4 to +21.6) | 53.2% / 38.2% |
| Wide 9b | +41.0 | +23.0 (+15.8 to +30.2) | 67.2% / 44.2% |
| Wide 13c | +22.0 | +16.5 (+9.2 to +23.8) | 58.8% / 42.2% |
| Wide 12b | +29.5 | +16.2 (+10.1 to +22.4) | 59.0% / 42.8% |
| Wide 15a | +32.2 | +47.0 (+40.7 to +53.3) | 83.8% / 36.8% |
| Wide 11a | +29.0 | +30.0 (+22.9 to +37.1) | 59.0% / 29.0% |
| Standard | +4.5 | +6.8 (+0.8 to +12.7) | 19.0% / 12.2% |

## Part 2: random armies (run 2's 8k self-play, same seed)

| | Before | After |
|---|---|---|
| Games | 20000 | 20000 |
| White's score | 56.1% (55.5%-56.7%) | 58.4% (57.8%-59.0%) |
| Draws | 22.7% | 21.1% |
| White won both (before) | 10000 pairs | 12.6% (12.0%-13.3%) |
| White won both (after) | 10000 pairs | 16.7% (15.9%-17.4%) |

## Part 3: each army against itself (Plusfish at 2,000,000 nodes, 8 threads)

White's first-move advantage in pawns, as an engine sees the start. Chess: +0.29 (top engines: +0.20 to +0.35).

| Army | Without the rule | With the rule |
|---|---|---|
| Wide 15b | +3.30 (Axb7!) | +2.82 (Ah3) |
| Wide 14b | +0.26 (Axf7!) | +0.29 (Gd3) |
| Wide 15c | +3.25 (Bxg7) | #1 (Wb6#) |
| Wide 14c | +3.91 (Axb7!) | +0.48 (ASab3) |
| Wide 14a | +4.28 (Axb7!) | +2.38 (Ba6) |
| Wide 9b | +3.04 (Lxe7+) | +2.88 (GAb6) |
| Wide 13c | +0.09 (Qxg7) | +0.11 (Gd3) |
| Wide 12b | +0.49 (Axa7) | +0.63 (ASg4) |
| Wide 15a | +0.15 (Axa7) | #1 (Wg6#) |
| Wide 11a | +1.82 (Lxh7) | +0.19 (Ed4) |
| Standard | +0.16 (d4) | +0.26 (d4) |

## Success test (run 3's, with the rule)

- Pool armies with a gap over 30 points: Wide 15b (+33.5), Wide 15c (+59.2), Wide 15a (+47.0)
- Pairings with White at 80% or more: Wide 15b vs Wide 15c (95.0%), Wide 15b vs Wide 15a (87.5%), Wide 14b vs Wide 15a (88.8%), Wide 15c vs Wide 14c (95.0%), Wide 15c vs Wide 9b (90.0%), Wide 15c vs Wide 15a (100.0%), Wide 15c vs Wide 11a (100.0%), Wide 13c vs Wide 15a (83.8%)
- **Result: FAILED**
