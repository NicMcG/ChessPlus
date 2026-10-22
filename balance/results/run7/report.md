# Balance run 7: the meta pool regrown with Plusfish PR #26, normal rules (report)

Made by `tools/balance/run6_analyse.py`. Parts 1 and 2 use run 3's settings, so they compare with run 3 directly. Points = percentage points.

## Part 1: round robin of the new pool (run 3's settings)

The 10 armies of `engine/plusfish/reports/meta_pool.txt` plus Standard, every pairing 40 games (20 with each colour), 8,000 nodes per move, `--random-plies 4`. 2200 games; White scored 59.4% overall. White won both games of a colour-swapped pair in 138 of 1100 pairs (12.5%, 95% 10.7%-14.6%; chess benchmark 23%). Games ended by King exposed: 0.

### Each army as White and as Black

Score = the army's own score (draws half). Gap = White score minus Black score, in points. 95% ranges in brackets.

| Army | Archers | As White | As Black | Gap (points) | Flag |
|---|---|---|---|---|---|
| Wide 14a | 1 | 74.5% (69.7%-79.3%), 200 games | 53.2% (48.2%-58.3%), 200 games | +21.3 (+14.3 to +28.2) |  |
| Wide 15a | 1 | 63.0% (58.1%-67.9%), 200 games | 53.8% (49.3%-58.2%), 200 games | +9.3 (+2.7 to +15.8) |  |
| Wide 15c | 0 | 64.5% (59.8%-69.2%), 200 games | 55.8% (50.6%-60.9%), 200 games | +8.8 (+1.8 to +15.7) |  |
| Wide 13a | 1 | 60.5% (55.0%-66.0%), 200 games | 49.2% (43.8%-54.7%), 200 games | +11.2 (+3.5 to +19.0) |  |
| Wide 10a | 1 | 62.7% (57.5%-68.0%), 200 games | 40.5% (35.1%-45.9%), 200 games | +22.2 (+14.7 to +29.8) |  |
| Wide 11a | 0 | 70.8% (66.0%-75.5%), 200 games | 39.5% (33.9%-45.1%), 200 games | +31.2 (+23.9 to +38.6) | over 30 |
| Wide 11c | 1 | 57.8% (52.4%-63.1%), 200 games | 39.2% (33.8%-44.7%), 200 games | +18.5 (+10.9 to +26.1) |  |
| Wide 13c | 0 | 64.0% (58.3%-69.7%), 200 games | 36.0% (30.3%-41.7%), 200 games | +28.0 (+19.9 to +36.1) |  |
| Wide 7c | 1 | 63.7% (59.0%-68.5%), 200 games | 36.2% (31.6%-40.9%), 200 games | +27.5 (+20.9 to +34.1) |  |
| Wide 14a | 1 | 59.0% (54.4%-63.6%), 200 games | 36.2% (31.1%-41.4%), 200 games | +22.7 (+15.9 to +29.6) |  |
| Standard | 0 | 12.5% (9.0%-16.0%), 200 games | 7.2% (4.0%-10.5%), 200 games | +5.3 (+0.5 to +10.0) |  |

### White's score in every pairing

