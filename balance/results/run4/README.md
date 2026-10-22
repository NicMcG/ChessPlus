# Balance run 4: the Quiet first move rule (AWS sims server, 22 October 2026)

Mac's candidate rule against first-move captures (see run 3): **neither player
may capture (or break a shield) or use an ability on their first move.**
Tested in Plusfish only (`--quiet-first-move=true`, branch
`experiment/quiet-first-move`, commits 9e4f396 and 29863bb), not in the game.
Full tables in `report.md` (`tools/balance/run4_analyse.py`).

| Part | What | Settings (as before, so they compare directly) |
|---|---|---|
| 1 | Run 3's meta pool round robin with the rule | 55 pairings x 40 games, 8,000 nodes, `--random-plies 4`, seeds 3000-3054 |
| 2 | Run 2's random-army self-play with the rule | 20,000 games, 8,000 nodes, seed 101, selfplay defaults |
| 3 | Each army against itself, without and with the rule | `plusfish analyse`, 2,000,000 nodes, 8 threads (`mirror.txt`) |

- Server: `chessplus-sims` (c8g.16xlarge, 64 cores). Games 06:24-06:35 UTC;
  server on 06:23-06:36, about $0.57, stopped through AWS.
- The script that played the games is `tools/balance/run4_server.sh` on the
  experiment branch. Game files (not in the repo):
  `C:\Users\Mac Wood\Documents\ChessPlusSims\run4\`.

## Result: the rule makes White's edge bigger

| | Without | With the rule |
|---|---|---|
| Random armies, White's score | 56.1% | **58.4%** |
| Random armies, White won both of a swapped pair | 12.6% | **16.7%** |
| Meta pool, White's score | 62.7% | 63.1% |
| Meta pool, pairings with White at 80%+ | 7 | 8 |

Why:

1. **First-move checkmates.** Black may not capture on its first move, so a
   check on White's first move that could only be answered by taking the
   checking piece is mate: Wide 15c and Wide 15a against themselves become mate
   in 1 (Wb6#, Wg6#). Any check on move 1 meets a Black side barred from
   capturing.
2. **White keeps the initiative.** Where both sides' pieces are exposed, White
   captures on move 2 instead of move 1: Wide 15b +3.30 -> +2.82, Wide 9b +3.04
   -> +2.88, Wide 14a +4.28 -> +2.38. Some armies did improve (Wide 14c
   +3.91 -> +0.48, Wide 11a +1.82 -> +0.19).

Run 3's success test still fails (3 pool armies over 30 points, 8 pairings at
White 80%+). The pool armies were grown under the old rules, so random armies
(part 2) are the fairer judge of a rule.
