# The eval-bar meta pool (October 2026)

Ten armies that look strongest **at turn 0 in Plusfish's eval bar** against
each other, grown by `plusfish meta` (see the README: "Growing an army pool
from the eval bar"). File: `reports/meta_pool.txt` (readable by
`enginematch --pool` and `start-check --pool`). Every army is legal under the
current costs (Lance 3.5, Necromancer 3.5, Ram 3, Archer 4.5) and none leaves
a king attacked at the start against another member or Standard.

Re-run it whenever Plusfish improves; the pool is only as good as the
evaluation that judged it.

## How it was grown

Three runs, 210 rounds in all, 16-19 threads, about 1 hour 30 minutes:

1. 50 rounds from Standard (the old pool's 8 armies all break the budget
   now). "New" meant at least 6 of 16 squares different, which every
   candidate was, so the pool never settled: layouts differ even when the
   pieces are the same.
2. 80 rounds with "new" meaning at least 3 pieces different. Still no
   settling: candidates climbed from random armies always ended 3+ pieces from
   every member, so the replace-if-better rule never fired.
3. 80 rounds where even rounds refine a member against the others. 25
   replacements, 12 close variants thrown away, 43 joins. It never went 8
   rounds without a change, but the new armies kept being variations on
   the same core, so this is the meta.

## The pool

Eval = mean turn-0 advantage over the other nine at 20,000 nodes (both
colours averaged, centipawns). Games = mean score against the other nine over
40 games per pairing (20 per colour, 6,000 nodes per move). vs Standard = 40
games.

| Army | Text | Eval | Games (Elo) | vs Standard |
|---|---|---|---|---|
| Meta C 70: Queen, 2 Vampire, Necromancer, Bishop, Knight, Ram, 2 Squire, Berserker, Pawn | `(SQ)1VNKV2/BQ(RM)(SQ)(BR)P(NC)1` | +167 | 66.4% (+118) | 97.5% |
| Meta C 76: Wizard, Rook, Archer, 2 Vampire, Necromancer, Ram, 2 Squire, Pawn | `1VPKWR(NC)1/1(SQ)A(RM)V1(SQ)1` | +132 | 64.0% (+100) | 96.2% |
| Meta C 74: Rook, 2 Archer, Vampire, 2 Bishop, Knight, 2 Ram, 2 Squire | `2(SQ)KV2(SQ)/ABA(RM)(RM)RBN` | +124 | 54.7% (+33) | 93.8% |
| Meta C 19: 2 Archer, Cannon, 2 Vampire, Necromancer, 2 Ram, 2 Squire, Berserker | `1V(SQ)CKV(SQ)1/2AA(RM)(BR)(RM)(NC)` | +69 | 49.9% (-1) | 96.2% |
| Meta C 56: Queen, Archer, Vampire, Necromancer, Bishop, Ghost, Knight, Ram, Squire, 3 Pawn | `(SQ)1Q1K(NC)PP/PN1(RM)VGAB` | +12 | 54.6% (+32) | 97.5% |
| Meta C 78: Cannon, 2 Vampire, 2 Bishop, Cavalry, Knight, 2 Ram, 2 Squire, 3 Pawn | `V1(SQ)KC(CV)B(SQ)/PPB(RM)V(RM)NP` | -5 | 47.8% (-15) | 100% |
| Meta C 50: Queen, 2 Archer, Vampire, 2 Bishop, Knight, 2 Squire, 2 Pawn | `A(SQ)PK1QV1/1BNPBA1(SQ)` | -92 | 38.8% (-80) | 97.5% |
| Meta C 63: Wizard, 2 Archer, Vampire, Lance, Necromancer, Bishop, Ram, Squire, 2 Pawn | `1P(NC)K1PW1/B1(SQ)(RM)VALA` | -130 | 40.4% (-67) | 90.0% |
| Meta C 72: Princess, Vampire, Lance, Necromancer, Bishop, 2 Knight, Ram, 2 Squire, 3 Pawn | `(RM)(SQ)(SQ)K(NC)1VP/LNP(PR)NBP1` | -136 | 31.1% (-138) | 98.8% |
| Meta C 71: Queen, Vampire, Bard, Necromancer, Bishop, Knight, Ram, 2 Squire, 4 Pawn | `PP(SQ)NK(NC)P1/Q(RM)(SQ)V(BD)B1P` | -140 | 52.4% (+16) | 96.2% |

## What it shows

* **The meta is real, not just Plusfish's opinion.** Every pool army beats
  Standard 90-100% in games (+380 to +800 Elo), and within the pool the
  eval-bar ranking matches the game results well: correlation 0.82 (rank
  0.78), with the eval's top two also the games' top two. The one clear miss
  is the Bard army (Meta C 71): last by the eval, fifth in games, so Song of
  Slumber is probably undervalued at the start.
* **The core**, found again and again from random starts: a Vampire (all 10,
  4 with two), two Squires (8 of 10; protecting Knights), a Ram (9 of 10)
  and a Necromancer (7 of 10), around a Queen, Wizard, Rook or Archers. Few
  pawns (0-4). In no final army: Paladin, Jester, Galleon, Chariot, Assassin,
  Parapet, Elephant, Man, Rogue, Catapult, Werewolf; the Princess, Lance,
  Ghost, Cavalry and Bard appear once or twice.
* **Balance hints for Mac** (engine play, not human play): the Vampire (cost 4)
  and Squire (cost 3) look underpriced, and the Ram (3) slightly. On the
  army-cost scale the re-tuned evaluation values them at about 6.1, 4.0 and
  3.7 points in the middlegame (4.7, 3.8 and 3.1 in the endgame), and a
  Vampire that has won its shield at about 4 more.
* **For engine testing**, this pool is where the new weights matter most:
  +107.5 ±19 Elo over the previous weights (ELO_LOG #23), and start-check
  correlation 0.79 against 0.41 before.
