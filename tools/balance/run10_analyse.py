"""Balance run 10: a meta pool grown with the White-only quiet first move
(Plusfish --white-quiet-first=true), its round robin with the rule, and each
pool army against itself. Mac's success test as in runs 8 and 9; its
random-army line comes from run 9 (random armies don't depend on the pool).

    python tools/balance/run10_analyse.py --run10 <run10 folder> \
        --run9-random <run9 selfplay_8k.jsonl> --out balance/results/run10/report.md

Uses run8_9_analyse.py's helpers (same statistics as runs 3-9).
"""
import argparse
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run3_analyse as r
import run8_9_analyse as a


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run10", required=True)
    ap.add_argument("--run9-random", required=True)
    ap.add_argument("--pieces", default="data/pieces")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    pieces = r.read_pieces(args.pieces)
    out = ["# Balance run 10: a meta pool grown with the White-only quiet first move (report)\n",
           "Made by `tools/balance/run10_analyse.py`. Rule (Plusfish `--white-quiet-first=true`): White may not "
           "capture, break a shield or use an ability on its first move unless in check; Black's first move is "
           "unrestricted. The pool was grown with the rule on, from run 7's pool plus Standard. Points = "
           "percentage points.\n"]

    rows = a.pool_pawns(args.run10)
    out.append("## The new pool\n")
    out.append("| Army | Pieces | Pawns | ...in the front row | Cost |\n|---|---|---|---|---|")
    for name, army, pawns, front, n, cost in rows:
        out.append("| %s `%s` | %d | %d | %d | %s |" % (name, army, n, pawns, front, cost))
    armies, ranked = a.diversity(args.run10, pieces)
    out.append("\n**Piece diversity:** %d piece types (not the King) in %d armies. Armies with each: %s\n"
               % (len(ranked), armies, ", ".join("%s %d" % (pieces.get(s, {}).get("name", s), c) for s, c in ranked)))

    rr = a.round_robin(args.run10)
    every = [g for k, i, j in [tuple(int(v) for v in l.split("|")) for l in open(os.path.join(args.run10, "pairings.txt")) if l.strip()]
             for g in r.read_games(os.path.join(args.run10, "pairs", "p%d.jsonl" % k))]
    mean, lo, hi, _ = r.mean_range([g["result"] for g in every])
    a.write_rr(out, rr, "Round robin of the new pool + Standard, with the rule (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000+)")
    out.append("\nWhite's score with its 95%% range: %s (%s-%s)." % (r.pct(mean), r.pct(lo), r.pct(hi)))

    out.append("\n## Each pool army against itself (Plusfish at 2,000,000 nodes, 8 threads)\n")
    out.append("White's first-move advantage in pawns; negative = Black ahead. Chess: +0.29 (top engines +0.20 to +0.35).\n")
    out.append("| Army | Without the rule | With the rule |\n|---|---|---|")
    with_rule = []
    for line in open(os.path.join(args.run10, "mirror.txt"), encoding="utf-8").read().splitlines()[1:]:
        source, name, army, without, rule = line.split("|", 4)
        x, xm = a.mirror_score(without)
        y, ym = a.mirror_score(rule)
        if y is not None:
            with_rule.append((y, name))
        fmt = lambda v, m: "%+.2f (%s)" % (v, m) if v is not None else m
        out.append("| %s `%s` | %s | %s |" % (name, army, fmt(x, xm), fmt(y, ym)))
    if with_rule:
        vals = [v for v, _ in with_rule]
        out.append("\nWith the rule: median %+.2f; within ±0.35: %d of %d; over +1: %s; Black ahead by more than a pawn: %s"
                   % (statistics.median(vals), sum(1 for v in vals if -0.35 <= v <= 0.35), len(vals),
                      ", ".join("%s %+.2f" % (n, v) for v, n in with_rule if v > 1) or "none",
                      ", ".join("%s %+.2f" % (n, v) for v, n in with_rule if v < -1) or "none"))

    random_white = r.mean_range([g["result"] for g in r.read_games(args.run9_random)])[0]
    checks = a.verdict(random_white, rr)
    checks[0] = (checks[0][0] + " (run 9: random armies don't depend on the pool)", checks[0][1], checks[0][2])
    out.append("\n## Success test\n")
    a.checks_md(out, checks)
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    open(args.out, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("\n".join(out[-8:]))
    print("RR white %s (%s-%s), W1st %s, B1st %s, both %s, max gap %+.1f, 80%%+ %d" % (
        r.pct(mean), r.pct(lo), r.pct(hi), r.pct(rr["white_first"]), r.pct(rr["black_first"]), r.pct(rr["both"]),
        max(g[2] for g in rr["gaps"] if g[1] != "standard"), len(a.lopsided(rr))))


if __name__ == "__main__":
    main()
