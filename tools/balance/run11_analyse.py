"""Balance runs 11 and 12 (--title / --note for 12): separate White and Black armies (Mac, 24 Oct 2026; report
only, no pass/fail). For each rule set (normal, and the White-only quiet
first move) Plusfish grew a White pool and a Black pool side by side
(`meta --wide --split-colours`), then played:
  specialists        every White army against every Black army
  white_vs_ordinary  the White armies against the ordinary pool playing Black
  ordinary_vs_black  the ordinary pool playing White against the Black armies
All with fixed colours, 40 games a pairing. The ordinary pool's own round
robin (both colours) is the baseline: run 7 for the normal rules, run 10 for
the rule.

    python tools/balance/run11_analyse.py --run11 <run11 folder> \
        --run7 <run7 folder> --run10 <run10 folder> --out balance/results/run11/report.md

Uses run3_analyse.py and run8_9_analyse.py's helpers.
"""
import argparse
import os
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run3_analyse as r
import run8_9_analyse as a

RULES = (("normal", "Normal rules", "run7"), ("rule", "White-only quiet first move", "run10"))


def read_list(path):
    return [line.rstrip("\n").split("|", 1) for line in open(path, encoding="utf-8") if line.strip()]


def grid(folder):
    """A fixed-colour grid: White's score overall, by White army, by Black army,
    per pairing, and first-move captures."""
    whites = read_list(os.path.join(folder, "whites.txt"))
    blacks = read_list(os.path.join(folder, "blacks.txt"))
    pairings = [tuple(int(v) for v in l.split("|")) for l in open(os.path.join(folder, "pairings.txt")) if l.strip()]
    by_white = {i: [] for i in range(len(whites))}
    by_black = {j: [] for j in range(len(blacks))}
    pairs = {}
    games = []
    for k, i, j in pairings:
        path = os.path.join(folder, "pairs", "p%d.jsonl" % k)
        if not os.path.exists(path):
            continue
        g = r.read_games(path)
        games += g
        res = [x["result"] for x in g]
        by_white[i] += res
        by_black[j] += [1 - x for x in res]
        pairs[(whites[i][0], blacks[j][0])] = sum(res) / len(res) if res else float("nan")
    w_first, b_first = a.first_moves(games) if games else (float("nan"), float("nan"))
    mean, lo, hi, _ = r.mean_range([x["result"] for x in games])
    return {"whites": whites, "blacks": blacks, "by_white": by_white, "by_black": by_black, "pairs": pairs,
            "white": mean, "lo": lo, "hi": hi, "games": len(games), "white_first": w_first, "black_first": b_first}


def features(army, pieces):
    """Pieces, pawns, front-row pawns, long-range pieces in the front row, Archers, empty squares."""
    text = "RNBQKBNR/PPPPPPPP" if army.strip().lower() == "standard" else army
    back, front = (text.split("/") + [""])[:2]
    syms = r.army_symbols(text)
    front_syms = r.army_symbols(front)
    return {
        "pieces": len(syms), "pawns": syms.count("P"), "front_pawns": front_syms.count("P"),
        "front_long": sum(1 for s in front_syms if pieces.get(s, {}).get("long_range")),
        "archers": syms.count("A"), "empty": 16 - len(syms),
        "ability": sum(1 for s in syms if pieces.get(s, {}).get("ability")),
    }


def pool_table(out, path, pieces, title):
    lines =[l for l in open(path, encoding="utf-8") if l.strip() and not l.startswith("#")]
    out.append("\n**%s**\n" % title)
    out.append("| Army | Score in games | Pieces | Pawns (front row) | Long-range in front row | Archers | Ability pieces |\n|---|---|---|---|---|---|---|")
    feats = []
    for l in lines:
        cols = [c.strip() for c in l.split("|")]
        army, name, games = cols[0], cols[1], cols[3]
        f = features(army, pieces)
        if name != "Standard":
            feats.append(f)
        out.append("| %s `%s` | %s | %d | %d (%d) | %d | %d | %d |" % (name, army, games, f["pieces"], f["pawns"], f["front_pawns"], f["front_long"], f["archers"], f["ability"]))
    if feats:
        out.append("\nAverages (not Standard): %.1f pieces, %.1f pawns (%.1f in the front row), %.1f long-range pieces in the front row, "
                   "%.1f Archers, %.1f ability pieces." % tuple(statistics.mean(f[k] for f in feats) for k in
                                                             ("pieces", "pawns", "front_pawns", "front_long", "archers", "ability")))
    return feats


