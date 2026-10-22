# How well Plusfish judges the start of a game (October 2026)

The question: when Plusfish scores a starting position (the eval bar at move
0, and every turn-0 score the meta pool is built on), how close is it to how
the game actually goes? And where it's wrong, why?

## How it was measured

`plusfish drift` played 8,000 games between random full-budget armies, with
Plusfish's top move every turn (40,000 nodes a move), logging its score at
every ply. Each start was also scored the way the eval bar does it: a fresh
search of 20,000 nodes (the web) and 150,000 (the PC).

"The truth" for a start is how the game went: its result, and the average
win chance Plusfish gave over plies 16 to 40 (once the armies have met; much
less noisy than one game's result). Scores become win chances with
1 / (1 + 10^(-score / 720)), the curve that fits these games.

A quarter of the games (every 4th) were kept back for testing; everything
below is measured on those 2,000 games.

## What was wrong

The biggest disagreements were armies Plusfish thought were 4 to 6 pawns
ahead that went on to lose. Splitting each start score into its parts
(material, mobility, where pieces stand, abilities, king safety, ...) and
checking which parts the later scores disagreed with:

* **Where pieces stand** (`reach`, how many squares a piece could reach from
  its square on an empty board) counted 60% too much at the start, and
  mobility 30% too much. These weights were learned from middlegame
  positions, where a piece still on its back row is usually stuck and the
  game going badly. At move 0 *every* piece is on its first two rows, and
  that means nothing yet.
* **The Vampire** was the worst case. It can't move straight forward, so
  from its back row it reaches few squares, and its learned reach weight is
  large: every Vampire lost about 2 pawns of start score just for standing
  where armies put it. With Vampires in random armies that alone swung start
  scores by about a pawn either way.
* **Unused abilities** counted about 20% too little at the start (there's a
  whole game left to use them).

Smaller versions of the same mistake hit the Catapult, Cavalry and Knight.

## The fix: opening terms

Each piece type got opening versions of its terms (material, mobility,
reach, being on the second row, unused ability, plus one for whose turn it
is). Each is multiplied by the share of pieces that haven't moved yet, so it
counts fully at move 0 and fades as the armies develop. They were fitted to
the later scores of the first 40 plies of 6,000 of the games, with nothing
else changed.

What they say each piece is really worth *at the start*, compared with
before (centipawns, 100 = a pawn's cost; middlegame weights):

| More than Plusfish thought | | Less than Plusfish thought | |
|---|---|---|---|
| Vampire | +139 | Rook | -47 |
| Princess | +57 | Queen | -38 |
| Lance | +52 | Wizard | -28 |
| Werewolf | +51 | Man | -26 |
| Necromancer | +48 | Chariot | -22 |
| Ghost | +44 | Assassin | -17 |
| Cannon | +25 | Knight, Ram | -15 |

These are Plusfish's own judgement of the start, not costs: the balance
report is still the place for those.

## Results (2,000 test games)

Brier score = average squared gap between the predicted win chance and the
result (lower is better; always saying 58% scores 0.166). "Skill" = how much
of that it removes.

| Start score | Brier vs result | Skill | Error vs later scores | Correlation with later scores |
|---|---|---|---|---|
| Before, 20,000 nodes (web) | 0.1395 | 0.16 | 0.0179 | 0.83 |
| Before, 150,000 nodes (PC) | 0.1371 | 0.18 | 0.0161 | 0.85 |
| Before, 1,000,000 nodes | 0.1346 | 0.19 | 0.0147 | 0.86 |
| **After, 20,000 nodes (web)** | **0.1206** | **0.27** | **0.0125** | **0.88** |
| **After, 150,000 nodes (PC)** | **0.1187** | **0.29** | **0.0114** | **0.89** |
| After, 1,000,000 nodes | 0.1177 | 0.29 | 0.0108 | 0.90 |

At the web's budget Plusfish now judges the start better than it used to
with 50 times the search. Searching deeper helps little either way, so what's
left is mostly not search depth: some games are decided by a tactic a few
moves in, and one game's result is noisy.

Examples (score in pawns, White's view; "later" = average over plies 16-40):

| Game | Before (20k) | After (20k) | Later | Result |
|---|---|---|---|---|
| Ghost/Princess/Lance/Vampire/Necromancer army vs two Chariots, two Cavalry, Galleon, Squire | -4.6 | -1.7 | +5.5 | White won |
| #778 | -5.1 | -1.5 | +6.8 | White won |
| #58 | +6.1 | +2.9 | -0.2 | Black won |

It also plays better, since the opening is where every game starts: +37
±11 Elo at 6,000 nodes a move and +54 ±14 at 20,000 (the web eval bar's
budget), random armies; see ELO_LOG #35.

## Still open

* A shielded Vampire walking through the enemy camp is misjudged in the
  middlegame too (one game: Plusfish thought it was 14 points up and lost).
  That's the middlegame evaluation, not the start.
* Vampires are worth a little more against armies with many pawns (about
  half a pawn against eight pawns); too small to add a term for.
* The later scores and the results disagree a little: Plusfish's middlegame
  scores give White less than White actually scores (56% vs 58%).
