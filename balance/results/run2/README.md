# Balance run 2 (AWS sims server, 21 October 2026)

The first run at Mac's new prices (Vampire 6.5, Princess 8.5, Squire 4,
Galleon 3, Elephant 1, Paladin 1.5, Assassin 0.5; Queen kept at 9), plus a
regrown meta pool. Same settings as run 1, so the two compare directly.

| File | What | Settings |
|---|---|---|
| `report_8k_seed101.txt` / `.html` | balance report | 20,000 self-play games, 8,000 nodes per move, seed 101 |
| `report_32k_seed202.txt` / `.html` | balance report | 20,000 self-play games, 32,000 nodes per move, seed 202 |
| `meta_pool.txt`, `meta.log` | meta pool regrown | `meta --wide 64 --game-climb --king-exposed reject --rounds 15 --seed 1`, from `engine/plusfish/reports/meta_pool.txt` |
| `progress.log` | when each step ran | |

- **Game version 1c9f93f.** Server: `chessplus-sims`, c8g.16xlarge (64
  Graviton4 cores), `--threads 64`. Run 1 used a c7a.16xlarge (AMD); the
  engine and its node budgets are the same, so results compare (only speed
  differs).
- Times: 8k run 8 minutes, 32k run 33 minutes, meta pool 27 minutes
  (15 rounds), about $3 in all.
- The raw game records (~18 MB each) stay on the server in
  `~/plusfish-work/run2/` (not in the repo).

## Did the new prices work?

"worth" = what one extra piece at the start is worth from game results, on
the cost scale; average of the 8k and 32k runs (run 1 = old prices).

| Piece | Old cost | New cost | Worth, run 1 | Worth, run 2 | Now |
|---|---|---|---|---|---|
| Vampire | 4 | 6.5 | 6.69 | 7.01 | still ~0.5 under its worth |
| Princess | 7 | 8.5 | 8.40 | 8.41 | about right |
| Squire | 3 | 4 | 4.09 | 3.98 | about right |
| Galleon | 4.5 | 3 | 3.20 | 3.21 | slightly under (+0.2) |
| Elephant | 1.5 | 1 | 0.86 | 0.79 | slightly over (-0.2) |
| Paladin | 2 | 1.5 | 1.45 | 1.42 | about right |
| Assassin | 2 | 0.5 | 0.42 | 0.43 | about right |
| Queen | 9 | 9 | 10.12 | 10.08 | still ~1 under (Mac kept 9) |

Other pieces at least 0.3 off in both runs: Bishop +0.5 (3, worth ~3.5),
Werewolf +0.4, Archer +0.3, Cavalry +0.3; Parapet -0.4, Jester -0.4, Lance
-0.3, Rook -0.3, Pawn -0.3. White scores 56.1% and 56.6% (first-move edge
+52 / +58 Elo).

## The meta pool

All ten armies of the old pool were over the 39 budget at the new prices, so
the pool regrew from Standard alone over 15 rounds. No Vampire, Squire or
Princess is in it now (they were in almost every strong army before); cheap
pieces fill it instead: Assassin in all ten armies, Paladin in nine, Queen,
Knight and Barbarian in eight, Elephant, Bishop and Pawn in seven. The pool
had not settled (members still changing in round 15), as before.

These are engine-vs-engine results, not human play: strong hints, not proof.
Balancing decisions are Mac's, discussed in normal Claude chat.
