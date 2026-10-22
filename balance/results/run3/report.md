# Balance run 3: colour swings (report)

Made by `tools/balance/run3_analyse.py`. Points = percentage points. "White won both" = the same two armies played twice with colours swapped and White won both games.

## Part 1: meta pool round robin

The 10 armies of `engine/plusfish/reports/meta_pool.txt` plus Standard, every pairing 40 games (20 with each colour), 8,000 nodes per move, `--random-plies 4`. 2200 games; White scored 62.7% overall. White won both games of a colour-swapped pair in 184 of 1100 pairs (16.7%, 95% 14.6%-19.0%; chess benchmark 23%). Games ended by King exposed: 0.

### Each army as White and as Black

Score = the army's own score (draws half). Gap = White score minus Black score, in points. 95% ranges in brackets.

| Army | Archers | As White | As Black | Gap (points) | Flag |
|---|---|---|---|---|---|
| Wide 15b | 1 | 71.2% (66.1%-76.4%), 200 games | 51.0% (45.3%-56.7%), 200 games | +20.2 (+12.6 to +27.9) |  |
| Wide 14b | 1 | 76.5% (71.8%-81.2%), 200 games | 47.5% (42.0%-53.0%), 200 games | +29.0 (+21.8 to +36.2) |  |
| Wide 15c | 0 | 63.2% (57.3%-69.2%), 200 games | 40.0% (34.8%-45.2%), 200 games | +23.2 (+15.3 to +31.2) |  |
| Wide 14c | 1 | 72.0% (67.7%-76.3%), 200 games | 49.0% (43.7%-54.3%), 200 games | +23.0 (+16.2 to +29.8) |  |
| Wide 14a | 1 | 67.5% (62.1%-72.9%), 200 games | 41.2% (35.6%-46.9%), 200 games | +26.3 (+18.4 to +34.1) |  |
| Wide 9b | 0 | 76.5% (71.9%-81.1%), 200 games | 35.5% (29.4%-41.6%), 200 games | +41.0 (+33.4 to +48.6) | over 30 |
| Wide 13c | 0 | 63.0% (57.7%-68.3%), 200 games | 41.0% (35.8%-46.2%), 200 games | +22.0 (+14.5 to +29.5) |  |
| Wide 12b | 2 | 66.8% (62.1%-71.4%), 200 games | 37.2% (31.8%-42.7%), 200 games | +29.5 (+22.3 to +36.7) |  |
| Wide 15a | 1 | 63.7% (58.7%-68.8%), 200 games | 31.5% (26.3%-36.7%), 200 games | +32.2 (+25.0 to +39.5) | over 30 |
| Wide 11a | 0 | 54.2% (48.6%-59.9%), 200 games | 25.2% (20.4%-30.1%), 200 games | +29.0 (+21.6 to +36.4) |  |
| Standard | 0 | 15.2% (11.3%-19.2%), 200 games | 10.8% (7.5%-14.0%), 200 games | +4.5 (-0.6 to +9.6) |  |

### White's score in every pairing

