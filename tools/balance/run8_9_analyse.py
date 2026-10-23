"""Balance runs 8 (cheaper pawns) and 9 (White-only quiet first move), with
today's Plusfish and no change as the control, compared with runs 2, 4, 5,
6 and 7. Checks Mac's success test (decided before running) for each run.

    python tools/balance/run8_9_analyse.py --run8 <run8 folder> --run9 <run9 folder> \
        --pieces data/pieces --out8 balance/results/run8/report.md \
        --out9 balance/results/run9/report.md

<run8 folder> holds p075/ and p050/ (what tools/balance/run8_server.sh wrote
for each Pawn price, on branch experiment/cheap-pawns); <run9 folder> is what
tools/balance/run9_server.sh wrote (branch experiment/white-quiet-first),
including the control self-play. Uses run3_analyse.py's helpers (same
statistics as runs 3-7).

Success test (Mac, 23 Oct 2026, decided before running), for each run:
  - White scores 52-55% in random armies and in the round robin;
  - no pool army's White-minus-Black gap is over 30 points;
  - no pairing has either colour at 80% or more;
  - Black is not favoured overall (White at least 50%).
"""
import argparse
import os
import re
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run3_analyse as r

ABILITY_MARKS = ("!", "@", "~")
WHITE_LOW, WHITE_HIGH = 0.52, 0.55
GAP_LIMIT = 30.0
COLOUR_LIMIT = 0.80


def capture_or_ability(move):
    return "x" in move or any(mark in move for mark in ABILITY_MARKS)


def first_moves(games):
    """Share of games whose White first move / Black first move captured or used an ability."""
    white = sum(1 for g in games if g["moves"].split()[:1] and capture_or_ability(g["moves"].split()[0]))
    black = sum(1 for g in games if len(g["moves"].split()) > 1 and capture_or_ability(g["moves"].split()[1]))
    return white / len(games), black / len(games)


def random_armies(path):
    """Figures from a random-army self-play file."""
    games = r.read_games(path)
    results = [g["result"] for g in games]
    mean, lo, hi, _ = r.mean_range(results)
    pairs, _ = r.swapped_pairs(games)
    both = sum(r.white_won_both(a, b) for a, b in pairs)
    w_first, b_first = first_moves(games)
    return {
        "games": len(games), "white": mean, "lo": lo, "hi": hi,
        "draws": sum(1 for x in results if x == 0.5) / len(results),
        "both": both / len(pairs) if pairs else float("nan"), "pairs": len(pairs),
        "white_first": w_first, "black_first": b_first,
        "plies": sum(g["plies"] for g in games) / len(games),
        "pawns": statistics.mean(r.army_symbols(g["white"]).count("P") + r.army_symbols(g["black"]).count("P")
                                 for g in games) / 2,
    }


def round_robin(folder):
    """Pool round robin: each army's scores by colour, White's score per pairing, everything."""
    armies = [line.rstrip("\n").split("|", 1) for line in open(os.path.join(folder, "armies.txt"), encoding="utf-8") if line.strip()]
    pairings = [tuple(int(v) for v in line.split("|")) for line in open(os.path.join(folder, "pairings.txt"), encoding="utf-8") if line.strip()]
    as_white = {i: [] for i in range(len(armies))}
    as_black = {i: [] for i in range(len(armies))}
    pairs = {}
    every = []
    games_all = []
    both = [0, 0]
    for k, i, j in pairings:
        games = r.read_games(os.path.join(folder, "pairs", "p%d.jsonl" % k))
        for n, g in enumerate(games):
            w, b = (i, j) if n % 2 == 0 else (j, i)
            as_white[w].append(g["result"])
            as_black[b].append(1 - g["result"])
            every.append(g["result"])
            games_all.append(g)
        for n in range(0, len(games) - 1, 2):
            both[1] += 1
            both[0] += r.white_won_both(games[n], games[n + 1])
        # White's score when A is White, and when B is White (each 20 games).
        a_white = [g["result"] for n, g in enumerate(games) if n % 2 == 0]
        b_white = [g["result"] for n, g in enumerate(games) if n % 2 == 1]
        pairs[(armies[i][0], armies[j][0])] = (sum(g["result"] for g in games) / len(games),
                                               sum(a_white) / len(a_white), sum(b_white) / len(b_white))
    w_first, b_first = first_moves(games_all)
    gaps = []
    for i, (name, text) in enumerate(armies):
        wm, _, _, ws = r.mean_range(as_white[i])
        bm, _, _, bs = r.mean_range(as_black[i])
        gaps.append((name, text, 100 * (wm - bm), 100 * 1.96 * (ws * ws + bs * bs) ** 0.5, wm, bm))
    return {
        "armies": armies, "pairs": pairs, "gaps": gaps,
        "white": sum(every) / len(every), "games": len(every),
        "both": both[0] / both[1], "white_first": w_first, "black_first": b_first,
    }


