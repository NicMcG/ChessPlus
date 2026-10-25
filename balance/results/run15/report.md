# Balance run 15: the three new pawn-type pieces (report)

Made by `tools/balance/run15_analyse.py`. Arm C = run 14's arm B (budget 40, the 24 Oct prices, the ability rule) plus the Grunt (1.5), Abatis (1) and Vassal (1), the Wall keyword and the 75-move rule. Compared with run 14's arm B throughout. Points = percentage points.

## (1) Piece values: 20,000 random-army games, 8,000 nodes

Run 14 B: Balance report from 20000 self-play games / White scores 55.8% overall (first-move edge with equal armies: +49 Elo); 24% draws; 127 plies per game on average
Run 15 C: Balance report from 20000 self-play games / White scores 56.4% overall (first-move edge with equal armies: +53 Elo); 23% draws; 130 plies per game on average

"Worth" = what one extra piece at the start is worth by game results, on the cost scale (±95%). Bold = new in run 15; * = has a special ability.

| Piece | Cost | Worth, Run 14 B | Worth, Run 15 C | Verdict, C | C minus B |
|---|---|---|---|---|---|
| Queen | 10.0 | 10.05 ±0.37 | 10.32 ±0.40 | about right | +0.27 |
| Princess | 8.5 | 8.55 ±0.31 | 8.64 ±0.33 | about right | +0.09 |
| Wizard | 8.0 | 8.34 ±0.31 | 8.72 ±0.33 | UNDERPRICED by ~0.7 | +0.38 |
| Vampire | 6.5 | 7.20 ±0.25 | 7.27 ±0.27 | UNDERPRICED by ~0.8 | +0.07 |
| Rook | 4.5 | 4.81 ±0.19 | 4.94 ±0.20 | slightly underpriced (+0.4) | +0.13 |
| Archer* | 4.5 | 4.78 ±0.19 | 4.77 ±0.20 | slightly underpriced (+0.3) | -0.01 |
| Chariot | 4.0 | 3.87 ±0.17 | 3.96 ±0.18 | about right | +0.09 |
| Squire | 4.0 | 3.89 ±0.17 | 4.05 ±0.18 | about right | +0.16 |
| Cannon | 4.0 | 3.86 ±0.17 | 3.82 ±0.18 | about right | -0.04 |
| Bard* | 3.5 | 3.26 ±0.16 | 3.31 ±0.17 | slightly overpriced (-0.2) | +0.05 |
| Bishop | 3.5 | 3.47 ±0.16 | 3.39 ±0.17 | about right | -0.08 |
| Rogue | 3.5 | 3.64 ±0.16 | 3.63 ±0.17 | about right | -0.01 |
| Lance | 3.5 | 3.37 ±0.16 | 3.30 ±0.17 | slightly overpriced (-0.2) | -0.07 |
| Jester | 3.5 | 3.65 ±0.16 | 3.74 ±0.17 | slightly underpriced (+0.2) | +0.09 |
| Necromancer* | 3.5 | 3.39 ±0.16 | 3.56 ±0.17 | about right | +0.17 |
| Werewolf* | 3.5 | 3.16 ±0.16 | 3.24 ±0.17 | slightly overpriced (-0.3) | +0.08 |
| Galleon | 3.0 | 3.25 ±0.15 | 3.24 ±0.16 | slightly underpriced (+0.2) | -0.01 |
| Catapult | 3.0 | 2.93 ±0.14 | 3.00 ±0.15 | about right | +0.07 |
| Cavalry | 3.0 | 3.37 ±0.15 | 3.33 ±0.16 | slightly underpriced (+0.3) | -0.04 |
| Knight | 3.0 | 3.15 ±0.15 | 3.18 ±0.16 | slightly underpriced (+0.2) | +0.03 |
| Man | 3.0 | 2.73 ±0.14 | 2.77 ±0.15 | slightly overpriced (-0.2) | +0.04 |
| Ram | 3.0 | 3.13 ±0.15 | 3.05 ±0.16 | about right | -0.08 |
| Ghost* | 3.0 | 3.17 ±0.14 | 3.15 ±0.16 | about right | -0.02 |
| Parapet | 2.5 | 2.61 ±0.13 | 2.61 ±0.14 | about right | +0.00 |
| Barbarian | 2.5 | 2.68 ±0.13 | 2.85 ±0.14 | slightly underpriced (+0.4) | +0.17 |
| **Grunt** | 1.5 | - | 0.89 ±0.08 | OVERPRICED by ~0.6 | - |
| Paladin | 1.5 | 1.46 ±0.10 | 1.48 ±0.11 | about right | +0.02 |
| **Abatis** | 1.0 | - | 0.64 ±0.07 | slightly overpriced (-0.4) | - |
| Pawn | 1.0 | 0.70 ±0.04 | 0.64 ±0.07 | slightly overpriced (-0.4) | -0.06 |
| **Vassal** | 1.0 | - | 1.01 ±0.07 | about right | - |
| Elephant | 1.0 | 0.81 ±0.09 | 0.78 ±0.09 | slightly overpriced (-0.2) | -0.03 |
| Assassin | 0.5 | 0.40 ±0.07 | 0.36 ±0.08 | slightly overpriced (-0.1) | -0.04 |

