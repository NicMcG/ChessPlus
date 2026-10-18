"""Turns the balancing games (balance_match.gd) into an estimate of what each
piece is really worth.

    python tools/balance/analyse_balance.py balance/results/round1 [more folders...]

How it works: each game is White's army against Black's. A logistic model says
the chance White wins grows with the difference in "true value" between the two
armies:

    P(White wins) = 1 / (1 + exp(-(edge + sum over piece types of beta * (White's count - Black's count))))

Draws count as half a win. The beta for each piece type is fitted to all the
games; then the betas are turned into points by scaling them so the standard
chess army (8 pawns, 2 knights, 2 bishops, 2 rooks, a queen) is worth 39, its
cost. Repeating the fit on resampled games (bootstrap) shows how sure each
estimate is.

Writes <first folder>/values.json (the measured values, for the bot to use in
the next round) and prints a table.
"""
import glob
import json
import math
import os
import random
import sys

STANDARD = {"pawn": 8, "knight": 2, "bishop": 2, "rook": 2, "queen": 1}
RIDGE = 0.5  # Keeps rarely seen pieces from running away.


def load(folders):
    games = []
    for folder in folders:
        for path in glob.glob(os.path.join(folder, "*.csv")):
            with open(path, encoding="utf-8") as f:
                for line in f:
                    parts = line.strip().split(",")
                    if len(parts) < 7:
                        continue
                    games.append({
                        "white": counts(parts[2]),
                        "black": counts(parts[3]),
                        "result": float(parts[4]),
                        "plies": int(parts[5]),
                        "end": parts[6],
                    })
    return games


def counts(text):
    found = {}
    for part in text.split(";"):
        if ":" in part:
            piece, n = part.split(":")
            found[piece] = int(n)
    return found


def features(games, pieces):
    rows = []
    for g in games:
        rows.append([1.0] + [g["white"].get(p, 0) - g["black"].get(p, 0) for p in pieces])
    return rows


def fit(rows, targets):
    """Logistic regression (with draws as 0.5) by Newton's method."""
    n = len(rows[0])
    beta = [0.0] * n
    for _ in range(25):
        grad = [0.0] * n
        hess = [[0.0] * n for _ in range(n)]
        for x, y in zip(rows, targets):
            z = sum(b * v for b, v in zip(beta, x))
            p = 1.0 / (1.0 + math.exp(-max(-30, min(30, z))))
            w = p * (1 - p)
            for i in range(n):
                if x[i] == 0:
                    continue
                grad[i] += (y - p) * x[i]
                xi = w * x[i]
                row = hess[i]
                for j in range(n):
                    if x[j]:
                        row[j] += xi * x[j]
        for i in range(1, n):
            grad[i] -= RIDGE * beta[i]
            hess[i][i] += RIDGE
        step = solve(hess, grad)
        beta = [b + s for b, s in zip(beta, step)]
        if max(abs(s) for s in step) < 1e-6:
            break
    return beta


def solve(a, b):
    n = len(b)
    m = [row[:] + [b[i]] for i, row in enumerate(a)]
    for c in range(n):
        pivot = max(range(c, n), key=lambda r: abs(m[r][c]))
        m[c], m[pivot] = m[pivot], m[c]
        if abs(m[c][c]) < 1e-12:
            m[c][c] = 1e-12
        for r in range(n):
            if r != c:
                f = m[r][c] / m[c][c]
                if f:
                    for k in range(c, n + 1):
                        m[r][k] -= f * m[c][k]
    return [m[i][n] / m[i][i] for i in range(n)]


def to_points(beta, pieces):
    scale = sum(beta[1 + pieces.index(p)] * n for p, n in STANDARD.items() if p in pieces) / 39.0
    return {p: beta[1 + i] / scale for i, p in enumerate(pieces)}, scale


def main():
    folders = sys.argv[1:] or ["balance/results/round1"]
    games = load(folders)
    if not games:
        print("No games found in", folders)
        return
    pieces = sorted({p for g in games for side in ("white", "black") for p in g[side]})
    costs = read_costs()
    rows = features(games, pieces)
    targets = [g["result"] for g in games]
    beta = fit(rows, targets)
    values, scale = to_points(beta, pieces)
    # How sure: refit on resampled games.
    random.seed(1)
    samples = {p: [] for p in pieces}
    for _ in range(30):
        pick = [random.randrange(len(rows)) for _ in rows]
        b = fit([rows[i] for i in pick], [targets[i] for i in pick])
        v, _ = to_points(b, pieces)
        for p in pieces:
            samples[p].append(v[p])
    white = sum(1 for g in games if g["result"] == 1) / len(games)
    draws = sum(1 for g in games if g["result"] == 0.5) / len(games)
    ends = {}
    for g in games:
        ends[g["end"]] = ends.get(g["end"], 0) + 1
    print(f"{len(games)} games. White wins {white:.0%}, draws {draws:.0%}. Endings: {ends}")
    print(f"White's first-move edge: worth about {beta[0] / scale:.1f} points")
    print()
    print(f"{'piece':<12}{'cost':>6}{'measured':>10}{'likely range':>16}{'appears in':>12}")
    seen = {p: sum(1 for g in games for side in ("white", "black") if p in g[side]) for p in pieces}
    for p in sorted(pieces, key=lambda p: values[p] - costs.get(p, 0)):
        s = sorted(samples[p])
        low, high = s[int(len(s) * 0.05)], s[int(len(s) * 0.95) - 1]
        print(f"{p:<12}{costs.get(p, 0):>6.1f}{values[p]:>10.1f}{f'{low:.1f} to {high:.1f}':>16}{seen[p]:>12}")
    out = os.path.join(folders[0], "values.json")
    with open(out, "w", encoding="utf-8") as f:
        json.dump({p: round(values[p], 2) for p in pieces}, f, indent=1, sort_keys=True)
    with open(os.path.join(folders[0], "ranges.json"), "w", encoding="utf-8") as f:
        json.dump({p: [round(sorted(samples[p])[1], 2), round(sorted(samples[p])[-2], 2)] for p in pieces}, f, indent=1, sort_keys=True)
    print("\nWrote", out)


def read_costs():
    costs = {}
    for path in glob.glob("data/pieces/*.tres"):
        piece_id = value = None
        with open(path, encoding="utf-8") as f:
            for line in f:
                if line.startswith("id = "):
                    piece_id = line.split('"')[1]
                elif line.startswith("value = "):
                    value = float(line.split("=")[1])
        if piece_id:
            costs[piece_id] = value or 0.0
    return costs


if __name__ == "__main__":
    main()
