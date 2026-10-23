# Balance run 9: White-only quiet first move (report)

Made by `tools/balance/run8_9_analyse.py`. Rule (Plusfish `--white-quiet-first=true`, branch `experiment/white-quiet-first`): White may not capture, break a shield or use an ability on its first move unless in check; Black's first move is unrestricted. "Control" = today's Plusfish, no rule, same seed. Points = percentage points.

## Random armies (20,000 games, 8,000 nodes, seed 101)

| | Games | White's score (95%) | Draws | White won both of a pair | White's 1st move captures/ability | Black's 1st move captures/ability | | Plies | Pawns per army |
|---|---|---|---|---|---|---|---|---|---|
| Control (no rule) | 20000 | 55.7% (55.1%-56.3%) | 23.5% | 12.3% | 23.7% | 20.6% |  | 129 | 3.4 |
| White-only quiet first move | 20000 | 52.7% (52.1%-53.3%) | 24.2% | 9.2% | 0.0% | 13.3% |  | 133 | 3.4 |

### Round robin: the current meta pool (run 7's) + Standard, with the rule (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000-3054). Run 7 is the same without the rule.

| | |
|---|---|
| Games | 2200 |
| White's score | 50.5% |
| White's first move a capture or ability | 0.0% |
| Black's first move a capture or ability | 38.9% |
| White won both games of a swapped pair (chess 23%) | 6.2% |

**Each army's gap (score as White minus score as Black, points, 95% range)**

| Army | Gap | As White | As Black |
|---|---|---|---|
| Wide 14a | +2.5 (-4.7 to +9.7) | 66.8% | 64.2% |
| Wide 15a | +5.0 (-1.8 to +11.8) | 64.8% | 59.8% |
| Wide 15c | +0.2 (-6.4 to +6.9) | 59.0% | 58.8% |
| Wide 13a | -0.5 (-8.4 to +7.4) | 52.2% | 52.8% |
| Wide 10a | -8.0 (-14.6 to -1.4) | 52.8% | 60.8% |
| Wide 11a | -4.5 (-11.7 to +2.7) | 37.0% | 41.5% |
| Wide 11c | +5.0 (-2.5 to +12.5) | 56.8% | 51.7% |
| Wide 13c | +5.8 (-2.5 to +14.0) | 48.0% | 42.2% |
| Wide 7c | +0.8 (-5.7 to +7.2) | 50.5% | 49.8% |
| Wide 14a (run 2) | +7.0 (-0.1 to +14.1) | 55.8% | 48.8% |
| Standard | -1.3 (-6.6 to +4.1) | 12.5% | 13.8% |

Pairings with either colour at 80%+: none

## Each army against itself (Plusfish at 2,000,000 nodes, 8 threads)

White's first-move advantage in pawns; negative = Black ahead. Chess: +0.29 (top engines +0.20 to +0.35).

