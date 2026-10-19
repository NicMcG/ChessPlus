# Chess Plus: findings from Plusfish (October 2026)

Everything below comes from Plusfish, an engine whose rules were checked
position by position against the game's own GDScript engine (142,000
positions from 630 random army games, zero differences). Design decisions are
Mac's; these are observations and options.

## 1. Bug: a king can be captured on move 1

Two legal armies can start with Black's king already attacked. White's first
move can then capture it, and the game carries on.

* How often: in 5.5% of random legal army pairings, Black's king can be
  captured on move 1. In another 5.6%, White starts in check. Real players
  leave fewer gaps than random armies do, but anyone who spots it can set it
  up on purpose.
* Minimal example (both armies legal, 37.5 and 38 points): White = standard,
  but a Lance on e2 instead of the pawn and no g1 knight; Black = standard
  without the e7 pawn. White's legal moves include `e2xe8=Q` (and =R/N/B/L),
  which takes the king. Reproduce it in the game's engine with
  `verify/king_capture_demo.gd`.
* What happens next: the side without a king can never be in check, so it
  can never be checkmated. It can only draw or win. Taking the king is actually
  a mistake for White.
* Knock-on: Raise Dead can bring a captured king back (seen in a traced game),
  since kings aren't excluded from the lost-piece list.
* Causes: anything that attacks the far king's square through the empty middle
  of the board at the start: a rook, queen or Lance on an open file, a cannon
  with exactly one screen, a Wizard or bishop-type on an open diagonal.
* Possible fixes (Mac's call): treat a king capture as winning the game; or
  make starting positions with an attacked king invalid when the match is set
  up (it depends on both armies, so the army builder can't check it on its
  own); or let the side whose king is attacked at the start move first.

## 2. Piece values compared with their costs

From 15,989 engine-vs-engine games between random legal armies. Budgets varied
between 33 and 39 points so that piece values can be measured; each pairing was
played with both colours. "Worth" is on the army-cost scale (scaled so that on
average worth = cost), with a 95% range.

| Piece | Cost | Measured worth | Verdict |
|---|---|---|---|
| Queen | 9 | 10.33 ± 0.40 | underpriced by ~1.3 |
| Wizard | 8 | 8.26 ± 0.35 | about right |
| Rook | 5 | 4.65 ± 0.22 | slightly overpriced (−0.3) |
| Archer | 4 | 4.55 ± 0.19 | underpriced by ~0.5 |
| Cannon | 4 | 3.53 ± 0.18 | overpriced (−0.5) |
| Chariot | 4 | 3.67 ± 0.18 | slightly overpriced (−0.3) |
| Ram | 3.5 | 2.95 ± 0.16 | overpriced by ~0.6 |
| Rogue | 3.5 | 3.50 ± 0.17 | about right |
| Bishop | 3 | 3.39 ± 0.15 | slightly underpriced (+0.4) |
| Cavalry | 3 | 3.22 ± 0.15 | slightly underpriced (+0.2) |
| Knight | 3 | 2.99 ± 0.15 | about right |
| Man | 3 | 2.80 ± 0.15 | slightly overpriced (−0.2) |
| Necromancer | 3 | 3.66 ± 0.16 | underpriced by ~0.7 |
| Berserker | 2.5 | 2.67 ± 0.14 | slightly underpriced (+0.2) |
| Lance | 2.5 | 3.43 ± 0.14 | underpriced by ~0.9 |
| Paladin | 2 | 1.54 ± 0.12 | overpriced (−0.5) |
| Elephant | 1.5 | 1.00 ± 0.10 | overpriced (−0.5) |
| Pawn | 1 | 0.83 ± 0.05 | slightly overpriced (−0.2) |

An earlier, independent run of 8,000 games, played by a weaker version of the
engine, gave the same picture: the same pieces flagged, in the same
directions.

Notes:

* **Lance**: worth ~3.4, but only ~2.35 while it's still a Lance. Most of its
  value is promotion. With a forward-only slide it often walks to the far rank.
* **Archer**: an unused Crack Shot is worth about 1.1 points on its own.
* **Paladin**: an intact shield is worth about 0.66, about a third of its
  cost.
* **Ram**: dying on its first capture makes it worth noticeably less than a
  rook-mover should be.
* **Cannon**: its on-board worth is only ~2.5. Captures need a screen, and
  the boards empty out.

## 3. White's first-move edge is large

White scored 58.5% between equal-strength armies, about +76 Elo, much more
than in standard chess. Army boards have holes in the first two rows, so lines
open early and the first attacker gains more.

## 4. Context matters: Berserkers in front of a standard back row

`plusfish match --white "RNBQKBNR/1(BR)PPP(BR)2" --black standard --games 300`.
That's the standard army with two Berserkers and three pawns instead of eight
pawns: same cost, 39. It scored **73% (+174 ±40 Elo)**. The random-army numbers
rate the Berserker only a little above its cost, so in this setup it's much
stronger than average: its forward reach and a full back row behind it work
well together. Worth testing specific army ideas this way before they reach
players.

## Caveats

Engine games (about 6,000 nodes per move, randomised openings) aren't human
games. Engines are better at using long-range pieces and at defending against
one-shot tricks. Treat these as strong hints. After changing costs, re-run
`plusfish selfplay` and `plusfish values` to check the new prices.
