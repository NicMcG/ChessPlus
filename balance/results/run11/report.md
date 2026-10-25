# Balance run 11: separate White and Black armies (report)

Made by `tools/balance/run11_analyse.py`. Plusfish grew a White pool and a Black pool side by side (`meta --wide --split-colours`): a White army is judged only as White against the Black pool, and the other way round. All games below have fixed colours, 40 games a pairing, 8,000 nodes, `--random-plies 4`. "Ordinary pool" = the one-army-for-both-colours pool for that rule set (run 7's for the normal rules, run 10's for the White-only quiet first move); its own round robin is the baseline. Points = percentage points.


## Normal rules


**White pool (judged only as White)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide W14a `PPCKLAP(NC)/A1(WW)GQ(AS)1(AS)` | 76.5% (+205) | 14 | 3 (0) | 2 | 2 | 5 |
| Wide W13a `1BP(CV)K1BQ/(AS)G(PD)N(WW)AA1` | 65.9% (+114) | 13 | 1 (0) | 2 | 2 | 4 |
| Wide W9c `(NC)1(RM)NK(WW)P1/ABQPG(AS)(PD)B` | 65.9% (+114) | 14 | 2 (1) | 4 | 1 | 4 |
| Wide W14c `PPPK(RM)P1(NC)/(PR)(BR)CGQ(AS)E1` | 60.6% (+75) | 14 | 4 (0) | 3 | 0 | 2 |
| Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | 60.1% (+71) | 15 | 2 (1) | 1 | 1 | 5 |
| Wide W12c `C1PK(NC)PW1/B(CV)GP(GA)(BR)(CV)B` | 59.4% (+66) | 14 | 3 (1) | 3 | 0 | 2 |
| Wide W15b `PP(NC)K(RM)1(NC)P/EPCAQP(BR)B` | 57.0% (+49) | 15 | 5 (2) | 4 | 1 | 3 |
| Wide W1a `1(CV)(CH)NKQ1(AS)/BA(AS)(BR)(WW)(RM)G1` | 54.5% (+31) | 13 | 0 (0) | 3 | 1 | 3 |
| Wide W6a `1Q1NK1GB/(AS)A(SQ)(NC)(BR)(BR)B(AS)` | 54.5% (+31) | 13 | 0 (0) | 2 | 1 | 3 |
| Wide 15c `EQ(RO)K1(AS)(WW)(NC)/(PD)GB(RM)GB(PD)(AS)` | 52.6% (+18) | 15 | 0 (0) | 3 | 0 | 4 |

Averages (not Standard): 14.0 pieces, 2.0 pawns (0.5 in the front row), 2.7 long-range pieces in the front row, 0.9 Archers, 3.5 ability pieces.

**Black pool (judged only as Black)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide B14a `PPQKA(WW)P1/B(AS)(BR)GG(WW)B(PD)` | 58.7% (+61) | 15 | 3 (0) | 2 | 1 | 5 |
| Wide B12c `Q(WW)(CH)KBPPP/(AS)(AS)G(BR)BG(PD)N` | 50.6% (+4) | 16 | 3 (0) | 1 | 0 | 3 |
| Wide B11a `1Q(WW)KBBE(NC)/(AS)1AE(CV)GG(PD)` | 48.3% (-12) | 14 | 0 (0) | 1 | 1 | 5 |
| Wide B6c `Q(BR)(WW)NK1(NC)(RM)/(AS)EPBA(PD)G(AS)` | 46.9% (-22) | 15 | 1 (1) | 2 | 1 | 4 |
| Wide B8a `1BBPK(NC)(SQ)P/A1QM(BR)PG(AS)` | 45.6% (-30) | 14 | 3 (1) | 2 | 1 | 3 |
| Wide B13a `AQ1KNPP1/(AS)(SQ)NGB(NC)G(AS)` | 32.0% (-131) | 14 | 2 (0) | 1 | 1 | 4 |
| Wide B12a `PG1KQ(NC)1(PD)/(AS)B(BR)AG(WW)(PD)B` | 30.6% (-142) | 14 | 1 (0) | 3 | 1 | 5 |
| Wide B7a `1PB(CV)K(NC)B1/A1(AS)P(CT)Q(WW)A` | 28.0% (-164) | 13 | 2 (1) | 3 | 2 | 4 |
| Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | 27.0% (-173) | 15 | 2 (1) | 1 | 1 | 5 |
| Wide B10c `1B1(NC)K2C/(AS)(AS)AVN(CV)(PD)Q` | 25.2% (-189) | 12 | 0 (0) | 3 | 1 | 2 |