### White's edge in the random-army games

| | Games | White's score (95%) | Draws | White won both of a pair | White's 1st move captures/ability | Black's 1st move captures/ability | | Plies | Pawns per army |
|---|---|---|---|---|---|---|---|---|---|
| Run 14 B | 20000 | 55.8% (55.2%-56.4%) | 23.8% | 12.8% | 21.0% | 17.4% |  | 127 | 3.3 |
| Run 15 C | 20000 | 56.4% (55.8%-57.0%) | 23.4% | 13.2% | 20.7% | 18.1% |  | 130 | 0.8 |

## (2) Run 14 B: the all-round pool

| Army | Pieces | Front-row squares filled | Pawn types in the front row | Grunts (front/back) | Abatis (front/back) | Vassals (front/back) | Cost |
|---|---|---|---|---|---|---|---|
| Wide 15a `AG(BR)K(GA)P(SQ)B/GAN(RM)E(AS)N(AS)` | 16 | 8 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 5b `(GA)2KC2N/B(GA)VJA(RM)(PD)A` | 12 | 8 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 14a `APPAK(CV)(NC)(NC)/(AS)B(BR)(GA)(BR)(PA)(SQ)(AS)` | 16 | 8 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 14c `R(BR)(BR)JK(RO)N1/1GAG(CH)(GA)(GA)1` | 13 | 6 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 13a `(NC)G(PD)(RM)KN(BD)1/1(CV)ALR(PD)(CV)(PA)` | 14 | 7 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 12c `(PD)1JK1Q(NC)(AS)/(AS)1LLVG(PA)(PD)` | 13 | 7 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 10b `W(PA)2K(RO)B(NC)/1L(PA)GV2B` | 11 | 5 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 10c `(CH)P(RO)RKPP(PA)/G(BR)(AS)L(NC)G(CV)B` | 16 | 8 | 0 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 13c `W(BR)(NC)GKNP(CV)/(AS)A(RM)(BR)GPP(AS)` | 16 | 8 | 2 | 0/0 | 0/0 | 0/0 | 40 |
| Wide 11a `RP(RO)KP(CV)1G/(RM)L(PA)PV(BR)A(AS)` | 15 | 8 | 1 | 0/0 | 0/0 | 0/0 | 40 |

Averages: 7.3 of 8 front-row squares filled, 0.3 pawn-type pieces in the front row; armies with a Grunt 0, an Abatis 0, a Vassal 0 (of 10).

**Piece diversity:** 25 piece types (not the King) in 10 armies. Armies with each: Ghost 8, Archer 7, Assassin 6, Barbarian 6, Necromancer 6, Parapet 6, Bishop 5, Cavalry 5, Knight 5, Lance 5, Pawn 5, Ram 5, Galleon 4, Rogue 4, Rook 4, Vampire 4, Jester 3, Paladin 3, Chariot 2, Squire 2, Wizard 2, Bard 1, Cannon 1, Elephant 1, Queen 1


### Round robin of Run 14 B's pool + Standard (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000+)

| | |
|---|---|
| Games | 2200 |
| White's score | 53.6% |
| White's first move a capture or ability | 43.6% |
| Black's first move a capture or ability | 51.1% |
| White won both games of a swapped pair (chess 23%) | 11.5% |

**Each army's gap (score as White minus score as Black, points, 95% range)**

