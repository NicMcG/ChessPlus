# The army pool (October 2026)

Eight varied, decent-to-strong 39-point armies, evolved by Plusfish and then
measured in a separate round robin. They're for repeatable engine tests
(`match --armies pool:armies/pool.txt`) and for checking whether the
random-army piece values (FINDINGS.md §2) hold for real builds. They don't.

Files: `armies/pool.txt` (text form + numbers), `armies/*.tres` (the game's
saved-army format; all 8 load in Godot and pass `Army.problems`).

## The pool

Final round robin: the 8 pool armies + Standard + the Berserker Wall
(FINDINGS §4), every pairing 60 games (30 with each colour), 6,000 nodes per
move, 2,700 games. No pairing in the pool, or with Standard, starts with a
king attacked.

| Army | Niche | Text | Cost | Elo in pool (±95%) | vs Standard, head to head (60 games) |
|---|---|---|---|---|---|
| Lancer Host | no royal, 4-6 pawns | `(CH)N(CV)PKBPP/LAP(NC)MB(RO)L` | 38.5 | **+170** ±38 | 67.5% = +127 [+52, +215] |
| Wizard Bishops | Wizard, 0-3 pawns | `PW1K(RO)(BR)P1/L(CH)PEBBAA` | 39 | **+115** ±37 | 98.3% = +708 [+515, >+1000] |
| Knights and Lances | no royal, 0-3 pawns | `(CH)NBKE(RM)PP/L(CV)P(NC)NBAL` | 39 | **+78** ±36 | 70.0% = +147 [+64, +251] |
| Queen Lance Line | Queen, 7+ pawns | `LPP(CV)KQBP/L(NC)PP(CH)PPA` | 38 | **+41** ±35 | 92.5% = +436 [+316, +792] |
| Twin Necromancers | Queen, 4-6 pawns | `AP(CH)1K(NC)QB/PBPPPA(NC)P` | 39 | **+18** ±35 | 94.2% = +483 [+362, +882] |
| Wizard Archers | Wizard, 4-6 pawns | `WP1K(RO)P(RM)1/L(NC)PP(CV)BAA` | 38.5 | **−12** ±35 | 95.8% = +545 [+403, >+1000] |
| Queen Chariots | Queen, 0-3 pawns | `CB2KP(CH)L/(BR)BQ(CV)(CH)1(NC)1` | 39 | **−114** ±36 | 99.2% = +830 [+640, >+1000] |
| Wizard Pawn Wall | Wizard, 7+ pawns | `CPPMKW(RM)L/APPP(CH)PPL` | 38.5 | **−297** ±43 | 85.8% = +313 [+221, +464] |
| *(Berserker Wall, not in pool)* | Queen, 4-6 pawns | `RNBQKBNR/1(BR)PPP(BR)2` | 39 | scores 9% against the pool | 74.2% = +183 [+106, +282] |

