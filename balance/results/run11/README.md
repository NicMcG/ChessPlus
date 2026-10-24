# Balance run 11: separate White and Black armies (AWS sims server, 24 October 2026)

Players can set a default army for each colour, used when the colour is decided
at random. Mac's question: what armies does Plusfish come up with when it may
have a different army for White and for Black, and how do they play? Report
only, no pass/fail (Mac's choice). Two rule sets: the normal rules, and the
White-only quiet first move (runs 9-10). Tested in Plusfish only, on branch
`experiment/colour-armies` (commit c317656, built on run 9's branch), not in
the game. Full tables in `report.md` (`tools/balance/run11_analyse.py`).

**How the colour pools were grown.** A new Plusfish mode, `meta --wide
--split-colours`, grows a White pool and a Black pool side by side. A White
army is judged only by its eval and games *as White* against the Black pool,
and the other way round; each round climbs and plays games for each colour in
turn, and the pools are written as `meta_pool_white.txt` / `meta_pool_black.txt`.
Settings as run 2's pool growth (`--wide 64 --game-climb --king-exposed reject
--rounds 15 --seed 1`), starting from that rule set's ordinary pool plus
Standard: run 7's pool for the normal rules, run 10's for the rule.

For each rule set (`normal/`, `rule/`):

| Part | What | Settings |
|---|---|---|
| 1 | White pool and Black pool (`meta_pool_white.txt`, `meta_pool_black.txt`, `meta_pool.log`) | as above |
| 2 | Specialists against specialists: every White army against every Black army | 40 games a pairing, **colours fixed** (`match --fixed-colours`, new), 8,000 nodes, `--random-plies 4`, seeds 4000 + pairing |
| 3 | Specialists against all-rounders: the White armies against the ordinary pool playing Black (seeds 5000+), and the ordinary pool playing White against the Black armies (seeds 6000+) | same |

The baseline is the ordinary pool's own round robin, where every army plays
both colours: run 7 (normal rules, White 59.4%) and run 10 (the rule, 51.1%).

- **Server:** `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores), 03:09-05:52
  UTC (about 2.7 hours, roughly $7 metered), stopped through AWS. The rule
  half's first start failed at once (run 10's pool file wasn't on the branch
  on the server; now it is) and was restarted at 04:25. Scripts:
  `tools/balance/run11_server.sh` (branch `experiment/colour-armies`). Game
  files (not in the repo): `Documents\ChessPlusSims\run11\`.
- "Uneven matchups" counts pairings with either side at 80%+ over 40 games,
  Standard left out. With fixed colours that mixes army strength with colour
  (a strong White army against a weak Black one), so it isn't the colour test
  of runs 3-10.

## Results

| | Normal rules | White-only quiet first move |
|---|---|---|
| Ordinary pool's round robin: White (baseline) | 59.4% | 51.1% |
| **Specialists against specialists: White** | **57.6%** (56.4-58.7) | **48.0%** (46.9-49.1) |
| White specialists against the ordinary pool as Black | 60.3% (White gains +1.0 points) | 45.5% (White loses 5.6 points) |
| Ordinary pool as White against Black specialists | 51.3% (Black gains +8.0 points) | 53.3% (Black loses 2.3 points) |
| White's first move a capture or ability (specialists) | 53.7% (ordinary 59.4%) | 0% |
| Black's first move a capture or ability (specialists) | 39.8% (ordinary 47.5%) | 37.5% (ordinary 33.7%) |
| Uneven matchups, specialists (of 100) | 28 | 22 |

### Normal rules: specialising helps Black much more than White

- A Black army built only to play Black gains about **8 points** against the
  ordinary pool (the ordinary pool's White score falls from 59.4% to 51.3%). A
  White army built only to play White gains about **1 point** (60.3%). So with
  separate default armies, White's edge between strong players shrinks a
  little: 57.6% specialists against specialists, against 59.4%.
- **What the Black armies look like:** fewer long-range pieces in the front row
  (1.9 each, against 2.7 in the White pool), more Paladins (6 of 10 armies,
  against 3), the Assassin, Bishop and Queen in all ten. Black's armies avoid
  pieces that White can capture on move 1 and keep cheap blockers; Black's
  own first-move captures fall from 47.5% to 39.8%.
- **What the White armies look like:** more pawns (2.0 each, 7 of 10 armies),
  more front-row strikers (2.7 long-range pieces), Rams in 5 and Cannons in 4,
  and the only Lance, Princess, Wizard and Chariot in either pool. White still
  captures on move 1 in 54% of games.
- One army (run 7's Wide 14a) is in both pools: it scores 63% as White but only
  34% as Black against the specialists.

### White-only quiet first move: with specialists, Black comes out ahead

- Specialists against specialists: **White 48.0%**, the first setting in any
  run where Black is ahead overall. Against the ordinary pool, though, the
  White specialists scored *worse* than the ordinary pool does as White (45.5%
  against 51.1%), and the Black specialists also did slightly worse than the
  ordinary pool as Black (53.3% against 51.1%): both colour pools are weaker
  than the all-rounders they started from.
- Why, most likely: in split mode each colour's armies are judged only against
  the other pool, which keeps changing, so the search has a moving target and
  half the games to learn from. Under the rule the White pool never settled:
  three of its ten armies score under 40% as White against the Black pool
  (Wide W11a 37%, W12c 30%, W10a 26%), and six of ten were replaced in the
  last six rounds. Treat the rule's numbers as a first look, not a measurement.
- Still worth noting: under the rule the White pool **drops the Queen** (6 of
  10 armies, against 10 of 10 in the Black pool) and takes Wizards (4) and
  Paladins (6), while the **Black pool becomes the striker**: 3.1 long-range
  pieces in its front row against the White pool's 2.7, and Black captures or
  uses an ability on its first move in 37.5% of games. When White can't strike
  first, exposed pieces cost White and pay Black.
- Two armies from run 10's pool (Wide 7c and Wide 4c) are in both colour
  pools, scoring 55-63% either way.

## What this says about separate default armies

Engine play, 15 rounds of search, one seed: strong hints only.

1. Under the normal rules, letting players pick a Black army is mostly a gift
   to Black: a defensive Black army (few exposed long-range pieces, Paladins,
   Assassins) claws back about 8 of White's points, and a White army gains
   little beyond what a good all-round army already has. It doesn't remove
   White's edge (still about 58%), because first-move captures still happen in
   half the games.
2. Under the White-only quiet first move, the picture flips: Black can afford
   strikers and White can't, and the only measured result (48% for White) has
   Black ahead. That needs a better-settled search before it's trusted.
3. The split search itself needs work before another run: judge each colour
   pool against a *fixed* opponent pool for a round (or play more games), so
   the two pools don't chase each other. Mac's call whether to pursue it.

These are engine-vs-engine results, not human play. Balancing decisions are
Mac's.
