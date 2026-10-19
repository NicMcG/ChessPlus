"""Final Ghost (round 23 ghost_sheet with sad eyes), Bard (round 23 lyre_even),
Werewolf (round 23 human_fur_ears_plain with three evenly spaced fur tufts a
side) and its wolf form (round 23 wolf_big_head: three evenly spaced spikes down
its back, no lines in its ears, no bottom tooth, a slightly thicker neck).
White and black, written to ../pieces/ (the wolf as <team>_werewolf_wolf.svg).

Run from this folder:  python make_final_ghost_bard_werewolf.py
"""
import io
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
for folder in ("round16", "round22", "round23"):
    sys.path.insert(0, os.path.join(HERE, folder))
import make_round16 as r16  # noqa: E402
import make_round22 as r22  # noqa: E402
import make_round23 as r23  # noqa: E402

shape, detail, circle, colours, inner = r16.shape, r16.detail, r16.circle, r16.colours, r16.inner


# --- Ghost: the bedsheet ghost with sad eyes ---------------------------------------------
def ghost(team):
    fill, line = colours(team)
    d = ("M 22.5,4.5 C 29.5,4.5 33.5,10 33.5,17 C 33.5,23 35,28 38,33 C 39,34.8 38.2,36.6 36.4,36.2 "
         "L 33.6,35.2 L 31.8,38.4 L 28.6,36.4 L 25.8,39.6 L 22.6,36.6 L 19.4,39.4 L 16.6,36.2 L 13.2,38.4 "
         "L 11.2,35.2 L 8.6,36.2 C 6.8,36.6 6,34.8 7,33 C 10,28 11.5,23 11.5,17 C 11.5,10 15.5,4.5 22.5,4.5 Z")
    out = shape(d, fill)
    out += detail("M 16.6,25 C 16.2,29 15.4,32.6 13.6,35.6 M 28.4,25 C 28.8,29 29.6,32.6 31.4,35.6 "
                  "M 22.5,27.5 L 22.5,34.6", inner(team), 1.0)
    eye = inner(team)
    # Sad eyes: drooping at the outer corners, under brows raised in the middle.
    out += shape("M 20.3,14.8 C 20.6,17.4 19.6,18.6 18.3,18.6 C 17,18.6 16.4,17.4 16.5,16 Z", eye, "none")
    out += shape("M 24.7,14.8 C 24.4,17.4 25.4,18.6 26.7,18.6 C 28,18.6 28.6,17.4 28.5,16 Z", eye, "none")
    out += detail("M 16,13.4 L 20,11.9 M 29,13.4 L 25,11.9", eye, 1.2)
    return out


# --- Werewolf: the coif with ears and three tufts of fur a side --------------------------
def werewolf(team):
    fill, line = colours(team)
    left = [(12.4, 12.6), (7.8, 15.4), (10.6, 18.5), (6.6, 21.6), (10.2, 24.7), (7.6, 27.8), (11.6, 30.6)]
    fur = shape(r22.poly(left), fill) + shape(r22.poly(r22.mirror_points(left)), fill)
    return r23.plain_coif(team, fur + r23.ears(team))


# --- The wolf ----------------------------------------------------------------------------
BACK = ((22, 10), (32.5, 11), (38.5, 18), (38, 39))  # The knight's back (a curve).


def _bez(t):
    (x0, y0), (x1, y1), (x2, y2), (x3, y3) = BACK
    u = 1 - t
    return (u ** 3 * x0 + 3 * u * u * t * x1 + 3 * u * t * t * x2 + t ** 3 * x3,
            u ** 3 * y0 + 3 * u * u * t * y1 + 3 * u * t * t * y2 + t ** 3 * y3)


# The curve sampled finely, with the distance along it to each sample.
_SAMPLES = [_bez(i / 400) for i in range(401)]
_DIST = [0.0]
for _i in range(1, len(_SAMPLES)):
    _DIST.append(_DIST[-1] + math.dist(_SAMPLES[_i - 1], _SAMPLES[_i]))


