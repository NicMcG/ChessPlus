# Balance run 15D: the new pieces with the White-only quiet first move (report)

Made by `tools/balance/run15_analyse.py --arm D`. Arm D = arm C (budget 40, the 24 Oct prices, the ability rule, the Grunt, Abatis and Vassal) plus the White-only quiet first move (Plusfish `--white-quiet-first=true`: White may not capture, break a shield or use an ability on its first move unless in check). Its all-round pool was regrown under the rule from C's. Compared with arm C throughout. Points = percentage points.

## (1) Piece values: 20,000 random-army games, 8,000 nodes

Run 15 C: Balance report from 20000 self-play games / White scores 56.4% overall (first-move edge with equal armies: +53 Elo); 23% draws; 130 plies per game on average
Run 15 D: Balance report from 20000 self-play games / White scores 53.6% overall (first-move edge with equal armies: +31 Elo); 24% draws; 134 plies per game on average

"Worth" = what one extra piece at the start is worth by game results, on the cost scale (±95%). Bold = new in run 15; * = has a special ability.

| Piece | Cost | Worth, Run 15 C | Worth, Run 15 D | Verdict, D | D minus C |
|---|---|---|---|---|---|
| Queen | 10.0 | 10.32 ±0.40 | 10.44 ±0.38 | slightly underpriced (+0.4) | +0.12 |
| Princess | 8.5 | 8.64 ±0.33 | 8.69 ±0.32 | about right | +0.05 |
| Wizard | 8.0 | 8.72 ±0.33 | 8.79 ±0.32 | UNDERPRICED by ~0.8 | +0.07 |
| Vampire | 6.5 | 7.27 ±0.27 | 7.35 ±0.26 | UNDERPRICED by ~0.9 | +0.08 |
| Archer* | 4.5 | 4.77 ±0.20 | 4.81 ±0.19 | slightly underpriced (+0.3) | +0.04 |
| Rook | 4.5 | 4.94 ±0.20 | 5.06 ±0.19 | UNDERPRICED by ~0.6 | +0.12 |
| Cannon | 4.0 | 3.82 ±0.18 | 3.68 ±0.18 | slightly overpriced (-0.3) | -0.14 |
| Chariot | 4.0 | 3.96 ±0.18 | 3.98 ±0.18 | about right | +0.02 |
| Squire | 4.0 | 4.05 ±0.18 | 4.13 ±0.18 | about right | +0.08 |
| Bishop | 3.5 | 3.39 ±0.17 | 3.47 ±0.16 | about right | +0.08 |
| Werewolf* | 3.5 | 3.24 ±0.17 | 3.25 ±0.16 | slightly overpriced (-0.2) | +0.01 |
| Bard* | 3.5 | 3.31 ±0.17 | 3.31 ±0.16 | slightly overpriced (-0.2) | +0.00 |
| Lance | 3.5 | 3.30 ±0.17 | 3.04 ±0.16 | slightly overpriced (-0.5) | -0.26 |
| Necromancer* | 3.5 | 3.56 ±0.17 | 3.61 ±0.17 | about right | +0.05 |
| Jester | 3.5 | 3.74 ±0.17 | 3.69 ±0.16 | slightly underpriced (+0.2) | -0.05 |
| Rogue | 3.5 | 3.63 ±0.17 | 3.59 ±0.16 | about right | -0.04 |
| Ram | 3.0 | 3.05 ±0.16 | 3.11 ±0.15 | about right | +0.06 |
| Catapult | 3.0 | 3.00 ±0.15 | 3.10 ±0.15 | about right | +0.10 |
| Knight | 3.0 | 3.18 ±0.16 | 3.22 ±0.15 | slightly underpriced (+0.2) | +0.04 |
| Galleon | 3.0 | 3.24 ±0.16 | 3.24 ±0.15 | slightly underpriced (+0.2) | +0.00 |
| Ghost* | 3.0 | 3.15 ±0.16 | 3.19 ±0.15 | slightly underpriced (+0.2) | +0.04 |
| Cavalry | 3.0 | 3.33 ±0.16 | 3.36 ±0.15 | slightly underpriced (+0.4) | +0.03 |
| Man | 3.0 | 2.77 ±0.15 | 2.77 ±0.15 | slightly overpriced (-0.2) | +0.00 |
| Barbarian | 2.5 | 2.85 ±0.14 | 2.91 ±0.14 | slightly underpriced (+0.4) | +0.06 |
| Parapet | 2.5 | 2.61 ±0.14 | 2.54 ±0.14 | about right | -0.07 |
| Paladin | 1.5 | 1.48 ±0.11 | 1.47 ±0.11 | about right | -0.01 |
| **Grunt** | 1.5 | 0.89 ±0.08 | 0.87 ±0.08 | OVERPRICED by ~0.6 | -0.02 |
| **Abatis** | 1.0 | 0.64 ±0.07 | 0.63 ±0.07 | slightly overpriced (-0.4) | -0.01 |
| Elephant | 1.0 | 0.78 ±0.09 | 0.74 ±0.09 | slightly overpriced (-0.3) | -0.04 |
| Pawn | 1.0 | 0.64 ±0.07 | 0.57 ±0.07 | slightly overpriced (-0.4) | -0.07 |
| **Vassal** | 1.0 | 1.01 ±0.07 | 0.96 ±0.07 | about right | -0.05 |
| Assassin | 0.5 | 0.36 ±0.08 | 0.33 ±0.08 | slightly overpriced (-0.2) | -0.03 |