| Army A | Army B | Games | White's score | 95% range | Flag |
|---|---|---|---|---|---|
| Wide 15b | Wide 14b | 40 | 50.0% | 35.2%-64.8% |  |
| Wide 15b | Wide 15c | 40 | 45.0% | 30.7%-60.2% |  |
| Wide 15b | Wide 14c | 40 | 82.5% | 68.0%-91.3% | 80%+ |
| Wide 15b | Wide 14a | 40 | 77.5% | 62.5%-87.7% |  |
| Wide 15b | Wide 9b | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 15b | Wide 13c | 40 | 50.0% | 35.2%-64.8% |  |
| Wide 15b | Wide 12b | 40 | 68.8% | 53.3%-80.9% |  |
| Wide 15b | Wide 15a | 40 | 63.7% | 48.3%-76.8% |  |
| Wide 15b | Wide 11a | 40 | 67.5% | 52.0%-79.9% |  |
| Wide 15b | Standard | 40 | 47.5% | 32.9%-62.5% |  |
| Wide 14b | Wide 15c | 40 | 83.8% | 69.5%-92.1% | 80%+ |
| Wide 14b | Wide 14c | 40 | 70.0% | 54.6%-81.9% |  |
| Wide 14b | Wide 14a | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 14b | Wide 9b | 40 | 76.2% | 61.1%-86.8% |  |
| Wide 14b | Wide 13c | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 14b | Wide 12b | 40 | 53.8% | 38.7%-68.2% |  |
| Wide 14b | Wide 15a | 40 | 90.0% | 76.9%-96.0% | 80%+ |
| Wide 14b | Wide 11a | 40 | 67.5% | 52.0%-79.9% |  |
| Wide 14b | Standard | 40 | 50.0% | 35.2%-64.8% |  |
| Wide 15c | Wide 14c | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 15c | Wide 14a | 40 | 62.5% | 47.0%-75.8% |  |
| Wide 15c | Wide 9b | 40 | 75.0% | 59.8%-85.8% |  |
| Wide 15c | Wide 13c | 40 | 78.8% | 63.9%-88.6% |  |
| Wide 15c | Wide 12b | 40 | 30.0% | 18.1%-45.4% |  |
| Wide 15c | Wide 15a | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 15c | Wide 11a | 40 | 86.2% | 72.4%-93.8% | 80%+ |
| Wide 15c | Standard | 40 | 57.5% | 42.2%-71.5% |  |
| Wide 14c | Wide 14a | 40 | 75.0% | 59.8%-85.8% |  |
| Wide 14c | Wide 9b | 40 | 78.8% | 63.9%-88.6% |  |
| Wide 14c | Wide 13c | 40 | 56.2% | 41.0%-70.4% |  |
| Wide 14c | Wide 12b | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 14c | Wide 15a | 40 | 52.5% | 37.5%-67.1% |  |
| Wide 14c | Wide 11a | 40 | 51.2% | 36.3%-65.9% |  |
| Wide 14c | Standard | 40 | 47.5% | 32.9%-62.5% |  |
| Wide 14a | Wide 9b | 40 | 67.5% | 52.0%-79.9% |  |
| Wide 14a | Wide 13c | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 14a | Wide 12b | 40 | 73.8% | 58.5%-84.9% |  |
| Wide 14a | Wide 15a | 40 | 67.5% | 52.0%-79.9% |  |
| Wide 14a | Wide 11a | 40 | 46.2% | 31.8%-61.3% |  |
| Wide 14a | Standard | 40 | 51.2% | 36.3%-65.9% |  |
| Wide 9b | Wide 13c | 40 | 57.5% | 42.2%-71.5% |  |
| Wide 9b | Wide 12b | 40 | 100.0% | 91.2%-100.0% | 80%+ |
| Wide 9b | Wide 15a | 40 | 63.7% | 48.3%-76.8% |  |
| Wide 9b | Wide 11a | 40 | 87.5% | 73.9%-94.5% | 80%+ |
| Wide 9b | Standard | 40 | 50.0% | 35.2%-64.8% |  |
| Wide 13c | Wide 12b | 40 | 78.8% | 63.9%-88.6% |  |
| Wide 13c | Wide 15a | 40 | 60.0% | 44.6%-73.7% |  |
| Wide 13c | Wide 11a | 40 | 61.3% | 45.8%-74.7% |  |
| Wide 13c | Standard | 40 | 63.7% | 48.3%-76.8% |  |
| Wide 12b | Wide 15a | 40 | 86.2% | 72.4%-93.8% | 80%+ |
| Wide 12b | Wide 11a | 40 | 48.8% | 34.1%-63.7% |  |
| Wide 12b | Standard | 40 | 55.0% | 39.8%-69.3% |  |
| Wide 15a | Wide 11a | 40 | 78.8% | 63.9%-88.6% |  |
| Wide 15a | Standard | 40 | 50.0% | 35.2%-64.8% |  |
| Wide 11a | Standard | 40 | 50.0% | 35.2%-64.8% |  |

### Gaps by how many Archers the army has