def _at(fraction):
    """The point `fraction` of the way along the back, and the unit tangent and
    outward normal there."""
    target = fraction * _DIST[-1]
    i = next(k for k, d in enumerate(_DIST) if d >= target)
    i = min(max(i, 1), len(_SAMPLES) - 2)
    p = _SAMPLES[i]
    tx, ty = _SAMPLES[i + 1][0] - _SAMPLES[i - 1][0], _SAMPLES[i + 1][1] - _SAMPLES[i - 1][1]
    n = math.hypot(tx, ty)
    tx, ty = tx / n, ty / n
    return p, (tx, ty), (ty, -tx)


SPIKES = (0.27, 0.48, 0.69)  # Where each spike starts, as a share of the back's length.
SPIKE_SPAN = 0.09


def wolf_body():
    """The knight's back with three spikes of fur evenly spaced down it, and its
    front (neck) line a little further left than the knight's."""
    points = []
    marks = sorted([0.0, 1.0] + [s for s in SPIKES] + [s + SPIKE_SPAN for s in SPIKES])
    d = "M 22,10"
    position = 0.0
    for start in SPIKES:
        # Along the back to the spike.
        for k in range(1, 13):
            f = position + (start - position) * k / 12
            (x, y), _, _ = _at(f)
            d += " L %.2f,%.2f" % (x, y)
        (bx, by), (tx, ty), (nx, ny) = _at(start + SPIKE_SPAN * 0.45)
        d += " L %.2f,%.2f" % (bx + nx * 4.0 + tx * 2.6, by + ny * 4.0 + ty * 2.6)
        (ex, ey), _, (nx, ny) = _at(start + SPIKE_SPAN)
        d += " L %.2f,%.2f" % (ex - nx * 0.9, ey - ny * 0.9)
        position = start + SPIKE_SPAN
    for k in range(1, 13):
        f = position + (1.0 - position) * k / 12
        (x, y), _, _ = _at(f)
        d += " L %.2f,%.2f" % (x, y)
    return d + " L 13.8,39 C 13.8,30 24.2,32.5 23,18"


def wolf_head(team):
    """Round 22's wolf head without the lines in its ears or its bottom tooth."""
    fill, line = colours(team)
    mark = inner(team)
    out = shape(r22.WOLF_HEAD, fill)
    out += shape("M 8.4,22.4 L 9.2,24.4 L 10,22.6 Z", "#fff", "#000", 0.7)
    out += shape("M 14.4,15.6 L 18,15.2 L 15.6,16.8 Z", mark, "none")
    out += circle(6.2, 20.6, 0.7, mark, "none")
    return out


def wolf(team):
    fill, line = colours(team)
    out = shape(wolf_body(), fill)
    # A line of fur under each gap between the spikes.
    lines = ""
    for i in range(len(SPIKES) - 1):
        middle = (SPIKES[i] + SPIKE_SPAN + SPIKES[i + 1]) / 2
        (x, y), (tx, ty), (nx, ny) = _at(middle)
        x0, y0 = x - nx * 2.4, y - ny * 2.4
        lines += "M %.2f,%.2f L %.2f,%.2f " % (x0, y0, x0 - nx * 1.6 + tx * 2.2, y0 - ny * 1.6 + ty * 2.2)
    out += detail(lines, inner(team), 0.9)
    k, cx, cy = 1.12, 24, 17  # The head 12% bigger, grown about the back of the neck.
    head = wolf_head(team).replace('stroke-width="1.5"', 'stroke-width="%.2f"' % (1.5 / k))
    return out + '<g transform="translate(%.2f %.2f) scale(%s)">%s</g>' % (cx * (1 - k), cy * (1 - k), k, head)


PIECES = {"ghost": ghost, "bard": r23.lyre_even, "werewolf": werewolf, "werewolf_wolf": wolf}

if __name__ == "__main__":
    for name, draw in PIECES.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "..", "pieces", "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(PIECES) * 2, "files")
