"""Balance run 3 (colour swings): turns the games into the report.

    python tools/balance/run3_analyse.py --run3 <run3 folder> \
        --run2-8k <run2 8k games.jsonl> --run2-32k <run2 32k games.jsonl> \
        --out balance/results/run3/report.md

<run3 folder> is what tools/balance/run3_server.sh wrote (armies.txt,
pairings.txt, pairs/p<n>.jsonl, standard_8k.jsonl, standard_32k.jsonl).
Every game file is Plusfish's: one JSON line per game with the two armies (as
text), the result for White (1, 0.5, 0), how it ended and the moves.

Part 1, the meta pool round robin: each army's score as White and as Black and
the gap, White's score in every pairing, flags, gaps by number of Archers.
Part 2, run 2's self-play games: colour-swapped pairs (same two armies, colours
swapped) and how often White won both, overall, split by army features, and
all features together in one logistic regression.
Part 3, Standard vs Standard: White's score and how often White won both games
of a pair.

Plain Python, no extra libraries. 95% ranges: mean +-1.96 standard errors for
scores (draws count half), Wilson intervals for proportions, and the
regression's own standard errors for its odds ratios.
"""
import argparse
import glob
import json
import math
import os
import re

ABILITY_MARKS = ("!", "@", "~")
# The first two moves of each side.
EARLY_PLIES = 4
GAP_LIMIT = 30.0
WHITE_LIMIT = 0.80


# --- Pieces and armies ---------------------------------------------------------

def read_pieces(folder):
    """symbol -> {"name", "ability", "long_range"} from the game's piece files.
    Long range = a move rule reaching 4 or more squares in a line (max_steps 0,
    i.e. unlimited, or 4+). Godot leaves max_steps out when it's the default 1."""
    pieces = {}
    for path in glob.glob(os.path.join(folder, "*.tres")):
        text = open(path, encoding="utf-8").read()
        main = text.split("[resource]", 1)[1]

        def field(name, default=None):
            m = re.search(r"^%s = (.+)$" % name, main, re.M)
            return m.group(1).strip().strip('"') if m else default

        steps = [int(s) for s in re.findall(r"^max_steps = (-?\d+)$", text, re.M)]
        pieces[field("symbol")] = {
            "name": field("display_name"),
            "ability": int(field("ability", "0")) != 0,
            "long_range": any(s == 0 or s >= 4 for s in steps),
        }
    return pieces


def army_symbols(text):
    """The piece symbols in an army as Plusfish writes it ("RNBQKBNR/PPPPPPPP",
    two-letter symbols in brackets, digits for empty squares)."""
    if text.strip().lower() == "standard":
        text = "RNBQKBNR/PPPPPPPP"
    symbols = []
    i = 0
    while i < len(text):
        c = text[i]
        if c == "(":
            j = text.index(")", i)
            symbols.append(text[i + 1:j])
            i = j + 1
        else:
            if not (c.isdigit() or c == "/" or c.isspace()):
                symbols.append(c)
            i += 1
    return symbols


def army_features(text, pieces):
    symbols = army_symbols(text)
    return {
        "archers": symbols.count("A"),
        "ability": any(pieces[s]["ability"] for s in symbols),
        "empty": 16 - len(symbols),
        "long_range": sum(1 for s in symbols if pieces[s]["long_range"]),
    }


