# Balance run 7: the meta pool regrown with the improved Plusfish (AWS sims server, 22 October 2026)

Mac merged Nicholas's PR #26 (Plusfish judges the start of a game better) and
asked for a new meta pool. Normal rules (no Front-row rule). Same settings as
run 2's regrowth, then run 3's colour checks on the new pool. Full tables in
`report.md` (`tools/balance/run6_analyse.py`).

| Part | What | Settings |
|---|---|---|
| 1 | Meta pool regrown (`meta_pool.txt`, `meta.log`) | `meta --wide 64 --game-climb --king-exposed reject --rounds 15 --seed 1`, from run 2's pool, Plusfish commit 2a93f06 (main + PR #26; the Front-row rule off) |
| 2 | Round robin of the new pool + Standard, Mac's success test | run 3's settings: 40 games a pairing, 8,000 nodes, `--random-plies 4`, seeds 3000-3054 |
| 3 | Each pool army against itself | `plusfish analyse`, 2,000,000 nodes, 8 threads (`mirror.txt`) |

- Server: `chessplus-sims` (c8g.16xlarge, 64 cores), 21:39-22:25 UTC, after
  run 6 in the same session (see run 6's README for the cost), stopped through
  AWS. Game files: `Documents\ChessPlusSims\run7\`.
- **This is now the official pool:** `engine/plusfish/reports/meta_pool.txt`.
  One member of run 2's pool survived; it's renamed "Wide 14a (run 2)" there,
  since a new member is also called Wide 14a.

## Results

- **The colour problem is still there with the better Plusfish:** White 59.4%
  overall (run 3: 62.7%); White won both of a swapped pair 12.5%; Wide 11a's
  gap +31.2; 3 pairings with White at 80%+ (Wide 11a vs Wide 7c 97.5%).
  **Success test: failed.**
- Against themselves, 5 of the 10 armies start +3 to +4.1 for White, again
  through first-move captures (1. Axg7!, 1. Lxd7+, 1. Bxf7+).
- The pool: Assassin and Bishop in 9 of 10 armies; Queen and Ghost in 8;
  Archer, Necromancer and Elephant in 7; Standard scores 7-12% against them.
