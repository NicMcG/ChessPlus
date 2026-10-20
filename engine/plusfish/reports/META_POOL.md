# The meta pool (October 2026)

Ten armies that hold up best **in games** against each other, found by
`plusfish meta --wide` (see the README: "Searching wide (`meta --wide`)").
File: `reports/meta_pool.txt` (readable by `enginematch --pool`,
`start-check --pool` and `meta --pool`). Every army costs 39 under the
current costs (Lance 3.5, Necromancer 3.5, Ram 3, Archer 4.5) and none
leaves a king attacked at the start against another member or Standard.

Re-run it whenever Plusfish improves or costs change; the pool is only as
good as the engine that played it.

## How it was grown

One run from the previous pool (the ten "Meta C" armies, plus Standard), 8
rounds, 19 threads, about 1 hour 17 minutes:

```
plusfish meta --wide 38 --pool reports/meta_pool.txt --game-climb --king-exposed reject --threads 19 --seed 12
```

Each round, 38 armies hill-climbed at once (34 from random armies, 4 from
members), guided by Plusfish's quick turn-0 eval. The best 3 by the eval bar
went on; the best of those was polished with games; then each played 40
games against every member, and **games, not the eval, decided** who joined,
replaced a member or was thrown away. The previous pool had been chosen by
the eval alone.

What happened: 12 replacements, 1 join (Wide 3c), 1 drop (Meta C 72). All
but one replacement kept a member's exact pieces on different squares (the
other changed one piece). 304 climbs from random armies found no new piece
list that beat the pool in games. Every round changed something, so layouts
are still improving, but the piece lists have settled.

## The pool

Games = mean score against the other nine over 40 games per pairing (20 per
colour, 6,000 nodes per move). Eval = mean turn-0 advantage over the other
nine at 20,000 nodes (both colours averaged, centipawns). vs Standard = 40
games (20 per colour), 6,000 nodes per move.

| Army | Text | Games (Elo) | Eval | vs Standard |
|---|---|---|---|---|
| Wide 8b: Rook, 2 Archer, Vampire, 2 Bishop, Knight, 2 Ram, 2 Squire | `1B(SQ)KV2(SQ)/ANB(RM)(RM)1AR` | 69.6% (+144) | +255 | 86.2% |
| Wide 7a: Queen, 2 Vampire, Necromancer, Bishop, Knight, Ram, 2 Squire, Berserker, Pawn | `(SQ)1(NC)NK(SQ)(RM)1/PV1Q(BR)VB1` | 68.9% (+138) | +138 | 100% |
| Meta C 19: 2 Archer, Cannon, 2 Vampire, Necromancer, 2 Ram, 2 Squire, Berserker | `1V(SQ)CKV(SQ)1/2AA(RM)(BR)(RM)(NC)` | 63.5% (+96) | +123 | 100% |
| Wide 6a: Queen, 2 Archer, Vampire, Bishop, 2 Knight, 2 Squire, 2 Pawn | `Q2KNVPA/1A(SQ)(SQ)NP1B` | 55.1% (+36) | +60 | 95.0% |
| Wide 6c: Wizard, Rook, Archer, 2 Vampire, Necromancer, Ram, 2 Squire, Pawn | `(NC)VPKW2R/1(SQ)A(RM)V1(SQ)1` | 54.9% (+34) | +19 | 96.2% |
| Meta C 63: Wizard, 2 Archer, Vampire, Lance, Necromancer, Bishop, Ram, Squire, 2 Pawn | `1P(NC)K1PW1/B1(SQ)(RM)VALA` | 50.4% (+3) | -50 | 95.0% |
| Wide 1a: Queen, Archer, Vampire, Necromancer, Bishop, Ghost, Knight, Ram, Squire, 3 Pawn | `G1QK(NC)1PP/PN1(RM)(SQ)VAB` | 37.9% (-86) | -214 | 100% |
| Wide 3b: Cannon, 2 Vampire, 2 Bishop, Cavalry, Knight, 2 Ram, 2 Squire, 3 Pawn | `VB(SQ)KC(CV)1(SQ)/PPB(RM)V(RM)NP` | 37.2% (-91) | -20 | 97.5% |
| Meta C 71: Queen, Vampire, Bard, Necromancer, Bishop, Knight, Ram, 2 Squire, 4 Pawn | `PP(SQ)NK(NC)P1/Q(RM)(SQ)V(BD)B1P` | 36.7% (-95) | -163 | 97.5% |
| Wide 3c: Wizard, Rook, 2 Vampire, Necromancer, Rogue, Bishop, Ghost, Squire, 2 Pawn | `1(NC)1(SQ)KWP1/BVVG(RO)R1P` | 25.8% (-183) | -149 | 93.8% |

Where the new armies came from (same pieces, rearranged): Wide 8b from Meta
C 74, Wide 7a from Meta C 70, Wide 6c from Meta C 76, Wide 1a from Meta C 56,
Wide 3b from Meta C 78. Wide 6a is Meta C 50 with a Bishop swapped for a
Knight and rearranged. Wide 3c is new.

## What it shows

* **Layout matters a lot.** The same pieces on different squares scored up to
  17 points more against the rest of the pool (51.1% -> 68.2%, on the way to
  Wide 6a), so the eval-only search found good piece lists but not the best
  squares for them.
* **The core is unchanged**: a Vampire (all 10, 5 with two), Squires (all
  10, 7 with two), a Ram (8 of 10), a Necromancer (7 of 10), around a Queen,
  Wizard, Rook or Archers, with few pawns (0-4).
* **The eval and the games agree closely**: correlation 0.90 (rank 0.89)
  between the eval column and the games column. The biggest miss is Wide 1a
  (last by the eval, seventh in games).
* **Standard is far behind**: every army beats it 86-100%.
* **Under the game's current temporary rule this pool can be beaten.** This
  run threw out any army that leaves the other king attacked at the start. A
  second run that instead counted that as an instant win for White, as the
  game does now (`--king-exposed win`), replaced the whole pool with Cannon
  and Parapet armies: some leave Black's king attacked from the start, others
  put a Parapet in front of their King to stop that. An army with a Cannon on
  e1 and nothing on e2 (`V1(SQ)KC2(SQ)/ABNC1(BR)BA`, found by `climb-fixed`)
  won instantly as White against Standard and all ten armies of the previous
  pool, and scored 78.1% against them overall (56.2% as Black). So this pool
  is the meta for once that rule is replaced.
