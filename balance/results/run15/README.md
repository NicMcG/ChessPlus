# Balance run 15: the three new pawn-type pieces (AWS sims server, 25-26 October 2026)

Mac's three pawn-type pieces of 25 Oct 2026, measured straight after run 14.
All promote, any number per army, captures as moves, Pawn type (so they take
part in en passant and reset the 50-move clock):

| Piece | Symbol | Start price | Moves | Keyword |
|---|---|---|---|---|
| **Grunt** | GR | 1.5 | 1 forward; 2 forward on its first move (the double step may capture, Mac). Captures straight ahead, so it can be taken en passant but never takes en passant. | Shield (helmeted; bare-headed once the shield breaks) |
| **Abatis** | AB | 1 | 1 forward or 1 back; 2 forward on its first move (may capture) | **Wall** (new keyword, the Parapet's old rule: the opponent's pieces can't jump over it, their Knights count as 2 straight then 1, no screen for their Cannons; own side's jumps unaffected) |
| **Vassal** | VS | 1 | 1 forward or 1 sideways; takes en passant sideways onto the skipped square | - |

Also new in the game since run 14 and in this run: the **75-move rule** (150
plies with no change to the pieces on the board is a draw, alongside the
50-move rule; pawn moves don't reset it).

**Arm C** = run 14's arm B (budget 40, the 24 Oct prices, the ability rule
`--abilities-need-move=true`) plus the three pieces at their start prices.
Branch `experiment/run15` (run 14's engine + main's rules: Plusfish reads the
new pieces' moves from their files, the Wall keyword from the keyword bit, and
has the 75-move rule). Compared with run 14's arm B throughout.

## Success lines (written before the run)

Run 14's lines, on arm C against run 14's B:

1. Each repriced piece (Queen 10, Bishop 3.5, Rook 4.5, Werewolf 3.5, Parapet
   2.5, Jester 3.5) within **0.5** of its cost.
2. No piece more than **1.0** off its cost (the new pieces included: their
   start prices are guesses, so this is the line most likely to fail).