def lopsided(rr):
    """Pairings where either colour scored 80%+ (White's score in all 40 games)."""
    out = []
    for (a, b), (white, _, _) in rr["pairs"].items():
        if white >= COLOUR_LIMIT or white <= 1 - COLOUR_LIMIT:
            out.append("%s vs %s (White %s)" % (a, b, r.pct(white)))
    return out


def big_gaps(rr):
    return ["%s (%+.1f)" % (name, gap) for name, text, gap, _, _, _ in rr["gaps"] if text != "standard" and gap > GAP_LIMIT]


def pawn_worth(report_path):
    """The Pawn's row of a balance report: (cost, worth, +-)."""
    for line in open(report_path, encoding="utf-8", errors="replace"):
        if line.startswith("Pawn "):
            parts = line.split()
            # parts[4] is "±0.04" (the ± may not decode cleanly): keep the number.
            return parts[1], parts[3], re.sub(r"[^\d.]", "", parts[4])
    return "?", "?", "?"


def pool_pawns(folder):
    """Each pool army's pawns and how many are in the front row (army text = back/front)."""
    rows = []
    for line in open(os.path.join(folder, "meta_pool.txt"), encoding="utf-8"):
        if line.startswith("#") or not line.strip():
            continue
        cols = [c.strip() for c in line.split("|")]
        army, name = cols[0], cols[1]
        back, front = (army.split("/") + [""])[:2] if "/" in army else (army, "")
        if army.lower() == "standard":
            back, front = "RNBQKBNR", "PPPPPPPP"
        rows.append((name, army, r.army_symbols(back).count("P") + r.army_symbols(front).count("P"),
                     r.army_symbols(front).count("P"), len(r.army_symbols(army)), cols[2] if len(cols) > 2 else ""))
    return rows


def diversity(folder, pieces):
    """Piece types in the pool (not the King): how many armies have each."""
    count = {}
    armies = 0
    for name, army, *_ in pool_pawns(folder):
        if name == "Standard":
            continue
        armies += 1
        for s in set(r.army_symbols(army)):
            if s != "K":
                count[s] = count.get(s, 0) + 1
    ranked = sorted(count.items(), key=lambda kv: (-kv[1], pieces.get(kv[0], {}).get("name", kv[0])))
    return armies, ranked


def mirror_score(text):
    """Plusfish's "Best move: Axb7! (...)  eval +3.34 [...]" -> (3.34, "Axb7!"); mates -> +-99."""
    if "eval" not in text:
        return None, text.strip()
    value = text.split("eval")[1].split()[0]
    move = text.split("Best move:")[1].split("(")[0].strip() if "Best move:" in text else ""
    if value.startswith("#"):
        return (-99.0 if value.startswith("#-") else 99.0), move
    return float(value), move


def verdict(random_white, rr):
    """Mac's success test for one run: list of (check, passed, detail)."""
    checks = []
    if random_white is not None:
        checks.append(("White 52-55% in random armies", WHITE_LOW <= random_white <= WHITE_HIGH, r.pct(random_white)))
    if rr is not None:
        checks.append(("White 52-55% in the round robin", WHITE_LOW <= rr["white"] <= WHITE_HIGH, r.pct(rr["white"])))
        gaps = big_gaps(rr)
        checks.append(("No pool army's gap over 30 points", not gaps, ", ".join(gaps) or "none"))
        lop = lopsided(rr)
        checks.append(("No pairing with either colour at 80%+", not lop, "%d: %s" % (len(lop), ", ".join(lop)) if lop else "none"))
    whites = [x for x in (random_white, rr["white"] if rr else None) if x is not None]
    checks.append(("Black not favoured (White at least 50%)", all(x >= 0.5 for x in whites), ", ".join(r.pct(x) for x in whites)))
    return checks


def write_rr(out, rr, title):
    out.append("\n### %s\n" % title)
    out.append("| | |\n|---|---|")
    out.append("| Games | %d |" % rr["games"])
    out.append("| White's score | %s |" % r.pct(rr["white"]))
    out.append("| White's first move a capture or ability | %s |" % r.pct(rr["white_first"]))
    out.append("| Black's first move a capture or ability | %s |" % r.pct(rr["black_first"]))
    out.append("| White won both games of a swapped pair (chess 23%%) | %s |" % r.pct(rr["both"]))
    out.append("\n**Each army's gap (score as White minus score as Black, points, 95% range)**\n")
    out.append("| Army | Gap | As White | As Black |\n|---|---|---|---|")
    for name, text, gap, half, wm, bm in rr["gaps"]:
        out.append("| %s | %+.1f (%+.1f to %+.1f) | %s | %s |" % (name, gap, gap - half, gap + half, r.pct(wm), r.pct(bm)))
    lop = lopsided(rr)
    out.append("\nPairings with either colour at 80%%+: %s" % ("; ".join(lop) if lop else "none"))


