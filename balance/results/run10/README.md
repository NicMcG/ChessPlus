# Balance run 10: the White-only quiet first move with strong armies (AWS sims server, 24 October 2026)

Run 9 tested Mac's White-only quiet first move (White may not capture, break a
shield or use an ability on its first move unless in check; Black's first move
is unrestricted) with random armies and with the normal meta pool. This run
grows a meta pool **with the rule on**, so the strongest armies are the ones
that do best under it (as run 6 did for the Front-row rule), then plays the
round robin on it. Tested in Plusfish only (`--white-quiet-first=true`, branch
`experiment/white-quiet-first`, commit 49adaf3), not in the game. Full tables
in `report.md` (`tools/balance/run10_analyse.py`).

| Part | What | Settings |
|---|---|---|
| 1 | Meta pool grown with the rule (`meta_pool.txt`, `meta.log`; also kept as `engine/plusfish/reports/meta_pool_white_quiet_first.txt`) | `meta --wide 64 --game-climb --king-exposed reject --rounds 15 --seed 1` (run 2's settings), from the official pool (run 7's) plus Standard |
| 2 | Round robin of the new pool + Standard, with the rule | run 3's settings: 40 games a pairing (20 per colour), 8,000 nodes, `--random-plies 4`, seeds 3000-3054 |
| 3 | Each pool army against itself, without and with the rule | `plusfish analyse`, 2,000,000 nodes, 8 threads (`mirror.txt`) |

- **Plusfish:** the same engine as runs 6-9 (Nicholas's PR #26), plus the
  experiment switch. Pieces at today's prices.
- **Server:** `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores), 00:21-01:09
  UTC on 24 Oct (about 48 minutes, roughly $2 metered), stopped through AWS.
  The rule was checked with perft before the games. Script:
  `tools/balance/run10_server.sh` (branch `experiment/white-quiet-first`).
  Game files (not in the repo): `Documents\ChessPlusSims\run10\`.

## Result: very close, but the success test fails on two lines

| Success test (Mac's, as for runs 8 and 9) | Result |
|---|---|
| White 52-55% in random armies | **yes**: 52.7% (run 9; random armies don't depend on the pool) |
| White 52-55% in the round robin | **no**: 51.1% (95% range 49.5-52.7) |
| No pool army's gap over 30 points | **yes**: the biggest is +11.3 (Wide 11a) |
| No pairing with either colour at 80%+ | **no**: one, Wide 11a vs Wide 7c, White exactly 80.0% (32 of 40 points) |
| Black not favoured (White at least 50%) | **yes**: 52.7% and 51.1% |

Both misses are at the edge: the round robin's range reaches 52.7%, and the one
lopsided pairing is exactly on the 80% line, with a wide range from 40 games.

- **Against themselves**, the pool armies start median +0.14 with the rule
  (chess +0.29); none over +1, none with Black more than a pawn ahead (lowest
  -0.41). Without the rule, 5 of these 10 armies start about +2.4 to +3.9
  through a first-move capture (1. Axg7!, 1. Bxf7+, ...): the pool still
  favours armies that can strike early, which the rule takes away from White
  but leaves to Black.
- **First moves in the round robin:** Black's first move is a capture or
  ability in 33.7% of games (run 9 with the normal pool: 38.9%). White won
  both games of a colour-swapped pair only 4.7% of the time (chess about 23%,
  run 9 6.2%, run 7 12.5%).
- **The pool:** Bishop and Queen in all 10 armies, Archer, Assassin and Ghost
  in 9, Necromancer in 8; 18 piece types in all (run 7's pool had 22). Few
  pawns (0-2 each). Two pairs of armies share a name ("Wide 14a", "Wide 15a"),
  a naming clash in Plusfish's meta command; their numbers are kept apart.

## Compared with the other runs

| Run | Change | Pool | Random: White | Round robin: White | Biggest gap | Pairings 80%+ | Passes? |
|---|---|---|---|---|---|---|---|
| Control + run 7 | none | normal (run 7's) | 55.7% | 59.4% | +31.2 | 3 | no |
| 6 (with run 5) | Front-row rule | grown under it | 52.0% | 51.0% | +14.5 | 1 (82.5%) | no |
| 9 | White-only quiet first move | normal (run 7's) | 52.7% | 50.5% | +7.0 | 0 | no (round robin under 52%) |
| **10** | **White-only quiet first move** | **grown under it** | 52.7% | **51.1%** | **+11.3** | **1 (80.0%)** | **no (round robin under 52%, one pairing at 80%)** |

The full table of runs 2-9 is in `balance/results/run9/README.md`.

These are engine-vs-engine results, not human play: strong hints, not proof.
Balancing decisions are Mac's.