| Army | Gap | As White | As Black |
|---|---|---|---|
| Wide 15a | +14.0 (+6.1 to +21.9) | 63.0% | 49.0% |
| Wide 5b | +18.0 (+10.9 to +25.1) | 84.8% | 66.8% |
| Wide 14a | +0.0 (-8.5 to +8.5) | 51.5% | 51.5% |
| Wide 14c | -2.0 (-9.4 to +5.4) | 49.5% | 51.5% |
| Wide 13a | +6.2 (-1.5 to +14.0) | 56.2% | 50.0% |
| Wide 12c | +10.5 (+1.7 to +19.3) | 52.0% | 41.5% |
| Wide 10b | +1.5 (-7.0 to +10.0) | 47.2% | 45.8% |
| Wide 10c | +17.8 (+9.8 to +25.7) | 55.8% | 38.0% |
| Wide 13c | -1.5 (-9.2 to +6.2) | 66.5% | 68.0% |
| Wide 11a | +19.2 (+11.3 to +27.2) | 46.0% | 26.8% |
| Standard | -5.2 (-12.0 to +1.5) | 16.8% | 22.0% |

Pairings with either colour at 80%+: Wide 15a vs Wide 11a (White 87.5%); Wide 5b vs Wide 12c (White 83.8%); Wide 5b vs Wide 10c (White 85.0%); Wide 10c vs Wide 11a (White 81.2%)

White's score with its 95% range: 53.6% (51.8%-55.4%).

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

## (4) C's pool armies against themselves (Plusfish at 2,000,000 nodes, 8 threads)

White's first-move advantage in pawns; negative = Black ahead. Chess: +0.29 (top engines +0.20 to +0.35).

