# Balance run 9: White-only quiet first move (AWS sims server, 23 October 2026)

Mac's candidate rule against White's first-move edge: **White may not capture,
break a shield or use an ability on its first move, unless White is in check.
Black's first move is unrestricted.** Tested in Plusfish only
(`--white-quiet-first=true`, branch `experiment/white-quiet-first`, commit
78f6fd2: run 4's switch plus this one), not in the game. Run alongside run 8;
full tables in `report.md` (`tools/balance/run8_9_analyse.py`).

| Part | What | Settings (as runs 2-5, so they compare) |
|---|---|---|
| 0 | **Control** (added): random armies, today's Plusfish, no rule | 20,000 games, 8,000 nodes, seed 101 (`report_control.txt` / `.html`) |
| 1 | Random armies with the rule | 20,000 games, 8,000 nodes, seed 101, selfplay defaults (`report_8k.txt` / `.html`) |
| 2 | Round robin: the current meta pool (run 7's) + Standard, with the rule | 55 pairings x 40 games (20 per colour), 8,000 nodes, `--random-plies 4`, seeds 3000-3054 |
| 3 | Each army against itself, without and with the rule | `plusfish analyse`, 2,000,000 nodes, 8 threads: run 4's 11 armies, run 5's 40, the current pool's 11 (`mirror.txt`) |

- **Plusfish version:** main at de87b38 for the control; the branch for the
  rule. Plusfish's engine hasn't changed since runs 6 and 7 (2a93f06, with
  Nicholas's PR #26). Runs 2, 4 and 5 used the Plusfish from before PR #26,
  which is why the control was added: it's run 2 again on today's engine
  (White 55.7% against run 2's 56.1%).
- **Server:** `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores), 04:50-05:11
  and 17:23-19:09 UTC on 23 Oct (about 2.1 hours for runs 8 and 9 together,
  roughly $5.40 metered), stopped through AWS. The rule was checked with perft
  before any games (`progress_driver.log`).
- **Interruption:** the server's idle switch-off stopped it at 05:10 UTC, during
  part 3. That check only counts programs named exactly `plusfish`, and the
  driver had copied the builds as `pf-main` / `pf-wq`. Parts 0-2 had finished;
  part 3 was redone in full at 17:24 (`tools/balance/run8_run9_resume.sh` on
  branch `experiment/cheap-pawns`; the driver there is fixed too).
- Scripts: `tools/balance/run9_server.sh` (branch
  `experiment/white-quiet-first`); `tools/balance/run8_run9_driver.sh` and
  `run8_run9_resume.sh` (branch `experiment/cheap-pawns`). Game files (not in
  the repo): `Documents\ChessPlusSims\run9\`.

## Result: the closest yet, but the success test fails on one line

| Success test (Mac, decided before running) | Result |
|---|---|
| White 52-55% in random armies | **yes**: 52.7% (52.1-53.3) |
| White 52-55% in the round robin | **no**: 50.5% (95% range 48.9-52.2) |
| No pool army's gap over 30 points | **yes**: the biggest is +7.0 (Wide 14a (run 2)); run 7 had +31.2 |
| No pairing with either colour at 80%+ | **yes**: none (run 7 had 3) |
| Black not favoured (White at least 50%) | **yes**: 52.7% and 50.5% |

The one miss is close: the round robin's 95% range reaches 52.2%.

- **Black's first move:** captures or uses an ability in 13.3% of random-army
  games (control 20.6%) and in 38.9% of round-robin games (run 7: 47.5%).
  White wins both games of a colour-swapped pair 9.2% of the time (control
  12.3%; chess about 23%).
- **No army starts with Black more than a pawn ahead.** Against itself, the
  lowest with the rule is -0.41 (Wide 15a). Median +0.20 with the rule
  against +0.33 without (chess +0.29); 43 of 60 within ±0.35 (33 without).
  Still over +1 with the rule: 5 armies, e.g. Wide 7c +3.01 (1. Be6, then the
  capture on move 2).
- Two of run 5's no-rule armies gave no evaluation either way (most likely
  the game is already over at the start, e.g. King exposed), so 60 of 62 armies
  have scores.

## All runs compared

Random armies: 20,000 games, 8,000 nodes, seed 101. Round robin: a meta pool
plus Standard, 40 games a pairing, 8,000 nodes, `--random-plies 4`.
"80%+" counts pairings with either colour at 80% or more (earlier READMEs
counted White only; it makes no difference to their numbers). Old Plusfish =
before Nicholas's PR #26; today's = after.

| Run | Change | Plusfish | Random: White | Random: White's 1st move captures | Random: Black's 1st move captures | Round robin: White | Biggest gap | Gaps over 30 | Pairings 80%+ | Passes? |
|---|---|---|---|---|---|---|---|---|---|---|
| 2 (+ run 3's round robin) | none | old | 56.1% | 23.5% | 20.8% | 62.7% | +41.0 | 2 | 7 | no |
| **Control** (+ run 7's round robin) | none | today's | 55.7% | 23.7% | 20.6% | 59.4% | +31.2 | 1 | 3 | no |
| 4 | Quiet first move (both sides) | old | 58.4% | 0% | 0% | 63.1% | +59.2 | 3 | 8 | no |
| 5 (+ run 6's round robin) | Front-row rule | old (run 6: today's) | 52.0% | 2.3% | 2.5% | 51.0% | +14.5 | 0 | 1 | no (round robin 51.0%, one pairing 82.5%) |
| 8 | Pawn 0.75 | today's | 56.1% | 24.8% | 21.3% | 64.2% | +41.8 | 5 | 8 | no |
| 8 | Pawn 0.5 | today's | 56.5% | 26.0% | 22.4% | 62.3% | +40.2 | 3 | 9 | no |
| **9** | **White-only quiet first move** | today's | **52.7%** | 0% | 13.3% | **50.5%** | **+7.0** | **0** | **0** | **no (round robin 50.5%, just under 52%)** |

Target: White 52-55% in both, gaps 30 or under, no 80% pairings, White at
least 50%. Chess, for scale: strong players' White scores 54-56%; Plusfish at
8,000 nodes gives White 59.7% in plain chess (run 3), and 48.1% at 32,000.

These are engine-vs-engine results, not human play: strong hints, not proof.
Balancing decisions are Mac's.