### White's edge in the random-army games

| | Games | White's score (95%) | Draws | White won both of a pair | White's 1st move captures/ability | Black's 1st move captures/ability | | Plies | Pawns per army |
|---|---|---|---|---|---|---|---|---|---|
| Run 15 C | 20000 | 56.4% (55.8%-57.0%) | 23.4% | 13.2% | 20.7% | 18.1% |  | 130 | 0.8 |
| Run 15 D | 20000 | 53.6% (53.0%-54.2%) | 24.0% | 10.2% | 0.0% | 11.0% |  | 134 | 0.8 |

### The same at 32,000 nodes (5,000 games, seed 303)

| | Games | White's score (95%) | Draws | White won both of a pair | White's 1st move captures/ability | Black's 1st move captures/ability | | Plies | Pawns per army |
|---|---|---|---|---|---|---|---|---|---|
| Run 15 C (32k) | 5000 | 56.7% (55.5%-57.9%) | 22.1% | 12.6% | 20.4% | 16.8% |  | 131 | 0.9 |
| Run 15 D (32k) | 5000 | 53.3% (52.1%-54.5%) | 23.5% | 9.6% | 0.0% | 10.4% |  | 135 | 0.9 |

Run 15 C at 32k, worth (rough, 5,000 games): new pieces Grunt 0.88 (-0.62), Abatis 0.68 (-0.32), Vassal 1.08 (+0.08); furthest off: Vampire +0.71, Grunt -0.62, Wizard +0.54, Knight +0.38, Lance -0.35, Barbarian +0.35.

Run 15 D at 32k, worth (rough, 5,000 games): new pieces Grunt 0.85 (-0.65), Abatis 0.58 (-0.42), Vassal 1.05 (+0.05); furthest off: Vampire +0.86, Lance -0.66, Grunt -0.65, Wizard +0.64, Rook +0.49, Barbarian +0.43.

## (2) Run 15 C: the all-round pool