def read_games(path):
    games = []
    with open(path, encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line:
                games.append(json.loads(line))
    return games


def early_ability(game):
    """True if a special ability was used in the first two moves of each side."""
    moves = game["moves"].split()[:EARLY_PLIES]
    return any(mark in m for m in moves for mark in ABILITY_MARKS)


# --- Statistics --------------------------------------------------------------------

def mean_range(scores):
    """Mean, and its 95% range (mean +-1.96 standard errors), as fractions."""
    n = len(scores)
    if n == 0:
        return float("nan"), float("nan"), float("nan"), 0.0
    mean = sum(scores) / n
    var = sum((s - mean) ** 2 for s in scores) / max(1, n - 1)
    se = math.sqrt(var / n)
    return mean, mean - 1.96 * se, mean + 1.96 * se, se


def wilson(k, n):
    """A proportion's 95% Wilson interval."""
    if n == 0:
        return float("nan"), float("nan")
    z = 1.96
    p = k / n
    centre = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return centre - half, centre + half


def pct(x):
    return "%.1f%%" % (100 * x)


def solve(a, b):
    """Solve a x = b (Gaussian elimination with pivoting)."""
    n = len(b)
    m = [row[:] + [b[i]] for i, row in enumerate(a)]
    for c in range(n):
        p = max(range(c, n), key=lambda r: abs(m[r][c]))
        m[c], m[p] = m[p], m[c]
        for r in range(n):
            if r != c and m[c][c] != 0:
                f = m[r][c] / m[c][c]
                for k in range(c, n + 1):
                    m[r][k] -= f * m[c][k]
    return [m[i][n] / m[i][i] for i in range(n)]


def inverse(a):
    n = len(a)
    cols = [solve(a, [1.0 if i == j else 0.0 for i in range(n)]) for j in range(n)]
    return [[cols[j][i] for j in range(n)] for i in range(n)]


def logistic_fit(rows, ys):
    """Maximum-likelihood logistic regression by Newton's method. Returns the
    coefficients and their standard errors (rows include the constant 1)."""
    k = len(rows[0])
    beta = [0.0] * k
    for _ in range(100):
        grad = [0.0] * k
        hess = [[0.0] * k for _ in range(k)]
        for x, y in zip(rows, ys):
            z = sum(b * v for b, v in zip(beta, x))
            p = 1 / (1 + math.exp(-z))
            w = p * (1 - p)
            for i in range(k):
                grad[i] += (y - p) * x[i]
                for j in range(k):
                    hess[i][j] += w * x[i] * x[j]
        step = solve(hess, grad)
        beta = [b + s for b, s in zip(beta, step)]
        if max(abs(s) for s in step) < 1e-10:
            break
    cov = inverse(hess)
    return beta, [math.sqrt(cov[i][i]) for i in range(k)]


# --- Colour-swapped pairs -----------------------------------------------------------

def swapped_pairs(games):
    """Pairs of games with the same two armies and colours swapped. Returns the
    pairs and how many games had no partner."""
    by_key = {}
    for g in games:
        by_key.setdefault((g["white"], g["black"]), []).append(g)
    pairs = []
    used = set()
    for (w, b), first in by_key.items():
        if (w, b) in used or w == b:
            continue
        second = by_key.get((b, w))
        if not second:
            continue
        used.add((w, b))
        used.add((b, w))
        for g1, g2 in zip(first, second):
            pairs.append((g1, g2))
    unpaired = len(games) - 2 * len(pairs)
    return pairs, unpaired


def white_won_both(g1, g2):
    return g1["result"] == 1 and g2["result"] == 1


# --- Part 1 ---------------------------------------------------------------------------

def part1(folder, pieces, out):
    armies = []
    for line in open(os.path.join(folder, "armies.txt"), encoding="utf-8"):
        if line.strip():
            name, text = line.rstrip("\n").split("|", 1)
            armies.append((name, text))
    pairings = []
    for line in open(os.path.join(folder, "pairings.txt"), encoding="utf-8"):
        if line.strip():
            k, i, j = (int(v) for v in line.split("|"))
            pairings.append((k, i, j))

    as_white = {i: [] for i in range(len(armies))}
    as_black = {i: [] for i in range(len(armies))}
    rows = []
    both = [0, 0]
    exposed = 0
    all_white = []
    for k, i, j in pairings:
        games = read_games(os.path.join(folder, "pairs", "p%d.jsonl" % k))
        results = []
        for n, g in enumerate(games):
            # plusfish match: A (army i) is White in the even-numbered games.
            w, b = (i, j) if n % 2 == 0 else (j, i)
            r = g["result"]
            as_white[w].append(r)
            as_black[b].append(1 - r)
            results.append(r)
            exposed += g["reason"] == "king_exposed"
        for n in range(0, len(games) - 1, 2):
            both[1] += 1
            both[0] += white_won_both(games[n], games[n + 1])
        all_white += results
        mean, lo, hi, _ = mean_range(results)
        rows.append((armies[i][0], armies[j][0], len(results), mean, lo, hi))

    out.append("## Part 1: meta pool round robin\n")
    out.append("The 10 armies of `engine/plusfish/reports/meta_pool.txt` plus Standard, every pairing "
               "40 games (20 with each colour), 8,000 nodes per move, `--random-plies 4`. "
               "%d games; White scored %s overall. White won both games of a colour-swapped pair "
               "in %d of %d pairs (%s, 95%% %s-%s; chess benchmark 23%%). Games ended by King exposed: %d.\n"
               % (len(all_white), pct(sum(all_white) / len(all_white)), both[0], both[1],
                  pct(both[0] / both[1]), pct(wilson(*both)[0]), pct(wilson(*both)[1]), exposed))

    out.append("### Each army as White and as Black\n")
    out.append("Score = the army's own score (draws half). Gap = White score minus Black score, in points. "
               "95% ranges in brackets.\n")
    out.append("| Army | Archers | As White | As Black | Gap (points) | Flag |")
    out.append("|---|---|---|---|---|---|")
    gaps = {}
    for i, (name, text) in enumerate(armies):
        wm, wl, wh, ws = mean_range(as_white[i])
        bm, bl, bh, bs = mean_range(as_black[i])
        gap = 100 * (wm - bm)
        half = 100 * 1.96 * math.sqrt(ws * ws + bs * bs)
        archers = army_features(text, pieces)["archers"]
        gaps[i] = (gap, gap - half, gap + half, archers)
        flag = "over 30" if gap > GAP_LIMIT else ""
        out.append("| %s | %d | %s (%s-%s), %d games | %s (%s-%s), %d games | %+.1f (%+.1f to %+.1f) | %s |"
                   % (name, archers, pct(wm), pct(wl), pct(wh), len(as_white[i]),
                      pct(bm), pct(bl), pct(bh), len(as_black[i]), gap, gap - half, gap + half, flag))

    out.append("\n### White's score in every pairing\n")
    out.append("| Army A | Army B | Games | White's score | 95% range | Flag |")
    out.append("|---|---|---|---|---|---|")
    for a, b, n, mean, lo, hi in rows:
        flag = "80%+" if mean >= WHITE_LIMIT else ""
        out.append("| %s | %s | %d | %s | %s-%s | %s |" % (a, b, n, pct(mean), pct(max(0, lo)), pct(min(1, hi)), flag))

    out.append("\n### Gaps by how many Archers the army has\n")
    out.append("| Archers | Armies | Mean gap (points) | Each army's gap |")
    out.append("|---|---|---|---|")
    for count in sorted(set(v[3] for v in gaps.values())):
        members = [(armies[i][0], gaps[i][0]) for i in gaps if gaps[i][3] == count]
        mean = sum(g for _, g in members) / len(members)
        out.append("| %d | %d | %+.1f | %s |" % (count, len(members), mean,
                                                  ", ".join("%s %+.1f" % m for m in members)))

    pool = [i for i, (name, text) in enumerate(armies) if text != "standard"]
    big_gaps = [(armies[i][0], gaps[i][0]) for i in pool if gaps[i][0] > GAP_LIMIT]
    lopsided = [(a, b, mean) for a, b, n, mean, lo, hi in rows if mean >= WHITE_LIMIT]
    return big_gaps, lopsided


# --- Part 2 -------------------------------------------------------------------------------

def quantile_buckets(values, groups=5):
    """Ranges [low, high] splitting `values` into about `groups` groups (ties kept together)."""
    ordered = sorted(values)
    edges = []
    for g in range(1, groups):
        edges.append(ordered[int(len(ordered) * g / groups)])
    buckets = []
    low = ordered[0]
    for e in sorted(set(edges)):
        if e > low:
            buckets.append((low, e - 1))
            low = e
    buckets.append((low, ordered[-1]))
    return buckets


def split_table(out, title, labels_and_flags):
    out.append("\n**%s**\n" % title)
    out.append("| Group | Pairs | White won both | Share | 95% range |")
    out.append("|---|---|---|---|---|")
    for label, flags in labels_and_flags:
        n = len(flags)
        k = sum(flags)
        if n == 0:
            continue
        lo, hi = wilson(k, n)
        out.append("| %s | %d | %d | %s | %s-%s |" % (label, n, k, pct(k / n), pct(lo), pct(hi)))


def part2(label, path, pieces, out):
    games = read_games(path)
    pairs, unpaired = swapped_pairs(games)
    data = []
    for g1, g2 in pairs:
        x = army_features(g1["white"], pieces)
        y = army_features(g1["black"], pieces)
        data.append({
            "won": white_won_both(g1, g2),
            "archers": x["archers"] + y["archers"],
            "ability": x["ability"] or y["ability"],
            "empty": x["empty"] + y["empty"],
            "long_range": x["long_range"] + y["long_range"],
            "early": early_ability(g1) or early_ability(g2),
        })
    n = len(data)
    k = sum(d["won"] for d in data)
    lo, hi = wilson(k, n)
    white = [g["result"] for g in games]
    out.append("\n### %s\n" % label)
    out.append("`%s`: %d games, %d colour-swapped pairs (%d games without a partner). White scored %s. "
               "**White won both games in %d pairs: %s (95%% %s-%s)**; chess benchmark 23%%.\n"
               % (os.path.basename(path), len(games), n, unpaired, pct(sum(white) / len(white)),
                  k, pct(k / n), pct(lo), pct(hi)))

    split_table(out, "Archers in the two armies together", [
        ("%d" % c, [d["won"] for d in data if d["archers"] == c])
        for c in range(0, max(d["archers"] for d in data) + 1)])
    split_table(out, "Any ability piece (Archer, Necromancer, Ghost, Bard, Werewolf) in either army", [
        ("no", [d["won"] for d in data if not d["ability"]]),
        ("yes", [d["won"] for d in data if d["ability"]])])
    for key, title in (("empty", "Empty squares in the two armies' starting rows together (32 squares)"),
                       ("long_range", "Long-range pieces in the two armies together")):
        buckets = quantile_buckets([d[key] for d in data])
        split_table(out, title, [
            (("%d" % a) if a == b else ("%d-%d" % (a, b)), [d["won"] for d in data if a <= d[key] <= b])
            for a, b in buckets])
    split_table(out, "An ability used in the first two moves of each side, in either game", [
        ("no", [d["won"] for d in data if not d["early"]]),
        ("yes", [d["won"] for d in data if d["early"]])])

    names = ["constant", "Archers (each)", "any ability piece", "empty squares (each)",
             "long-range pieces (each)", "ability in the first two moves"]
    rows = [[1.0, d["archers"], float(d["ability"]), d["empty"], d["long_range"], float(d["early"])] for d in data]
    # A feature that's the same in every pair can't be fitted: leave it out.
    keep = [0] + [c for c in range(1, len(names)) if len(set(r[c] for r in rows)) > 1]
    left_out = [names[c] for c in range(1, len(names)) if c not in keep]
    names = [names[c] for c in keep]
    rows = [[r[c] for c in keep] for r in rows]
    beta, se = logistic_fit(rows, [1.0 if d["won"] else 0.0 for d in data])
    out.append("\n**All together: logistic regression of \"White won both\"** (%d pairs). "
               "Odds ratio = how the odds of White winning both change with one more of each, "
               "the others held the same; 1 = no effect.%s\n"
               % (n, (" Left out (the same in every pair): " + ", ".join(left_out) + ".") if left_out else ""))
    out.append("| Feature | Coefficient | Odds ratio | 95% range | p |")
    out.append("|---|---|---|---|---|")
    for name, b, s in zip(names, beta, se):
        z = b / s
        p = math.erfc(abs(z) / math.sqrt(2))
        if name == "constant":
            out.append("| %s | %+.3f | (baseline odds %.3f) | | |" % (name, b, math.exp(b)))
        else:
            out.append("| %s | %+.3f | %.3f | %.3f-%.3f | %s |"
                       % (name, b, math.exp(b), math.exp(b - 1.96 * s), math.exp(b + 1.96 * s),
                          "<0.001" if p < 0.001 else "%.3f" % p))


def long_range_note(pieces):
    names = sorted(v["name"] for v in pieces.values() if v["long_range"])
    return "Long-range pieces (a move reaching 4+ squares in a line): " + ", ".join(names) + "."


# --- Part 3 -------------------------------------------------------------------------------

def part3(label, path, out):
    games = read_games(path)
    results = [g["result"] for g in games]
    mean, lo, hi, _ = mean_range(results)
    wins = sum(1 for r in results if r == 1)
    draws = sum(1 for r in results if r == 0.5)
    losses = len(results) - wins - draws
    both = [white_won_both(games[n], games[n + 1]) for n in range(0, len(games) - 1, 2)]
    k, n = sum(both), len(both)
    blo, bhi = wilson(k, n)
    plies = sum(g["plies"] for g in games) / len(games)
    out.append("| %s | %d | +%d =%d -%d | %s (%s-%s) | %d of %d: %s (%s-%s) | %.0f |"
               % (label, len(games), wins, draws, losses, pct(mean), pct(lo), pct(hi),
                  k, n, pct(k / n), pct(blo), pct(bhi), plies))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--run3", required=True)
    ap.add_argument("--run2-8k", required=True)
    ap.add_argument("--run2-32k", required=True)
    ap.add_argument("--pieces", default="data/pieces")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    pieces = read_pieces(args.pieces)
    out = ["# Balance run 3: colour swings (report)\n",
           "Made by `tools/balance/run3_analyse.py`. Points = percentage points. "
           "\"White won both\" = the same two armies played twice with colours swapped and White won both games.\n"]
    big_gaps, lopsided = part1(args.run3, pieces, out)

    out.append("\n## Part 2: what goes with colour-decided games (run 2's self-play games)\n")
    out.append("Pairs found by matching each game with the one where the same two armies swapped colours. "
               "Features are for the pair: both armies together (each army plays both colours in a pair). "
               + long_range_note(pieces)
               + " Ability moves are the ones written with `!`, `@` or `~`; \"first two moves\" = the first "
                 "4 plies (all inside run 2's random opening plies).\n")
    part2("8,000 nodes per move (seed 101)", args.run2_8k, pieces, out)
    part2("32,000 nodes per move (seed 202)", args.run2_32k, pieces, out)

    out.append("\n## Part 3: chess benchmark, Standard vs Standard\n")
    out.append("`--random-plies 4`; a pair = games 2n and 2n+1 (identical armies, so any two games could pair).\n")
    out.append("| Nodes | Games | White +win =draw -loss | White's score (95%) | White won both | Mean plies |")
    out.append("|---|---|---|---|---|---|")
    part3("8,000 (seed 301)", os.path.join(args.run3, "standard_8k.jsonl"), out)
    part3("32,000 (seed 302)", os.path.join(args.run3, "standard_32k.jsonl"), out)

    out.append("\n## Success test (decided before running)\n")
    out.append("No pool army's White-minus-Black gap over 30 points, and no pairing with White at 80% or more.\n")
    out.append("- Pool armies with a gap over 30 points: %s"
               % (", ".join("%s (%+.1f)" % g for g in big_gaps) if big_gaps else "none"))
    out.append("- Pairings with White at 80%% or more: %s"
               % (", ".join("%s vs %s (%s)" % (a, b, pct(m)) for a, b, m in lopsided) if lopsided else "none"))
    out.append("- **Result: %s**" % ("PASSED" if not big_gaps and not lopsided else "FAILED"))
    os.makedirs(os.path.dirname(args.out) or ".", exist_ok=True)
    with open(args.out, "w", encoding="utf-8") as f:
        f.write("\n".join(out) + "\n")
    print("\n".join(out))


if __name__ == "__main__":
    main()
