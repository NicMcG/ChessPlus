# Balance run 13: separate White and Black armies, each colour judged against the all-round pool frozen (report)

Made by `tools/balance/run11_analyse.py`. Plusfish grew a White pool and a Black pool side by side (`meta --wide --split-colours`): a White army is judged only as White against the Black pool, and the other way round. All games below have fixed colours, 40 games a pairing, 8,000 nodes, `--random-plies 4`. "Ordinary pool" = the one-army-for-both-colours pool for that rule set (run 7's for the normal rules, run 10's for the White-only quiet first move); its own round robin is the baseline. Points = percentage points. Run 13 judged each colour only against the starting all-round pool, frozen for the whole run (`--fixed-opponent`), so the two searches are independent; runs 11 and 12 judged each colour against the other colour's moving or phased pool.


## Normal rules


**White pool (judged only as White)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide W10a `1PBCK1P1/B(PD)CL(RM)QA(AS)` | 89.4% (+371) | 13 | 2 (0) | 6 | 1 | 1 |
| Wide W4a `(NC)PPKGPW(NC)/BB(AS)(AS)(WW)L(PD)(RM)` | 79.9% (+240) | 16 | 3 (0) | 4 | 0 | 4 |
| Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | 76.1% (+202) | 15 | 2 (1) | 1 | 1 | 5 |
| Wide W1c `BPQK(NC)PC1/(PD)BPGP(AS)GA` | 75.5% (+195) | 15 | 4 (2) | 2 | 1 | 4 |
| Wide W3a `(NC)WGK1L1G/A(RM)L(PD)B1(BR)1` | 74.2% (+184) | 12 | 0 (0) | 4 | 1 | 4 |
| Wide W6c `J(GA)(NC)K1Q1E/AB1BGLE(AS)` | 73.8% (+179) | 13 | 0 (0) | 4 | 1 | 3 |
| Wide W3c `Q(WW)EPKN1(NC)/(AS)A(CT)(WW)(BR)(PD)G(AS)` | 73.3% (+175) | 15 | 1 (0) | 1 | 1 | 5 |
| Wide W12a `(PD)WAK(NC)JPP/BCL(AS)PL2` | 73.2% (+174) | 14 | 3 (1) | 4 | 1 | 2 |
| Wide W12b `A(NC)1KE1W1/BBG(WW)(CV)LG1` | 72.3% (+166) | 12 | 0 (0) | 3 | 1 | 5 |
| Wide W1a `1(CV)(CH)NKQ1(AS)/BA(AS)(BR)(WW)(RM)G1` | 72.2% (+165) | 13 | 0 (0) | 3 | 1 | 3 |

Averages (not Standard): 13.8 pieces, 1.5 pawns (0.4 in the front row), 3.2 long-range pieces in the front row, 0.9 Archers, 3.6 ability pieces.

**Black pool (judged only as Black)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide B14a `1B(BR)K(NC)(WW)Q1/(AS)(PD)(BR)(PD)(PA)GGB` | 69.4% (+143) | 14 | 0 (0) | 2 | 0 | 4 |
| Wide B7c `2BQK1PA/E(PD)VAG(PD)G(AS)` | 64.4% (+103) | 13 | 1 (0) | 2 | 2 | 4 |
| Wide B13c `PP(WW)1KA(RO)(NC)/P(AS)(BR)QGG(AS)B` | 63.5% (+96) | 15 | 3 (1) | 2 | 1 | 5 |
| Wide B4b `1Q(RO)K(WW)(AS)E(NC)/(PD)GB(CV)BG(PD)(AS)` | 60.3% (+73) | 15 | 0 (0) | 2 | 0 | 4 |
| Wide B11b `1QGK(NC)(WW)A1/1GAN(GA)(BR)2` | 60.2% (+72) | 11 | 0 (0) | 2 | 2 | 6 |
| Wide B11c `1Q(NC)AKPB1/1(AS)N(CV)(BR)GGB` | 59.7% (+68) | 13 | 1 (0) | 1 | 1 | 4 |
| Wide B10a `(AS)1Q1KN(SQ)(NC)/(AS)1(CV)B(BR)GG(SQ)` | 59.3% (+66) | 13 | 0 (0) | 1 | 0 | 3 |
| Wide B10c `Q(WW)BPKN(NC)1/(AS)AP(BR)(RM)(PD)G(AS)` | 55.5% (+38) | 15 | 2 (1) | 2 | 1 | 4 |
| Wide B12c `BPQKA(SQ)BP/(AS)G(CV)G(GA)1P1` | 55.0% (+35) | 14 | 3 (1) | 1 | 1 | 3 |
| Wide B9c `G(SQ)(CV)KQP(NC)1/(AS)1BB(AS)G(PD)(SQ)` | 52.0% (+14) | 14 | 1 (0) | 2 | 0 | 3 |

