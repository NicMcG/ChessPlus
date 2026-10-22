"""Balance run 6 (the Front-row rule with strong armies): run 3's round robin
and success test on a meta pool regrown under the rule, each pool army against
itself, and random armies at 32,000 nodes compared with run 2's.

    python tools/balance/run6_analyse.py --run6 <run6 folder> \
        --run2-32k <run2 32k games.jsonl> --out balance/results/run6/report.md

Uses run3_analyse.py's helpers (same statistics and success test).
"""
import argparse
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run3_analyse as r
import run5_analyse as r5


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run6", required=True)
    ap.add_argument("--run2-32k", required=True)
    ap.add_argument("--pieces", default="data/pieces")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    pieces = r.read_pieces(args.pieces)
    out = ["# Balance run 6: the Front-row rule with strong armies (report)\n",
           "Made by `tools/balance/run6_analyse.py`. The meta pool was regrown with Plusfish enforcing the "
           "Front-row rule (`engine/plusfish` on branch `experiment/front-row-rule`, `--front-row-rule=true`); "
           "parts 1 and 2 use run 3's settings, so they compare with run 3 directly. Points = percentage points.\n"]
    big_gaps, lopsided = r.part1(args.run6, pieces, out)
    out[out.index("## Part 1: meta pool round robin\n")] = "## Part 1: round robin of the new pool (run 3's settings)\n"

    out.append("\n## Part 2: each army against itself (Plusfish at 2,000,000 nodes, 8 threads)\n")
    out.append("White's first-move advantage in pawns. Chess: +0.29 (top engines +0.20 to +0.35).\n")
    out.append("| Army | White's advantage | Plusfish's first move |\n|---|---|---|")
    for line in open(os.path.join(args.run6, "mirror.txt"), encoding="utf-8").read().splitlines()[1:]:
        name, army, res = line.split("|", 2)
        if "eval" in res:
            out.append("| %s `%s` | %s | %s |" % (name, army, res.split("eval")[1].split()[0],
                                                  res.split("Best move:")[1].split("(")[0].strip()))

    out.append("\n## Part 3: random armies at 32,000 nodes\n")
    before = r5.describe(r.read_games(args.run2_32k))
    after = r5.describe(r.read_games(os.path.join(args.run6, "selfplay_32k.jsonl")))
    out.append("| | Run 2 (no rule, 32k) | Run 6 (Front-row rule, 32k) |\n|---|---|---|")
    for key, label in (("games", "Games"), ("white", "White's score (95%)"), ("draws", "Draws"),
                       ("both", "White won both games of a swapped pair (chess benchmark 23%)"),
                       ("first", "Games where White's first move captures or uses an ability"),
                       ("plies", "Mean game length (plies)")):
        out.append("| %s | %s | %s |" % (label, before[key], after[key]))

    out.append("\n## Success test (run 3's, decided before running), on the new pool\n")
    out.append("- Pool armies with a gap over 30 points: %s" % (", ".join("%s (%+.1f)" % g for g in big_gaps) if big_gaps else "none"))
    out.append("- Pairings with White at 80%% or more: %s"
               % (", ".join("%s vs %s (%s)" % (a, b, r.pct(m)) for a, b, m in lopsided) if lopsided else "none"))
    out.append("- **Result: %s**" % ("PASSED" if not big_gaps and not lopsided else "FAILED"))
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