Averages (not Standard): 14.2 pieces, 1.7 pawns (0.4 in the front row), 1.9 long-range pieces in the front row, 1.0 Archers, 4.0 ability pieces.

Piece types, White pool: 22 piece types in 10 armies: Ghost 9, Queen 9, Assassin 8, Bishop 8, Necromancer 8, Archer 7, Pawn 7, Werewolf 6, Barbarian 5, Knight 5, Ram 5, Cannon 4, Cavalry 4, Elephant 4, Paladin 3, Chariot 1, Galleon 1, Lance 1, Princess 1, Rogue 1, Squire 1, Wizard 1

Piece types, Black pool: 20 piece types in 10 armies: Assassin 10, Bishop 10, Queen 10, Archer 9, Ghost 8, Necromancer 8, Pawn 8, Werewolf 7, Paladin 6, Barbarian 5, Knight 5, Cavalry 4, Elephant 3, Squire 2, Cannon 1, Catapult 1, Chariot 1, Man 1, Ram 1, Vampire 1

Armies in both pools: `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)`


### Specialists against specialists (every White army against every Black army)

| | |
|---|---|
| Games | 4840 |
| White's score (95%) | 57.6% (56.4%-58.7%) |
| Ordinary pool's round robin, White's score (run 7) | 59.4% |
| White's first move a capture or ability | 53.7% (ordinary 59.4%) |
| Black's first move a capture or ability | 39.8% (ordinary 47.5%) |
| Uneven matchups: either side at 80%+ (40 games each, Standard left out; with fixed colours this mixes army strength and colour) | 28 of 100 |

Each White army as White (all Black armies) and each Black army as Black (all White armies):

| White army | Score as White | | Black army | Score as Black |
|---|---|---|---|---|
| Wide W14a | 67.7% | | Wide B14a | 62.8% |
| Wide W13a | 68.9% | | Wide B12c | 57.0% |
| Wide W9c | 71.8% | | Wide B11a | 54.9% |
| Wide W14c | 59.4% | | Wide B6c | 52.2% |
| Wide 14a | 63.2% | | Wide B8a | 48.3% |
| Wide W12c | 62.3% | | Wide B13a | 36.0% |
| Wide W15b | 55.7% | | Wide B12a | 32.2% |
| Wide W1a | 56.2% | | Wide B7a | 40.9% |
| Wide W6a | 60.6% | | Wide 14a | 34.2% |
| Wide 15c | 54.8% | | Wide B10c | 37.6% |
| Standard | 13.0% | | Standard | 10.3% |

Pairings at 80%+: Wide W14a vs Wide B13a (White 100.0%); Wide W14a vs Wide 14a (White 100.0%); Wide W14a vs Wide B10c (White 100.0%); Wide W13a vs Wide B7a (White 96.2%); Wide W13a vs Wide 14a (White 86.2%); Wide W9c vs Wide B8a (White 100.0%); Wide W9c vs Wide B12a (White 80.0%); Wide W9c vs Wide B7a (White 100.0%); Wide W14c vs Wide B12c (White 20.0%); Wide W14c vs Wide B11a (White 10.0%); Wide W14c vs Wide B13a (White 100.0%); Wide W14c vs Wide B12a (White 100.0%); Wide W14c vs Wide 14a (White 100.0%); Wide W14c vs Wide B10c (White 100.0%); Wide 14a vs Wide B7a (White 81.2%); Wide 14a vs Wide 14a (White 80.0%); Wide W12c vs Wide B14a (White 18.8%); Wide W12c vs Wide B11a (White 100.0%); Wide W12c vs Wide B7a (White 82.5%); Wide W15b vs Wide B12c (White 0.0%); Wide W15b vs Wide B11a (White 17.5%); Wide W15b vs Wide B13a (White 100.0%); Wide W15b vs Wide B12a (White 100.0%); Wide W15b vs Wide B7a (White 18.8%); Wide W15b vs Wide 14a (White 100.0%); Wide W15b vs Wide B10c (White 100.0%); Wide W6a vs Wide B12a (White 100.0%); Wide 15c vs Wide B7a (White 93.8%)

### Specialists against the ordinary pool

| | White's score | vs the ordinary round robin |
|---|---|---|
| Ordinary as White against ordinary as Black (run 7) | 59.4% | |
| White specialists against ordinary as Black | 60.3% (59.2%-61.5%) | White gains +1.0 points |
| Ordinary as White against Black specialists | 51.3% (50.2%-52.4%) | Black gains +8.0 points |
| White specialists against Black specialists | 57.6% | -1.8 points for White overall |

