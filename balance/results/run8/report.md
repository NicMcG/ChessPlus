# Balance run 8: cheaper pawns (report)

Made by `tools/balance/run8_9_analyse.py`. Pawn cost 0.75 and 0.5 (branch `experiment/cheap-pawns`; nothing else changed), with today's Plusfish. "Control" = the same random-army self-play with the Pawn at 1 and today's Plusfish (run 9's part 0). Points = percentage points.

## Random armies (20,000 games, 8,000 nodes, seed 101)

| | Games | White's score (95%) | Draws | White won both of a pair | White's 1st move captures/ability | Black's 1st move captures/ability | | Plies | Pawns per army |
|---|---|---|---|---|---|---|---|---|---|
| Control, Pawn 1 | 20000 | 55.7% (55.1%-56.3%) | 23.5% | 12.3% | 23.7% | 20.6% |  | 129 | 3.4 |
| Pawn 0.75 | 20000 | 56.1% (55.5%-56.7%) | 23.7% | 12.6% | 24.8% | 21.3% |  | 128 | 3.3 |
| Pawn 0.5 | 20000 | 56.5% (55.9%-57.1%) | 24.1% | 13.6% | 26.0% | 22.4% |  | 128 | 3.0 |

## The Pawn's measured worth (balance report, random armies)

| Pawn cost | Worth (army), on the cost scale | ± |
|---|---|---|
| 1 (control) | 0.73 | 0.04 |
| 0.75 | 0.72 | 0.04 |
| 0.5 | 0.72 | 0.04 |

(Worth is on each run's own cost scale: the average piece's worth equals its cost.)


## Pawn 0.75: the meta pool

| Army | Pieces | Pawns | ...in the front row | Cost |
|---|---|---|---|---|
| Wide 15c `(PD)QP(WW)KPPP/A(GA)BG(NC)AE1` | 15 | 4 | 0 | 39 |
| Wide 12c `PP(BR)K(WW)1Q(WW)/(AS)B(BR)G(CV)B(AS)A` | 15 | 2 | 0 | 39 |
| Wide 12a `E(CV)PK(NC)PPA/PLB(SQ)(CV)AB(RM)` | 16 | 4 | 1 | 39 |
| Wide 14c `2(BR)K(NC)GPQ/1GP(RM)(CT)BBA` | 13 | 2 | 1 | 39 |
| Wide 11c `2QK(NC)PPR/(AS)(RM)(PD)(BR)(CV)(WW)GL` | 14 | 2 | 0 | 39 |
| Wide 10a `1(NC)(SQ)KP1PQ/B1AGE(RM)BL` | 13 | 2 | 0 | 39 |
| Wide 7b `QPPEKPP(BD)/A(BR)(CV)B(WW)GB(AS)` | 16 | 4 | 0 | 39 |
| Wide 10a `1Q1KGE(NC)C/B(AS)BG(BR)(AS)(PD)A` | 14 | 0 | 0 | 39 |
| Wide 6a `A(RO)EK(CV)1(NC)1/(PD)BB(CV)(BR)(PD)Q1` | 13 | 0 | 0 | 39 |
| Wide 13c `(PD)P(SQ)KJ(RM)1(BR)/B(BR)1GLQ(PD)P` | 14 | 2 | 1 | 39 |

Pool armies (not Standard): 2.2 pawns each on average, 0.3 in the front row; armies with 4+ pawns in the front row: 0 of 10.

**Piece diversity:** 22 piece types (not the King) in 10 armies. Armies with each: Bishop 9, Queen 9, Archer 8, Ghost 8, Pawn 8, Barbarian 7, Necromancer 7, Elephant 6, Cavalry 5, Paladin 5, Ram 5, Assassin 4, Lance 4, Werewolf 4, Squire 3, Bard 1, Cannon 1, Catapult 1, Galleon 1, Jester 1, Rogue 1, Rook 1


### Pawn 0.75: round robin of this pool + Standard (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000+)

| | |
|---|---|
| Games | 2200 |
| White's score | 64.2% |
| White's first move a capture or ability | 72.2% |
| Black's first move a capture or ability | 65.5% |
| White won both games of a swapped pair (chess 23%) | 18.5% |

**Each army's gap (score as White minus score as Black, points, 95% range)**

| Army | Gap | As White | As Black |
|---|---|---|---|
| Wide 15c | +35.8 (+28.8 to +42.7) | 81.0% | 45.2% |
| Wide 12c | +22.0 (+14.6 to +29.4) | 71.8% | 49.8% |
| Wide 12a | +41.8 (+34.0 to +49.5) | 77.5% | 35.8% |
| Wide 14c | +29.3 (+22.1 to +36.4) | 73.8% | 44.5% |
| Wide 11c | +24.7 (+16.5 to +33.0) | 63.7% | 39.0% |
| Wide 10a | +37.5 (+29.6 to +45.4) | 74.8% | 37.2% |
| Wide 7b | +15.7 (+7.6 to +23.9) | 58.5% | 42.8% |
| Wide 10a | +34.5 (+28.0 to +41.0) | 67.2% | 32.8% |
| Wide 6a | +21.0 (+13.5 to +28.5) | 63.7% | 42.8% |
| Wide 13c | +41.8 (+34.9 to +48.6) | 63.5% | 21.8% |
| Standard | +7.5 (+3.8 to +11.2) | 10.2% | 2.8% |

Pairings with either colour at 80%+: Wide 12c vs Wide 12a (White 83.8%); Wide 12a vs Wide 14c (White 80.0%); Wide 12a vs Wide 10a (White 88.8%); Wide 12a vs Wide 7b (White 85.0%); Wide 12a vs Wide 13c (White 96.2%); Wide 14c vs Wide 11c (White 82.5%); Wide 10a vs Wide 10a (White 92.5%); Wide 6a vs Wide 13c (White 93.8%)

**Success test (Pawn 0.75)**

- White 52-55% in random armies: **no** (56.1%)
- White 52-55% in the round robin: **no** (64.2%)
- No pool army's gap over 30 points: **no** (Wide 15c (+35.8), Wide 12a (+41.8), Wide 10a (+37.5), Wide 10a (+34.5), Wide 13c (+41.8))
- No pairing with either colour at 80%+: **no** (8: Wide 12c vs Wide 12a (White 83.8%), Wide 12a vs Wide 14c (White 80.0%), Wide 12a vs Wide 10a (White 88.8%), Wide 12a vs Wide 7b (White 85.0%), Wide 12a vs Wide 13c (White 96.2%), Wide 14c vs Wide 11c (White 82.5%), Wide 10a vs Wide 10a (White 92.5%), Wide 6a vs Wide 13c (White 93.8%))
- Black not favoured (White at least 50%): **yes** (56.1%, 64.2%)
- **Result: FAILED**

## Pawn 0.5: the meta pool

| Army | Pieces | Pawns | ...in the front row | Cost |
|---|---|---|---|---|
| Wide 15c `(NC)PPPKPP(NC)/(RM)PAG(RO)Q(PD)A` | 16 | 6 | 1 | 39 |
| Wide 15a `(WW)PP(NC)K1P1/CABQ(CV)1GA` | 13 | 3 | 0 | 39 |
| Wide 14b `BPPPKP(WW)(NC)/PQ(PD)GNBAG` | 16 | 5 | 1 | 39 |
| Wide 11b `PPPK(WW)PQP/AEGA(BR)GBB` | 16 | 5 | 0 | 39 |
| Wide 5c `1(NC)PPK1P1/B(GA)CQA(RM)BA` | 13 | 3 | 0 | 39 |
| Wide 13c `NP(NC)KPP(WW)Q/(PD)GPEAA(AS)L` | 16 | 4 | 1 | 39 |
| Wide 9b `PPPKPQ(BR)A/(BR)GGVPPA(AS)` | 16 | 6 | 2 | 39 |
| Wide 14c `C(RO)(CV)K(NC)PPA/ECP(CT)GAB(AS)` | 16 | 3 | 1 | 39 |
| Wide 8c `BP(NC)CKPPP/GB(GA)QGCEP` | 16 | 5 | 1 | 39 |
| Wide 13a `(AS)PPK(RO)PPC/GCP(GA)LBGQ` | 16 | 5 | 1 | 39 |

Pool armies (not Standard): 4.5 pawns each on average, 0.8 in the front row; armies with 4+ pawns in the front row: 0 of 10.

**Piece diversity:** 20 piece types (not the King) in 10 armies. Armies with each: Pawn 10, Ghost 9, Queen 9, Archer 8, Bishop 7, Necromancer 7, Cannon 5, Assassin 4, Elephant 4, Werewolf 4, Galleon 3, Paladin 3, Rogue 3, Barbarian 2, Cavalry 2, Knight 2, Lance 2, Ram 2, Catapult 1, Vampire 1


### Pawn 0.5: round robin of this pool + Standard (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000+)

| | |
|---|---|
| Games | 2200 |
| White's score | 62.3% |
| White's first move a capture or ability | 65.5% |
| Black's first move a capture or ability | 59.7% |
| White won both games of a swapped pair (chess 23%) | 18.5% |

**Each army's gap (score as White minus score as Black, points, 95% range)**

| Army | Gap | As White | As Black |
|---|---|---|---|
| Wide 15c | +40.2 (+32.8 to +47.7) | 82.0% | 41.8% |
| Wide 15a | +28.8 (+21.0 to +36.5) | 79.0% | 50.2% |
| Wide 14b | +30.0 (+21.8 to +38.2) | 73.5% | 43.5% |
| Wide 11b | +26.0 (+18.0 to +34.0) | 73.8% | 47.8% |
| Wide 5c | +34.5 (+26.3 to +42.7) | 71.8% | 37.2% |
| Wide 13c | +20.2 (+11.7 to +28.8) | 64.0% | 43.8% |
| Wide 9b | +13.3 (+4.7 to +21.8) | 64.5% | 51.2% |
| Wide 14c | +30.2 (+22.0 to +38.5) | 58.0% | 27.8% |
| Wide 8c | +28.0 (+19.7 to +36.3) | 63.5% | 35.5% |
| Wide 13a | +17.0 (+8.8 to +25.2) | 51.0% | 34.0% |
| Standard | +1.2 (-1.8 to +4.3) | 3.8% | 2.5% |

Pairings with either colour at 80%+: Wide 15c vs Wide 11b (White 95.0%); Wide 15c vs Wide 13c (White 92.5%); Wide 15c vs Wide 8c (White 92.5%); Wide 15a vs Wide 5c (White 97.5%); Wide 15a vs Wide 13c (White 82.5%); Wide 14b vs Wide 5c (White 88.8%); Wide 5c vs Wide 13c (White 93.8%); Wide 5c vs Wide 14c (White 90.0%); Wide 14c vs Wide 8c (White 90.0%)

**Success test (Pawn 0.5)**

- White 52-55% in random armies: **no** (56.5%)
- White 52-55% in the round robin: **no** (62.3%)
- No pool army's gap over 30 points: **no** (Wide 15c (+40.2), Wide 5c (+34.5), Wide 14c (+30.2))
- No pairing with either colour at 80%+: **no** (9: Wide 15c vs Wide 11b (White 95.0%), Wide 15c vs Wide 13c (White 92.5%), Wide 15c vs Wide 8c (White 92.5%), Wide 15a vs Wide 5c (White 97.5%), Wide 15a vs Wide 13c (White 82.5%), Wide 14b vs Wide 5c (White 88.8%), Wide 5c vs Wide 13c (White 93.8%), Wide 5c vs Wide 14c (White 90.0%), Wide 14c vs Wide 8c (White 90.0%))
- Black not favoured (White at least 50%): **yes** (56.5%, 62.3%)
- **Result: FAILED**