Averages (not Standard): 13.7 pieces, 1.1 pawns (0.3 in the front row), 1.7 long-range pieces in the front row, 0.8 Archers, 4.0 ability pieces.

Piece types, White pool: 21 piece types in 10 armies: Archer 9, Bishop 9, Assassin 8, Ghost 8, Necromancer 8, Lance 6, Paladin 6, Pawn 6, Queen 6, Werewolf 5, Elephant 4, Ram 4, Wizard 4, Barbarian 3, Cannon 3, Cavalry 3, Knight 3, Jester 2, Catapult 1, Chariot 1, Galleon 1

Piece types, Black pool: 19 piece types in 10 armies: Ghost 10, Queen 10, Assassin 9, Bishop 9, Necromancer 8, Archer 6, Barbarian 6, Pawn 6, Cavalry 5, Paladin 5, Werewolf 5, Knight 4, Squire 3, Elephant 2, Galleon 2, Rogue 2, Parapet 1, Ram 1, Vampire 1

Armies in both pools: none


### Specialists against specialists (every White army against every Black army)

| | |
|---|---|
| Games | 4840 |
| White's score (95%) | 56.7% (55.6%-57.8%) |
| Ordinary pool's round robin, White's score (run 7) | 59.4% |
| White's first move a capture or ability | 65.1% (ordinary 59.4%) |
| Black's first move a capture or ability | 41.7% (ordinary 47.5%) |
| Uneven matchups: either side at 80%+ (40 games each, Standard left out; with fixed colours this mixes army strength and colour) | 35 of 100 |

Each White army as White (all Black armies) and each Black army as Black (all White armies):

| White army | Score as White | | Black army | Score as Black |
|---|---|---|---|---|
| Wide W10a | 76.2% | | Wide B14a | 68.8% |
| Wide W4a | 60.8% | | Wide B7c | 32.4% |
| Wide 14a | 57.2% | | Wide B13c | 61.7% |
| Wide W1c | 46.5% | | Wide B4b | 53.0% |
| Wide W3a | 61.5% | | Wide B11b | 35.5% |
| Wide W6c | 78.0% | | Wide B11c | 53.8% |
| Wide W3c | 56.2% | | Wide B10a | 42.0% |
| Wide W12a | 50.5% | | Wide B10c | 52.0% |
| Wide W12b | 66.2% | | Wide B12c | 40.7% |
| Wide W1a | 60.0% | | Wide B9c | 31.8% |
| Standard | 10.7% | | Standard | 4.7% |

Pairings at 80%+: Wide W10a vs Wide B7c (White 100.0%); Wide W10a vs Wide B4b (White 100.0%); Wide W10a vs Wide B11b (White 100.0%); Wide W10a vs Wide B11c (White 100.0%); Wide W10a vs Wide B10a (White 100.0%); Wide W10a vs Wide B10c (White 100.0%); Wide W10a vs Wide B9c (White 20.0%); Wide W4a vs Wide B7c (White 100.0%); Wide W4a vs Wide B11b (White 81.2%); Wide W4a vs Wide B10a (White 80.0%); Wide W4a vs Wide B12c (White 0.0%); Wide W4a vs Wide B9c (White 100.0%); Wide W3a vs Wide B7c (White 100.0%); Wide W3a vs Wide B11b (White 100.0%); Wide W3a vs Wide B11c (White 17.5%); Wide W3a vs Wide B10c (White 0.0%); Wide W3a vs Wide B12c (White 100.0%); Wide W3a vs Wide B9c (White 100.0%); Wide W6c vs Wide B7c (White 100.0%); Wide W6c vs Wide B13c (White 100.0%); Wide W6c vs Wide B10a (White 85.0%); Wide W6c vs Wide B9c (White 100.0%); Wide W12a vs Wide B14a (White 13.8%); Wide W12a vs Wide B13c (White 3.8%); Wide W12a vs Wide B4b (White 17.5%); Wide W12a vs Wide B11b (White 85.0%); Wide W12a vs Wide B11c (White 10.0%); Wide W12a vs Wide B12c (White 100.0%); Wide W12a vs Wide B9c (White 100.0%); Wide W12b vs Wide B14a (White 18.8%); Wide W12b vs Wide B7c (White 100.0%); Wide W12b vs Wide B10a (White 82.5%); Wide W12b vs Wide B12c (White 100.0%); Wide W12b vs Wide B9c (White 100.0%); Wide W1a vs Wide B7c (White 100.0%)