def diversity_line(path, pieces):
    count = {}
    n = 0
    for l in open(path, encoding="utf-8"):
        if not l.strip() or l.startswith("#"):
            continue
        cols = [c.strip() for c in l.split("|")]
        if cols[1] == "Standard":
            continue
        n += 1
        for s in set(r.army_symbols(cols[0])):
            if s != "K":
                count[s] = count.get(s, 0) + 1
    ranked = sorted(count.items(), key=lambda kv: (-kv[1], pieces.get(kv[0], {}).get("name", kv[0])))
    return "%d piece types in %d armies: %s" % (len(ranked), n, ", ".join("%s %d" % (pieces.get(s, {}).get("name", s), c) for s, c in ranked))


def armies_in(path):
    return {l.split("|")[0].strip(): l.split("|")[1].strip() for l in open(path, encoding="utf-8") if l.strip() and not l.startswith("#")}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run11", required=True)
    ap.add_argument("--run7", required=True)
    ap.add_argument("--run10", required=True)
    ap.add_argument("--pieces", default="data/pieces")
    ap.add_argument("--out", required=True)
    ap.add_argument("--title", default="Balance run 11: separate White and Black armies (report)")
    ap.add_argument("--note", default="", help="a sentence added to the opening paragraph (e.g. run 12's phases)")
    args = ap.parse_args()
    pieces = r.read_pieces(args.pieces)
    baselines = {"run7": a.round_robin(args.run7), "run10": a.round_robin(args.run10)}
    out = ["# %s\n" % args.title,
           "Made by `tools/balance/run11_analyse.py`. Plusfish grew a White pool and a Black pool side by side "
           "(`meta --wide --split-colours`): a White army is judged only as White against the Black pool, and the other "
           "way round. All games below have fixed colours, 40 games a pairing, 8,000 nodes, `--random-plies 4`. "
           "\"Ordinary pool\" = the one-army-for-both-colours pool for that rule set (run 7's for the normal rules, run 10's "
           "for the White-only quiet first move); its own round robin is the baseline. Points = percentage points.%s\n" % (" " + args.note if args.note else "")]
    summary = []
    for label, title, base_name in RULES:
        folder = os.path.join(args.run11, label)
        if not os.path.isdir(folder):
            out.append("\n## %s: not run\n" % title)
            continue
        base = baselines[base_name]
        out.append("\n## %s\n" % title)
        wpath = os.path.join(folder, "meta_pool_white.txt")
        bpath = os.path.join(folder, "meta_pool_black.txt")
        wf = pool_table(out, wpath, pieces, "White pool (judged only as White)")
        bf = pool_table(out, bpath, pieces, "Black pool (judged only as Black)")
        out.append("\nPiece types, White pool: %s\n" % diversity_line(wpath, pieces))
        out.append("Piece types, Black pool: %s\n" % diversity_line(bpath, pieces))
        both = set(armies_in(wpath)) & set(armies_in(bpath)) - {"standard", "RNBQKBNR/PPPPPPPP"}
        out.append("Armies in both pools: %s\n" % (", ".join("`%s`" % x for x in sorted(both)) if both else "none"))

        spec = grid(os.path.join(folder, "specialists"))
        wvo = grid(os.path.join(folder, "white_vs_ordinary"))
        ovb = grid(os.path.join(folder, "ordinary_vs_black"))
        out.append("\n### Specialists against specialists (every White army against every Black army)\n")
        out.append("| | |\n|---|---|")
        out.append("| Games | %d |" % spec["games"])
        out.append("| White's score (95%%) | %s (%s-%s) |" % (r.pct(spec["white"]), r.pct(spec["lo"]), r.pct(spec["hi"])))
        out.append("| Ordinary pool's round robin, White's score (%s) | %s |" % (base_name.replace("run", "run "), r.pct(base["white"])))
        out.append("| White's first move a capture or ability | %s (ordinary %s) |" % (r.pct(spec["white_first"]), r.pct(base["white_first"])))
        out.append("| Black's first move a capture or ability | %s (ordinary %s) |" % (r.pct(spec["black_first"]), r.pct(base["black_first"])))
        # With fixed colours a lopsided pairing is mostly a strong army against a weak one, not a colour
        # effect, so Standard's pairings (it loses whichever side it plays) are left out of the count.
        real = {k: v for k, v in spec["pairs"].items() if "Standard" not in k}
        lop = ["%s vs %s (White %s)" % (w, b, r.pct(v)) for (w, b), v in real.items() if v >= 0.8 or v <= 0.2]
        out.append("| Uneven matchups: either side at 80%%+ (40 games each, Standard left out; with fixed colours this mixes army strength and colour) | %d of %d |" % (len(lop), len(real)))
        out.append("\nEach White army as White (all Black armies) and each Black army as Black (all White armies):\n")
        out.append("| White army | Score as White | | Black army | Score as Black |\n|---|---|---|---|---|")
        for k in range(max(len(spec["whites"]), len(spec["blacks"]))):
            wcell = ("%s | %s" % (spec["whites"][k][0], r.pct(statistics.mean(spec["by_white"][k])))) if k < len(spec["whites"]) and spec["by_white"][k] else " | "
            bcell = ("%s | %s" % (spec["blacks"][k][0], r.pct(statistics.mean(spec["by_black"][k])))) if k < len(spec["blacks"]) and spec["by_black"][k] else " | "
            out.append("| %s | | %s |" % (wcell, bcell))
        if lop:
            out.append("\nPairings at 80%%+: %s" % "; ".join(lop))

        out.append("\n### Specialists against the ordinary pool\n")
        gain_w = wvo["white"] - base["white"]
        gain_b = base["white"] - ovb["white"]
        out.append("| | White's score | vs the ordinary round robin |\n|---|---|---|")
        out.append("| Ordinary as White against ordinary as Black (%s) | %s | |" % (base_name.replace("run", "run "), r.pct(base["white"])))
        out.append("| White specialists against ordinary as Black | %s (%s-%s) | White gains %+.1f points |" % (r.pct(wvo["white"]), r.pct(wvo["lo"]), r.pct(wvo["hi"]), 100 * gain_w))
        out.append("| Ordinary as White against Black specialists | %s (%s-%s) | Black gains %+.1f points |" % (r.pct(ovb["white"]), r.pct(ovb["lo"]), r.pct(ovb["hi"]), 100 * gain_b))
        out.append("| White specialists against Black specialists | %s | %+.1f points for White overall |" % (r.pct(spec["white"]), 100 * (spec["white"] - base["white"])))
        summary.append((title, base_name, base, spec, wvo, ovb, wf, bf, len(lop), len(real)))

    out.append("\n## Summary\n")
    out.append("| Rules | Ordinary round robin: White | Specialists vs specialists: White | White specialists vs ordinary | Ordinary vs Black specialists | "
               "Uneven matchups (specialists, no Standard) | Long-range front-row pieces: White pool / Black pool |\n|---|---|---|---|---|---|---|")
    for title, base_name, base, spec, wvo, ovb, wf, bf, nlop, nreal in summary:
        out.append("| %s | %s | %s | %s | %s | %d of %d | %.1f / %.1f |" % (
            title, r.pct(base["white"]), r.pct(spec["white"]), r.pct(wvo["white"]), r.pct(ovb["white"]), nlop, nreal,
            statistics.mean(f["front_long"] for f in wf) if wf else float("nan"),
            statistics.mean(f["front_long"] for f in bf) if bf else float("nan")))
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    open(args.out, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("\n".join(out[-(len(summary) + 3):]))


if __name__ == "__main__":
    main()