| Source | Army | Without the rule | With the rule |
|---|---|---|---|
| run 4 | Wide 9b `1(NC)1K(BD)(AS)1B/L(GA)(AS)(RM)LQB(GA)` | +2.90 (Lxa7) | +0.42 (GAh3) |
| run 4 | Wide 12b `M(RO)1KN2Q/EN(BR)G(PD)A(AS)A` | +0.69 (Axa7) | -0.11 (ASg4) |
| run 4 | Wide 15b `(AS)P(BR)NKN(NC)1/B(AS)EQ(RM)(PD)AB` | +4.27 (Axb7) | +0.03 (Ah3) |
| run 4 | Wide 14b `(PD)Q(BR)NK(BR)(CV)P/A(GA)(RM)EGE(AS)(AS)` | +0.08 (Gf3) | +0.10 (Gf3) |
| run 4 | Wide 13c `C1(BR)K(RM)N(BR)P/BQG(AS)(RO)(PD)E(PD)` | +0.05 (Ne3) | +0.16 (Gd3) |
| run 4 | Wide 14c `QP(BR)NK(BR)P1/(AS)(AS)BB(RO)(PD)A(GA)` | +3.66 (Axb7!) | +0.22 (Ah3) |
| run 4 | Wide 14a `1(BR)ENK1Q(BR)/C(AS)(RO)EB(PD)AB` | +3.87 (Axb7!) | +0.17 (Bf3) |
| run 4 | Wide 15c `B(CV)(GA)CKNW(AS)/NB(NC)(PD)EPP(AS)` | +2.97 (Bxg7) | +0.29 (PDd3) |
| run 4 | Wide 15a `(RM)(BR)(GA)K(BD)PWP/PB(PD)(RM)BA(AS)(AS)` | +0.37 (Axa7) | +0.11 (AShh3) |
| run 5 (rule) | 2 `(PR)(AS)(GA)(PR)KQ(NC)E/5P2` | +0.91 (PRd5+) | +0.96 (PRd5+) |
| run 4 | Wide 11a `(CV)(NC)1(CV)K(RO)(BR)Q/(AS)(GA)(PD)(AS)NEPL` | +1.50 (Lxh7) | -0.08 (Nc1) |
| run 5 (rule) | 1 `J(SQ)(CT)KBMMB/PPPPV1PE` | +0.48 (g4) | +0.31 (g4) |
| run 4 | Standard `standard` | +0.11 (d4) | +0.13 (e4) |
| run 5 (rule) | 3 `(PR)(RM)VKE(BD)(CT)J/1P1(GA)P1(AS)1` | +0.23 (b4) | +0.26 (b4) |
| run 5 (rule) | 5 `(GA)(CT)NKJM(BD)(CT)/P(BR)PPPPPP` | +0.09 (f4) | +0.10 (f4) |
| run 5 (rule) | 4 `(CH)(CT)(PR)(CT)K(RO)NB/(AS)PNPPPPP` | +0.20 (g3) | +0.16 (g3) |
| run 5 (rule) | 6 `Q(NC)(NC)KVENJ/(AS)PPPPPPP` | +0.28 (b4) | +0.33 (b4) |
| run 5 (rule) | 8 `(GA)AGKV(RM)(NC)(RM)/(CH)E(BR)E(AS)P(AS)P` | +0.25 (Eb4) | +0.27 (Eb4) |
| run 5 (rule) | 9 `(CH)B(SQ)K1(NC)(PD)Q/PPPPPPPP` | +0.35 (c4) | +0.51 (c4) |
| run 5 (rule) | 11 `(CH)(GA)(RO)KQEEV/P1PPPPPP` | +0.31 (g3) | +0.26 (g3) |
| run 5 (rule) | 10 `RJ(CT)(CT)KE(PD)Q/PPPPPPPP` | +0.20 (g3) | +0.22 (g3) |
| run 5 (rule) | 7 `(PA)BQ(CV)KJ(CV)(CT)/PPP1P(AS)1(PD)` | +0.13 (CTg2) | +0.12 (CTg2) |
| run 5 (rule) | 12 `(PA)(GA)V(PR)K(BR)N(WW)/PPPPPPPP` | +0.34 (b4) | +0.14 (b3) |
| run 5 (rule) | 13 `(CH)(WW)AQK(SQ)(GA)M/(AS)PEE1P1P` | +0.14 (SQe2) | +0.20 (Ee4) |
| run 5 (no rule) | 21 `(NC)(CT)(SQ)KC(PD)A(BD)/1EL1EPPL` |  |  |
| run 5 (rule) | 14 `VE(BD)KM(BD)(PR)E/P(BR)PPPPPP` | +0.23 (BRb3) | +0.17 (BRb3) |
| run 5 (rule) | 16 `RVMJKM(CV)V/P(AS)(AS)PP(BR)P1` | +0.15 (AScc3) | +0.47 (g3) |
| run 5 (rule) | 15 `(CT)(RO)EK(BD)EN(NC)/(BD)PPPPPV1` | +0.02 (Vh3) | +0.00 (Ed3) |
| run 5 (rule) | 17 `V1(PR)BK(PD)(CT)(CV)/PPPPPPPP` | +0.28 (b4) | +0.42 (b4) |
| run 5 (rule) | 19 `(GA)(CT)(WW)GKN(PR)(PR)/P(AS)4P1` | +0.15 (Ge2) | +0.19 (CTc2) |
| run 5 (rule) | 18 `(PA)(PD)Q(RO)K(NC)NV/2(BR)(BR)1PP1` | +0.78 (Qa3) | +0.75 (Qa3) |
| run 5 (no rule) | 22 `(PA)(PR)(PD)KJ(WW)C(PA)/1B3L1P` | +11.40 (Cxg8+) | +7.07 (PRe4+) |
| run 5 (rule) | 20 `(CH)(AS)(CT)KB(NC)(SQ)R/PP1(BR)PJ(BR)(NC)` | +0.22 (b4) | +0.12 (BRf3) |
| run 5 (no rule) | 26 `Q(PR)(PR)K(AS)E(NC)(GA)/P1E5` | +4.73 (PRb5+) | +4.13 (PRb5+) |
| run 5 (no rule) | 23 `(CH)(AS)MKJN(WW)A/PPPPPLPP` | +0.56 (g3) | +0.55 (g3) |
| run 5 (no rule) | 32 `R(NC)VWK(GA)J(AS)/1E1P3E` |  |  |
| run 5 (no rule) | 24 `(AS)(PR)Q(AS)K(PD)N(BD)/PPP2LPP` | +0.29 (Qe3) | +0.44 (Qe3) |
| run 5 (no rule) | 28 `(PA)(NC)V(NC)KBWB/2(PD)P1PL1` | +3.73 (Lxg8=PD) | +3.62 (Wd4+) |
| run 5 (no rule) | 29 `EC(CV)KV(NC)(CV)J/(AS)PPPPEBL` | +1.47 (Bxb7) | +0.67 (Ed4) |
| run 5 (no rule) | 36 `(CH)Q(RM)VKEB(PA)/N2(CH)(AS)2P` | +99.00 (Bb6+) | +99.00 (Bb6+) |
| run 5 (no rule) | 25 `(PA)(RM)(CT)(PR)KM(RO)(SQ)/PP(AS)1PLPP` | +0.08 (PRd3) | +0.06 (PRd3) |
| run 5 (no rule) | 27 `(PA)(RM)(NC)(WW)K(PR)(GA)M/2EPPPPE` | +0.14 (g4) | +0.14 (e4) |
| run 5 (no rule) | 30 `(CT)AGK(NC)(PR)WC/1(AS)P4(PD)` | +1.98 (Cxh8) | +0.14 (CTa2) |
| run 5 (no rule) | 35 `(CH)(NC)NK(PR)(SQ)AC/(PD)3P(AS)2` | +0.49 (Cxh8) | +0.28 (PRa5) |
| run 5 (no rule) | 34 `(GA)AGKV(RM)(NC)(RM)/(CH)E(BR)E(AS)P(AS)P` | +0.35 (Eb4) | +0.41 (f3) |
| run 5 (no rule) | 31 `(PD)C(PD)KW(CV)(RO)C/P(PA)P(SQ)PP1P` | +0.18 (Cxb8) | +0.19 (ROe3) |
| run 5 (no rule) | 33 `(CH)AC(NC)KE(AS)(PA)/P(PD)PP(CT)PP(BR)` | +0.27 (c4) | +0.25 (c4) |
| run 5 (no rule) | 38 `(PA)(PD)VK(AS)(CV)WN/1(BR)1(CV)(AS)(RM)2` | +0.54 (CVc3) | +0.69 (CVc3) |
| run 5 (no rule) | 37 `(CH)(RO)(RO)KE(SQ)C(PD)/PNP(RM)PPPL` | +0.23 (f4) | +0.18 (ROd3) |
| run 5 (no rule) | 39 `RWVK(CT)JE(PA)/1(GA)2E1(GA)(AS)` | +0.62 (Ra4) | +0.24 (Vd2) |
| run 5 (no rule) | 40 `RC(GA)KB(CT)(NC)(PA)/P(PD)PPPP(AS)J` | +0.11 (Cxb7) | +0.21 (Jf4) |
| current pool | Wide 14a `(NC)(WW)ENKQPA/GB(AS)(CV)PG1(AS)` | +2.90 (Axa8!) | +0.06 (Gf3) |
| current pool | Wide 15a `QE(WW)1KN(NC)(RM)/(AS)APB(BR)(PD)G(AS)` | +3.93 (Axg7!) | -0.41 (c3) |
| current pool | Wide 15c `EQ(RO)K1(AS)(WW)(NC)/(PD)GB(RM)GB(PD)(AS)` | +0.16 (Bxh7*) | +0.03 (Gc3) |
| current pool | Wide 11a `1(WW)GK(NC)(CV)(GA)R/(AS)BB(CV)GE(PD)L` | +0.21 (Lxh7) | +0.09 (Gf3) |
| current pool | Wide 13a `(NC)PQPK(GA)P(CV)/EBAGPEGP` | +0.10 (Gf3) | +0.08 (Gf3) |
| current pool | Wide 10a `1Q1KGE(NC)C/B(AS)BG(BR)(AS)(PD)A` | +4.04 (Bxf7+) | -0.11 (Bab3) |
| current pool | Wide 11c `1Q1NKPP(NC)/(RM)(SQ)(CV)(AS)(RM)A(WW)(AS)` | +0.13 (SQc3) | +0.12 (SQc3) |
| current pool | Wide 13c `P(CV)NCK(BR)1B/(AS)G(BR)LV(RM)B(AS)` | +3.86 (Lxd7+) | -0.04 (Be4) |
| current pool | Wide 7c `1G1NKQG1/BA(AS)(RM)(CV)(BR)(AS)(CH)` | +4.13 (Axg7!) | +3.01 (Be6) |
| current pool | Wide 14a (run 2) `1(BR)ENK1Q(BR)/C(AS)(RO)EB(PD)AB` | +3.77 (Axb7!) | +0.15 (Bf3) |
| current pool | Standard `standard` | +0.05 (Nc3) | +0.20 (d4) |

Without the rule: median +0.33; within +0.35: 33 of 60; over +1: 18; Black ahead (below 0): 0; Black ahead by more than a pawn: 0

With the rule: median +0.20; within +0.35: 43 of 60; over +1: 5; Black ahead (below 0): 5; Black ahead by more than a pawn: 0

Armies starting with Black ahead by more than a pawn with the rule: none

## Success test

- White 52-55% in random armies: **yes** (52.7%)
- White 52-55% in the round robin: **no** (50.5%)
- No pool army's gap over 30 points: **yes** (none)
- No pairing with either colour at 80%+: **yes** (none)
- Black not favoured (White at least 50%): **yes** (52.7%, 50.5%)
- **Result: FAILED**