### Specialists against the ordinary pool

| | White's score | vs the ordinary round robin |
|---|---|---|
| Ordinary as White against ordinary as Black (run 7) | 59.4% | |
| White specialists against ordinary as Black | 70.4% (69.3%-71.5%) | White gains +11.0 points |
| Ordinary as White against Black specialists | 45.8% (44.7%-46.9%) | Black gains +13.5 points |
| White specialists against Black specialists | 56.7% | -2.7 points for White overall |

## White-only quiet first move


**White pool (judged only as White)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide W11a `1P(AS)KC(CV)B(NC)/1(WW)(WW)GB1(CV)Q` | 73.1% (+173) | 13 | 1 (0) | 2 | 0 | 4 |
| Wide W15b `1(CV)1KC(BR)(NC)1/Q(AS)(WW)GGBB(PD)` | 72.6% (+169) | 13 | 0 (0) | 3 | 0 | 4 |
| Wide W3a `1QGKC(AS)(BR)(NC)/B1BGAE(PD)(AS)` | 71.4% (+159) | 14 | 0 (0) | 3 | 1 | 4 |
| Wide W14c `PAPKC(BR)P(NC)/AP1BQ(BR)E(AS)` | 65.7% (+113) | 15 | 4 (1) | 3 | 2 | 3 |
| Wide W5b `BQ1KC2(CV)/A(BR)B(WW)G(CV)P1` | 64.9% (+107) | 12 | 1 (1) | 2 | 1 | 3 |
| Wide W7a `2(BR)K1(WW)B(NC)/(AS)Q(CV)G(CV)GEA` | 62.2% (+86) | 13 | 0 (0) | 2 | 1 | 5 |
| Wide 11a `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ` | 60.5% (+74) | 14 | 2 (0) | 6 | 1 | 2 |
| Wide W1c `1PPK(BR)1(NC)C/Q(WW)(AS)(BR)GBA(PD)` | 58.4% (+59) | 14 | 2 (0) | 3 | 1 | 4 |
| Wide 9b `AA(BR)QK(CV)2/(AS)B1(RM)(CV)(BR)G(AS)` | 55.8% (+40) | 13 | 0 (0) | 2 | 2 | 3 |
| Wide 9c `1PBK1(NC)Q1/A1(AS)GG(SQ)AB` | 55.5% (+38) | 12 | 1 (0) | 3 | 2 | 5 |

Averages (not Standard): 13.3 pieces, 1.1 pawns (0.2 in the front row), 2.9 long-range pieces in the front row, 1.1 Archers, 3.7 ability pieces.

**Black pool (judged only as Black)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide B1a `GPA1K(NC)1Q/B1(AS)BG(AS)AL` | 72.4% (+167) | 13 | 1 (0) | 4 | 2 | 5 |
| Wide 11a `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ` | 63.9% (+99) | 14 | 2 (0) | 6 | 1 | 2 |
| Wide B15a `(NC)1(WW)PKN2/QGBG(CV)B(WW)(PD)` | 63.1% (+93) | 13 | 1 (0) | 3 | 0 | 5 |
| Wide 15a `1Q(BR)KCG1(NC)/BEB(AS)(AS)AG(PD)` | 62.2% (+86) | 14 | 0 (0) | 3 | 1 | 4 |
| Wide B14c `1PPK(BR)(NC)QC/(AS)A(PD)(BR)GB1B` | 58.3% (+58) | 14 | 2 (0) | 3 | 1 | 3 |
| Wide 9b `AA(BR)QK(CV)2/(AS)B1(RM)(CV)(BR)G(AS)` | 55.3% (+37) | 13 | 0 (0) | 2 | 2 | 3 |
| Wide B13c `1QPGKEP1/AGB(WW)(PD)NB(GA)` | 55.0% (+35) | 14 | 2 (0) | 4 | 1 | 4 |
| Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | 54.8% (+33) | 15 | 2 (1) | 1 | 1 | 5 |
| Wide B6c `PP(WW)1KN(NC)N/(AS)AQB(BR)(PD)G(AS)` | 52.5% (+17) | 15 | 2 (0) | 3 | 1 | 4 |
| Wide 7c `2(CV)K(NC)(WW)B1/Q(AS)(BR)(GA)(CV)GEA` | 52.2% (+15) | 13 | 0 (0) | 3 | 1 | 4 |