| Army | Pieces | Front-row squares filled | Pawn types in the front row | Grunts (front/back) | Abatis (front/back) | Vassals (front/back) | Cost |
|---|---|---|---|---|---|---|---|
| Wide 13a `(GR)(CT)(NC)CK(BR)(AB)W/1E(PD)(GR)AA(CV)(AS)` | 15 | 7 | 1 | 1/1 | 0/1 | 0/0 | 40 |
| Wide 13c `W(BR)(NC)GKNP(CV)/(AS)A(RM)(BR)GPP(AS)` | 16 | 8 | 2 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 15b `CW1(PD)K(AB)(NC)1/1(SQ)L(NC)(RM)L(GR)(RM)` | 13 | 7 | 1 | 1/0 | 0/1 | 0/0 | 40 |
| Wide 3c `BG(NC)1KN1W/(CV)(CV)A(GR)(VS)(PD)(GA)(GR)` | 14 | 8 | 3 | 2/0 | 0/0 | 1/0 | 40 |
| Wide 5b `(GA)2KC2N/B(GA)VJA(RM)(PD)A` | 12 | 8 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 12c `(GR)1(GA)1KJRW/(PD)(CV)1(BR)G(GR)V(GR)` | 13 | 7 | 2 | 2/1 | 0/0 | 0/0 | 40 |
| Wide 14c `R(BR)(RO)KN(NC)(GR)(GR)/(RM)GR(SQ)(AS)(GR)G(AS)` | 16 | 8 | 1 | 1/2 | 0/0 | 0/0 | 40 |
| Wide 13b `(GR)(GR)(NC)(GR)K(BR)(AB)W/(GA)A(PD)(BR)AE(CV)(AS)` | 16 | 8 | 0 | 0/3 | 0/1 | 0/0 | 40 |
| Wide 14c `R(BR)(BR)JK(RO)N1/1GAG(CH)(GA)(GA)1` | 13 | 6 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 8a `E(PD)W1KJ(NC)1/L(SQ)L(RM)(RM)1(VS)B` | 13 | 7 | 1 | 0/0 | 0/0 | 1/0 | 40 |

Averages: 7.4 of 8 front-row squares filled, 1.1 pawn-type pieces in the front row; armies with a Grunt 6, an Abatis 3, a Vassal 2 (of 10).

**Piece diversity:** 26 piece types (not the King) in 10 armies. Armies with each: Necromancer 7, Paladin 7, Wizard 7, Archer 6, Barbarian 6, Grunt 6, Cavalry 5, Galleon 5, Ghost 5, Knight 5, Ram 5, Assassin 4, Jester 4, Abatis 3, Bishop 3, Cannon 3, Elephant 3, Rook 3, Squire 3, Lance 2, Rogue 2, Vampire 2, Vassal 2, Catapult 1, Chariot 1, Pawn 1


### Round robin of Run 15 C's pool + Standard (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000+)

| | |
|---|---|
| Games | 2200 |
| White's score | 57.6% |
| White's first move a capture or ability | 29.4% |
| Black's first move a capture or ability | 30.8% |
| White won both games of a swapped pair (chess 23%) | 15.1% |

**Each army's gap (score as White minus score as Black, points, 95% range)**

| Army | Gap | As White | As Black |
|---|---|---|---|
| Wide 13a | +10.0 (+2.0 to +18.0) | 58.0% | 48.0% |
| Wide 13c | +7.3 (-0.9 to +15.4) | 68.8% | 61.5% |
| Wide 15b | +44.3 (+36.5 to +52.0) | 79.5% | 35.2% |
| Wide 3c | +16.0 (+8.2 to +23.8) | 62.5% | 46.5% |
| Wide 5b | +8.8 (+0.7 to +16.8) | 64.0% | 55.2% |
| Wide 12c | +9.8 (+1.3 to +18.2) | 60.5% | 50.7% |
| Wide 14c | +1.0 (-7.7 to +9.7) | 52.5% | 51.5% |
| Wide 13b | +15.7 (+7.3 to +24.2) | 58.5% | 42.8% |
| Wide 14c | +13.5 (+6.3 to +20.7) | 49.2% | 35.8% |
| Wide 8a | +39.0 (+31.3 to +46.7) | 64.2% | 25.2% |
| Standard | +2.2 (-3.8 to +8.3) | 16.0% | 13.8% |

Pairings with either colour at 80%+: Wide 13a vs Wide 15b (White 82.5%); Wide 13c vs Wide 8a (White 97.5%); Wide 15b vs Wide 12c (White 100.0%); Wide 15b vs Wide 8a (White 91.2%); Wide 14c vs Wide 8a (White 96.2%)

White's score with its 95% range: 57.6% (55.8%-59.4%).

