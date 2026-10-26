# Balance run 16: the meta by share (AWS sims server, 26 October 2026)

Mac's question (26 Oct 2026): where do the bots think the meta is now, with
the rules and prices of 24-25 October, but not as a top-10 pool: as a
**percentage breakdown of the armies in the meta**, with similar builds
counted as one archetype, **split into White-only armies, Black-only armies
and all-round armies** (all-rounders counted where they hold up against the
colour specialists). Report only, no pass/fail lines.

## Method

Plusfish is Nicholas's build of PR #28 (every rule the game has, retrained
weights) with the split-colours meta search merged in (branch
`experiment/meta-share`). Four independent runs of everything ("seeds"), so
the percentages come from a population rather than one search's ten armies:

| Phase | What | Settings |
|---|---|---|
| 1 | 4 all-round searches **from scratch** (Standard plus random climbers; no starting pool, so the official pool doesn't steer them), 10 armies each -> 40 all-rounders | `meta --wide 64 --game-climb --king-exposed reject --rounds 12 --seed 1..4`, two searches at a time with 32 threads each |
| 2 | the opponent set for the specialists: the top 3 of each all-round pool (12 armies), frozen | |
| 3 | 4 specialist searches: a White pool and a Black pool each, judged only as that colour against the opponent set -> 40 White specialists, 40 Black specialists | `--split-colours --fixed-opponent --pool opponents.txt`, same settings |
| 4 | all-rounders against the specialists: every all-rounder as White against every Black specialist, every White specialist against every all-rounder as Black | 20 games a pairing, colours fixed, 8,000 nodes, `--random-plies 4` (3,200 pairings) |

**Archetypes** (`tools/balance/run16_analyse.py`): an army is its piece
list, placement ignored. Two armies are "similar" when the points they have
in common (summing the lesser count of each piece type, times its cost) are
at least 70% of the budget; archetypes are built greedily from the most
central armies and named by the pieces most of their members share. The
report gives each archetype's share of the all-rounders, of the White
specialists and of the Black specialists, with an example army, plus the
all-rounders that score 50% or more both as White against the Black
specialists and as Black against the White specialists.

- Server: `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores). Script:
  `tools/balance/run16_server.sh` (the branch). Expected: about 6-7 hours,
  roughly $17 metered.
- Game files (not in the repo): `Documents\ChessPlusSims\run16\`.

## Results

(pending)