3. The five ability pieces within **1.0** of cost.
4. White's edge no bigger than run 14 B's in random armies (C's 95% range
   overlaps or sits below B's), and C's regrown-pool round robin passes Mac's
   standing lines: White 50-55%, no gap over 30 points, no pairing at 80%+.
5. No game starts with a special ability.
6. Diversity: C's pool uses at least as many piece types as B's (within 2)
   and at least 3 of the 5 ability types.

New for run 15:

7. **Front-row occupancy in the pool rises against run 14's B pool.** Measured
   as filled front-row squares per army (B: 7.3 of 8, A: 7.7) and, because
   that is already near the ceiling, also as pawn-type pieces in the front row
   (B: 0.3 per army). The line is on filled squares, as Mac wrote it; the
   pawn-type count is the number to read if it can't rise.

Report only: each new piece's worth; how many of each the pool armies take
and how many sit in the front row; the move-1 tally; the colour specialists
and mirror matches (run 14's parts 3 and 4).

## Run 15D (Mac, 25 Oct 2026, straight after run 15; lines written before it starts)

**Arm D** = arm C with the **White-only quiet first move** on as well
(Plusfish `--white-quiet-first=true`, run 9's rule: White may not capture,
break a shield or use an ability on its first move unless in check; Black's
first move is unrestricted). Same branch and build. The all-round pool is
regrown **under the rule from C's regrown pool**; then the same parts as C
(round robin, colour specialists, mirror matches with the ability rule only
and with both rules, move-1 tally), plus **5,000 random-army games at 32,000
nodes (seed 303) for both C and D** (`selfplay_32k.jsonl`, `report_32k.txt`).
Script: `tools/balance/run15d_server.sh` (the branch). Expected: about 2.7
hours, roughly $7 metered.

Success lines for D: lines 1-7 above, judged on D (line 4's "no bigger"
against C; line 7 against C's pool), plus:

8. **Specialists vs specialists under 60%** (White's score when D's White
   specialists play D's Black specialists; run 14 B was 70.6%, run 13 under
   this rule 50.0%).
9. **No White specialist at 90%+ against every Black specialist** (no White
   pool army whose score as White over the whole Black pool is 90% or more;
   run 14 B had one at 100%).

## Before the run: does Plusfish agree with the game?

`plusfish perft-suite`, and traced games from the game's own engine leaning
towards the three new pieces, the Parapet (Wall from the keyword now) and the
ability pieces, checked with `trace-check --abilities-need-move=true`: must be
0 mismatches. **Done before the run (25 Oct, branch commit 96dd282):** perft
suite all PASS; 340 traced games (283 with Grunts, 284 Abatis, 282 Vassals,
184 Parapets), 25,949 + 25,367 = **51,316 positions, 0 mismatches** with the
rule on; with it off, 132 mismatches in the first set (the traces exercise
the ability rule too).

## Parts and settings

The same as run 14's arm B (`tools/balance/run15_server.sh` on the branch):

| Part | What | Settings |
|---|---|---|
| (1) | balance report (`C/report.txt`, `.html`) | `selfplay --games 20000 --nodes 8000 --seed 101` (budgets 34-40), `values` |
| (2) | the all-round pool regrown from run 14's B pool (`meta_pool.txt`, `meta.log`), then run 10's colour test on it | `meta --wide 64 --game-climb --king-exposed reject --rounds 15 --seed 1`; round robin of the pool + Standard, 40 games a pairing, 8,000 nodes, `--random-plies 4`, seeds 3000+ |
| (3) | run 13's colour specialists from C's regrown pool (`split/`) | `meta --split-colours --fixed-opponent`; three grids, 40 games a pairing, colours fixed, seeds 4000+/5000+/6000+ |
| (4) | each regrown-pool army against itself (`mirror.txt`) | `plusfish analyse`, 2,000,000 nodes, 8 threads, with the ability rule and without |
| (5) | move-1 tally over every game (`firstmoves.jsonl`) | `plusfish first-moves` |
| (6) | diversity, the new pieces' counts and places, front-row occupancy | `tools/balance/run15_analyse.py` (reads run 14's B folder for the comparison) |

- Server: `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores), `--threads 64`.
  Game files (not in the repo): `Documents\ChessPlusSims\run15\`.
- Expected: about 2.5 hours, roughly $6.50 metered.

## Results, arm C (full tables in `report.md`, `tools/balance/run15_analyse.py --arm C`)

Server 12:46-15:03 UTC 25 Oct for arm C (2.2 hours; arm D followed on the
same server, see below). Plusfish commit 96dd282 (branch `experiment/run15`).

**Success lines: 1, 2, 3, 5, 6 and 7 pass; 4 fails** (White's edge is bigger
than run 14 B's, not smaller).

### The new pieces' worth (20,000 random-army games)

| Piece | Start price | Worth | |
|---|---|---|---|
| Grunt | 1.5 | **0.89 ±0.08** | overpriced by ~0.6 |
| Abatis | 1 | **0.64 ±0.07** | overpriced by ~0.4 |
| Vassal | 1 | **1.01 ±0.07** | about right |

The rest hardly moved: Queen 10.32 (+0.3), Wizard 8.72 (+0.7), Vampire 7.27
(+0.8, as always), Rook 4.94 (+0.4); the six repriced pieces all within 0.45.

### What the strong armies do with them

C's regrown pool (from run 14's B pool): 6 of 10 armies take a Grunt (7 front
row, 7 back row in all), 3 an Abatis (all back row), 2 a Vassal (front row).
Front-row squares filled 7.3 -> 7.4 of 8; pawn-type pieces in the front row
0.3 -> **1.1** per army (line 7 passes, but as a Grunt here and there, not a
wall). 26 piece types in the pool (B: 25). Colour specialists: the Black pool
takes **20 Grunts** in 10 armies (2 each, the commonest piece with Archers
and Necromancers); the White pool stays Lances (10/10) and Wizards (10/10).

### White's edge

| | Run 14 B | Run 15 C |
|---|---|---|
| Random armies: White | 55.8% (55.2-56.4) | **56.4%** (55.8-57.0) |
| Pool round robin: White | 53.6% | **57.6%** (55.8-59.4) |
| ...biggest White-minus-Black gap | +19.2 | **+44.3** (Wide 15b), +39.0 (Wide 8a) |
| ...pairings at 80%+ | 4 | 5 (Wide 15b vs Wide 12c 100%) |
| ...White won both of a swapped pair | 11.5% | 15.1% |
| Mirror matches with the ability rule: median | +0.70, 5 of 11 over +1 | **+0.23**, 7 of 11 within ±0.35, 2 over +1 |
| Specialists vs specialists: White | 70.6% | **54.9%** |
| White specialists vs all-rounders / all-rounders vs Black specialists | +16.3 / +7.5 | +15.6 / +5.9 |
| Best White specialist over the Black pool | 100% | 83.1% |

Mixed: the random-army and pool figures are a little worse, the mirror
matches and the specialist fight much better. The move-1 tally says why.
Strong armies now open with a capture in 42% of games (B 53%), and a quarter
of those hits are "free" (B 5%): nearly all of them a Lance or Wizard hitting
a front-row **Grunt**, which only breaks its shield; White scores **28%**
after Lance x Grunt (325 games). A shielded Grunt in the front row is a
tempo trap for strikers, which is what dulls the specialists. Away from the
Grunts, the usual Lance x Jester / Lance x Archer / Bishop x Pawn (100%)
openings are as deadly as before, so the overall pool figures didn't improve.

### An army that mates itself on move 1

Wide 8a `E(PD)W1KJ(NC)1/L(SQ)L(RM)(RM)1(VS)B` against itself: **1. Lxc8=SQ#**.
Black's army is mirrored, so White's c-file Lance looks up an empty file at
the Black Jester on c8 beside the King on d8; it captures, promotes to a
Squire (2 straight or 1 diagonal) and mates. Plusfish found it (score +99 in
the mirror match, checked at 300,000 nodes). King exposed only catches a
king attacked before the first move; a forced mate on move 1 is the same
problem one move later. Worth a rule thought (Mac).

### Arm C's lines in short

- 1-3, 5, 6, 7: pass (7 on filled squares 7.3 -> 7.4; pawn types 0.3 -> 1.1).
- 4: **fails**: random armies 56.4% vs B's 55.8% (ranges just touch), round
  robin 57.6% with a +44.3 gap and 5 pairings at 80%+.
- Report-only lines 8 and 9, for comparison with D: specialists vs
  specialists 54.9% (would pass "under 60%"); best White specialist 83.1%
  (would pass "no 90%+").

## Results, arm D

(pending)