def write_random(out, s, label):
    out.append("| %s | %d | %s (%s-%s) | %s | %s | %s | %s | %s | %.0f | %.1f |"
               % (label, s["games"], r.pct(s["white"]), r.pct(s["lo"]), r.pct(s["hi"]), r.pct(s["draws"]),
                  r.pct(s["both"]), r.pct(s["white_first"]), r.pct(s["black_first"]), "", s["plies"], s["pawns"]))


RANDOM_HEADER = ("| | Games | White's score (95%) | Draws | White won both of a pair | White's 1st move captures/ability "
                 "| Black's 1st move captures/ability | | Plies | Pawns per army |\n|---|---|---|---|---|---|---|---|---|---|")


def checks_md(out, checks):
    for name, ok, detail in checks:
        out.append("- %s: **%s** (%s)" % (name, "yes" if ok else "no", detail))
    out.append("- **Result: %s**" % ("PASSED" if all(ok for _, ok, _ in checks) else "FAILED"))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run8", required=True)
    ap.add_argument("--run9", required=True)
    ap.add_argument("--pieces", default="data/pieces")
    ap.add_argument("--out8", required=True)
    ap.add_argument("--out9", required=True)
    args = ap.parse_args()
    pieces = r.read_pieces(args.pieces)

    control = random_armies(os.path.join(args.run9, "selfplay_control.jsonl"))
    control_pawn = pawn_worth(os.path.join(args.run9, "report_control.txt"))
    summary = {}

    # --- Run 8 -------------------------------------------------------------------
    out = ["# Balance run 8: cheaper pawns (report)\n",
           "Made by `tools/balance/run8_9_analyse.py`. Pawn cost 0.75 and 0.5 (branch `experiment/cheap-pawns`; "
           "nothing else changed), with today's Plusfish. \"Control\" = the same random-army self-play with the "
           "Pawn at 1 and today's Plusfish (run 9's part 0). Points = percentage points.\n"]
    out.append("## Random armies (20,000 games, 8,000 nodes, seed 101)\n")
    out.append(RANDOM_HEADER)
    write_random(out, control, "Control, Pawn 1")
    eights = {}
    for folder, price in (("p075", "0.75"), ("p050", "0.5")):
        path = os.path.join(args.run8, folder)
        eights[price] = {"random": random_armies(os.path.join(path, "selfplay_8k.jsonl")),
                         "rr": round_robin(path), "pawn": pawn_worth(os.path.join(path, "report_8k.txt")),
                         "pool": pool_pawns(path), "div": diversity(path, pieces)}
        write_random(out, eights[price]["random"], "Pawn %s" % price)
    out.append("\n## The Pawn's measured worth (balance report, random armies)\n")
    out.append("| Pawn cost | Worth (army), on the cost scale | ± |\n|---|---|---|")
    out.append("| 1 (control) | %s | %s |" % (control_pawn[1], control_pawn[2]))
    for price, e in eights.items():
        out.append("| %s | %s | %s |" % (price, e["pawn"][1], e["pawn"][2]))
    out.append("\n(Worth is on each run's own cost scale: the average piece's worth equals its cost.)\n")
    for price, e in eights.items():
        out.append("\n## Pawn %s: the meta pool\n" % price)
        out.append("| Army | Pieces | Pawns | ...in the front row | Cost |\n|---|---|---|---|---|")
        for name, army, pawns, front, n, cost in e["pool"]:
            out.append("| %s `%s` | %d | %d | %d | %s |" % (name, army, n, pawns, front, cost))
        pool_only = [row for row in e["pool"] if row[0] != "Standard"]
        out.append("\nPool armies (not Standard): %.1f pawns each on average, %.1f in the front row; armies with 4+ "
                   "pawns in the front row: %d of %d." % (
                       statistics.mean(x[2] for x in pool_only), statistics.mean(x[3] for x in pool_only),
                       sum(1 for x in pool_only if x[3] >= 4), len(pool_only)))
        armies, ranked = e["div"]
        out.append("\n**Piece diversity:** %d piece types (not the King) in %d armies. Armies with each: %s\n"
                   % (len(ranked), armies, ", ".join("%s %d" % (pieces.get(s, {}).get("name", s), c) for s, c in ranked)))
        write_rr(out, e["rr"], "Pawn %s: round robin of this pool + Standard (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000+)" % price)
        checks = verdict(e["random"]["white"], e["rr"])
        out.append("\n**Success test (Pawn %s)**\n" % price)
        checks_md(out, checks)
        summary["Run 8, Pawn %s" % price] = (e["random"], e["rr"], checks)
    os.makedirs(os.path.dirname(args.out8) or ".", exist_ok=True)
    open(args.out8, "w", encoding="utf-8").write("\n".join(out) + "\n")

    # --- Run 9 -------------------------------------------------------------------
    out = ["# Balance run 9: White-only quiet first move (report)\n",
           "Made by `tools/balance/run8_9_analyse.py`. Rule (Plusfish `--white-quiet-first=true`, branch "
           "`experiment/white-quiet-first`): White may not capture, break a shield or use an ability on its first "
           "move unless in check; Black's first move is unrestricted. \"Control\" = today's Plusfish, no rule, same "
           "seed. Points = percentage points.\n"]
    nine = random_armies(os.path.join(args.run9, "selfplay_8k.jsonl"))
    out.append("## Random armies (20,000 games, 8,000 nodes, seed 101)\n")
    out.append(RANDOM_HEADER)
    write_random(out, control, "Control (no rule)")
    write_random(out, nine, "White-only quiet first move")
    rr9 = round_robin(args.run9)
    write_rr(out, rr9, "Round robin: the current meta pool (run 7's) + Standard, with the rule (40 games a pairing, 8,000 nodes, --random-plies 4, seeds 3000-3054). Run 7 is the same without the rule.")
    out.append("\n## Each army against itself (Plusfish at 2,000,000 nodes, 8 threads)\n")
    out.append("White's first-move advantage in pawns; negative = Black ahead. Chess: +0.29 (top engines +0.20 to +0.35).\n")
    out.append("| Source | Army | Without the rule | With the rule |\n|---|---|---|---|")
    black_ahead = []
    stats = {"without": [], "with": []}
    for line in open(os.path.join(args.run9, "mirror.txt"), encoding="utf-8").read().splitlines()[1:]:
        source, name, army, without, with_rule = line.split("|", 4)
        a, am = mirror_score(without)
        b, bm = mirror_score(with_rule)
        if a is not None:
            stats["without"].append(a)
        if b is not None:
            stats["with"].append(b)
            if b < -1.0:
                black_ahead.append("%s %s (%+.2f)" % (source, name, b))
        fmt = lambda v, m: "%+.2f (%s)" % (v, m) if v is not None else m
        out.append("| %s | %s `%s` | %s | %s |" % (source, name, army, fmt(a, am), fmt(b, bm)))
    for key in ("without", "with"):
        vals = stats[key]
        if vals:
            out.append("\n%s the rule: median %+.2f; within +0.35: %d of %d; over +1: %d; Black ahead (below 0): %d; "
                       "Black ahead by more than a pawn: %d" % (
                           key.capitalize(), statistics.median(vals), sum(1 for v in vals if -0.35 <= v <= 0.35), len(vals),
                           sum(1 for v in vals if v > 1), sum(1 for v in vals if v < 0), sum(1 for v in vals if v < -1)))
    out.append("\nArmies starting with Black ahead by more than a pawn with the rule: %s"
               % ("; ".join(black_ahead) if black_ahead else "none"))
    checks9 = verdict(nine["white"], rr9)
    out.append("\n## Success test\n")
    checks_md(out, checks9)
    summary["Run 9, White-only quiet first move"] = (nine, rr9, checks9)
    summary["Control (today's Plusfish, no change)"] = (control, None, verdict(control["white"], None))
    os.makedirs(os.path.dirname(args.out9) or ".", exist_ok=True)
    open(args.out9, "w", encoding="utf-8").write("\n".join(out) + "\n")

    # Machine-readable summary for the README table.
    for label, (rnd, rr, checks) in summary.items():
        print("%s | random %s, White 1st capture %s, Black 1st capture %s, pair both %s | RR %s | gaps>30 %s | 80%%+ %d | %s"
              % (label, r.pct(rnd["white"]), r.pct(rnd["white_first"]), r.pct(rnd["black_first"]), r.pct(rnd["both"]),
                 r.pct(rr["white"]) if rr else "-", ", ".join(big_gaps(rr)) if rr else "-",
                 len(lopsided(rr)) if rr else 0, "PASSED" if all(ok for _, ok, _ in checks) else "FAILED"))


if __name__ == "__main__":
    main()
