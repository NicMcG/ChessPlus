# Chess Plus balancing: briefing (for a chat that can't see the repo)

Last updated 22 October 2026 (after run 7). The full data is in the repo
(github.com/thedarkhorse99/ChessPlus): `balance/results/run1` to `run7` (a
README and report each) and `CLAUDE.md`. All numbers below come from
Plusfish, the game's own engine, playing itself: strong hints, not human play.
Balancing is now discussed in Claude Code; Mac makes the decisions.

## The game in one paragraph

Each player builds an army on a budget of 39 points (pawns count) on their
own first two rows of an 8x8 board: exactly one King (middle of the back row),
at most one extra Royal piece, at most 2 copies of any non-pawn type. White
moves first. 30 piece types.

## Current prices

Pawn 1, Knight 3, Bishop 3, Rook 5, Queen 9, King 0. Archer 4.5, Assassin 0.5,
Barbarian 2.5, Bard 3.5, Cannon 4, Catapult 3, Cavalry 3, Chariot 4, Elephant 1,
Galleon 3, Ghost 3, Jester 4, Lance 3.5, Man 3, Necromancer 3.5, Paladin 1.5,
Parapet 3, Princess 8.5, Ram 3, Rogue 3.5, Squire 4, Vampire 6.5, Werewolf 3,
Wizard 8.

Changed in October from run 1's data: Vampire 4 -> 6.5, Princess 7 -> 8.5,
Squire 3 -> 4, Galleon 4.5 -> 3, Elephant 1.5 -> 1, Paladin 2 -> 1.5,
Assassin 2 -> 0.5 (earlier: Lance 2.5 -> 3.5, Necromancer 3 -> 3.5,
Ram 3.5 -> 3, Archer 4 -> 4.5). Queen kept at 9 on purpose (measured ~10).

## Piece values (run 2, at the current prices)

"Worth" = what one extra piece is worth at the start, judged from 40,000 games.
About right: Princess, Squire, Paladin, Assassin. Still off by 0.3 or more:
Vampire worth ~7.0 (costs 6.5), Queen ~10 (9), Bishop ~3.5 (3), Werewolf
+0.4, Archer +0.3, Cavalry +0.3, Galleon +0.2; Parapet -0.4, Jester -0.4,
Lance -0.3, Rook -0.3, Pawn -0.3, Elephant -0.2.

## Colour balance (Mac's goal: White's edge close to chess's)

Target: top engines rate the chess start +0.20 to +0.35 pawns for White;
strong players score 54-56% with White. Plusfish rates the chess start +0.29.

- **Random armies:** White scores about 56%.
- **The strongest armies (meta pool):** White scores about 63%, and some
  pairings are 80-100% White (run 3).
- **The cause (found 22 Oct):** armies have no pawn wall, so long-range
  front-row pieces (Bishop, Lance, Queen) and the Archer's Crack Shot can
  capture before anyone moves, and White goes first. When White's first move
  is a capture, White scores 67-71%; otherwise about 53%, already chess-like.
  Some strong armies played against themselves start +3 to +4.6 pawns for
  White (e.g. 1. Axb7! with Crack Shot).
- **Run 4, "Quiet first move"** (no captures or abilities on either side's
  first move): made it worse (White 58.4%), because a first-move check that
  could only be answered by a capture became mate, and White just captured on
  move 2 instead. Rejected.
- **Run 5, the "Front-row rule"** (Mac's name; no piece may start able to
  capture anything on the opponent's two starting rows): random armies White
  52.0% (from 56.1%); an army against itself median +0.26 (chess +0.29), none
  over +1 pawn (was 6 of 18). It would also make the temporary "King exposed"
  rule unnecessary. Status: tested, **not adopted yet** (Mac's choice).
- **Run 6, the Front-row rule with strong armies** (a meta pool grown under
  it): White 51.0% overall, every army's White-minus-Black gap under 15
  points; Mac's success test failed by a single pairing at 82.5% (33 of 40
  games). At deeper search (32k nodes) random armies under the rule: White
  51.4%. The one strong army still well ahead against itself opens with a
  check on move 1 (the rule only stops captures).
- **Run 7, the normal rules with the improved Plusfish:** the problem is
  still there (White 59.4%, 3 pairings at 80%+, half the strong armies +3 to
  +4 against themselves via first-move captures). Its pool is the official
  meta pool now.

## Other open questions

- Whether to adopt the Front-row rule (and the army builder's wording for it).
- Queen at 9 vs measured ~10 (raising it puts Standard over 39).
- Vampire still ~0.5 under its worth; Bishop ~0.5 under.
- The Berserker/Barbarian card note; Nicholas's Plusfish retrain.

## Running sims

On Mac's AWS server (64 cores, ~$2.54/hour, ~$0.50-2 a run).