| Army | Without the ability rule | With the rule |
|---|---|---|
| Wide 5b `(GA)2KC2N/B(GA)VJA(RM)(PD)A` | +2.19 (Bxf7+) | +1.79 (Kc1) |
| Wide 3c `BG(NC)1KN1W/(CV)(CV)A(GR)(VS)(PD)(GA)(GR)` | +0.52 (Axh7!) | +0.14 (Ad3) |
| Wide 8a `E(PD)W1KJ(NC)1/L(SQ)L(RM)(RM)1(VS)B` | +99.00 (Lxc8=SQ#) | +99.00 (Lxc8=SQ#) |
| Wide 15b `CW1(PD)K(AB)(NC)1/1(SQ)L(NC)(RM)L(GR)(RM)` | +1.67 (Wd3) | +0.59 (Ca4) |
| Wide 13a `(GR)(CT)(NC)CK(BR)(AB)W/1E(PD)(GR)AA(CV)(AS)` | +0.04 (Wxh8*) | +0.22 (Wxh8*) |
| Wide 12c `(GR)1(GA)1KJRW/(PD)(CV)1(BR)G(GR)V(GR)` | +0.12 (BRc3) | +0.04 (BRc3) |
| Wide 14c `R(BR)(RO)KN(NC)(GR)(GR)/(RM)GR(SQ)(AS)(GR)G(AS)` | +0.18 (Rxc7*) | +0.20 (Rxc7*) |
| Wide 13c `W(BR)(NC)GKNP(CV)/(AS)A(RM)(BR)GPP(AS)` | +3.62 (Axg7!) | +0.95 (Wxg7) |
| Wide 13b `(GR)(GR)(NC)(GR)K(BR)(AB)W/(GA)A(PD)(BR)AE(CV)(AS)` | +3.39 (Axg7!) | +0.23 (Axg7) |
| Wide 14c `R(BR)(BR)JK(RO)N1/1GAG(CH)(GA)(GA)1` | +0.15 (Aa4) | +0.29 (Aa4) |
| Standard `standard` | +0.17 (d4) | +0.23 (d4) |

With the rule: median +0.23; within ±0.35: 7 of 11; over +1: Wide 5b +1.79, Wide 8a +99.00; Black ahead by more than a pawn: none (run 14 B: median +0.70, 5 of 11 over +1)

## (3) Colour specialists (run 13's method on C's regrown pool)


**White pool (judged only as White)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide W8a `(AB)(GR)(CV)CKPN(GR)/W(RM)LL(RM)E(AS)(PA)` | 83.1% (+276) | 16 | 1 (0) | 6 | 0 | 0 |
| Wide W11a `(GA)W(NC)(AB)KR1(CV)/1AL(BR)(PD)L(GR)1` | 82.5% (+269) | 13 | 0 (0) | 3 | 1 | 2 |
| Wide W15a `1(GR)(CV)CKN1(PA)/W(RM)LL(RM)(AS)(AS)(PA)` | 81.0% (+252) | 14 | 0 (0) | 6 | 0 | 0 |
| Wide W14c `(NC)(GR)(NC)K1(VS)W1/CLLRN(PD)(GR)P` | 80.0% (+241) | 14 | 1 (1) | 4 | 0 | 2 |
| Wide W2a `1(VS)(PD)1K(CV)1(RM)/BRL(CT)GWG(GA)` | 79.3% (+234) | 13 | 0 (0) | 5 | 0 | 2 |
| Wide W9a `1(GR)RK2(NC)(RM)/(AB)(SQ)LL(RM)W(VS)B` | 79.1% (+231) | 13 | 0 (0) | 5 | 0 | 1 |
| Wide W14a `1(GR)(AB)K(PD)(GR)W(BR)/C(AS)L(NC)(PA)(AB)AR` | 78.5% (+225) | 15 | 0 (0) | 5 | 1 | 2 |
| Wide W7a `1(VS)(VS)(RM)K(CV)G1/BBLLGW1(GA)` | 77.5% (+215) | 13 | 0 (0) | 6 | 0 | 2 |
| Wide W10c `1(GR)1K1(NC)W1/(PR)(VS)L(CV)(BR)LB(PD)` | 77.4% (+214) | 12 | 0 (0) | 4 | 0 | 1 |
| Wide W11c `(PA)(CV)(BR)AK(RM)W1/1(PD)L(RM)(AB)L(VS)(CV)` | 77.3% (+213) | 14 | 0 (0) | 3 | 1 | 1 |

Averages (not Standard): 13.7 pieces, 0.2 pawns (0.1 in the front row), 4.7 long-range pieces in the front row, 0.3 Archers, 1.3 ability pieces.

**Black pool (judged only as Black)**

| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |
|---|---|---|---|---|---|---|
| Wide B8a `(GR)(GA)(NC)WK(BR)(CV)(GR)/(AS)(AB)(PD)(BR)(GR)EAA` | 67.2% (+124) | 16 | 0 (0) | 2 | 2 | 3 |
| Wide B11a `W(GR)(CV)K1J2/(GR)A(GR)(BR)(CV)GV(PD)` | 58.4% (+59) | 13 | 0 (0) | 2 | 1 | 2 |
| Wide 5b `(GA)2KC2N/B(GA)VJA(RM)(PD)A` | 56.4% (+44) | 12 | 0 (0) | 6 | 2 | 2 |
| Wide 13c `W(BR)(NC)GKNP(CV)/(AS)A(RM)(BR)GPP(AS)` | 53.8% (+26) | 16 | 3 (2) | 2 | 1 | 4 |
| Wide B11c `(GR)Q(NC)PKN(BR)(GR)/(PA)N(AS)(GA)(BR)(GR)B(AS)` | 53.8% (+26) | 16 | 1 (0) | 3 | 0 | 1 |
| Wide 3c `BG(NC)1KN1W/(CV)(CV)A(GR)(VS)(PD)(GA)(GR)` | 52.5% (+17) | 14 | 0 (0) | 2 | 1 | 3 |
| Wide 14c `R(BR)(RO)KN(NC)(GR)(GR)/(RM)GR(SQ)(AS)(GR)G(AS)` | 51.3% (+9) | 16 | 0 (0) | 2 | 0 | 3 |
| Wide B2a `(NC)PAK(GR)(BR)(GR)1/B(AS)GVG(CV)(GA)(RM)` | 50.7% (+5) | 15 | 1 (0) | 4 | 1 | 4 |
| Wide 13a `(GR)(CT)(NC)CK(BR)(AB)W/1E(PD)(GR)AA(CV)(AS)` | 49.1% (-6) | 15 | 0 (0) | 2 | 2 | 3 |
| Wide B14a `(GR)(NC)1CK(GR)(AB)W/N(BD)(PD)(CV)(AS)A(CV)(AB)` | 47.3% (-19) | 15 | 0 (0) | 2 | 1 | 3 |

Averages (not Standard): 14.8 pieces, 0.5 pawns (0.2 in the front row), 2.7 long-range pieces in the front row, 1.1 Archers, 2.8 ability pieces.

White pool: 7.6 of 8 front-row squares filled, 0.9 pawn types in the front row; Grunts 10, Abatis 6, Vassals 7 in all.

Black pool: 7.9 of 8 front-row squares filled, 1.3 pawn types in the front row; Grunts 20, Abatis 4, Vassals 1 in all.

Piece types, White pool: 24 piece types in 10 armies: Lance 10, Wizard 10, Cavalry 7, Grunt 7, Paladin 6, Ram 6, Vassal 6, Abatis 5, Necromancer 5, Rook 5, Barbarian 4, Bishop 4, Cannon 4, Parapet 4, Archer 3, Assassin 3, Galleon 3, Knight 3, Ghost 2, Pawn 2, Catapult 1, Elephant 1, Princess 1, Squire 1

Piece types, Black pool: 27 piece types in 10 armies: Archer 8, Grunt 8, Necromancer 8, Assassin 7, Barbarian 7, Cavalry 7, Knight 6, Paladin 6, Wizard 6, Galleon 5, Ghost 5, Bishop 4, Ram 4, Abatis 3, Cannon 3, Pawn 3, Vampire 3, Elephant 2, Jester 2, Bard 1, Catapult 1, Parapet 1, Queen 1, Rogue 1, Rook 1, Squire 1, Vassal 1

| | White's score | vs C's all-round round robin |
|---|---|---|
| All-rounders as White against all-rounders as Black (C's round robin) | 57.6% | |
| White specialists against all-rounders as Black | 73.2% (72.1%-74.4%) | White gains +15.6 points |
| All-rounders as White against Black specialists | 51.7% (50.5%-52.9%) | Black gains +5.9 points |
| White specialists against Black specialists | 54.9% (53.6%-56.1%) | -2.7 points for White overall |
| Uneven specialist matchups (either side at 80%+, Standard left out) | 56 of 100 | |

Run 14 B (no new pieces, no first-move rule): White specialists +16.3, Black +7.5, specialists vs specialists 70.6% (all-rounders 53.6%); run 13 under the White-only quiet first move: +6.8 / +5.2, 50.0%.

Each White army as White (all Black armies) and each Black army as Black (all White armies):

| White army | Score as White | | Black army | Score as Black |
|---|---|---|---|---|
| Wide W8a | 61.6% | | Wide B8a | 80.6% |
| Wide W11a | 57.5% | | Wide B11a | 54.1% |
| Wide W15a | 67.2% | | Wide 5b | 30.6% |
| Wide W14c | 56.4% | | Wide 13c | 49.9% |
| Wide W2a | 63.1% | | Wide B11c | 62.4% |
| Wide W9a | 51.0% | | Wide 3c | 32.4% |
| Wide W14a | 48.4% | | Wide 14c | 76.5% |
| Wide W7a | 54.3% | | Wide B2a | 49.1% |
| Wide W10c | 58.5% | | Wide 13a | 6.9% |
| Wide W11c | 61.7% | | Wide B14a | 38.2% |
| Standard | 23.9% | | Standard | 15.9% |

Pairings at 80%+: Wide W8a vs Wide B11a (White 100.0%); Wide W8a vs Wide 5b (White 96.2%); Wide W8a vs Wide 13c (White 100.0%); Wide W8a vs Wide B11c (White 100.0%); Wide W8a vs Wide 3c (White 0.0%); Wide W8a vs Wide 14c (White 20.0%); Wide W8a vs Wide B2a (White 0.0%); Wide W8a vs Wide 13a (White 100.0%); Wide W8a vs Wide B14a (White 100.0%); Wide W11a vs Wide B8a (White 0.0%); Wide W11a vs Wide 13c (White 15.0%); Wide W11a vs Wide 13a (White 100.0%); Wide W11a vs Wide B14a (White 87.5%); Wide W15a vs Wide 5b (White 100.0%); Wide W15a vs Wide 13c (White 100.0%); Wide W15a vs Wide B11c (White 100.0%); Wide W15a vs Wide 3c (White 100.0%); Wide W15a vs Wide 14c (White 16.2%); Wide W15a vs Wide B2a (White 3.8%); Wide W15a vs Wide 13a (White 100.0%); Wide W15a vs Wide B14a (White 100.0%); Wide W14c vs Wide 5b (White 83.8%); Wide W14c vs Wide B11c (White 0.0%); Wide W14c vs Wide 3c (White 100.0%); Wide W14c vs Wide 14c (White 10.0%); Wide W14c vs Wide 13a (White 100.0%); Wide W2a vs Wide B8a (White 11.2%); Wide W2a vs Wide B2a (White 100.0%); Wide W2a vs Wide 13a (White 100.0%); Wide W9a vs Wide B8a (White 0.0%); Wide W9a vs Wide B11a (White 0.0%); Wide W9a vs Wide 5b (White 100.0%); Wide W9a vs Wide 13c (White 100.0%); Wide W9a vs Wide B11c (White 0.0%); Wide W9a vs Wide 13a (White 100.0%); Wide W14a vs Wide B11a (White 0.0%); Wide W14a vs Wide 5b (White 100.0%); Wide W14a vs Wide B11c (White 8.8%); Wide W14a vs Wide 3c (White 100.0%); Wide W14a vs Wide 14c (White 7.5%); Wide W14a vs Wide 13a (White 100.0%); Wide W14a vs Wide B14a (White 0.0%); Wide W7a vs Wide B8a (White 17.5%); Wide W7a vs Wide B11c (White 17.5%); Wide W7a vs Wide 3c (White 100.0%); Wide W7a vs Wide 14c (White 13.8%); Wide W7a vs Wide 13a (White 100.0%); Wide W7a vs Wide B14a (White 18.8%); Wide W10c vs Wide 13c (White 15.0%); Wide W10c vs Wide 3c (White 100.0%); Wide W10c vs Wide 14c (White 2.5%); Wide W10c vs Wide B2a (White 80.0%); Wide W10c vs Wide 13a (White 100.0%); Wide W10c vs Wide B14a (White 83.8%); Wide W11c vs Wide 13a (White 100.0%); Wide W11c vs Wide B14a (White 92.5%)

## (5) White's first move, every game (B = Run 14 B, C = Run 15 C)

Random armies = the 20,000 balance-report games; pool games = the regrown pool's round robin and the specialist grids. "Hit" = a capture, a shield break or a special ability on move 1; "free" = Black could not hit the mover back where it stood.

| | B, random armies | C, random armies | B, pool games | C, pool games |
|---|---|---|---|---|
| Games | 20000 | 20000 | 16720 | 16720 |
| White's first move a hit | 21.0% (4198) | 20.7% (4143) | 53.3% (8910) | 48.3% (8071) |
| ...a capture | 20.7% | 18.6% | 52.8% | 42.2% |
| ...a special ability | 0.0% | 0.0% | 0.0% | 0.0% |
| White's score after a hit / after a quiet first move | 68.9% / 52.3% | 66.6% / 53.7% | 70.9% / 49.9% | 64.8% / 54.8% |
| Free hits: share of hits, White's score | 41.8%, 78.6% | 44.2%, 74.6% | 5.2%, 73.3% | 26.8%, 67.9% |
| Recapturable hits: share, recaptured | 55.6%, 75.9% | 53.1%, 78.8% | 90.6%, 78.3% | 69.5%, 75.4% |

### C, random armies: by the piece that hit (move 1)

| Mover | Hits | Share of hits | White's score | Free | Recaptured |
|---|---|---|---|---|---|
| Lance | 1800 | 43.4% | 69.8% | 36.6% | 47.1% |
| Cannon | 1028 | 24.8% | 60.3% | 32.6% | 56.8% |
| Wizard | 470 | 11.3% | 66.2% | 75.5% | 22.6% |
| Rook | 312 | 7.5% | 70.8% | 59.9% | 31.4% |
| Bishop | 157 | 3.8% | 59.2% | 48.4% | 37.6% |
| Queen | 154 | 3.7% | 72.1% | 88.3% | 11.0% |
| Ram | 111 | 2.7% | 57.7% | 0.0% | 0.0% |
| Archer | 111 | 2.7% | 76.1% | 73.9% | 21.6% |

**By the piece hit:**

| Target | Cost | Hit on move 1 | Share of hits | White's score |
|---|---|---|---|---|
| Jester | 3.5 | 392 | 9.5% | 59.6% |
| Grunt | 1.5 | 377 | 9.1% | 54.1% |
| Princess | 8.5 | 213 | 5.1% | 81.9% |
| Queen | 10.0 | 203 | 4.9% | 84.7% |
| Wizard | 8.0 | 200 | 4.8% | 80.2% |
| Rook | 4.5 | 179 | 4.3% | 67.6% |
| Vampire | 6.5 | 175 | 4.2% | 74.6% |
| Lance | 3.5 | 173 | 4.2% | 63.3% |
| Archer | 4.5 | 148 | 3.6% | 61.5% |
| Barbarian | 2.5 | 126 | 3.0% | 57.1% |
| Chariot | 4.0 | 123 | 3.0% | 67.1% |
| Squire | 4.0 | 116 | 2.8% | 69.0% |
| Ghost | 3.0 | 115 | 2.8% | 63.0% |
| Abatis | 1.0 | 108 | 2.6% | 71.3% |
| Bishop | 3.5 | 105 | 2.5% | 71.9% |
| Vassal | 1.0 | 103 | 2.5% | 59.7% |
| Necromancer | 3.5 | 102 | 2.5% | 70.6% |
| Cannon | 4.0 | 97 | 2.3% | 66.5% |
| Assassin | 0.5 | 94 | 2.3% | 67.0% |
| Rogue | 3.5 | 91 | 2.2% | 67.6% |
| Galleon | 3.0 | 91 | 2.2% | 66.5% |
| Cavalry | 3.0 | 88 | 2.1% | 67.0% |
| Parapet | 2.5 | 85 | 2.1% | 62.4% |
| Ram | 3.0 | 82 | 2.0% | 61.6% |
| Bard | 3.5 | 80 | 1.9% | 62.5% |
| Knight | 3.0 | 78 | 1.9% | 71.2% |
| Pawn | 1.0 | 77 | 1.9% | 68.8% |
| Werewolf | 3.5 | 70 | 1.7% | 60.0% |
| Catapult | 3.0 | 69 | 1.7% | 63.8% |
| Elephant | 1.0 | 65 | 1.6% | 63.1% |
| Man | 3.0 | 62 | 1.5% | 74.2% |
| Paladin | 1.5 | 56 | 1.4% | 50.0% |

**Commonest hits (mover -> target):** Lance x Jester 208 (White 61.3%, free 19.7%); Lance x Grunt 107 (White 50.9%, free 92.5%); Cannon x Jester 98 (White 53.1%, free 17.3%); Wizard x Grunt 95 (White 56.8%, free 97.9%); Lance x Lance 72 (White 61.8%, free 16.7%); Cannon x Vampire 69 (White 74.6%, free 13.0%); Cannon x Wizard 67 (White 76.9%, free 17.9%); Cannon x Queen 67 (White 82.1%, free 11.9%); Lance x Barbarian 65 (White 52.3%, free 16.9%); Cannon x Princess 64 (White 90.6%, free 23.4%); Cannon x Grunt 64 (White 43.8%, free 100.0%); Lance x Bishop 63 (White 76.2%, free 38.1%); Cannon x Rook 62 (White 65.3%, free 32.3%); Lance x Cavalry 61 (White 65.6%, free 23.0%); Lance x Assassin 59 (White 72.0%, free 54.2%)

### C, pool games: by the piece that hit (move 1)

| Mover | Hits | Share of hits | White's score | Free | Recaptured |
|---|---|---|---|---|---|
| Lance | 4304 | 53.3% | 69.1% | 19.7% | 62.4% |
| Cannon | 1178 | 14.6% | 68.9% | 49.1% | 27.5% |
| Wizard | 884 | 11.0% | 49.5% | 46.8% | 41.2% |
| Bishop | 834 | 10.3% | 70.9% | 26.0% | 50.6% |
| Archer | 301 | 3.7% | 51.7% | 22.6% | 71.1% |
| Ram | 297 | 3.7% | 51.3% | 0.0% | 0.0% |
| Rook | 273 | 3.4% | 39.9% | 13.9% | 80.6% |

**By the piece hit:**

| Target | Cost | Hit on move 1 | Share of hits | White's score |
|---|---|---|---|---|
| Archer | 4.5 | 1891 | 23.4% | 59.4% |
| Jester | 3.5 | 1180 | 14.6% | 76.7% |
| Grunt | 1.5 | 893 | 11.1% | 34.5% |
| Pawn | 1.0 | 630 | 7.8% | 99.6% |
| Rook | 4.5 | 476 | 5.9% | 54.3% |
| Cavalry | 3.0 | 468 | 5.8% | 52.5% |
| Ghost | 3.0 | 442 | 5.5% | 64.1% |
| Ram | 3.0 | 431 | 5.3% | 72.5% |
| Galleon | 3.0 | 252 | 3.1% | 87.5% |
| Vassal | 1.0 | 240 | 3.0% | 66.7% |
| Assassin | 0.5 | 217 | 2.7% | 50.0% |
| Lance | 3.5 | 205 | 2.5% | 97.3% |
| Knight | 3.0 | 163 | 2.0% | 97.5% |
| Barbarian | 2.5 | 151 | 1.9% | 61.6% |
| Paladin | 1.5 | 128 | 1.6% | 31.6% |
| Bishop | 3.5 | 126 | 1.6% | 25.8% |
| Wizard | 8.0 | 118 | 1.5% | 91.5% |
| Squire | 4.0 | 40 | 0.5% | 82.5% |
| Necromancer | 3.5 | 20 | 0.2% | 50.0% |

**Commonest hits (mover -> target):** Lance x Jester 902 (White 74.7%, free 39.7%); Lance x Archer 841 (White 73.0%, free 0.0%); Lance x Ghost 343 (White 70.1%, free 0.0%); Wizard x Archer 336 (White 48.2%, free 0.0%); Lance x Grunt 325 (White 28.0%, free 94.2%); Bishop x Pawn 309 (White 100.0%, free 54.7%); Lance x Ram 304 (White 78.5%, free 5.6%); Lance x Pawn 300 (White 100.0%, free 53.3%); Wizard x Grunt 292 (White 39.0%, free 100.0%); Lance x Cavalry 287 (White 62.4%, free 0.0%); Ram x Archer 269 (White 53.2%, free 0.0%); Lance x Vassal 240 (White 66.7%, free 0.0%); Cannon x Rook 220 (White 99.5%, free 100.0%); Cannon x Jester 214 (White 88.6%, free 0.0%); Bishop x Archer 212 (White 60.8%, free 0.0%)

## Success lines (from the README, written before the run)

- 1. Each repriced piece within 0.5 of its cost: **yes** (Queen +0.32, Bishop -0.11, Rook +0.44, Werewolf -0.26, Parapet +0.11, Jester +0.24)
- 2. No piece more than 1.0 off its cost: **yes** (worst: Vampire +0.77, Wizard +0.72, Grunt -0.61, Rook +0.44)
- 3. Ability pieces within 1.0 of cost under the rule: **yes** (Archer +0.27, Necromancer +0.06, Ghost +0.15, Bard -0.19, Werewolf -0.26)
- 4. White's edge no bigger than Run 14 B's in random armies, and C's round robin passes Mac's lines (50-55%, no gap over 30, no pairing at 80%+): **no** (random armies B 55.8% (55.2%-56.4%), C 56.4% (55.8%-57.0%); C's round robin White 57.6% (55.8%-59.4%), biggest gap +44.3, pairings at 80%+: 5)
- 5. Under the rule no game starts with an ability: **yes** (abilities on move 1 in C's games: 0)
- 6. Diversity: C's pool has at least as many piece types as Run 14 B's (within 2) and at least 3 of the 5 ability types: **yes** (types B 25, C 26; ability types in C's pool: Necromancer, Archer, Ghost)
- 7. Front-row occupancy in the pool rises against Run 14 B's pool (filled squares; pawn types in the front row shown too): **yes** (filled squares 7.3 -> 7.4 of 8; pawn types in the front row 0.3 -> 1.1)
- New pieces' worth (report only): starting prices Grunt 1.5, Abatis 1, Vassal 1: **yes** (Grunt worth 0.89 (-0.61); Abatis worth 0.64 (-0.36); Vassal worth 1.01 (+0.01))
- Report only: specialists vs specialists, and the best White specialist (lines 8 and 9 of run 15D): **yes** (White 54.9%; best White specialist 67.2% over the Black pool)
- **Result: FAILED**