| Archers | Armies | Mean gap (points) | Each army's gap |
|---|---|---|---|
| 0 | 5 | +23.9 | Wide 15c +23.2, Wide 9b +41.0, Wide 13c +22.0, Wide 11a +29.0, Standard +4.5 |
| 1 | 5 | +26.1 | Wide 15b +20.2, Wide 14b +29.0, Wide 14c +23.0, Wide 14a +26.3, Wide 15a +32.2 |
| 2 | 1 | +29.5 | Wide 12b +29.5 |

## Part 2: what goes with colour-decided games (run 2's self-play games)

Pairs found by matching each game with the one where the same two armies swapped colours. Features are for the pair: both armies together (each army plays both colours in a pair). Long-range pieces (a move reaching 4+ squares in a line): Archer, Bard, Bishop, Cannon, Chariot, Galleon, Lance, Parapet, Princess, Queen, Ram, Rook, Vampire, Wizard. Ability moves are the ones written with `!`, `@` or `~`; "first two moves" = the first 4 plies (all inside run 2's random opening plies).


### 8,000 nodes per move (seed 101)

`games_8k_seed101.jsonl`: 20000 games, 10000 colour-swapped pairs (0 games without a partner). White scored 56.1%. **White won both games in 1264 pairs: 12.6% (95% 12.0%-13.3%)**; chess benchmark 23%.


**Archers in the two armies together**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| 0 | 5399 | 702 | 13.0% | 12.1%-13.9% |
| 1 | 3384 | 425 | 12.6% | 11.5%-13.7% |
| 2 | 1049 | 117 | 11.2% | 9.4%-13.2% |
| 3 | 148 | 17 | 11.5% | 7.3%-17.6% |
| 4 | 20 | 3 | 15.0% | 5.2%-36.0% |

**Any ability piece (Archer, Necromancer, Ghost, Bard, Werewolf) in either army**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| no | 377 | 51 | 13.5% | 10.4%-17.4% |
| yes | 9623 | 1213 | 12.6% | 12.0%-13.3% |

**Empty squares in the two armies' starting rows together (32 squares)**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| 0-1 | 1707 | 173 | 10.1% | 8.8%-11.7% |
| 2 | 1235 | 156 | 12.6% | 10.9%-14.6% |
| 3-4 | 2987 | 404 | 13.5% | 12.3%-14.8% |
| 5 | 1310 | 175 | 13.4% | 11.6%-15.3% |
| 6-15 | 2761 | 356 | 12.9% | 11.7%-14.2% |

**Long-range pieces in the two armies together**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| 2-6 | 1700 | 199 | 11.7% | 10.3%-13.3% |
| 7 | 1850 | 225 | 12.2% | 10.8%-13.7% |
| 8 | 2260 | 279 | 12.3% | 11.1%-13.8% |
| 9 | 1963 | 270 | 13.8% | 12.3%-15.3% |
| 10-15 | 2227 | 291 | 13.1% | 11.7%-14.5% |

**An ability used in the first two moves of each side, in either game**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| no | 8028 | 1005 | 12.5% | 11.8%-13.3% |
| yes | 1972 | 259 | 13.1% | 11.7%-14.7% |

**All together: logistic regression of "White won both"** (10000 pairs). Odds ratio = how the odds of White winning both change with one more of each, the others held the same; 1 = no effect.

| Feature | Coefficient | Odds ratio | 95% range | p |
|---|---|---|---|---|
| constant | -2.214 | (baseline odds 0.109) | | |
| Archers (each) | -0.082 | 0.921 | 0.848-1.002 | 0.055 |
| any ability piece | -0.046 | 0.955 | 0.703-1.298 | 0.770 |
| empty squares (each) | +0.022 | 1.023 | 0.999-1.047 | 0.056 |
| long-range pieces (each) | +0.032 | 1.032 | 0.997-1.069 | 0.072 |
| ability in the first two moves | +0.089 | 1.093 | 0.942-1.269 | 0.239 |

### 32,000 nodes per move (seed 202)

`games_32k_seed202.jsonl`: 20000 games, 10000 colour-swapped pairs (0 games without a partner). White scored 56.6%. **White won both games in 1302 pairs: 13.0% (95% 12.4%-13.7%)**; chess benchmark 23%.


**Archers in the two armies together**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| 0 | 5349 | 677 | 12.7% | 11.8%-13.6% |
| 1 | 3428 | 480 | 14.0% | 12.9%-15.2% |
| 2 | 1051 | 124 | 11.8% | 10.0%-13.9% |
| 3 | 163 | 19 | 11.7% | 7.6%-17.5% |
| 4 | 9 | 2 | 22.2% | 6.3%-54.7% |

**Any ability piece (Archer, Necromancer, Ghost, Bard, Werewolf) in either army**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| no | 365 | 55 | 15.1% | 11.8%-19.1% |
| yes | 9635 | 1247 | 12.9% | 12.3%-13.6% |

**Empty squares in the two armies' starting rows together (32 squares)**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| 0-1 | 1853 | 182 | 9.8% | 8.5%-11.3% |
| 2 | 1295 | 164 | 12.7% | 11.0%-14.6% |
| 3 | 1470 | 186 | 12.7% | 11.1%-14.5% |
| 4-5 | 2677 | 365 | 13.6% | 12.4%-15.0% |
| 6-14 | 2705 | 405 | 15.0% | 13.7%-16.4% |

**Long-range pieces in the two armies together**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| 2-6 | 1675 | 197 | 11.8% | 10.3%-13.4% |
| 7 | 1833 | 221 | 12.1% | 10.6%-13.6% |
| 8 | 2272 | 296 | 13.0% | 11.7%-14.5% |
| 9 | 1943 | 272 | 14.0% | 12.5%-15.6% |
| 10-15 | 2277 | 316 | 13.9% | 12.5%-15.4% |

**An ability used in the first two moves of each side, in either game**

| Group | Pairs | White won both | Share | 95% range |
|---|---|---|---|---|
| no | 8047 | 1068 | 13.3% | 12.5%-14.0% |
| yes | 1953 | 234 | 12.0% | 10.6%-13.5% |

**All together: logistic regression of "White won both"** (10000 pairs). Odds ratio = how the odds of White winning both change with one more of each, the others held the same; 1 = no effect.

| Feature | Coefficient | Odds ratio | 95% range | p |
|---|---|---|---|---|
| constant | -2.217 | (baseline odds 0.109) | | |
| Archers (each) | -0.004 | 0.996 | 0.919-1.081 | 0.931 |
| any ability piece | -0.146 | 0.864 | 0.641-1.165 | 0.339 |
| empty squares (each) | +0.051 | 1.052 | 1.029-1.076 | <0.001 |
| long-range pieces (each) | +0.032 | 1.033 | 0.998-1.069 | 0.064 |
| ability in the first two moves | -0.097 | 0.908 | 0.779-1.058 | 0.216 |

## Part 3: chess benchmark, Standard vs Standard

`--random-plies 4`; a pair = games 2n and 2n+1 (identical armies, so any two games could pair).

| Nodes | Games | White +win =draw -loss | White's score (95%) | White won both | Mean plies |
|---|---|---|---|---|---|
| 8,000 (seed 301) | 4000 | +1821 =1137 -1042 | 59.7% (58.5%-61.0%) | 405 of 2000: 20.2% (18.5%-22.1%) | 134 |
| 32,000 (seed 302) | 4000 | +1321 =1204 -1475 | 48.1% (46.8%-49.4%) | 226 of 2000: 11.3% (10.0%-12.8%) | 135 |

## Success test (decided before running)

No pool army's White-minus-Black gap over 30 points, and no pairing with White at 80% or more.

- Pool armies with a gap over 30 points: Wide 9b (+41.0), Wide 15a (+32.2)
- Pairings with White at 80% or more: Wide 15b vs Wide 14c (82.5%), Wide 14b vs Wide 15c (83.8%), Wide 14b vs Wide 15a (90.0%), Wide 15c vs Wide 11a (86.2%), Wide 9b vs Wide 12b (100.0%), Wide 9b vs Wide 11a (87.5%), Wide 12b vs Wide 15a (86.2%)
- **Result: FAILED**
