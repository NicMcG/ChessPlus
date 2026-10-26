"""Balance run 16: the meta by share (Mac, 26 Oct 2026). Reads the server's
run16 folder (tools/balance/run16_server.sh on the branch experiment/meta-share):
the all-round pools (all/pool_<s>.txt), the specialist pools
(split/pool_<s>_white.txt / _black.txt) and the two grids of all-rounders
against specialists, and writes a report of archetypes as percentages of each
population.

    python tools/balance/run16_analyse.py --run16 <run16 folder> --out balance/results/run16/report.md

An army is its piece list (placement ignored). Two armies are similar when the
points they have in common (the lesser count of each piece type, times its
cost) reach --similar (default 70%) of the budget (40). Archetypes are built
greedily around the most-connected armies of the whole population, so one
archetype can be counted in all three populations, and named by the pieces at
least three quarters of their members have.
"""
import argparse
import glob
import os
import re
import statistics
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import run3_analyse as r
import run14_analyse as r14

BUDGET = 40.0


def read_pool(path, prefix):
    """[(name, army text)] from a pool file, Standard left out."""
    out = []
    if not os.path.exists(path):
        return out
    for l in open(path, encoding="utf-8"):
        if l.startswith("#") or not l.strip():
            continue
        cols = [c.strip() for c in l.split("|")]
        if len(cols) < 2 or cols[1] == "Standard" or cols[0].lower() == "standard":
            continue
        out.append((prefix + cols[1], cols[0]))
    return out


def read_list(path):
    if not os.path.exists(path):
        return []
    return [tuple(l.rstrip("\n").split("|", 1)) for l in open(path, encoding="utf-8") if l.strip()]


class Army:
    def __init__(self, name, text, population, by_symbol):
        self.name, self.text, self.population = name, text, population
        self.counts = {}
        for sym in r.army_symbols(text):
            if sym == "K":
                continue
            self.counts[sym] = self.counts.get(sym, 0) + 1
        self.value = {sym: by_symbol.get(sym, {}).get("value", 0.0) for sym in self.counts}
        self.cost = sum(self.counts[s] * self.value[s] for s in self.counts)
        self.archetype = None


def common_points(a, b):
    return sum(min(a.counts[s], b.counts.get(s, 0)) * a.value[s] for s in a.counts)


def cluster(armies, threshold, by_symbol):
    """Greedy archetypes: the unassigned army with most similar unassigned neighbours becomes a centre."""
    n = len(armies)
    sim = [[common_points(armies[i], armies[j]) >= threshold for j in range(n)] for i in range(n)]
    archetypes = []
    left = set(range(n))
    while left:
        centre = max(left, key=lambda i: (sum(1 for j in left if sim[i][j]), -i))
        members = [j for j in left if sim[centre][j]]
        for j in members:
            left.discard(j)
            armies[j].archetype = len(archetypes)
        archetypes.append({"centre": centre, "members": members})
    # Name each archetype by the pieces at least 3/4 of its members have, dearest first.
    for a in archetypes:
        mem = [armies[j] for j in a["members"]]
        shared = []
        for sym in {s for m in mem for s in m.counts}:
            have = sum(1 for m in mem if sym in m.counts)
            if have >= 0.75 * len(mem):
                mean_n = statistics.mean(m.counts.get(sym, 0) for m in mem)
                shared.append((by_symbol.get(sym, {}).get("value", 0.0) * mean_n, sym, mean_n))
        shared.sort(reverse=True)
        a["defining"] = [(by_symbol.get(sym, {}).get("name", sym), mean_n) for _, sym, mean_n in shared[:5]]
        a["name"] = " + ".join(("%d " % round(mean_n) if round(mean_n) > 1 else "") + nm for nm, mean_n in a["defining"][:3]) or "mixed"
    return archetypes


