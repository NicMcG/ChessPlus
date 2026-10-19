"""Final Ghost (round 23 ghost_sheet with sad jellybean eyes), Bard (round 23
lyre_even), Werewolf (round 23 human_fur_ears_plain with three evenly spaced fur
tufts a side) and its wolf form (round 22 wolf_mane with three of its six
spikes, same shape, evenly spaced; no lines in its ears, no bottom tooth).
White and black, written to ../pieces/ (the wolf as <team>_werewolf_wolf.svg).

Run from this folder:  python make_final_ghost_bard_werewolf.py
"""
import io
import math
import re
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
                  "M 22.5,27.5 L 22.5,34.6", inner(team), 1.5)  # Cburnett-thick (Mac)
    eye = inner(team)
    # Sad eyes (Mac): tall jellybeans, dented on the outside, their tops leaning in.
    for cx, lean, flip in ((18.4, 35, -1), (26.6, -35, 1)):
        out += '<g transform="translate(%s 16.2) rotate(%s) scale(%s 1)">%s</g>' % (cx, lean, flip, shape(JELLYBEAN, eye, "none"))
    return out


# A jellybean eye, centred on (0, 0), the dent on its right.
JELLYBEAN = "M 0,-3 C 1.7,-3 2.1,-1.4 1.6,0 C 1.2,1.2 1.9,2.6 0.4,3.05 C -1.5,3.5 -2.1,1.8 -2.1,0 C -2.1,-1.8 -1.4,-3 0,-3 Z"


# --- The coif: the Man, and the Werewolf's human form ------------------------------------
# The coif squashed a tad from top to bottom (Mac, Oct 2026), its bottom (the
# ties' ends) staying put.
SQUASH, SQUASH_BASE = 0.92, 39.6


def squashed(svg):
    """`svg` with every point in its paths moved towards the bottom; line widths
    stay as they are."""
    def path(m):
        points = re.sub(r"(-?[0-9.]+),(-?[0-9.]+)",
                        lambda p: "%s,%.2f" % (p.group(1), SQUASH_BASE - (SQUASH_BASE - float(p.group(2))) * SQUASH),
                        m.group(1))
        return 'd="%s"' % points
    return re.sub(r'd="([^"]*)"', path, svg)


def coif(team, behind="", fur=()):
    """The Man's linen coif (Mac, Oct 2026): on the white one, no line round the
    opening, the centre seam running down to the opening; on the black one, a
    Cburnett-thick white line round the opening and black ties. `fur`: tufts
    (paths) on its sides that join it with no line between them (Mac), as on
    the black one: drawn with a double-width outline under the coif, then filled
    again over it, so only their outside edge shows."""
    fill, line = colours(team)
    out = behind + shape(r22.COIF_FACE, fill)
    out += "".join('<path fill="%s" stroke="#000" stroke-width="3" d="%s"/>' % (fill, d) for d in fur)
    out += shape(r22.COIF, fill)
    out += "".join('<path fill="%s" stroke="none" d="%s"/>' % (fill, d) for d in fur)
    if team == "white":
        out += detail("M 22.5,4.6 L 22.5,14.2", "#000", 1.1)
        out += detail(r22.COIF_TIES, "#000", 1.4)
    else:
        out += detail(r22.COIF_HEM, "#fff", 1.5)
        out += detail("M 22.5,4.6 L 22.5,12.6", "#fff", 1.1)
        out += detail(r22.COIF_TIES, "#000", 1.4)
    return out


def man(team):
    return squashed(coif(team))


# --- Werewolf: the coif with ears and three tufts of fur a side --------------------------
def werewolf(team):
    fill, line = colours(team)
    left = [(12.4, 12.6), (7.8, 15.4), (10.6, 18.5), (6.6, 21.6), (10.2, 24.7), (7.6, 27.8), (11.6, 30.6)]
    fur = (r22.poly(left), r22.poly(r22.mirror_points(left)))
    return squashed(coif(team, r23.ears(team), fur))


# --- The wolf: round 22's maned wolf, with three of its six spikes ------------------------
# Round 22's mane, spike by spike: (tip, where it rejoins the back). Spikes 2, 4
# and 6 are kept exactly as they were (Mac: same fur shape, three instead of
# six); where 1, 3 and 5 were, the back runs straight on between the spikes.
MANE = [((26.4, 10.4), (25.2, 12.2)), ((30, 12.8), (28.6, 14.6)), ((33.2, 16.4), (31.6, 18)),
        ((35.6, 21), (33.8, 22.6)), ((37, 26.6), (35.2, 28)), ((37.8, 32.4), (36.4, 33.8))]
KEPT = (1, 3, 5)


# The back bowed outwards like the knight's (Mac, Oct 2026): each point of the
# mane pushed out, most in the middle of the back, none at its ends.
BACK_START, BACK_END = (22.0, 10.0), (38.0, 39.0)
ARCH = 2.4


def _arched(point):
    (x0, y0), (x1, y1) = BACK_START, BACK_END
    dx, dy = x1 - x0, y1 - y0
    length2 = dx * dx + dy * dy
    t = max(0.0, min(1.0, ((point[0] - x0) * dx + (point[1] - y0) * dy) / length2))
    nx, ny = dy / length2 ** 0.5, -dx / length2 ** 0.5
    bulge = ARCH * math.sin(math.pi * t)
    return (point[0] + nx * bulge, point[1] + ny * bulge)


def wolf_body():
    d = "M 22,10"
    for i, (tip, rejoin) in enumerate(MANE):
        if i in KEPT:
            d += " L %.2f,%.2f" % _arched(tip)
        d += " L %.2f,%.2f" % _arched(rejoin)
    return d + " L 38,39 L 15,39 C 15,30 25,32.5 23,18"


def wolf_head(team):
    """Round 22's wolf head without the lines in its ears or its bottom tooth."""
    fill, line = colours(team)
    mark = inner(team)
    out = shape(r22.WOLF_HEAD, fill)
    out += shape("M 8.4,22.4 L 9.2,24.4 L 10,22.6 Z", "#fff", "#000", 0.7)
    out += shape("M 14.4,15.6 L 18,15.2 L 15.6,16.8 Z", mark, "none")
    out += circle(6.2, 20.6, 0.7, mark, "none")
    return out


# The head a tad bigger (Mac, Oct 2026), grown about the back of the neck.
HEAD_SCALE = 1.1


def wolf(team):
    fill, line = colours(team)
    out = shape(wolf_body(), fill)
    # Round 22's strokes of fur, one under each spike (following the arch).
    fur = ""
    for a, b in (((27.6, 17.2), (25.8, 19.6)), ((31, 22), (29, 24.4)), ((33.4, 27.6), (31.6, 30))):
        fur += "M %.2f,%.2f L %.2f,%.2f " % (_arched(a) + _arched(b))
    out += detail(fur, inner(team), 0.9)
    k, cx, cy = HEAD_SCALE, 24, 17
    head = wolf_head(team).replace('stroke-width="1.5"', 'stroke-width="%.2f"' % (1.5 / k))
    return out + '<g transform="translate(%.2f %.2f) scale(%s)">%s</g>' % (cx * (1 - k), cy * (1 - k), k, head)


PIECES = {"ghost": ghost, "bard": r23.lyre_even, "werewolf": werewolf, "werewolf_wolf": wolf, "man": man}

if __name__ == "__main__":
    for name, draw in PIECES.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "..", "pieces", "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(PIECES) * 2, "files")
