# Balance run 12: separate White and Black armies, split search in phases (report)

Made by `tools/balance/run11_analyse.py`. Plusfish grew a White pool and a Black pool side by side (`meta --wide --split-colours`): a White army is judged only as White against the Black pool, and the other way round. All games below have fixed colours, 40 games a pairing, 8,000 nodes, `--random-plies 4`. "Ordinary pool" = the one-army-for-both-colours pool for that rule set (run 7's for the normal rules, run 10's for the White-only quiet first move); its own round robin is the baseline. Points = percentage points. Run 12 grew one colour at a time (`--phase 5`: five rounds for White against the Black pool frozen, then five for Black, and so on, 30 rounds); run 11 grew both every round.


## Normal rules


**White pool (judged only as White)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | 62.9% (+92) | 15 | 2 (1) | 1 | 1 | 5 |
| Wide W21a `1PNKR1(NC)1/(CV)GQ(AS)L(PD)(CV)B` | 54.6% (+32) | 13 | 1 (0) | 3 | 0 | 2 |
| Wide W25a `(NC)1(GA)K1L2/B(GA)PGLQ(CV)G` | 40.6% (-66) | 12 | 1 (1) | 4 | 0 | 3 |
| Wide W22b `EN(GA)K(NC)(NC)1(BR)/1LGEBABA` | 33.9% (-116) | 14 | 0 (0) | 5 | 2 | 5 |
| Wide W24a `(NC)P1KLB(NC)B/1(PD)GLQ1C1` | 30.5% (-143) | 12 | 1 (0) | 3 | 0 | 3 |
| Wide W22c `PB(NC)K(RM)1B(BD)/PPP(BR)Q(SQ)(AS)(PA)` | 30.2% (-145) | 15 | 4 (3) | 2 | 0 | 2 |
| Wide W12a `(NC)2(NC)K(GA)W1/LC1(CT)(BR)L(PD)B` | 25.1% (-190) | 12 | 0 (0) | 4 | 0 | 2 |
| Wide W21c `(NC)(CV)(RO)K1LN1/BLPB(CT)Q2` | 24.4% (-197) | 12 | 1 (1) | 4 | 0 | 1 |
| Wide W24c `(NC)1PK(RM)NNP/(AS)LELQG(BD)(AS)` | 22.4% (-216) | 15 | 2 (0) | 4 | 0 | 3 |
| Wide W23a `1(NC)PK(RM)G(RO)M/(AS)LPLQPN(AS)` | 15.4% (-296) | 15 | 3 (2) | 3 | 0 | 2 |

Averages (not Standard): 13.5 pieces, 1.5 pawns (0.8 in the front row), 3.3 long-range pieces in the front row, 0.3 Archers, 2.8 ability pieces.

**Black pool (judged only as Black)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide B27a `QBE(RO)K(WW)(WW)(NC)/1B(PD)G(AS)G(PD)(AS)` | 79.8% (+238) | 15 | 0 (0) | 1 | 0 | 5 |
| Wide B27c `(NC)PP(RO)KP(WW)Q/BG(PD)P(WW)G(PD)E` | 76.9% (+209) | 16 | 4 (1) | 1 | 0 | 5 |
| Wide B30a `Q(BR)P1K1P(WW)/(AS)AG(NC)G(PA)(AS)A` | 69.9% (+146) | 14 | 2 (0) | 3 | 2 | 6 |
| Wide B29a `Q(BR)A(BD)K1P1/(AS)AGNG(GA)(AS)P` | 68.0% (+131) | 14 | 2 (1) | 2 | 2 | 5 |
| Wide B29c `1(BR)(BR)KNP1(NC)/Q1G(GA)(SQ)(GA)(PD)(RM)` | 66.6% (+120) | 13 | 1 (0) | 4 | 0 | 2 |
| Wide B30c `(CH)PQ(WW)K(RO)BP/(AS)(BR)P(WW)GEG(AS)` | 63.4% (+95) | 16 | 3 (1) | 0 | 0 | 4 |
| Wide B26c `Q(WW)1KGNG1/N(RM)(AS)(WW)(BR)A(AS)E` | 60.6% (+75) | 14 | 0 (0) | 2 | 1 | 5 |
| Wide B28a `BP(RO)KN(WW)(SQ)G/(BD)(AS)(AS)EBNG(CH)` | 59.9% (+70) | 16 | 1 (0) | 3 | 0 | 4 |
| Wide B29b `Q(BR)A(BD)K1P1/(AS)A(GA)(RM)G(GA)(AS)E` | 57.6% (+53) | 14 | 1 (0) | 4 | 2 | 4 |
| Wide B28c `1(WW)P(WW)KWBP/A(GA)(AS)E(BR)(RM)(BR)(CV)` | 57.4% (+52) | 15 | 2 (0) | 3 | 1 | 3 |