## White-only quiet first move


**White pool (judged only as White)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide W14a `1B(BR)KCE(PD)(NC)/A(AS)BGQ(AS)(CV)1` | 64.6% (+105) | 14 | 0 (0) | 3 | 1 | 3 |
| Wide W15a `BP(NC)K2QB/A1(AS)GG(CH)1A` | 58.6% (+61) | 12 | 1 (0) | 3 | 2 | 5 |
| Wide 7c `2(CV)K(NC)(WW)B1/Q(AS)(BR)(GA)(CV)GEA` | 54.8% (+33) | 13 | 0 (0) | 3 | 1 | 4 |
| Wide W14c `1AQ1K(CV)(BR)1/(AS)AG(CV)NB(BR)(AS)` | 52.4% (+17) | 13 | 0 (0) | 2 | 2 | 3 |
| Wide 4c `EQ(RO)K(WW)(AS)1(NC)/BGB(RM)G(PD)(PD)(AS)` | 51.4% (+10) | 15 | 0 (0) | 3 | 0 | 4 |
| Wide W4c `Q(GA)PBKN(NC)1/(AS)AGP(BR)(PD)(WW)(AS)` | 46.2% (-26) | 15 | 2 (1) | 1 | 1 | 4 |
| Wide W7a `WP(WW)CKPE(NC)/(AS)GGAB(PD)(PD)(AS)` | 44.1% (-41) | 16 | 2 (0) | 2 | 1 | 5 |
| Wide W11a `(AS)B(BR)EK(CV)W1/GALA(PD)EG1` | 36.9% (-93) | 14 | 0 (0) | 3 | 2 | 4 |
| Wide W12c `GW1K(NC)(PD)B1/(GA)(BR)G(BR)A1A1` | 29.8% (-149) | 12 | 0 (0) | 3 | 2 | 5 |
| Wide W10a `1WPKN(NC)G1/1VCBGPB1` | 25.9% (-183) | 12 | 2 (1) | 4 | 0 | 3 |

Averages (not Standard): 13.6 pieces, 0.7 pawns (0.2 in the front row), 2.7 long-range pieces in the front row, 1.2 Archers, 4.0 ability pieces.

**Black pool (judged only as Black)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide B14a `(NC)P(WW)K(BR)1P(PD)/ABP(BR)G(AS)GQ` | 63.9% (+99) | 15 | 3 (1) | 3 | 1 | 5 |
| Wide 7c `2(CV)K(NC)(WW)B1/Q(AS)(BR)(GA)(CV)GEA` | 55.8% (+40) | 13 | 0 (0) | 3 | 1 | 4 |
| Wide B10c `(CV)(RM)1K2Q(PD)/(AS)A(WW)(NC)G(WW)A(AS)` | 55.2% (+37) | 13 | 0 (0) | 2 | 2 | 6 |
| Wide B12c `1A1K1(NC)(SQ)Q/PGABG(AS)B1` | 54.2% (+30) | 12 | 1 (1) | 3 | 2 | 5 |
| Wide 4c `EQ(RO)K(WW)(AS)1(NC)/BGB(RM)G(PD)(PD)(AS)` | 54.2% (+30) | 15 | 0 (0) | 3 | 0 | 4 |
| Wide 11a `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ` | 54.1% (+29) | 14 | 2 (0) | 6 | 1 | 2 |
| Wide B14c `1Q1KE(BR)G(NC)/(PD)(CH)BB(AS)GA(AS)` | 53.0% (+21) | 14 | 0 (0) | 4 | 1 | 4 |
| Wide B15a `A(CV)QK(AS)(BR)2/(AS)1A(BR)(WW)(CT)BB` | 53.0% (+21) | 13 | 0 (0) | 3 | 2 | 3 |
| Wide B13a `B(CT)(AS)KE(GA)Q(RM)/G1AG(BR)B(AS)1` | 47.2% (-19) | 14 | 0 (0) | 2 | 1 | 3 |
| Wide B3c `(NC)PENK(AS)PA/B(CV)GG(WW)Q1(AS)` | 44.6% (-37) | 15 | 2 (0) | 2 | 1 | 5 |

Averages (not Standard): 13.8 pieces, 0.8 pawns (0.2 in the front row), 3.1 long-range pieces in the front row, 1.2 Archers, 4.1 ability pieces.

Piece types, White pool: 21 piece types in 10 armies: Bishop 10, Ghost 10, Archer 8, Assassin 8, Necromancer 8, Barbarian 6, Paladin 6, Queen 6, Elephant 5, Cavalry 4, Pawn 4, Werewolf 4, Wizard 4, Cannon 3, Galleon 3, Knight 3, Chariot 1, Lance 1, Ram 1, Rogue 1, Vampire 1