## (2) Run 15 D: the all-round pool

| Army | Pieces | Front-row squares filled | Pawn types in the front row | Grunts (front/back) | Abatis (front/back) | Vassals (front/back) | Cost |
|---|---|---|---|---|---|---|---|
| Wide 7c `(GR)(NC)1CK(GR)(AB)W/A(AB)(PD)A(BR)(CT)(CV)(AS)` | 15 | 8 | 1 | 0/2 | 1/1 | 0/0 | 40 |
| Wide 8c `N(NC)1K(AS)PW(GR)/(AS)B(BR)(GA)(BR)A(CV)(CV)` | 15 | 8 | 0 | 0/1 | 0/0 | 0/0 | 40 |
| Wide 7a `1(AB)1CK(GR)(GR)(AB)/(NC)R(PD)ABAEW` | 14 | 8 | 0 | 0/2 | 0/2 | 0/0 | 40 |
| Wide 5b `(GA)2KC2N/B(GA)VJA(RM)(PD)A` | 12 | 8 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 5a `(GR)(GR)J1K(GA)R1/(PD)(CV)V(BR)G(GR)V(GR)` | 14 | 8 | 2 | 2/2 | 0/0 | 0/0 | 40 |
| Wide 13c `W(BR)(NC)GKNP(CV)/(AS)A(RM)(BR)GPP(AS)` | 16 | 8 | 2 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 1a `(GR)(GR)(NC)(GR)KA(AB)W/(RM)AE(BR)(BR)(CV)(PD)(AS)` | 16 | 8 | 0 | 0/3 | 0/1 | 0/0 | 40 |
| Wide 5c `1AN1K(NC)(GR)W/(CV)(CV)GB(VS)(GR)G(PD)` | 14 | 8 | 2 | 1/1 | 0/0 | 1/0 | 40 |
| Wide 1c `1P1(GR)K(CV)1(GR)/(NC)QVJ(GR)(BR)(VS)A` | 13 | 8 | 2 | 1/2 | 0/0 | 1/0 | 40 |
| Wide 4c `(GR)(AS)(BR)QK(AB)(RO)(NC)/(AB)(BR)G(GR)A(PD)G(AS)` | 16 | 8 | 2 | 1/1 | 1/1 | 0/0 | 40 |

Averages: 8.0 of 8 front-row squares filled, 1.1 pawn-type pieces in the front row; armies with a Grunt 8, an Abatis 4, a Vassal 2 (of 10).

**Piece diversity:** 24 piece types (not the King) in 10 armies. Armies with each: Archer 9, Grunt 8, Necromancer 8, Barbarian 7, Cavalry 7, Paladin 7, Wizard 6, Assassin 5, Abatis 4, Bishop 4, Ghost 4, Knight 4, Cannon 3, Galleon 3, Jester 3, Pawn 3, Ram 3, Vampire 3, Elephant 2, Queen 2, Rook 2, Vassal 2, Catapult 1, Rogue 1


### Round robin of Run 15 D's pool + Standard (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000+)

| | |
|---|---|
| Games | 2200 |
| White's score | 52.1% |
| White's first move a capture or ability | 0.0% |
| Black's first move a capture or ability | 13.4% |
| White won both games of a swapped pair (chess 23%) | 11.9% |

**Each army's gap (score as White minus score as Black, points, 95% range)**

| Army | Gap | As White | As Black |
|---|---|---|---|
| Wide 7c | +12.5 (+4.5 to +20.5) | 74.0% | 61.5% |
| Wide 8c | -6.2 (-14.9 to +2.4) | 55.8% | 62.0% |
| Wide 7a | +17.8 (+9.6 to +25.9) | 64.5% | 46.8% |
| Wide 5b | +4.5 (-3.6 to +12.6) | 59.8% | 55.2% |
| Wide 5a | -12.5 (-21.5 to -3.5) | 49.0% | 61.5% |
| Wide 13c | +13.5 (+5.4 to +21.6) | 61.3% | 47.8% |
| Wide 1a | +9.5 (+0.8 to +18.2) | 54.0% | 44.5% |
| Wide 5c | +2.0 (-6.3 to +10.3) | 47.8% | 45.8% |
| Wide 1c | +1.5 (-7.8 to +10.8) | 52.5% | 51.0% |
| Wide 4c | +3.2 (-5.4 to +11.9) | 43.5% | 40.2% |
| Standard | +1.3 (-4.1 to +6.6) | 11.5% | 10.2% |

