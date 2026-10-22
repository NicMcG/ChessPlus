# Balance run 6: the Front-row rule with strong armies (report)

Made by `tools/balance/run6_analyse.py`. Parts 1 and 2 use run 3's settings, so they compare with run 3 directly. Points = percentage points.

## Part 1: round robin of the new pool (run 3's settings)

The 10 armies of `engine/plusfish/reports/meta_pool.txt` plus Standard, every pairing 40 games (20 with each colour), 8,000 nodes per move, `--random-plies 4`. 2200 games; White scored 51.0% overall. White won both games of a colour-swapped pair in 97 of 1100 pairs (8.8%, 95% 7.3%-10.6%; chess benchmark 23%). Games ended by King exposed: 0.

### Each army as White and as Black

Score = the army's own score (draws half). Gap = White score minus Black score, in points. 95% ranges in brackets.

| Army | Archers | As White | As Black | Gap (points) | Flag |
|---|---|---|---|---|---|
| Wide 14c | 0 | 62.3% (56.2%-68.3%), 200 games | 55.0% (48.8%-61.2%), 200 games | +7.3 (-1.4 to +15.9) |  |
| Wide 11c | 1 | 60.0% (54.3%-65.7%), 200 games | 58.5% (52.8%-64.2%), 200 games | +1.5 (-6.6 to +9.6) |  |
| Wide 15c | 0 | 65.0% (59.7%-70.3%), 200 games | 65.0% (59.6%-70.4%), 200 games | +0.0 (-7.6 to +7.6) |  |
| Wide 5a | 1 | 59.2% (54.1%-64.4%), 200 games | 44.8% (38.7%-50.8%), 200 games | +14.5 (+6.6 to +22.4) |  |
| Wide 14b | 1 | 58.0% (52.8%-63.2%), 200 games | 56.0% (51.1%-60.9%), 200 games | +2.0 (-5.2 to +9.2) |  |
| Wide 9a | 1 | 49.8% (44.6%-54.9%), 200 games | 52.5% (47.1%-57.9%), 200 games | -2.8 (-10.2 to +4.7) |  |
| Wide 7a | 2 | 59.5% (53.9%-65.1%), 200 games | 57.2% (51.4%-63.1%), 200 games | +2.2 (-5.8 to +10.3) |  |
| Wide 8b | 0 | 45.2% (39.2%-51.3%), 200 games | 48.5% (42.7%-54.3%), 200 games | -3.2 (-11.7 to +5.2) |  |
| Wide 8a | 0 | 48.2% (42.1%-54.4%), 200 games | 47.8% (41.8%-53.7%), 200 games | +0.5 (-8.1 to +9.1) |  |
| Wide 10a | 2 | 47.8% (42.0%-53.5%), 200 games | 45.5% (39.9%-51.1%), 200 games | +2.2 (-5.8 to +10.3) |  |
| Standard | 0 | 6.0% (3.2%-8.8%), 200 games | 8.2% (5.3%-11.2%), 200 games | -2.3 (-6.3 to +1.8) |  |

### White's score in every pairing

| Army A | Army B | Games | White's score | 95% range | Flag |
|---|---|---|---|---|---|
| Wide 14c | Wide 11c | 40 | 40.0% | 26.3%-55.4% |  |
| Wide 14c | Wide 15c | 40 | 61.3% | 45.8%-74.7% |  |
| Wide 14c | Wide 5a | 40 | 65.0% | 49.5%-77.9% |  |
| Wide 14c | Wide 14b | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 14c | Wide 9a | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 14c | Wide 7a | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 14c | Wide 8b | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 14c | Wide 8a | 40 | 58.8% | 43.4%-72.6% |  |
| Wide 14c | Wide 10a | 40 | 53.8% | 38.7%-68.2% |  |
| Wide 14c | Standard | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 11c | Wide 15c | 40 | 56.2% | 41.0%-70.4% |  |
| Wide 11c | Wide 5a | 40 | 68.8% | 53.3%-80.9% |  |
| Wide 11c | Wide 14b | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 11c | Wide 9a | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 11c | Wide 7a | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 11c | Wide 8b | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 11c | Wide 8a | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 11c | Wide 10a | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 11c | Standard | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 15c | Wide 5a | 40 | 37.5% | 24.2%-53.0% |  |
| Wide 15c | Wide 14b | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 15c | Wide 9a | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 15c | Wide 7a | 40 | 42.5% | 28.5%-57.8% |  |
| Wide 15c | Wide 8b | 40 | 47.5% | 32.9%-62.5% |  |
| Wide 15c | Wide 8a | 40 | 62.5% | 47.0%-75.8% |  |
| Wide 15c | Wide 10a | 40 | 51.2% | 36.3%-65.9% |  |
| Wide 15c | Standard | 40 | 50.0% | 35.2%-64.8% |  |
| Wide 5a | Wide 14b | 40 | 75.0% | 59.8%-85.8% |  |
| Wide 5a | Wide 9a | 40 | 51.2% | 36.3%-65.9% |  |
| Wide 5a | Wide 7a | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 5a | Wide 8b | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 5a | Wide 8a | 40 | 43.8% | 29.6%-59.0% |  |
| Wide 5a | Wide 10a | 40 | 82.5% | 68.0%-91.3% | 80%+ |
| Wide 5a | Standard | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 14b | Wide 9a | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 14b | Wide 7a | 40 | 58.8% | 43.4%-72.6% |  |
| Wide 14b | Wide 8b | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 14b | Wide 8a | 40 | 43.8% | 29.6%-59.0% |  |
| Wide 14b | Wide 10a | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 14b | Standard | 40 | 47.5% | 32.9%-62.5% |  |
| Wide 9a | Wide 7a | 40 | 56.2% | 41.0%-70.4% |  |
| Wide 9a | Wide 8b | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 9a | Wide 8a | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 9a | Wide 10a | 40 | 43.8% | 29.6%-59.0% |  |
| Wide 9a | Standard | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 7a | Wide 8b | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 7a | Wide 8a | 40 | 60.0% | 44.6%-73.7% |  |
| Wide 7a | Wide 10a | 40 | 50.0% | 35.2%-64.8% |  |
| Wide 7a | Standard | 40 | 51.2% | 36.3%-65.9% |  |
| Wide 8b | Wide 8a | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 8b | Wide 10a | 40 | 40.0% | 26.3%-55.4% |  |
| Wide 8b | Standard | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 8a | Wide 10a | 40 | 38.8% | 25.3%-54.2% |  |
| Wide 8a | Standard | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 10a | Standard | 40 | 52.5% | 37.5%-67.1% |  |

