# Balance run 14: the 24 October prices and the ability rule (AWS sims server, 25 October 2026)

Mac's update of 24 Oct 2026 went into the game: budget **40**, Queen 10,
Bishop 3.5, Rook 4.5, Werewolf 3.5, Parapet 2.5, Jester 3.5, and a new rule:
**a special ability can't be used until the piece has moved at least once; a
capture or a shield break counts as a move even when the piece stays put.**
Plusfish didn't know the rule, so this run teaches it on a branch
(`experiment/run14`, `--abilities-need-move=true`) and measures both changes.
Normal rules otherwise (no first-move rule). Two arms:

| Arm | What |
|---|---|
| **A** | the new prices and budget 40 (Plusfish's own `BUDGET` raised to 40 too, so its random armies and meta pool follow) |
| **B** | arm A plus the ability rule (`--abilities-need-move=true`) |

**Haunt under the rule (Claude's reading of Mac's wording, as the game does
it):** a Ghost captured before it ever moved can never Haunt; one that had
moved Haunts as before. Crack Shot counts as the Archer's move. A piece
brought back by Raise Dead counts as moved, so it may use its ability at once.

## Success lines (written before the run)

Prices (arm A, 20,000 random-army games; "worth" = what one extra piece at
the start is worth by game results, on the cost scale):

1. Each repriced piece (Queen 10, Bishop 3.5, Rook 4.5, Werewolf 3.5,
   Parapet 2.5, Jester 3.5) has its worth within **0.5** of its new cost.
2. No piece is more than **1.0** off its cost (run 2's worst was the Queen,
   +1.1 at 9).

The ability rule (arm B against arm A):

3. The five ability pieces (Archer, Necromancer, Ghost, Bard, Werewolf) each
   stay within **1.0** of cost under the rule, and none loses more than
   **0.5** of worth from A to B (the rule shouldn't gut them; if one does
   drop, that's a price question for Mac).
4. White's edge is not made bigger by the rule: B's White score in random
   armies is no higher than A's (B's 95% range overlaps or sits below A's),
   and B's regrown-pool round robin passes Mac's standing lines: White
   50-55%, no pool army's White-minus-Black gap over 30 points, no pairing
   with either colour at 80%+.
5. First moves: under B no game starts with a special ability (0%), and
   White's first-move capture share in B is no higher than A's.
6. Diversity: B's regrown pool uses at least as many piece types as A's (or
   within 2), and at least 3 of the 5 ability types still appear in B's pool
   (the rule mustn't make ability pieces not worth buying).

Report only for the colour specialists (3) and the mirror matches (4): no
pass line, they show how the strongest armies play under the rule.

## Before the run: does Plusfish agree with the game?

- `plusfish perft-suite` (standard positions): must match.
- Traced games: the game's own engine (`engine/plusfish/verify/plusfish_trace.gd`,
  main at dd06e19, which has the rule) played 320 random games leaning towards
  the ability and shield pieces (Archer, Necromancer, Ghost, Bard, Werewolf,
  Paladin, Vampire; no Jesters, whose two-Jester choice Plusfish doesn't know),
  logging every position's FEN, full legal move list, check and outcome.
  `plusfish trace-check` with `--abilities-need-move=true` must give **0
  mismatches**; without the flag it must give **some** (proof the traces
  exercise the rule). Results below.

## Parts and settings

| Part | What | Settings |
|---|---|---|
| (1) | balance report, both arms (`A/report.txt`, `B/report.txt`, `.html`) | `selfplay --games 20000 --nodes 8000 --seed 101` (budgets 34-40), `values` |
| (2) | the all-round pool regrown, both arms (`meta_pool.txt`, `meta.log`), then run 10's colour test on it (`rr/`) | `meta --wide 64 --game-climb --king-exposed reject --rounds 15 --seed 1` from run 7's pool; round robin of the pool + Standard, 40 games a pairing (20 per colour), 8,000 nodes, `--random-plies 4`, seeds 3000+ |
| (3) | B: run 13's colour specialists from B's regrown pool (`split/`) | `meta --split-colours --fixed-opponent` (B's pool + Standard frozen as the opponent); specialists vs specialists (seeds 4000+), White specialists vs the pool as Black (5000+), the pool as White vs Black specialists (6000+); 40 games a pairing, colours fixed |
| (4) | B: each regrown-pool army against itself (`mirror.txt`) | `plusfish analyse`, 2,000,000 nodes, 8 threads, with the rule and without |
| (5) | move-1 tally over every game of each arm (`firstmoves.jsonl`) | new `plusfish first-moves`: White's first move's kind, mover, target, check, whether Black could capture the mover back and whether it did |
| (6) | piece-type diversity of the pools | from the pool files (`tools/balance/run14_analyse.py`) |

- Server: `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores), `--threads 64`.
  Script: `tools/balance/run14_server.sh` (branch `experiment/run14`).
  Game files (not in the repo): `Documents\ChessPlusSims\run14\`.
- Expected: about 4 hours, roughly $10 metered.

## Results

(pending)