Averages (not Standard): 14.7 pieces, 1.6 pawns (0.3 in the front row), 2.3 long-range pieces in the front row, 0.8 Archers, 4.3 ability pieces.

Piece types, White pool: 25 piece types in 10 armies: Necromancer 10, Bishop 8, Lance 8, Pawn 8, Queen 8, Ghost 7, Knight 6, Assassin 5, Cavalry 4, Barbarian 3, Elephant 3, Galleon 3, Paladin 3, Ram 3, Archer 2, Bard 2, Cannon 2, Catapult 2, Rogue 2, Man 1, Parapet 1, Rook 1, Squire 1, Werewolf 1, Wizard 1

Piece types, Black pool: 21 piece types in 10 armies: Ghost 9, Assassin 8, Pawn 8, Queen 8, Barbarian 7, Elephant 7, Werewolf 7, Archer 5, Bishop 5, Galleon 4, Knight 4, Necromancer 4, Ram 4, Rogue 4, Bard 3, Paladin 3, Chariot 2, Squire 2, Cavalry 1, Parapet 1, Wizard 1

Armies in both pools: none


### Specialists against specialists (every White army against every Black army)

| | |
|---|---|
| Games | 4840 |
| White's score (95%) | 36.8% (35.6%-37.9%) |
| Ordinary pool's round robin, White's score (run 7) | 59.4% |
| White's first move a capture or ability | 39.6% (ordinary 59.4%) |
| Black's first move a capture or ability | 50.4% (ordinary 47.5%) |
| Uneven matchups: either side at 80%+ (40 games each, Standard left out; with fixed colours this mixes army strength and colour) | 39 of 100 |

Each White army as White (all Black armies) and each Black army as Black (all White armies):

| White army | Score as White | | Black army | Score as Black |
|---|---|---|---|---|
| Wide 14a | 69.1% | | Wide B27a | 78.1% |
| Wide W21a | 57.8% | | Wide B27c | 83.4% |
| Wide W25a | 42.7% | | Wide B30a | 75.5% |
| Wide W22b | 30.8% | | Wide B29a | 58.4% |
| Wide W24a | 31.7% | | Wide B29c | 64.5% |
| Wide W22c | 33.3% | | Wide B30c | 64.7% |
| Wide W12a | 28.5% | | Wide B26c | 60.6% |
| Wide W21c | 43.1% | | Wide B28a | 59.9% |
| Wide W24c | 28.6% | | Wide B29b | 65.8% |
| Wide W23a | 18.2% | | Wide B28c | 67.8% |
| Standard | 20.5% | | Standard | 17.0% |

Pairings at 80%+: Wide 14a vs Wide B29a (White 100.0%); Wide 14a vs Wide B30c (White 87.5%); Wide 14a vs Wide B28c (White 86.2%); Wide W21a vs Wide B29c (White 100.0%); Wide W25a vs Wide B27c (White 16.2%); Wide W22b vs Wide B27a (White 16.2%); Wide W22b vs Wide B27c (White 8.8%); Wide W22b vs Wide B30a (White 16.2%); Wide W22b vs Wide B29a (White 17.5%); Wide W22b vs Wide B29b (White 13.8%); Wide W24a vs Wide B27a (White 7.5%); Wide W24a vs Wide B27c (White 12.5%); Wide W24a vs Wide B30c (White 0.0%); Wide W24a vs Wide B29b (White 16.2%); Wide W22c vs Wide B27a (White 20.0%); Wide W22c vs Wide B27c (White 16.2%); Wide W22c vs Wide B30a (White 7.5%); Wide W12a vs Wide B27a (White 0.0%); Wide W12a vs Wide B27c (White 11.2%); Wide W12a vs Wide B29a (White 13.8%); Wide W12a vs Wide B29c (White 0.0%); Wide W12a vs Wide B28c (White 5.0%); Wide W21c vs Wide B27c (White 10.0%); Wide W21c vs Wide B30a (White 17.5%); Wide W21c vs Wide B29a (White 100.0%); Wide W21c vs Wide B28a (White 17.5%); Wide W24c vs Wide B27a (White 16.2%); Wide W24c vs Wide B27c (White 16.2%); Wide W24c vs Wide B30a (White 10.0%); Wide W24c vs Wide B29a (White 16.2%); Wide W24c vs Wide B29b (White 18.8%); Wide W23a vs Wide B27a (White 6.2%); Wide W23a vs Wide B27c (White 10.0%); Wide W23a vs Wide B30a (White 20.0%); Wide W23a vs Wide B29a (White 12.5%); Wide W23a vs Wide B30c (White 18.8%); Wide W23a vs Wide B26c (White 17.5%); Wide W23a vs Wide B29b (White 16.2%); Wide W23a vs Wide B28c (White 0.0%)