Pairings with either colour at 80%+: Wide 8c vs Wide 5a (White 5.0%); Wide 7a vs Wide 1a (White 80.0%)

White's score with its 95% range: 52.1% (50.3%-54.0%).

## (4) C's pool armies against themselves (Plusfish at 2,000,000 nodes, 8 threads)

White's first-move advantage in pawns; negative = Black ahead. Chess: +0.29 (top engines +0.20 to +0.35).

| Army | Without the ability rule | With the rule |
|---|---|---|
| Wide 5b `(GA)2KC2N/B(GA)VJA(RM)(PD)A` | +2.09 (Bxf7+) | +2.16 (Kc1) |
| Wide 7a `1(AB)1CK(GR)(GR)(AB)/(NC)R(PD)ABAEW` | +1.81 (Ade3+) | +1.87 (Ade3+) |
| Wide 5a `(GR)(GR)J1K(GA)R1/(PD)(CV)V(BR)G(GR)V(GR)` | +0.08 (Vf3) | +0.14 (Vf3) |
| Wide 5c `1AN1K(NC)(GR)W/(CV)(CV)GB(VS)(GR)G(PD)` | +0.17 (Gb3) | +0.13 (Gb3) |
| Wide 13c `W(BR)(NC)GKNP(CV)/(AS)A(RM)(BR)GPP(AS)` | +1.04 (Axg7) | -0.09 (ASa3) |
| Wide 8c `N(NC)1K(AS)PW(GR)/(AS)B(BR)(GA)(BR)A(CV)(CV)` | +3.56 (Bxg7) | +0.08 (Bd4) |
| Wide 1a `(GR)(GR)(NC)(GR)KA(AB)W/(RM)AE(BR)(BR)(CV)(PD)(AS)` | +0.15 (Axg7) | -0.08 (BRee3) |
| Wide 7c `(GR)(NC)1CK(GR)(AB)W/A(AB)(PD)A(BR)(CT)(CV)(AS)` | +0.75 (Axf7*) | +0.95 (CTe3) |
| Wide 1c `1P1(GR)K(CV)1(GR)/(NC)QVJ(GR)(BR)(VS)A` | +1.02 (Ag3) | +0.66 (Ag3) |
| Standard `standard` | +0.01 (e4) | +0.22 (d4) |
| Wide 4c `(GR)(AS)(BR)QK(AB)(RO)(NC)/(AB)(BR)G(GR)A(PD)G(AS)` | +0.40 (Af3) | +0.23 (Af3) |

With the rule: median +0.22; within ±0.35: 7 of 11; over +1: Wide 5b +2.16, Wide 7a +1.87; Black ahead by more than a pawn: none (run 14 B: median +0.70, 5 of 11 over +1)

## (3) Colour specialists (run 13's method on C's regrown pool)


