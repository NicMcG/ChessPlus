# Balance run 3: colour swings (AWS sims server, 22 October 2026)

Does the colour a player gets decide too many games? Three parts. The full
tables are in `report.md`, made by `tools/balance/run3_analyse.py`.

| Part | What | Settings |
|---|---|---|
| 1 | Round robin: the 10 armies of `engine/plusfish/reports/meta_pool.txt` (run 2's regrown pool) plus Standard | 55 pairings x 40 games (20 with each colour) = 2,200 games, 8,000 nodes per move, `--random-plies 4`, seeds 3000-3054 (3000 + pairing number; `pairings.txt`, `armies.txt`) |
| 2 | Run 2's self-play games re-read: colour-swapped pairs (same two armies, colours swapped) | 20,000 games at 8,000 nodes (seed 101) and 20,000 at 32,000 (seed 202), selfplay's default 4 random opening plies; 10,000 pairs each |
| 3 | Chess benchmark: Standard vs Standard | 4,000 games at 8,000 nodes (seed 301) and 4,000 at 32,000 (seed 302), `--random-plies 4` |

- **Game version 8a02334** (Plusfish unchanged since run 2's 1c9f93f).
  Server: `chessplus-sims`, c8g.16xlarge (64 Graviton4 cores); part 1 ran 16
  pairings at a time with 4 threads each, part 3 with 64 threads.
- Scripts: `tools/balance/run3_server.sh` (parts 1 and 3, on the server) and
  `tools/balance/run3_analyse.py` (everything else). `progress.log` has the
  times: the games took 9 minutes. The server ran 05:49 to 06:00 UTC, about
  $0.49, and was stopped through AWS.
- The game files (9.6 MB) are not in the repo: they're on Mac's PC in
  `Documents\ChessPlusSims\run3\`, with run 2's in `...\run2\`.
- Random opening plies: the first 4 plies are picked at random among good
  moves, so repeated games differ.
- Definitions: points = percentage points; a gap = an army's score as White
  minus its score as Black; "White won both" = White won both games of a
  colour-swapped pair; long-range piece = a move reaching 4+ squares in a line
  (Archer, Bard, Bishop, Cannon, Chariot, Galleon, Lance, Parapet, Princess,
  Queen, Ram, Rook, Vampire, Wizard); "first two moves" = the first 4 plies.
  Part 2's features are for the two armies of a pair together, since each
  plays both colours.

## Success test (decided before running)

No pool army's White-minus-Black gap over 30 points, and no pairing with White
at 80% or more (all 55 pairings).

**Result: failed.**

- Gaps over 30 points: **Wide 9b +41.0** (95% +33.4 to +48.6) and **Wide 15a
  +32.2** (+25.0 to +39.5). The other eight pool armies: +20.2 to +29.5.
- Pairings with White at 80% or more: **7 of 55**: Wide 9b vs Wide 12b 100%
  (White won all 40), Wide 14b vs Wide 15a 90.0%, Wide 9b vs Wide 11a 87.5%,
  Wide 15c vs Wide 11a 86.2%, Wide 12b vs Wide 15a 86.2%, Wide 14b vs Wide 15c
  83.8%, Wide 15b vs Wide 14c 82.5%.

## What else it showed

- **Plain chess has a big colour gap at this engine depth too.** Standard vs
  Standard at 8,000 nodes: White 59.7% (95% 58.5-61.0), i.e. a gap of about
  19 points with no Chess Plus pieces at all. The pool armies average a 27.5
  point gap at the same settings, so most of part 1's gaps are what the engine
  does at 8,000 nodes in any game, and the pool adds roughly 8 points on top.
- **That engine effect isn't stable across depth.** At 32,000 nodes Standard
  vs Standard gives White only 48.1% (46.8-49.4), slightly below 50%. Part 1
  was run only at 8,000 nodes, as planned.
- **Colour-decided pairs are not more common than in chess.** White won both
  games of a pair: pool round robin 16.7% (14.6-19.0); run 2's random armies
  12.6% (8k) and 13.0% (32k); Standard 20.2% (8k) and 11.3% (32k); chess
  benchmark 23%.
- **Archers and abilities don't explain it.** Gaps by Archers in the army:
  pool armies with 0 average +28.8, with 1 +26.1, with 2 +29.5. In run 2, the
  number of Archers, having any ability piece, and using an ability in the
  first two moves made no clear difference, alone or in the regression.
- **Empty starting squares do, a little (32k).** In run 2 at 32,000 nodes,
  each extra empty square in the two armies' starting rows raised the odds of
  White winning both by about 5% (odds ratio 1.052, 95% 1.029-1.076); pairs
  with 6-14 empty squares 15.0%, with 0-1 9.8%. At 8,000 nodes the same
  direction, not clear (1.023, p = 0.056). Long-range pieces: slightly more
  White-won-both in both runs, not clear (p about 0.06-0.07).

## Afterwards: where White's edge comes from

Checked the same day on Mac's PC (no server). Armies have no pawn wall, so
long-range front-row pieces and Crack Shot can capture before anyone has
moved, and White goes first. Using "White's first move was a capture or an
ability" as the sign of that:

| Games | White's first move captures | White scores then | Otherwise |
|---|---|---|---|
| run 2, random armies, 8k | 23.5% of games | 67.2% | 52.6% |
| run 2, random armies, 32k | 23.3% | 68.3% | 53.0% |
| run 3, meta pool, 8k | 52.1% | 71.1% | 53.7% |

Without a first-move capture, White already scores about 53%, inside chess's
54-56%. Plusfish rates the chess start +0.29 (2M nodes), like top chess
engines (+0.20 to +0.35). Each pool army against itself (the same measure for
an army): Wide 15b +4.59 (1. Axb7!), 14a +4.53 (1. Axb7!), 14c +3.86
(1. Axb7!), 15c +3.28 (1. Bxg7), 9b +2.91 (1. Lxa7), 11a +1.90 (1. Lxh7),
12b +0.65, 15a +0.42, 14b +0.16, 13c +0.07.

These are engine-vs-engine results, not human play. Balancing decisions are
Mac's.