### Gaps by how many Archers the army has

| Archers | Armies | Mean gap (points) | Each army's gap |
|---|---|---|---|
| 0 | 5 | +0.5 | Wide 14c +7.3, Wide 15c +0.0, Wide 8b -3.2, Wide 8a +0.5, Standard -2.3 |
| 1 | 4 | +3.8 | Wide 11c +1.5, Wide 5a +14.5, Wide 14b +2.0, Wide 9a -2.8 |
| 2 | 2 | +2.2 | Wide 7a +2.2, Wide 10a +2.2 |

## Part 2: each army against itself (Plusfish at 2,000,000 nodes, 8 threads)

White's first-move advantage in pawns. Chess: +0.29 (top engines +0.20 to +0.35).

| Army | White's advantage | Plusfish's first move |
|---|---|---|
| Wide 5a `2(WW)K(NC)AQB/(AS)N(PD)B1(WW)(PD)(NC)` | +2.80 | Ab5+ |
| Wide 15c `B2K1QB(NC)/(AS)N(SQ)N(WW)V(AS)1` | +0.48 | Nbc4 |
| Wide 14b `(NC)(PD)1KQ(NC)(WW)1/(AS)(BR)(PD)(WW)AGG(AS)` | +0.21 | Ge3 |
| Wide 14c `P1NK(SQ)(BR)(WW)1/(AS)(BR)G(WW)VVG(AS)` | +0.40 | Ve3 |
| Wide 8b `1(NC)(SQ)KPPQ1/(AS)(BR)G(PD)(WW)GV(AS)` | +0.09 | Vf3 |
| Wide 11c `QPPK(CV)1(NC)A/(AS)E(WW)BBGG(AS)` | +0.26 | Ed4 |
| Wide 7a `BQP1KPPA/(AS)(CV)(PD)AB(BR)P(NC)` | +0.56 | PDc3 |
| Wide 9a `A(NC)(WW)(BR)KEQN/(AS)G(CT)1(CV)(AS)(BR)1` | +0.37 | Gb3 |
| Wide 8a `PP(SQ)K1(NC)Q1/(AS)NGG(WW)(PD)V1` | +0.00 | Vf3 |
| Wide 10a `E(PA)1PK(WW)PQ/(BR)(AS)(WW)AAG(BR)(AS)` | +0.19 | WWc2! |
| Standard `standard` | +0.12 | d4 |

## Part 3: random armies at 32,000 nodes

| | Run 2 (no rule, 32k) | Run 6 (Front-row rule, 32k) |
|---|---|---|
| Games | 20000 | 10000 |
| White's score (95%) | 56.6% (56.0%-57.2%) | 51.4% (50.6%-52.3%) |
| Draws | 20.9% | 21.1% |
| White won both games of a swapped pair (chess benchmark 23%) | 13.0% (12.4%-13.7%), 10000 pairs | 8.2% (7.5%-9.0%), 5000 pairs |
| Games where White's first move captures or uses an ability | 23.3% | 3.5% |
| Mean game length (plies) | 127 | 135 |

## Success test (run 3's, decided before running), on the new pool

- Pool armies with a gap over 30 points: none
- Pairings with White at 80% or more: Wide 5a vs Wide 10a (82.5%)
- **Result: FAILED**