**White pool (judged only as White)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide W5a `(AB)WACK(GR)(GR)1/1R(PD)AB(VS)(NC)(AB)` | 80.1% (+242) | 14 | 0 (0) | 3 | 2 | 3 |
| Wide W2a `1(NC)(VS)CK(GR)(AB)W/A(GR)(PD)A(BR)(CV)(RM)(AS)` | 79.8% (+238) | 15 | 0 (0) | 3 | 2 | 3 |
| Wide W10a `1(GR)NCKNW1/(AS)(CV)(GR)J(PD)(CV)L(CH)` | 71.4% (+159) | 14 | 0 (0) | 2 | 0 | 0 |
| Wide W6a `(AB)(NC)(VS)CK(CV)WE/(AS)(AB)(PR)A(GR)(GR)1(AS)` | 69.3% (+142) | 15 | 0 (0) | 2 | 1 | 2 |
| Wide W12b `(CV)W(NC)(BR)K(AB)PP/(AS)(BR)NGGAN(AS)` | 66.0% (+115) | 16 | 2 (0) | 1 | 1 | 4 |
| Wide 8c `N(NC)1K(AS)PW(GR)/(AS)B(BR)(GA)(BR)A(CV)(CV)` | 65.8% (+114) | 15 | 1 (0) | 3 | 1 | 2 |
| Wide W12a `GW(NC)1KPPP/(AS)(BR)N(PD)(CV)ANA` | 65.5% (+111) | 15 | 3 (0) | 2 | 2 | 4 |
| Wide W14a `(GR)(GR)2K1W(GR)/1(RM)VV(GR)G(BR)R` | 61.7% (+83) | 12 | 0 (0) | 4 | 0 | 1 |
| Wide W4a `(GR)E(PD)(GR)K(NC)W(AB)/(RM)(BR)A(PD)(BR)(CV)A(AS)` | 57.2% (+50) | 16 | 0 (0) | 3 | 2 | 3 |
| Wide 5a `(GR)(GR)J1K(GA)R1/(PD)(CV)V(BR)G(GR)V(GR)` | 56.8% (+48) | 14 | 0 (0) | 2 | 0 | 1 |

Averages (not Standard): 14.6 pieces, 0.6 pawns (0.0 in the front row), 2.5 long-range pieces in the front row, 1.1 Archers, 2.3 ability pieces.

**Black pool (judged only as Black)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide B11a `1(NC)(GR)KEG2/(CV)(PD)A(GR)VJQ(AS)` | 73.1% (+173) | 13 | 0 (0) | 3 | 1 | 3 |
| Wide B15a `(GR)(NC)1CK(CV)(AB)W/A(GR)(AB)A(PD)(RM)(BR)(AS)` | 68.3% (+133) | 15 | 0 (0) | 3 | 2 | 3 |
| Wide B3a `N(NC)1K(GR)PW(AS)/(AS)B(BR)(GA)(BR)A(CV)(CV)` | 61.1% (+79) | 15 | 1 (0) | 3 | 1 | 2 |
| Wide B2a `(NC)A(BR)(AS)K(AB)Q(GR)/(VS)(PD)G(BR)(GR)BG(AS)` | 60.0% (+70) | 16 | 0 (0) | 1 | 1 | 4 |
| Wide B1a `(GR)(GR)J1K(GR)R1/(VS)(CV)V(BR)G(RM)V(GR)` | 59.0% (+63) | 14 | 0 (0) | 3 | 0 | 1 |
| Wide B12b `(GR)1(GR)K(GR)2P/(NC)QVJ(CV)(BR)(VS)A` | 53.8% (+26) | 13 | 1 (0) | 3 | 1 | 2 |
| Wide 7a `1(AB)1CK(GR)(GR)(AB)/(NC)R(PD)ABAEW` | 53.7% (+26) | 14 | 0 (0) | 5 | 2 | 3 |
| Wide B4a `A(GR)(GR)(GR)K1(AB)W/(PD)A(NC)(BR)(BR)(CV)(RM)(PD)` | 51.4% (+9) | 15 | 0 (0) | 2 | 2 | 3 |
| Wide 5b `(GA)2KC2N/B(GA)VJA(RM)(PD)A` | 49.5% (-3) | 12 | 0 (0) | 6 | 2 | 2 |
| Wide B7c `(PR)1(SQ)K1R(GR)(NC)/ABA(GR)(GR)1(VS)(PD)` | 47.6% (-17) | 13 | 0 (0) | 3 | 2 | 3 |

Averages (not Standard): 14.0 pieces, 0.2 pawns (0.0 in the front row), 3.2 long-range pieces in the front row, 1.4 Archers, 2.6 ability pieces.

White pool: 7.7 of 8 front-row squares filled, 1.0 pawn types in the front row; Grunts 19, Abatis 7, Vassals 3 in all.

Black pool: 7.9 of 8 front-row squares filled, 1.1 pawn types in the front row; Grunts 22, Abatis 6, Vassals 4 in all.