def grid_scores(folder):
    """White's score per (white index, black index) and per white / per black army, from a run13-style grid."""
    whites, blacks = read_list(os.path.join(folder, "whites.txt")), read_list(os.path.join(folder, "blacks.txt"))
    if not whites or not blacks:
        return None
    pairings = [tuple(int(v) for v in l.split("|")) for l in open(os.path.join(folder, "pairings.txt")) if l.strip()]
    by_white = {i: [] for i in range(len(whites))}
    by_black = {j: [] for j in range(len(blacks))}
    every = []
    for k, i, j in pairings:
        path = os.path.join(folder, "pairs", "p%d.jsonl" % k)
        if not os.path.exists(path):
            continue
        res = [g["result"] for g in r.read_games(path)]
        by_white[i] += res
        by_black[j] += res
        every += res
    return {"whites": whites, "blacks": blacks, "by_white": by_white, "by_black": by_black, "every": every}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run16", required=True)
    ap.add_argument("--pieces", default="data/pieces")
    ap.add_argument("--similar", type=float, default=0.70, help="common points needed, as a share of the budget")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    defs = r14.read_defs(args.pieces)
    by_symbol = {d["symbol"]: d for d in defs.values()}
    base = args.run16

    armies = []
    seeds = sorted(int(re.search(r"pool_(\d+)\.txt", p).group(1)) for p in glob.glob(os.path.join(base, "all", "pool_*.txt")))
    for s in seeds:
        for name, text in read_pool(os.path.join(base, "all", "pool_%d.txt" % s), "S%d " % s):
            armies.append(Army(name, text, "all-round", by_symbol))
        for name, text in read_pool(os.path.join(base, "split", "pool_%d_white.txt" % s), "S%d " % s):
            armies.append(Army(name, text, "White", by_symbol))
        for name, text in read_pool(os.path.join(base, "split", "pool_%d_black.txt" % s), "S%d " % s):
            armies.append(Army(name, text, "Black", by_symbol))
    pops = {p: [a for a in armies if a.population == p] for p in ("all-round", "White", "Black")}
    threshold = args.similar * BUDGET
    archetypes = cluster(armies, threshold, by_symbol)

    out = ["# Balance run 16: the meta by share (report)\n",
           "Made by `tools/balance/run16_analyse.py`. %d independent searches under today's rules and prices (Nicholas's Plusfish of PR #28): "
           "%d all-round armies grown from scratch, %d White-only and %d Black-only armies grown against a frozen set of the best all-rounders. "
           "An army is its piece list (placement ignored); two armies belong to the same archetype when the points they have in common reach "
           "%.0f%% of the budget (%.0f of 40), built greedily around the most-connected armies. Shares are percentages of each population.\n"
           % (len(seeds), len(pops["all-round"]), len(pops["White"]), len(pops["Black"]), 100 * args.similar, threshold)]

    # --- the archetype table ------------------------------------------------------------
    def share(arch, pop):
        n = len(pops[pop])
        return (100.0 * sum(1 for j in arch["members"] if armies[j].population == pop) / n) if n else 0.0
    archetypes.sort(key=lambda a: -(share(a, "all-round") + share(a, "White") + share(a, "Black")))
    out.append("## Archetypes and their share of each population\n")
    out.append("| # | Archetype (pieces most members have, mean count) | All-round (%d) | White-only (%d) | Black-only (%d) | Armies | Example |\n|---|---|---|---|---|---|---|"
               % (len(pops["all-round"]), len(pops["White"]), len(pops["Black"])))
    for k, a in enumerate(archetypes, 1):
        a["number"] = k
        defining = ", ".join("%s x%.1f" % (nm, mn) if mn >= 1.5 else nm for nm, mn in a["defining"])
        centre = armies[a["centre"]]
        out.append("| %d | **%s** (%s) | %s | %s | %s | %d | %s `%s` |" % (
            k, a["name"], defining or "-", "%.0f%%" % share(a, "all-round") if share(a, "all-round") else "-",
            "%.0f%%" % share(a, "White") if share(a, "White") else "-", "%.0f%%" % share(a, "Black") if share(a, "Black") else "-",
            len(a["members"]), centre.name, centre.text))
    singles = sum(1 for a in archetypes if len(a["members"]) == 1)
    out.append("\n%d archetypes in %d armies (%d of them armies on their own)." % (len(archetypes), len(armies), singles))

    # --- pieces by population ------------------------------------------------------------------
    out.append("\n## Pieces by population (share of armies that have the piece, and the mean number when they do)\n")
    syms = sorted({s for a in armies for s in a.counts}, key=lambda s: -by_symbol.get(s, {}).get("value", 0.0))
    out.append("| Piece | Cost | All-round | White-only | Black-only |\n|---|---|---|---|---|")
    for s in syms:
        cells = []
        for p in ("all-round", "White", "Black"):
            have = [a.counts[s] for a in pops[p] if s in a.counts]
            cells.append("%.0f%% (x%.1f)" % (100.0 * len(have) / len(pops[p]), statistics.mean(have)) if have and pops[p] else "-")
        out.append("| %s | %s | %s |" % (by_symbol.get(s, {}).get("name", s), r14.fmt(by_symbol.get(s, {}).get("value", 0.0), 1), " | ".join(cells)))
    front_rows = {}
    for p in ("all-round", "White", "Black"):
        if pops[p]:
            cells = [run15_cells(a.text) for a in pops[p]]
            front_rows[p] = (statistics.mean(sum(1 for c in f if c) for b, f in cells),
                             statistics.mean(sum(1 for c in f if c in ("P", "GR", "AB", "VS")) for b, f in cells),
                             statistics.mean(len(a.counts) + 1 for a in pops[p]))
    out.append("\nFront row: " + "; ".join("%s %.1f of 8 squares filled, %.1f pawn types there, %.1f pieces an army" % (p, v[0], v[1], v[2]) for p, v in front_rows.items()) + ".")

    # --- all-rounders against the specialists -------------------------------------------------------
    avb = grid_scores(os.path.join(base, "allround_vs_black"))
    wva = grid_scores(os.path.join(base, "white_vs_allround"))
    if avb and wva:
        out.append("\n## All-rounders against the colour specialists (20 games a pairing, colours fixed)\n")
        m1, lo1, hi1, _ = r.mean_range(avb["every"])
        m2, lo2, hi2, _ = r.mean_range(wva["every"])
        out.append("| | White's score |\n|---|---|")
        out.append("| All-rounders as White against the Black specialists | %s (%s-%s) |" % (r.pct(m1), r.pct(lo1), r.pct(hi1)))
        out.append("| White specialists against the all-rounders as Black | %s (%s-%s) |" % (r.pct(m2), r.pct(lo2), r.pct(hi2)))
        by_name = {a.name: a for a in armies}
        rows = []
        for i, (name, text) in enumerate(avb["whites"]):
            as_white = statistics.mean(avb["by_white"][i]) if avb["by_white"][i] else float("nan")
            j = next((j for j, (n2, _) in enumerate(wva["blacks"]) if n2 == name), None)
            as_black = 1 - statistics.mean(wva["by_black"][j]) if j is not None and wva["by_black"][j] else float("nan")
            arch = by_name.get(name).archetype if name in by_name else None
            rows.append((name, text, as_white, as_black, arch))
        rows.sort(key=lambda t: -(t[2] + t[3]))
        holds = [t for t in rows if t[2] >= 0.5 and t[3] >= 0.5]
        out.append("\n**All-rounders that hold up against both colours' specialists (50%% or more each way): %d of %d.**\n" % (len(holds), len(rows)))
        out.append("| All-rounder | Archetype | As White vs Black specialists | As Black vs White specialists |\n|---|---|---|---|")
        for name, text, w, b, arch in rows:
            mark = "**" if w >= 0.5 and b >= 0.5 else ""
            out.append("| %s%s%s `%s` | %s | %s | %s |" % (mark, name, mark, text, ("#%d %s" % (archetypes[arch]["number"], archetypes[arch]["name"])) if arch is not None else "-", r.pct(w), r.pct(b)))
        if holds:
            counts = {}
            for _, _, _, _, arch in holds:
                counts[arch] = counts.get(arch, 0) + 1
            out.append("\nArchetypes among the all-rounders that hold up: " + "; ".join(
                "#%d %s %.0f%%" % (archetypes[k]["number"], archetypes[k]["name"], 100.0 * v / len(holds)) for k, v in sorted(counts.items(), key=lambda kv: -kv[1])))
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    open(args.out, "w", encoding="utf-8").write("\n".join(out) + "\n")
    print("\n".join(out[2:min(len(out), 20)]))


def run15_cells(army):
    """(back row, front row) as lists of symbols or "" per square."""
    rows = (army.split("/") + [""])[:2]
    out = []
    for text in rows:
        cells = []
        for token in re.findall(r"\([A-Z]+\)|[A-Z]|\d", text):
            if token.isdigit():
                cells += [""] * int(token)
            else:
                cells.append(token.strip("()"))
        out.append(cells)
    return out[0], out[1]


if __name__ == "__main__":
    main()