Piece types, Black pool: 19 piece types in 10 armies: Assassin 10, Queen 10, Archer 9, Bishop 9, Ghost 8, Necromancer 8, Werewolf 6, Barbarian 5, Elephant 5, Cavalry 4, Paladin 4, Pawn 4, Ram 4, Galleon 3, Catapult 2, Knight 2, Squire 2, Chariot 1, Rogue 1

Armies in both pools: `2(CV)K(NC)(WW)B1/Q(AS)(BR)(GA)(CV)GEA`, `EQ(RO)K(WW)(AS)1(NC)/BGB(RM)G(PD)(PD)(AS)`


### Specialists against specialists (every White army against every Black army)

| | |
|---|---|
| Games | 4840 |
| White's score (95%) | 48.0% (46.9%-49.1%) |
| Ordinary pool's round robin, White's score (run 10) | 51.1% |
| White's first move a capture or ability | 0.0% (ordinary 0.0%) |
| Black's first move a capture or ability | 37.5% (ordinary 33.7%) |
| Uneven matchups: either side at 80%+ (40 games each, Standard left out; with fixed colours this mixes army strength and colour) | 22 of 100 |

Each White army as White (all Black armies) and each Black army as Black (all White armies):

| White army | Score as White | | Black army | Score as Black |
|---|---|---|---|---|
| Wide W14a | 72.4% | | Wide B14a | 70.5% |
| Wide W15a | 55.2% | | Wide 7c | 55.0% |
| Wide 7c | 63.0% | | Wide B10c | 54.7% |
| Wide W14c | 55.5% | | Wide B12c | 52.6% |
| Wide 4c | 54.3% | | Wide 4c | 56.4% |
| Wide W4c | 54.7% | | Wide 11a | 55.6% |
| Wide W7a | 47.8% | | Wide B14c | 56.5% |
| Wide W11a | 37.2% | | Wide B15a | 58.0% |
| Wide W12c | 35.0% | | Wide B13a | 56.1% |
| Wide W10a | 39.8% | | Wide B3c | 44.9% |
| Standard | 13.5% | | Standard | 11.6% |

Pairings at 80%+: Wide W14a vs Wide 7c (White 100.0%); Wide W14a vs Wide B12c (White 93.8%); Wide W14a vs Wide B15a (White 86.2%); Wide W14a vs Wide B13a (White 100.0%); Wide W15a vs Wide B12c (White 17.5%); Wide 7c vs Wide 11a (White 100.0%); Wide W4c vs Wide B14a (White 17.5%); Wide W7a vs Wide B14a (White 0.0%); Wide W7a vs Wide 11a (White 100.0%); Wide W11a vs Wide B14a (White 15.0%); Wide W11a vs Wide 7c (White 18.8%); Wide W11a vs Wide B14c (White 6.2%); Wide W11a vs Wide B13a (White 0.0%); Wide W11a vs Wide B3c (White 100.0%); Wide W12c vs Wide 7c (White 12.5%); Wide W12c vs Wide 4c (White 20.0%); Wide W12c vs Wide B14c (White 11.2%); Wide W10a vs Wide B10c (White 7.5%); Wide W10a vs Wide 11a (White 1.2%); Wide W10a vs Wide B15a (White 0.0%); Wide W10a vs Wide B13a (White 15.0%); Wide W10a vs Wide B3c (White 100.0%)

### Specialists against the ordinary pool

| | White's score | vs the ordinary round robin |
|---|---|---|
| Ordinary as White against ordinary as Black (run 10) | 51.1% | |
| White specialists against ordinary as Black | 45.5% (44.4%-46.6%) | White gains -5.6 points |
| Ordinary as White against Black specialists | 53.3% (52.3%-54.4%) | Black gains -2.3 points |
| White specialists against Black specialists | 48.0% | -3.1 points for White overall |

## Summary

| Rules | Ordinary round robin: White | Specialists vs specialists: White | White specialists vs ordinary | Ordinary vs Black specialists | Uneven matchups (specialists, no Standard) | Long-range front-row pieces: White pool / Black pool |
|---|---|---|---|---|---|---|
| Normal rules | 59.4% | 57.6% | 60.3% | 51.3% | 28 of 100 | 2.7 / 1.9 |
| White-only quiet first move | 51.1% | 48.0% | 45.5% | 53.3% | 22 of 100 | 2.7 / 3.1 |