| Army A | Army B | Games | White's score | 95% range | Flag |
|---|---|---|---|---|---|
| Wide 14a | Wide 15a | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 14a | Wide 15c | 40 | 41.2% | 27.4%-56.6% |  |
| Wide 14a | Wide 13a | 40 | 51.2% | 36.3%-65.9% |  |
| Wide 14a | Wide 10a | 40 | 50.0% | 35.2%-64.8% |  |
| Wide 14a | Wide 11a | 40 | 75.0% | 59.8%-85.8% |  |
| Wide 14a | Wide 11c | 40 | 68.8% | 53.3%-80.9% |  |
| Wide 14a | Wide 13c | 40 | 92.5% | 80.1%-97.4% | 80%+ |
| Wide 14a | Wide 7c | 40 | 53.8% | 38.7%-68.2% |  |
| Wide 14a | Wide 14a | 40 | 75.0% | 59.8%-85.8% |  |
| Wide 14a | Standard | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 15a | Wide 15c | 40 | 42.5% | 28.5%-57.8% |  |
| Wide 15a | Wide 13a | 40 | 53.8% | 38.7%-68.2% |  |
| Wide 15a | Wide 10a | 40 | 60.0% | 44.6%-73.7% |  |
| Wide 15a | Wide 11a | 40 | 61.3% | 45.8%-74.7% |  |
| Wide 15a | Wide 11c | 40 | 62.5% | 47.0%-75.8% |  |
| Wide 15a | Wide 13c | 40 | 41.2% | 27.4%-56.6% |  |
| Wide 15a | Wide 7c | 40 | 70.0% | 54.6%-81.9% |  |
| Wide 15a | Wide 14a | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 15a | Standard | 40 | 57.5% | 42.2%-71.5% |  |
| Wide 15c | Wide 13a | 40 | 53.8% | 38.7%-68.2% |  |
| Wide 15c | Wide 10a | 40 | 75.0% | 59.8%-85.8% |  |
| Wide 15c | Wide 11a | 40 | 60.0% | 44.6%-73.7% |  |
| Wide 15c | Wide 11c | 40 | 47.5% | 32.9%-62.5% |  |
| Wide 15c | Wide 13c | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 15c | Wide 7c | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 15c | Wide 14a | 40 | 61.3% | 45.8%-74.7% |  |
| Wide 15c | Standard | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 13a | Wide 10a | 40 | 65.0% | 49.5%-77.9% |  |
| Wide 13a | Wide 11a | 40 | 43.8% | 29.6%-59.0% |  |
| Wide 13a | Wide 11c | 40 | 42.5% | 28.5%-57.8% |  |
| Wide 13a | Wide 13c | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 13a | Wide 7c | 40 | 77.5% | 62.5%-87.7% |  |
| Wide 13a | Wide 14a | 40 | 61.3% | 45.8%-74.7% |  |
| Wide 13a | Standard | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 10a | Wide 11a | 40 | 53.8% | 38.7%-68.2% |  |
| Wide 10a | Wide 11c | 40 | 73.8% | 58.5%-84.9% |  |
| Wide 10a | Wide 13c | 40 | 62.5% | 47.0%-75.8% |  |
| Wide 10a | Wide 7c | 40 | 62.5% | 47.0%-75.8% |  |
| Wide 10a | Wide 14a | 40 | 62.5% | 47.0%-75.8% |  |
| Wide 10a | Standard | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 11a | Wide 11c | 40 | 76.2% | 61.1%-86.8% |  |
| Wide 11a | Wide 13c | 40 | 58.8% | 43.4%-72.6% |  |
| Wide 11a | Wide 7c | 40 | 97.5% | 87.1%-99.6% | 80%+ |
| Wide 11a | Wide 14a | 40 | 63.7% | 48.3%-76.8% |  |
| Wide 11a | Standard | 40 | 66.2% | 50.8%-78.9% |  |
| Wide 11c | Wide 13c | 40 | 73.8% | 58.5%-84.9% |  |
| Wide 11c | Wide 7c | 40 | 42.5% | 28.5%-57.8% |  |
| Wide 11c | Wide 14a | 40 | 58.8% | 43.4%-72.6% |  |
| Wide 11c | Standard | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 13c | Wide 7c | 40 | 67.5% | 52.0%-79.9% |  |
| Wide 13c | Wide 14a | 40 | 80.0% | 65.2%-89.5% | 80%+ |
| Wide 13c | Standard | 40 | 53.8% | 38.7%-68.2% |  |
| Wide 7c | Wide 14a | 40 | 56.2% | 41.0%-70.4% |  |
| Wide 7c | Standard | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 14a | Standard | 40 | 50.0% | 35.2%-64.8% |  |

### Gaps by how many Archers the army has

| Archers | Armies | Mean gap (points) | Each army's gap |
|---|---|---|---|
| 0 | 4 | +18.3 | Wide 15c +8.8, Wide 11a +31.2, Wide 13c +28.0, Standard +5.3 |
| 1 | 7 | +19.0 | Wide 14a +21.3, Wide 15a +9.3, Wide 13a +11.2, Wide 10a +22.2, Wide 11c +18.5, Wide 7c +27.5, Wide 14a +22.7 |

## Part 2: each army against itself (Plusfish at 2,000,000 nodes, 8 threads)

White's first-move advantage in pawns. Chess: +0.29 (top engines +0.20 to +0.35).

| Army | White's advantage | Plusfish's first move |
|---|---|---|
| Wide 11a `1(WW)GK(NC)(CV)(GA)R/(AS)BB(CV)GE(PD)L` | +0.23 | Lxh7 |
| Wide 13c `P(CV)NCK(BR)1B/(AS)G(BR)LV(RM)B(AS)` | +4.05 | Lxd7+ |
| Wide 15a `QE(WW)1KN(NC)(RM)/(AS)APB(BR)(PD)G(AS)` | +3.43 | Axg7! |
| Wide 10a `1Q1KGE(NC)C/B(AS)BG(BR)(AS)(PD)A` | +4.05 | Bxf7+ |
| Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | +2.99 | Axa8! |
| Wide 15c `EQ(RO)K1(AS)(WW)(NC)/(PD)GB(RM)GB(PD)(AS)` | +0.30 | Bxh7* |
| Wide 13a `(NC)PQPK(GA)P(CV)/EBAGPEGP` | +0.19 | Ge3 |
| Wide 11c `1Q1NKPP(NC)/(RM)(SQ)(CV)(AS)(RM)A(WW)(AS)` | +0.12 | SQc3 |
| Wide 7c `1G1NKQG1/BA(AS)(RM)(CV)(BR)(AS)(CH)` | +4.10 | Axg7! |
| Standard `standard` | +0.13 | d4 |
| Wide 14a `1(BR)ENK1Q(BR)/C(AS)(RO)EB(PD)AB` | +3.87 | Axb7! |

## Success test (run 3's, decided before running), on the new pool

- Pool armies with a gap over 30 points: Wide 11a (+31.2)
- Pairings with White at 80% or more: Wide 14a vs Wide 13c (92.5%), Wide 11a vs Wide 7c (97.5%), Wide 13c vs Wide 14a (80.0%)
- **Result: FAILED**