### Specialists against the ordinary pool

| | White's score | vs the ordinary round robin |
|---|---|---|
| Ordinary as White against ordinary as Black (run 7) | 59.4% | |
| White specialists against ordinary as Black | 51.5% (50.3%-52.7%) | White gains -7.9 points |
| Ordinary as White against Black specialists | 60.3% (59.2%-61.4%) | Black gains -0.9 points |
| White specialists against Black specialists | 36.8% | -22.6 points for White overall |

## White-only quiet first move


**White pool (judged only as White)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide W25a `AA(BR)1K(CV)1Q/(AS)B1(RM)(CV)(BR)G(AS)` | 52.5% (+17) | 13 | 0 (0) | 2 | 2 | 3 |
| Wide W13a `1P(CV)AK(NC)(PA)1/(AS)BG(BR)(CT)BQ1` | 49.9% (-1) | 13 | 1 (0) | 3 | 1 | 3 |
| Wide W21c `(NC)PPNKQB1/G(AS)B(CV)EAG(AS)` | 48.8% (-9) | 15 | 2 (0) | 2 | 1 | 4 |
| Wide W23c `(NC)P(BR)(WW)K3/(AS)BGBAG(WW)Q` | 45.8% (-30) | 13 | 1 (0) | 4 | 1 | 6 |
| Wide W2c `(NC)B1NK1PA/EABGQ(GA)1(AS)` | 42.4% (-53) | 13 | 1 (0) | 4 | 2 | 4 |
| Wide W14a `(GA)1(NC)K(RM)1W1/(AS)(GA)(PD)(CV)(CV)V1J` | 38.6% (-80) | 12 | 0 (0) | 2 | 0 | 1 |
| Wide 11a `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ` | 33.8% (-117) | 14 | 2 (0) | 6 | 1 | 2 |
| Wide W23a `BW(NC)PKPPP/AB(AS)G(PD)L(CH)1` | 33.6% (-118) | 15 | 4 (0) | 4 | 1 | 3 |
| Wide W22c `(CV)PEPKGW(NC)/AGB(PD)PL(PD)(AS)` | 26.9% (-174) | 16 | 3 (1) | 3 | 1 | 4 |
| Wide W24c `(NC)W(WW)PKEPC/(AS)(BR)EG(BR)LG(PD)` | 26.3% (-179) | 16 | 2 (0) | 1 | 0 | 4 |

Averages (not Standard): 14.0 pieces, 1.6 pawns (0.1 in the front row), 3.1 long-range pieces in the front row, 1.0 Archers, 3.4 ability pieces.

**Black pool (judged only as Black)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide B29a `(NC)(WW)PNKP1Q/(AS)GBG(AS)EAB` | 69.1% (+140) | 15 | 2 (0) | 3 | 1 | 5 |
| Wide B30a `1PA(NC)K3/(CV)1GQ(NC)(SQ)AB` | 68.4% (+134) | 11 | 1 (0) | 3 | 2 | 5 |
| Wide B27c `QEPCKPP(NC)/(AS)A(AS)G(CV)BPB` | 67.9% (+130) | 16 | 4 (1) | 3 | 1 | 3 |
| Wide B27a `A1(BR)QKB(GA)1/(AS)A(BR)(CV)G1G(AS)` | 67.8% (+129) | 13 | 0 (0) | 1 | 2 | 4 |
| Wide B20c `1PB(NC)KGQ1/1A1G(AS)(SQ)AB` | 58.5% (+60) | 12 | 1 (0) | 3 | 2 | 5 |
| Wide B16c `(AS)1QK(NC)1(RO)1/C(PD)(WW)BGBA(AS)` | 56.3% (+44) | 13 | 0 (0) | 4 | 1 | 4 |
| Wide B29c `CQ(BR)KEB1(NC)/B1G(AS)(AS)AG(PD)` | 55.2% (+37) | 14 | 0 (0) | 2 | 1 | 4 |
| Wide B28b `1BPK(NC)EQB/(BD)A(AS)GG(BD)1(AS)` | 54.9% (+34) | 14 | 1 (0) | 3 | 1 | 6 |
| Wide 11a `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ` | 53.2% (+23) | 14 | 2 (0) | 6 | 1 | 2 |
| Wide 4c `EQ(RO)K(WW)(AS)1(NC)/BGB(RM)G(PD)(PD)(AS)` | 50.4% (+3) | 15 | 0 (0) | 3 | 0 | 4 |

Averages (not Standard): 13.7 pieces, 1.1 pawns (0.1 in the front row), 3.1 long-range pieces in the front row, 1.2 Archers, 4.2 ability pieces.