Averages (not Standard): 13.8 pieces, 1.2 pawns (0.1 in the front row), 3.2 long-range pieces in the front row, 1.1 Archers, 3.9 ability pieces.

Piece types, White pool: 17 piece types in 10 armies: Bishop 10, Queen 10, Assassin 9, Archer 8, Ghost 8, Necromancer 8, Barbarian 7, Cannon 6, Pawn 6, Cavalry 5, Werewolf 5, Elephant 3, Paladin 3, Ram 2, Squire 2, Galleon 1, Knight 1

Piece types, Black pool: 18 piece types in 10 armies: Bishop 10, Queen 10, Archer 9, Ghost 9, Assassin 8, Necromancer 8, Pawn 7, Barbarian 5, Knight 5, Paladin 5, Werewolf 5, Cavalry 4, Elephant 4, Galleon 3, Cannon 2, Ram 2, Lance 1, Squire 1

Armies in both pools: `AA(BR)QK(CV)2/(AS)B1(RM)(CV)(BR)G(AS)`, `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ`


### Specialists against specialists (every White army against every Black army)

| | |
|---|---|
| Games | 4840 |
| White's score (95%) | 50.0% (48.9%-51.1%) |
| Ordinary pool's round robin, White's score (run 10) | 51.1% |
| White's first move a capture or ability | 0.0% (ordinary 0.0%) |
| Black's first move a capture or ability | 42.1% (ordinary 33.7%) |
| Uneven matchups: either side at 80%+ (40 games each, Standard left out; with fixed colours this mixes army strength and colour) | 18 of 100 |

Each White army as White (all Black armies) and each Black army as Black (all White armies):

| White army | Score as White | | Black army | Score as Black |
|---|---|---|---|---|
| Wide W11a | 64.4% | | Wide B1a | 72.5% |
| Wide W15b | 60.3% | | Wide 11a | 58.8% |
| Wide W3a | 56.0% | | Wide B15a | 58.1% |
| Wide W14c | 47.6% | | Wide 15a | 46.5% |
| Wide W5b | 39.4% | | Wide B14c | 57.3% |
| Wide W7a | 59.5% | | Wide 9b | 56.9% |
| Wide 11a | 50.2% | | Wide B13c | 51.0% |
| Wide W1c | 56.8% | | Wide 14a | 56.8% |
| Wide 9b | 53.9% | | Wide B6c | 50.7% |
| Wide 9c | 51.6% | | Wide 7c | 34.3% |
| Standard | 10.3% | | Standard | 6.9% |

Pairings at 80%+: Wide W11a vs Wide 11a (White 82.5%); Wide W11a vs Wide 7c (White 100.0%); Wide W15b vs Wide B1a (White 0.0%); Wide W15b vs Wide B14c (White 91.2%); Wide W15b vs Wide 7c (White 92.5%); Wide W3a vs Wide 15a (White 87.5%); Wide W14c vs Wide B1a (White 0.0%); Wide W14c vs Wide 11a (White 5.0%); Wide W14c vs Wide B15a (White 7.5%); Wide W14c vs Wide 15a (White 87.5%); Wide W14c vs Wide 7c (White 100.0%); Wide W5b vs Wide B1a (White 0.0%); Wide W5b vs Wide B14c (White 8.8%); Wide W5b vs Wide 9b (White 13.8%); Wide W5b vs Wide 7c (White 100.0%); Wide 11a vs Wide B14c (White 0.0%); Wide 9b vs Wide 11a (White 100.0%); Wide 9c vs Wide B1a (White 17.5%)

### Specialists against the ordinary pool

| | White's score | vs the ordinary round robin |
|---|---|---|
| Ordinary as White against ordinary as Black (run 10) | 51.1% | |
| White specialists against ordinary as Black | 57.9% (56.8%-59.0%) | White gains +6.8 points |
| Ordinary as White against Black specialists | 45.9% (44.9%-47.0%) | Black gains +5.2 points |
| White specialists against Black specialists | 50.0% | -1.1 points for White overall |

## Summary

| Rules | Ordinary round robin: White | Specialists vs specialists: White | White specialists vs ordinary | Ordinary vs Black specialists | Uneven matchups (specialists, no Standard) | Long-range front-row pieces: White pool / Black pool |
|---|---|---|---|---|---|---|
| Normal rules | 59.4% | 56.7% | 70.4% | 45.8% | 35 of 100 | 3.2 / 1.7 |
| White-only quiet first move | 51.1% | 50.0% | 57.9% | 45.9% | 18 of 100 | 2.9 / 3.2 |
