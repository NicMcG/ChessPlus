# Balance run 10: a meta pool grown with the White-only quiet first move (report)

Made by `tools/balance/run10_analyse.py`. Rule (Plusfish `--white-quiet-first=true`): White may not capture, break a shield or use an ability on its first move unless in check; Black's first move is unrestricted. The pool was grown with the rule on, from run 7's pool plus Standard. Points = percentage points.

## The new pool

| Army | Pieces | Pawns | ...in the front row | Cost |
|---|---|---|---|---|
| Wide 15a `1Q(BR)KCG1(NC)/BEB(AS)(AS)AG(PD)` | 14 | 0 | 0 | 39 |
| Wide 11a `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ` | 14 | 2 | 0 | 39 |
| Wide 7c `2(CV)K(NC)(WW)B1/Q(AS)(BR)(GA)(CV)GEA` | 13 | 0 | 0 | 39 |
| Wide 14a `(WW)QBKC2(CV)/1(BR)ABG(CV)P1` | 12 | 1 | 1 | 39 |
| Wide 9b `AA(BR)QK(CV)2/(AS)B1(RM)(CV)(BR)G(AS)` | 13 | 0 | 0 | 39 |
| Wide 9c `1PBK1(NC)Q1/A1(AS)GG(SQ)AB` | 12 | 1 | 0 | 39 |
| Wide 4c `EQ(RO)K(WW)(AS)1(NC)/BGB(RM)G(PD)(PD)(AS)` | 15 | 0 | 0 | 39 |
| Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | 15 | 2 | 1 | 39 |
| Wide 4b `1PPK(BR)C(NC)1/A(AS)(WW)(BR)GBQ(PD)` | 14 | 2 | 0 | 39 |
| Wide 15a `QE(WW)1KN(NC)(RM)/(AS)APB(BR)(PD)G(AS)` | 15 | 1 | 1 | 39 |

**Piece diversity:** 18 piece types (not the King) in 10 armies. Armies with each: Bishop 10, Queen 10, Archer 9, Assassin 9, Ghost 9, Necromancer 8, Barbarian 6, Pawn 6, Werewolf 6, Elephant 5, Cavalry 4, Paladin 4, Ram 4, Cannon 3, Knight 3, Galleon 2, Squire 2, Rogue 1


### Round robin of the new pool + Standard, with the rule (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000+)

| | |
|---|---|
| Games | 2200 |
| White's score | 51.1% |
| White's first move a capture or ability | 0.0% |
| Black's first move a capture or ability | 33.7% |
| White won both games of a swapped pair (chess 23%) | 4.7% |

**Each army's gap (score as White minus score as Black, points, 95% range)**

| Army | Gap | As White | As Black |
|---|---|---|---|
| Wide 15a | +1.0 (-5.4 to +7.4) | 56.8% | 55.8% |
| Wide 11a | +11.3 (+4.0 to +18.5) | 65.0% | 53.8% |
| Wide 7c | +1.5 (-5.8 to +8.8) | 59.0% | 57.5% |
| Wide 14a | +6.2 (-1.1 to +13.6) | 58.0% | 51.7% |
| Wide 9b | +0.7 (-6.6 to +8.1) | 61.0% | 60.2% |
| Wide 9c | +1.3 (-5.6 to +8.1) | 55.0% | 53.8% |
| Wide 4c | +2.5 (-4.4 to +9.4) | 52.0% | 49.5% |
| Wide 14a | -7.3 (-14.3 to -0.2) | 52.0% | 59.2% |
| Wide 4b | +0.0 (-7.3 to +7.3) | 47.5% | 47.5% |
| Wide 15a | +1.2 (-6.4 to +8.9) | 47.5% | 46.2% |
| Standard | +5.5 (+2.0 to +9.0) | 8.2% | 2.8% |

Pairings with either colour at 80%+: Wide 11a vs Wide 7c (White 80.0%)

White's score with its 95% range: 51.1% (49.5%-52.7%).

## Each pool army against itself (Plusfish at 2,000,000 nodes, 8 threads)

White's first-move advantage in pawns; negative = Black ahead. Chess: +0.29 (top engines +0.20 to +0.35).

| Army | Without the rule | With the rule |
|---|---|---|
| Wide 9b `AA(BR)QK(CV)2/(AS)B1(RM)(CV)(BR)G(AS)` | +1.05 (Af5) | +0.65 (Af5) |
| Wide 9c `1PBK1(NC)Q1/A1(AS)GG(SQ)AB` | +3.01 (Axb7!) | +0.18 (Ah3) |
| Wide 4c `EQ(RO)K(WW)(AS)1(NC)/BGB(RM)G(PD)(PD)(AS)` | +0.66 (Bxh7) | -0.21 (Gb3) |
| Wide 15a `1Q(BR)KCG1(NC)/BEB(AS)(AS)AG(PD)` | +3.06 (Bxf7+) | +0.42 (ASf3+) |
| Wide 11a `P1(AS)1K(AS)P(NC)/B(GA)N(SQ)(RM)ABQ` | +2.42 (Axa7!) | +0.24 (Qh3) |
| Wide 7c `2(CV)K(NC)(WW)B1/Q(AS)(BR)(GA)(CV)GEA` | +0.42 (Axc7!) | +0.12 (BRd3) |
| Wide 14a `(WW)QBKC2(CV)/1(BR)ABG(CV)P1` | +0.45 (Gf3+) | +0.37 (Gd3+) |
| Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | +3.03 (Axa8!) | +0.08 (e4) |
| Wide 4b `1PPK(BR)C(NC)1/A(AS)(WW)(BR)GBQ(PD)` | +0.18 (Qxb7) | +0.14 (Gd3) |
| Wide 15a `QE(WW)1KN(NC)(RM)/(AS)APB(BR)(PD)G(AS)` | +3.86 (Axg7!) | -0.41 (c3) |
| Standard `standard` | +0.13 (d4) | +0.07 (d4) |

With the rule: median +0.14; within ±0.35: 7 of 11; over +1: none; Black ahead by more than a pawn: none

## Success test

- White 52-55% in random armies (run 9: random armies don't depend on the pool): **yes** (52.7%)
- White 52-55% in the round robin: **no** (51.1%)
- No pool army's gap over 30 points: **yes** (none)
- No pairing with either colour at 80%+: **no** (1: Wide 11a vs Wide 7c (White 80.0%))
- Black not favoured (White at least 50%): **yes** (52.7%, 51.1%)
- **Result: FAILED**