Piece types, White pool: 24 piece types in 10 armies: Wizard 9, Cavalry 8, Grunt 8, Archer 7, Assassin 7, Barbarian 7, Necromancer 7, Paladin 6, Abatis 5, Cannon 4, Ghost 4, Knight 4, Pawn 3, Ram 3, Rook 3, Vassal 3, Bishop 2, Elephant 2, Galleon 2, Jester 2, Vampire 2, Chariot 1, Lance 1, Princess 1

Piece types, Black pool: 24 piece types in 10 armies: Archer 9, Grunt 9, Necromancer 8, Paladin 7, Barbarian 6, Cavalry 6, Bishop 5, Abatis 4, Assassin 4, Jester 4, Ram 4, Vampire 4, Vassal 4, Wizard 4, Cannon 3, Ghost 3, Queen 3, Rook 3, Elephant 2, Galleon 2, Knight 2, Pawn 2, Princess 1, Squire 1

| | White's score | vs C's all-round round robin |
|---|---|---|
| All-rounders as White against all-rounders as Black (C's round robin) | 52.1% | |
| White specialists against all-rounders as Black | 58.3% (57.1%-59.5%) | White gains +6.2 points |
| All-rounders as White against Black specialists | 51.1% (49.9%-52.4%) | Black gains +1.0 points |
| White specialists against Black specialists | 47.5% (46.3%-48.8%) | -4.6 points for White overall |
| Uneven specialist matchups (either side at 80%+, Standard left out) | 28 of 100 | |

Run 14 B (no new pieces, no first-move rule): White specialists +16.3, Black +7.5, specialists vs specialists 70.6% (all-rounders 53.6%); run 13 under the White-only quiet first move: +6.8 / +5.2, 50.0%.

Each White army as White (all Black armies) and each Black army as Black (all White armies):

| White army | Score as White | | Black army | Score as Black |
|---|---|---|---|---|
| Wide W5a | 55.6% | | Wide B11a | 69.3% |
| Wide W2a | 67.4% | | Wide B15a | 64.9% |
| Wide W10a | 56.0% | | Wide B3a | 66.5% |
| Wide W6a | 36.4% | | Wide B2a | 61.7% |
| Wide W12b | 51.7% | | Wide B1a | 32.3% |
| Wide 8c | 59.2% | | Wide B12b | 51.1% |
| Wide W12a | 46.6% | | Wide 7a | 50.0% |
| Wide W14a | 49.2% | | Wide B4a | 55.1% |
| Wide W4a | 43.3% | | Wide 5b | 60.1% |
| Wide 5a | 41.6% | | Wide B7c | 49.7% |
| Standard | 16.0% | | Standard | 16.4% |

Pairings at 80%+: Wide W5a vs Wide B2a (White 87.5%); Wide W5a vs Wide B1a (White 90.0%); Wide W5a vs Wide B7c (White 5.0%); Wide W2a vs Wide B15a (White 95.0%); Wide W2a vs Wide B2a (White 0.0%); Wide W2a vs Wide B1a (White 90.0%); Wide W2a vs Wide B12b (White 88.8%); Wide W2a vs Wide 7a (White 100.0%); Wide W10a vs Wide B11a (White 12.5%); Wide W10a vs Wide 7a (White 86.2%); Wide W10a vs Wide B7c (White 88.8%); Wide W6a vs Wide B15a (White 0.0%); Wide W6a vs Wide B3a (White 13.8%); Wide W6a vs Wide B12b (White 20.0%); Wide W6a vs Wide B4a (White 0.0%); Wide W6a vs Wide B7c (White 10.0%); Wide W12b vs Wide 7a (White 0.0%); Wide W12b vs Wide B7c (White 82.5%); Wide 8c vs Wide B11a (White 20.0%); Wide 8c vs Wide 7a (White 100.0%); Wide 8c vs Wide B4a (White 88.8%); Wide W12a vs Wide B11a (White 15.0%); Wide W12a vs Wide B15a (White 0.0%); Wide W4a vs Wide B15a (White 5.0%); Wide W4a vs Wide B2a (White 6.2%); Wide W4a vs Wide B1a (White 100.0%); Wide W4a vs Wide 7a (White 18.8%); Wide 5a vs Wide B3a (White 0.0%)

## (5) White's first move, every game (C = Run 15 C, D = Run 15 D)

Random armies = the 20,000 balance-report games; pool games = the regrown pool's round robin and the specialist grids. "Hit" = a capture, a shield break or a special ability on move 1; "free" = Black could not hit the mover back where it stood.

| | C, random armies | D, random armies | C, pool games | D, pool games |
|---|---|---|---|---|
| Games | 20000 | 20000 | 16720 | 16720 |
| White's first move a hit | 20.7% (4143) | 0.0% (0) | 48.3% (8071) | 0.0% (0) |
| ...a capture | 18.6% | 0.0% | 42.2% | 0.0% |
| ...a special ability | 0.0% | 0.0% | 0.0% | 0.0% |
| White's score after a hit / after a quiet first move | 66.6% / 53.7% | nan% / 53.6% | 64.8% / 54.8% | nan% / 52.3% |
| Free hits: share of hits, White's score | 44.2%, 74.6% | -, nan% | 26.8%, 67.9% | -, nan% |
| Recapturable hits: share, recaptured | 53.1%, 78.8% | -, - | 69.5%, 75.4% | -, - |

### D, random armies: by the piece that hit (move 1)

| Mover | Hits | Share of hits | White's score | Free | Recaptured |
|---|---|---|---|---|---|

**By the piece hit:**

| Target | Cost | Hit on move 1 | Share of hits | White's score |
|---|---|---|---|---|

**Commonest hits (mover -> target):** 

### D, pool games: by the piece that hit (move 1)

| Mover | Hits | Share of hits | White's score | Free | Recaptured |
|---|---|---|---|---|---|

**By the piece hit:**

| Target | Cost | Hit on move 1 | Share of hits | White's score |
|---|---|---|---|---|

**Commonest hits (mover -> target):** 

## Success lines (from the README, written before the run)

- 1. Each repriced piece within 0.5 of its cost: **no** (Queen +0.44, Bishop -0.03, Rook +0.56, Werewolf -0.25, Parapet +0.04, Jester +0.19)
- 2. No piece more than 1.0 off its cost: **yes** (worst: Vampire +0.85, Wizard +0.79, Grunt -0.63, Rook +0.56)
- 3. Ability pieces within 1.0 of cost under the rule: **yes** (Archer +0.31, Necromancer +0.11, Ghost +0.19, Bard -0.19, Werewolf -0.25)
- 4. White's edge no bigger than Run 15 C's in random armies, and D's round robin passes Mac's lines (50-55%, no gap over 30, no pairing at 80%+): **no** (random armies C 56.4% (55.8%-57.0%), D 53.6% (53.0%-54.2%); D's round robin White 52.1% (50.3%-54.0%), biggest gap +17.8, pairings at 80%+: 2)
- 5. Under the rule no game starts with an ability: **yes** (abilities on move 1 in D's games: 0)
- 6. Diversity: D's pool has at least as many piece types as Run 15 C's (within 2) and at least 3 of the 5 ability types: **yes** (types C 26, D 24; ability types in D's pool: Archer, Necromancer, Ghost)
- 7. Front-row occupancy in the pool rises against Run 15 C's pool (filled squares; pawn types in the front row shown too): **yes** (filled squares 7.4 -> 8.0 of 8; pawn types in the front row 1.1 -> 1.1)
- 8. Specialists vs specialists under 60%: **yes** (White 47.5% (46.3%-48.8%))
- 9. No White specialist at 90%+ against every Black specialist: **yes** (best White specialist 67.4% over the Black pool)
- New pieces' worth (report only): starting prices Grunt 1.5, Abatis 1, Vassal 1: **yes** (Grunt worth 0.87 (-0.63); Abatis worth 0.63 (-0.37); Vassal worth 0.96 (-0.04))
- **Result: FAILED**
