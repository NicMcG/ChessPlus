# Balance run 12: separate White and Black armies, the split search in phases (AWS sims server, 24 October 2026)

Run 11 grew a White pool and a Black pool side by side, both colours every
round, and neither settled. This run tries the fix proposed there: **grow one
colour at a time against the other pool frozen** (`meta --split-colours
--phase 5`, new): five rounds for White against the Black pool as it stands,
then five for Black against the White pool, and so on, 30 rounds (15 each, as
run 11). Everything else as run 11: same two rule sets (normal; the White-only
quiet first move), same starting pools (run 7's; run 10's), then specialists
against specialists and against the ordinary pool with fixed colours, 40 games
a pairing, 8,000 nodes, `--random-plies 4`. Report only (Mac's choice). Full
tables in `report.md` (`tools/balance/run11_analyse.py --title ... --note ...`).

- Branch `experiment/colour-armies`, commit 0cbc2db (Plusfish's `--phase`
  added on top of run 11's code). Not a game rule.
- **Server:** `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores), 06:09-08:51
  UTC (about 2.7 hours, roughly $7 metered), stopped through AWS. Scripts:
  `tools/balance/run12_server.sh` (that branch). Game files (not in the repo):
  `Documents\ChessPlusSims\run12\`.

## Result: the phases don't settle the search either; they make it cycle

| | Normal rules | | White-only quiet first move | |
|---|---|---|---|---|
| | run 11 (both colours every round) | **run 12 (phases)** | run 11 | **run 12** |
| Ordinary pool's round robin: White (baseline) | 59.4% | 59.4% | 51.1% | 51.1% |
| Specialists against specialists: White | 57.6% | **36.8%** (35.6-37.9) | 48.0% | **43.3%** (42.1-44.4) |
| White specialists against the ordinary pool as Black | 60.3% | 51.5% | 45.5% | 48.9% |
| Ordinary pool as White against Black specialists | 51.3% | 60.3% | 53.3% | 52.9% |
| White's first move a capture or ability (specialists) | 53.7% | 39.6% | 0% | 0% |
| Black's first move a capture or ability (specialists) | 39.8% | 50.4% | 37.5% | 41.0% |

- **Both colour pools lose to the all-rounders.** Under the normal rules the
  White specialists score 51.5% against the ordinary pool playing Black (the
  ordinary pool scores 59.4% against itself), and the ordinary pool scores
  60.3% as White against the Black specialists. Under the rule it's 48.9% and
  52.9% against a 51.1% baseline. Run 11's one clear gain, Black's 8 points
  under the normal rules, is gone.
- **Black "wins" specialists against specialists only because it went last.**
  The phases ran White, Black, White, Black, White, Black, so the final Black
  pool was tuned against the final White pool and not the reverse: 36.8% and
  43.3% for White measure the order of the phases, not the colours.
- **The pools cycle instead of converging.** The meta log (`meta_pool.log`)
  shows each growing side's armies shooting up against the frozen opponent and
  collapsing the moment the opponent's phase begins. Normal rules, the White
  pool's new armies (game Elo as White against the Black pool): after White's
  phases +104 to +268 (round 5), +117 to +259 (15), +177 to +424 (25); after
  the Black phase that followed each: -50 to +87 (10), -279 to +22 (20),
  -296 to +32 (30). The Black pool does the same the other way. Each pool is
  a set of counters to the opponents it last saw, and a new set of opponents
  undoes it. Under the rule the swings are smaller (White after round 25: -46
  to +168; after 30: -178 to +18) but the shape is the same.
- **The all-rounder is the only steady army.** Run 7's Wide 14a, carried into
  the White pool, stays at +92 to +217 as White through every phase and tops
  the White pool at the end (62.9% against the Black pool); the nine White
  specialists around it score 15-55%. The same army scored 63% as White and
  34% as Black in run 11's specialist games.
- **What the specialists look like now:** under the normal rules the White
  pool took Lances (8 of 10 armies), Necromancers (all 10) and almost no
  Archers (2 in 10 armies), and the Black pool Werewolves (7), Barbarians (7)
  and Elephants (7): tuned to what the other pool had at the time, and not
  strong in general (51.5% / 39.7% against the all-rounders). Under the rule
  both pools look like run 10's pool (Bishop, Queen, Archer, Assassin, Ghost,
  Necromancer in most armies), with run 10's Wide 11a and Wide 4c surviving in
  the Black pool.

## What this says

- The design question (do separate White and Black defaults change the game?)
  isn't answered by this search, in either form. Judging a colour's armies
  against a small opponent pool that is itself being searched, whether it moves
  every round (run 11) or is frozen in phases (run 12), finds counters to those
  ten opponents, not armies that are good as that colour in general. A fairer
  method would judge each colour against a **fixed, broad opponent set that
  never changes**, for example the all-round pool itself: "the best White
  armies against strong all-rounders playing Black", which is exactly what a
  player with a Black default faces. That's a different, cheaper run (each
  colour's search is independent, no cycling), if Mac wants it.
- Run 11's normal-rules numbers remain the better guide for now: a Black-only
  army gains about 8 points against all-rounders, a White-only army about 1,
  and the Black armies that do it keep long-range pieces out of the front row.
  Run 12 shows how fragile such armies are once the opponents change.

These are engine-vs-engine results, not human play. Balancing decisions are
Mac's.
