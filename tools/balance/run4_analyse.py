"""Balance run 4 (Mac's "Quiet first move" rule): compares it with the same
measurements without the rule (run 3's pool round robin, run 2's 8k self-play).

    python tools/balance/run4_analyse.py --run4 <run4 folder> --run3 <run3 folder> \
        --run2-8k <run2 8k games.jsonl> --out balance/results/run4/report.md

Uses run3_analyse.py's helpers (same statistics).
"""
import argparse
import glob
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run3_analyse as r


def pool_scores(folder):
    """Each army's (as White, as Black) scores and White's score per pairing."""
    armies = [line.rstrip("\n").split("|", 1) for line in open(os.path.join(folder, "armies.txt"), encoding="utf-8") if line.strip()]
    pairings = [tuple(int(v) for v in line.split("|")) for line in open(os.path.join(folder, "pairings.txt"), encoding="utf-8") if line.strip()]
    as_white = {i: [] for i in range(len(armies))}
    as_black = {i: [] for i in range(len(armies))}
    pairs = {}
    every = []
    both = [0, 0]
    for k, i, j in pairings:
        games = r.read_games(os.path.join(folder, "pairs", "p%d.jsonl" % k))
        for n, g in enumerate(games):
            w, b = (i, j) if n % 2 == 0 else (j, i)
            as_white[w].append(g["result"])
            as_black[b].append(1 - g["result"])
            every.append(g["result"])
        for n in range(0, len(games) - 1, 2):
            both[1] += 1
            both[0] += r.white_won_both(games[n], games[n + 1])
        pairs[(armies[i][0], armies[j][0])] = sum(g["result"] for g in games) / len(games)
    return armies, as_white, as_black, pairs, every, both


def gap(as_white, as_black, i):
    wm, _, _, ws = r.mean_range(as_white[i])
    bm, _, _, bs = r.mean_range(as_black[i])
    return 100 * (wm - bm), 100 * 1.96 * (ws * ws + bs * bs) ** 0.5, wm, bm


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run4", required=True)
    ap.add_argument("--run3", required=True)
    ap.add_argument("--run2-8k", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    out = ["# Balance run 4: the Quiet first move rule (report)\n",
           "Made by `tools/balance/run4_analyse.py`. \"Before\" = the same measurement without the rule "
           "(run 3's pool round robin, run 2's 8k self-play); \"after\" = with the rule (Plusfish "
           "`--quiet-first-move=true`). Points = percentage points.\n"]

    armies, w4, b4, pairs4, every4, both4 = pool_scores(args.run4)
    _, w3, b3, pairs3, every3, both3 = pool_scores(args.run3)
    out.append("## Part 1: meta pool round robin (same armies, seeds and settings)\n")
    lo4, hi4 = r.wilson(*both4)
    lo3, hi3 = r.wilson(*both3)
    out.append("| | Before | After |\n|---|---|---|")
    out.append("| White's score, all 2,200 games | %s | %s |" % (r.pct(sum(every3) / len(every3)), r.pct(sum(every4) / len(every4))))
    out.append("| White won both games of a swapped pair | %s (%s-%s) | %s (%s-%s) |"
               % (r.pct(both3[0] / both3[1]), r.pct(lo3), r.pct(hi3), r.pct(both4[0] / both4[1]), r.pct(lo4), r.pct(hi4)))
    out.append("| Pairings with White at 80%%+ | %d | %d |"
               % (sum(1 for v in pairs3.values() if v >= r.WHITE_LIMIT), sum(1 for v in pairs4.values() if v >= r.WHITE_LIMIT)))
    out.append("\n**Each army's gap (White score minus Black score, points; 95% range for after)**\n")
    out.append("| Army | Before | After | As White / as Black after |\n|---|---|---|---|")
    big = []
    for i, (name, text) in enumerate(armies):
        g3 = gap(w3, b3, i)
        g4 = gap(w4, b4, i)
        out.append("| %s | %+.1f | %+.1f (%+.1f to %+.1f) | %s / %s |"
                   % (name, g3[0], g4[0], g4[0] - g4[1], g4[0] + g4[1], r.pct(g4[2]), r.pct(g4[3])))
        if text != "standard" and g4[0] > r.GAP_LIMIT:
            big.append("%s (%+.1f)" % (name, g4[0]))
    lopsided = ["%s vs %s (%s)" % (a, b, r.pct(v)) for (a, b), v in pairs4.items() if v >= r.WHITE_LIMIT]

    out.append("\n## Part 2: random armies (run 2's 8k self-play, same seed)\n")
    before = r.read_games(args.run2_8k)
    after = r.read_games(os.path.join(args.run4, "selfplay_8k.jsonl"))
    out.append("| | Before | After |\n|---|---|---|")
    for label, fn in (("Games", lambda g: "%d" % len(g)),
                      ("White's score", lambda g: "%s (%s-%s)" % tuple(r.pct(x) for x in r.mean_range([x["result"] for x in g])[:3])),
                      ("Draws", lambda g: r.pct(sum(1 for x in g if x["result"] == 0.5) / len(g)))):
        out.append("| %s | %s | %s |" % (label, fn(before), fn(after)))
    for games, label in ((before, "Before"), (after, "After")):
        pairs, _ = r.swapped_pairs(games)
        k = sum(r.white_won_both(a, b) for a, b in pairs)
        lo, hi = r.wilson(k, len(pairs))
        out.append("| White won both (%s) | %d pairs | %s (%s-%s) |" % (label.lower(), len(pairs), r.pct(k / len(pairs)), r.pct(lo), r.pct(hi)))

    out.append("\n## Part 3: each army against itself (Plusfish at 2,000,000 nodes, 8 threads)\n")
    out.append("White's first-move advantage in pawns, as an engine sees the start. Chess: +0.29 "
               "(top engines: +0.20 to +0.35).\n")
    out.append("| Army | Without the rule | With the rule |\n|---|---|---|")
    for line in open(os.path.join(args.run4, "mirror.txt"), encoding="utf-8").read().splitlines()[1:]:
        name, without, with_rule = line.split("|")

        def short(text):
            # "Best move: Axb7! (g2!b7)  eval +3.34  [...]" -> "+3.34 (Axb7!)"
            if "eval" not in text:
                return text
            move = text.split("Best move:")[1].split("(")[0].strip()
            return "%s (%s)" % (text.split("eval")[1].split()[0], move)
        out.append("| %s | %s | %s |" % (name, short(without), short(with_rule)))

    out.append("\n## Success test (run 3's, with the rule)\n")
    out.append("- Pool armies with a gap over 30 points: %s" % (", ".join(big) if big else "none"))
    out.append("- Pairings with White at 80%% or more: %s" % (", ".join(lopsided) if lopsided else "none"))
    out.append("- **Result: %s**" % ("PASSED" if not big and not lopsided else "FAILED"))
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