"Elo in pool" is a fit to the 1,680 games between the eight, relative to
their average. The spread from "decent" (Wizard Pawn Wall) to "good" (Lancer
Host) is about 470 Elo and well outside the error bars. Every pool army beats
Standard clearly; the Berserker Wall, the best hand-made build we had, beats
Standard too (74%, matching FINDINGS' +174) but is far below the pool (9%), so
it was left out: its games would carry little information in A/B tests.

**Results aren't transitive.** The two armies without a queen or Wizard are
the best in the pool but beat Standard only ~70%; Queen Chariots is 7th in
the pool and beats Standard 99%. So one "Elo vs Standard" number per army is
misleading; that's why the table gives the head-to-head score, not a fitted
rating (the fitted ratings, which assume transitivity, say +280 to +640 vs
Standard and put the Berserker Wall below Standard, contradicting its 74%).

**White's edge is huge between these armies**: +208 Elo in pool-vs-pool
games (+171 over the whole round robin), against +76 between random armies
(FINDINGS §3). Strong builds open lines fast (Lances, Archers, Chariots), and
moving first matters more. Pool A/B tests should always play both colours,
which `match --armies pool:` does.

## Variety

* 8 of the 9 niches (extra royal × pawn count) have an army. "No royal,
  7+ pawns" stayed empty: nothing that landed there in 52 generations was
  legal, near budget and not exposed, or it was never generated; with 7
  pawns and no queen/Wizard you need 31+ points of minor pieces at 2 copies
  each, and few mutation paths lead there.
* Each pool army differs from every other on at least 7 of its 16 starting
  squares. (The raw per-niche winners were not this varied: neighbouring
  niches can hold near-copies, e.g. the best Wizard 0-3 and 4-6 pawn armies
  differed by one square, so the pool takes, per niche, the best army with
  96+ games that is at least 7 squares from those already chosen.)
* Pawns: 1 to 7 (the three 0-3-pawn armies have 1, 3 and 3). Royals: 3 Queen,
  3 Wizard, 2 none. Piece counts 12 to 16.
* Style is less varied than the niches: by points, every pool army is mostly
  sliders and has an ability piece. Leaper- or stepper-heavy builds didn't
  win any niche, which is itself a finding (below).

## What the strong builds favour and avoid

Pieces per army in the pool, against random legal armies (the self-play data
behind FINDINGS, 8,000 armies):

| Piece | Cost | Pool | Random | FINDINGS worth/cost |
|---|---|---|---|---|
| Bishop | 3 | **1.50** | 0.55 | 1.13 |
| Lance | 2.5 | **1.38** | 0.55 | 1.37 |
| Archer | 4 | **1.25** | 0.53 | 1.14 |
| Chariot | 4 | **1.00** | 0.53 | 0.92 |
| Necromancer | 3 | **0.88** | 0.54 | 1.22 |
| Cavalry | 3 | 0.62 | 0.55 | 1.07 |
| Queen / Wizard | 9 / 8 | 0.38 / 0.38 | 0.35 / 0.36 | 1.15 / 1.03 |
| Rogue, Ram, Knight | | 0.38 each | ~0.52 | |
| Cannon, Man, Berserker, Elephant | | 0.25 each | 0.50-0.77 | |
| **Rook** | 5 | **0** | 0.51 | 0.93 |
| **Paladin** | 2 | **0** | 0.63 | 0.77 |
| Pawn | 1 | 4.4 | 3.7 | 0.83 |

* Favoured, and in line with FINDINGS: **Lance** (the most underpriced piece
  there), **Archer**, **Necromancer**, **Bishop**. Six of the eight take two
  Archers or two Bishops; Lances often sit in front of the king or in a back
  corner aimed down an open file.
* Favoured beyond what FINDINGS predicts: **Chariot** (rated slightly
  overpriced there, 3.67 for 4, yet in 7 of 8 armies, often as a corner
  rook).
* Avoided, in line with FINDINGS: **Paladin** and **Elephant** (overpriced),
  **Cannon**, **Ram**.
* Avoided beyond what FINDINGS predicts: **Rook** (0 of 8; at 5 points the
  Chariot does most of its job for 4) and **Berserker** (2 of 8, despite the
  Berserker Wall result).

## How this compares with the random-army piece values

Adding up FINDINGS' "worth (army)" values and converting at the regression's
~62 Elo per point (Queen: +637 Elo for 10.33 points) predicts each army's
edge over Standard:

| Army | Predicted vs Standard | Measured head to head |
|---|---|---|
| Lancer Host | +143 | +127 [+52, +215] |
| Knights and Lances | +131 | +147 [+64, +251] |
| Queen Lance Line | +152 | +436 [+316, +792] |
| Twin Necromancers | +194 | +483 [+362, +882] |
| Wizard Archers | +111 | +545 [+403, >+1000] |
| Wizard Bishops | +115 | +708 [+515, >+1000] |
| Queen Chariots | +170 | +830 [+640, >+1000] |
| Wizard Pawn Wall | −37 | +313 [+221, +464] |
| Berserker Wall | +73 | +183 [+106, +282] |

* The values get the two royal-less armies right against Standard, but
  underrate the other six by 250 to 650 Elo. The Wizard Pawn Wall is
  predicted *worse* than Standard and wins 86%.
* So the suspicion was right: **piece values measured over random armies
  don't hold for curated builds**. Random armies are badly arranged (pieces
  where they can't move, open lines to their own king); a good arrangement
  of the same pieces is worth hundreds of Elo, and some pieces gain far more
  from good placement than others (Lances aimed down open files, Archers and
  Bishops on long diagonals, Chariots in corners). A sum of piece values
  can't see that, and engine play exploits it hard.
* Against each other, the pool's ratings don't follow predicted worth
  either: Lancer Host and Knights and Lances are best in the pool but have
  middling predicted worth; Twin Necromancers has the highest predicted worth
  (42.2) and sits mid-pool.

For balancing, this means the per-piece verdicts in FINDINGS (which pieces
are cheap or dear relative to each other) are still useful hints, but the
absolute picture is wrong: Standard is much weaker than an equal-cost
custom army built well, and arrangement matters as much as the shopping
list. Re-running `values` on games between good armies (e.g. pool mutants)
rather than random ones would give values closer to what players will meet.

## How it was made

`plusfish evolve` (README, "Evolving armies"): MAP-Elites over 9 niches,
racing fitness on a shared Elo scale anchored at Standard = 0, 4,000 nodes
per move, 6 threads, seed 1.

* 52 generations, 1,560 candidates played, 315 more rejected before playing
  for starting with a king attacked (or attacking the other king) against
  more than 3% of random armies; 35,432 games, 111 minutes. Final round
  robin 2,700 games at 6,000 nodes, ~10 minutes. About 2 h 10 min in all.
* During the run the ratings were inflated (elites at +300 to +500 against
  Standard after 48 games: the luckiest of hundreds of challengers). A
  96-game confirmation stage was added at generation 19, which slowed but
  didn't stop the drift, so evolution ratings were only used to pick
  candidates; every number above comes from the separate round robin.
* The evolution found an engine bug on the way (quiescence search in check
  had no depth limit, so a depth-1 search could run forever; fixed in
  `search.rs`).

## Caveats

* Engine games at 4,000-6,000 nodes, not human play. The pool is what's
  strong for Plusfish; humans may find different builds strong, and the
  armies' rankings may shift at longer time controls.
* The pool armies were chosen partly by beating the evolution's own
  references and each other, at 4,000 nodes. The 6,000-node round robin was
  separate, but with the same engine.
* Head-to-head scores against Standard come from 60 games each; above ~95%
  the Elo upper bounds are effectively open.

Raw outputs are in `reports/army_pool/`: the round robin (`tournament.txt`;
"Lancer Host" ran there under a draft name), and the evolution's final
archive, every army with 48+ games (`evolve_candidates.txt`) and its state
(reference ratings, run seed 1).