Piece types, White pool: 24 piece types in 10 armies: Assassin 10, Necromancer 9, Archer 8, Bishop 8, Ghost 8, Pawn 8, Queen 6, Cavalry 5, Barbarian 4, Elephant 4, Paladin 4, Wizard 4, Galleon 3, Knight 3, Lance 3, Ram 3, Werewolf 2, Cannon 1, Catapult 1, Chariot 1, Jester 1, Parapet 1, Squire 1, Vampire 1

Piece types, Black pool: 19 piece types in 10 armies: Bishop 10, Queen 10, Archer 9, Assassin 9, Ghost 9, Necromancer 9, Pawn 6, Elephant 5, Cannon 3, Cavalry 3, Paladin 3, Squire 3, Werewolf 3, Barbarian 2, Galleon 2, Knight 2, Ram 2, Rogue 2, Bard 1

Armies in both pools: `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ`


### Specialists against specialists (every White army against every Black army)

| | |
|---|---|
| Games | 4840 |
| White's score (95%) | 43.3% (42.1%-44.4%) |
| Ordinary pool's round robin, White's score (run 10) | 51.1% |
| White's first move a capture or ability | 0.0% (ordinary 0.0%) |
| Black's first move a capture or ability | 41.0% (ordinary 33.7%) |
| Uneven matchups: either side at 80%+ (40 games each, Standard left out; with fixed colours this mixes army strength and colour) | 25 of 100 |

Each White army as White (all Black armies) and each Black army as Black (all White armies):

| White army | Score as White | | Black army | Score as Black |
|---|---|---|---|---|
| Wide W25a | 56.4% | | Wide B29a | 68.1% |
| Wide W13a | 49.3% | | Wide B30a | 59.3% |
| Wide W21c | 60.8% | | Wide B27c | 73.0% |
| Wide W23c | 51.5% | | Wide B27a | 65.1% |
| Wide W2c | 46.4% | | Wide B20c | 61.9% |
| Wide W14a | 40.7% | | Wide B16c | 52.8% |
| Wide 11a | 45.8% | | Wide B29c | 63.6% |
| Wide W23a | 43.1% | | Wide B28b | 61.3% |
| Wide W22c | 38.5% | | Wide 11a | 57.0% |
| Wide W24c | 31.1% | | Wide 4c | 53.4% |
| Standard | 12.5% | | Standard | 8.4% |

Pairings at 80%+: Wide W25a vs Wide B27c (White 81.2%); Wide W13a vs Wide 11a (White 13.8%); Wide W21c vs Wide 11a (White 100.0%); Wide W23c vs Wide B27c (White 16.2%); Wide W2c vs Wide B27c (White 7.5%); Wide W14a vs Wide B27c (White 0.0%); Wide W14a vs Wide 11a (White 13.8%); Wide 11a vs Wide B29a (White 3.8%); Wide 11a vs Wide B27a (White 88.8%); Wide 11a vs Wide B29c (White 16.2%); Wide 11a vs Wide B28b (White 1.2%); Wide W23a vs Wide B30a (White 13.8%); Wide W23a vs Wide B27c (White 18.8%); Wide W23a vs Wide B27a (White 0.0%); Wide W23a vs Wide B29c (White 18.8%); Wide W22c vs Wide B29a (White 17.5%); Wide W22c vs Wide B30a (White 100.0%); Wide W22c vs Wide B27c (White 13.8%); Wide W22c vs Wide B20c (White 0.0%); Wide W22c vs Wide B16c (White 12.5%); Wide W22c vs Wide B28b (White 17.5%); Wide W24c vs Wide B30a (White 5.0%); Wide W24c vs Wide B27c (White 16.2%); Wide W24c vs Wide B20c (White 8.8%); Wide W24c vs Wide 4c (White 18.8%)

### Specialists against the ordinary pool

| | White's score | vs the ordinary round robin |
|---|---|---|
| Ordinary as White against ordinary as Black (run 10) | 51.1% | |
| White specialists against ordinary as Black | 48.9% (47.8%-50.0%) | White gains -2.2 points |
| Ordinary as White against Black specialists | 52.9% (51.8%-53.9%) | Black gains -1.8 points |
| White specialists against Black specialists | 43.3% | -7.8 points for White overall |

## Summary

| Rules | Ordinary round robin: White | Specialists vs specialists: White | White specialists vs ordinary | Ordinary vs Black specialists | Uneven matchups (specialists, no Standard) | Long-range front-row pieces: White pool / Black pool |
|---|---|---|---|---|---|---|
| Normal rules | 59.4% | 36.8% | 51.5% | 60.3% | 39 of 100 | 3.3 / 2.3 |
| White-only quiet first move | 51.1% | 43.3% | 48.9% | 52.9% | 25 of 100 | 3.1 / 3.1 |
