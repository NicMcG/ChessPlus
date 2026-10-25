# Balance run 13: separate White and Black armies, each colour judged against the all-round pool (AWS sims server, 24-25 October 2026)

The third try at Mac's question (runs 11 and 12): players can set a default
army for each colour, used when the colour is decided at random, so what does
Plusfish build when it may have a different army for White and for Black, and
how do they play? Runs 11 and 12 judged each colour's armies against the
*other colour's* pool, which was itself being searched; the pools chased each
other (11) or cycled (12), and the "specialists" they found lost to ordinary
all-round armies. Here each colour is judged against a **fixed, broad opponent
set that never changes**: the ordinary all-round pool (run 7's; run 10's for
the rule) plus Standard, frozen for the whole run. A White army is judged only
as White against those all-rounders playing Black, which is exactly what a
player faces against someone's Black default; a Black army only as Black
against them playing White. The two searches are independent, so nothing can
cycle. Plusfish's `meta --wide --split-colours --fixed-opponent` (new), branch
`experiment/colour-armies`, commit 095369e. Not a game rule. Report only
(Mac's choice). Full tables in `report.md` (`tools/balance/run11_analyse.py`).

For each rule set (`normal/`, `rule/`), as runs 11 and 12:

| Part | What | Settings |
|---|---|---|
| 1 | White pool and Black pool (`meta_pool_white.txt`, `meta_pool_black.txt`, `meta_pool.log`) | `meta --wide 64 --game-climb --king-exposed reject --rounds 15 --seed 1 --split-colours --fixed-opponent` (run 2's settings), opponent = the ordinary pool + Standard, frozen |
| 2 | Specialists against specialists: every White army against every Black army | 40 games a pairing, colours fixed, 8,000 nodes, `--random-plies 4`, seeds 4000 + pairing |
| 3 | Specialists against the all-rounders: the White armies against the ordinary pool playing Black (seeds 5000+), the ordinary pool playing White against the Black armies (seeds 6000+) | same |

- **Server:** `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores), 21:57 UTC
  24 Oct to 00:29 UTC 25 Oct (about 2.5 hours, roughly $6.50 metered),
  stopped through AWS. Script: `tools/balance/run13_server.sh` (that branch).
  Game files (not in the repo): `Documents\ChessPlusSims\run13\`.
- The normal-rules colour pools are kept as
  `engine/plusfish/reports/meta_pool_split_white.txt` / `_black.txt`
  (replacing run 11's, which hadn't settled).
- "Uneven matchups" counts pairings with either side at 80%+ over 40 games,
  Standard left out; with fixed colours that mixes army strength with colour.

## Result: this time both colour pools beat the all-rounders, and the search settled

| | Normal rules | White-only quiet first move |
|---|---|---|
| Ordinary pool's round robin: White (baseline) | 59.4% | 51.1% |
| White specialists against the ordinary pool as Black | **70.4%** (69.3-71.5): White gains **+11.0** points | **57.9%** (56.8-59.0): **+6.8** |
| Ordinary pool as White against Black specialists | **45.8%** (44.7-46.9): Black gains **+13.5** points | **45.9%** (44.9-47.0): **+5.2** |
| **Specialists against specialists: White** | **56.7%** (55.6-57.8) | **50.0%** (48.9-51.1) |
| White's first move a capture or ability (specialists) | 65.1% (ordinary 59.4%) | 0% |
| Black's first move a capture or ability (specialists) | 41.7% (ordinary 47.5%) | 42.1% (ordinary 33.7%) |
| Uneven matchups (of 100) | 35 | 18 |

- **Settled, not cycling.** In the meta log every pool only climbs: normal
  rules, the White pool's game Elo against the frozen all-rounders goes from
  +57..+202 at the start to +165..+371 at round 15, with run 7's all-rounder
  Wide 14a steady at +202 throughout; the Black pool from -115..+40 to
  +14..+143. Under the rule: White +13..+78 to +38..+173, Black -22..+99 to
  +15..+167. No army's score falls when another joins, because the opponents
  never change. (The log's wording still says "against the Black pool" /
  "the White pool"; with `--fixed-opponent` that means the frozen pool.)

### Normal rules

- **A White-only army gains 11 points, a Black-only army 13.5.** Against each
  other the specialists give White 56.7%: specialising helps Black a little
  more than White, so between two players who both set colour defaults White's
  edge comes down from about 59% to about 57%. It does not go away: White's
  first move is a capture or ability in 65% of specialist games (more than the
  all-rounders' 59%).
- **White's armies are strikers:** 3.2 long-range pieces in the front row on
  average, Archers in 9 of 10, Lances in 6 (the only pool with many Lances),
  Rams and Cannons; the top army (Wide W10a, 89% as White against the
  all-rounders, 76% against the Black specialists) has six long-range pieces in
  its front row. **Black's armies are defenders:** 1.7 long-range front-row
  pieces, Ghost and Queen in all 10, Necromancer in 8, Paladins and Barbarians,
  and 42% first-move captures against the all-rounders' 47%. No army is in
  both pools.
- Against each other, some Black specialists still do badly (Wide B9c 32%,
  Wide B7c 32% as Black): a defender built against all-rounders meets White
  strikers it never saw. The best Black army (Wide B14a: no long-range piece
  in the front row, two Paladins, a Parapet) holds 69%.

### White-only quiet first move

- **Smaller gains both ways** (+6.8 for a White-only army, +5.2 for a
  Black-only one), and **specialists against specialists is level, 50.0%.**
  Under the rule there is less to specialise on: White can't strike first, so
  the two colour pools end up alike (2.9 and 3.2 long-range front-row pieces;
  Bishop, Queen, Archer, Ghost, Assassin, Necromancer in most armies of both),
  two armies sit in both pools, and five of the ten Black-pool armies are run
  10's all-rounders unchanged (they already play Black well under the rule).
- Black's first-move captures rise to 42% (all-rounders 34%): the Black
  specialists make use of the strike White can't make.

## What this says about separate default armies

Engine play, one seed, 15 rounds of search: strong hints, not proof.

1. Under the normal rules, separate colour defaults are worth a lot to a
   strong player: about +11 points as White with a striker army and about
   +13.5 as Black with a defender. When both players do it, White's edge
   narrows a little (59% to 57%) but stays, because the first-move capture is
   still there for a striker to use.
2. Under the White-only quiet first move, colour defaults matter less (about
   +5 to +7 points each way) and cancel out: specialists against specialists is
   50.0%. That rule plus colour defaults is the most even setting measured so
   far, and it was reached without the search having to be tuned to it.
3. The method matters: a colour specialist is only as good as the opponents it
   was built against. Judged against all-rounders (this run) the specialists
   are strong and settle; judged against each other (runs 11-12) they were
   brittle counters. This run's numbers supersede runs 11 and 12's for the
   design question.

These are engine-vs-engine results, not human play. Balancing decisions are
Mac's.
