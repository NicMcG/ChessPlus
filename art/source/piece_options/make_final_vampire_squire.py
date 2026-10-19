"""Final Vampire (a bat after Mac's reference: wings swept up to points with
scalloped lower edges, little ears, two dot eyes, the body tapering to a point;
with lines on the wings like a bat's wing bones) and Squire (a saddle after Mac's
reference: a rounded knob at the front, the seat sweeping up to a tall back, a
strap and a stirrup). White and black, written to ../pieces/.

Run from this folder:  python make_final_vampire_squire.py
"""
import io
import math
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "round16"))
import make_round16 as r16  # noqa: E402

shape, detail, circle, colours, inner = r16.shape, r16.detail, r16.circle, r16.colours, r16.inner

# --- The bat -----------------------------------------------------------------------------
# The left half, from the middle of the head round to the bottom point, as
# (control 1, control 2, end) curves or (end,) straight lines. The right half is
# its mirror image, so the bat is perfectly symmetrical.
BAT_START = (22.5, 15.4)
BAT_LEFT = [
    ((21.0, 14.8),),
    ((19.4, 11.8),),
    ((18.3, 16.4),),
    ((16.4, 17.6), (14.4, 17.9), (12.8, 16.4)),
    ((10.8, 13.4), (8.0, 9.6), (4.0, 7.8)),
    ((5.6, 12.6), (6.2, 17.6), (5.0, 22.2)),
    ((7.4, 22.6), (9.4, 24.4), (10.0, 27.2)),
    ((12.6, 27.2), (15.0, 29.0), (16.0, 31.6)),
    ((19.0, 32.6), (21.4, 36.0), (22.5, 40.6)),
]


def _mirror(p):
    return (45 - p[0], p[1])


def bat_path():
    d = "M %.2f,%.2f" % BAT_START
    for seg in BAT_LEFT:
        d += " " + ("L %.2f,%.2f" % seg[0] if len(seg) == 1 else "C %.2f,%.2f %.2f,%.2f %.2f,%.2f" % (seg[0] + seg[1] + seg[2]))
    # Back up the right side: the left side's segments in reverse, mirrored.
    points = [BAT_START] + [seg[-1] for seg in BAT_LEFT]
    for i in range(len(BAT_LEFT) - 1, -1, -1):
        seg = BAT_LEFT[i]
        start = points[i]
        if len(seg) == 1:
            d += " L %.2f,%.2f" % _mirror(start)
        else:
            d += " C %.2f,%.2f %.2f,%.2f %.2f,%.2f" % (_mirror(seg[1]) + _mirror(seg[0]) + _mirror(start))
    return d + " Z"


def vampire(team):
    fill, line = colours(team)
    out = shape(bat_path(), fill)
    # The wing bones: from near each shoulder out to the middle two of the
    # wing's four points (Mac). Each starts a little way along its own line, so
    # the two lines on a wing don't meet.
    bones = ""
    for tip in ((6.4, 21.4), (10.6, 26.4)):
        for x, y in (tip, _mirror(tip)):
            sx = 15.2 if x < 22.5 else 29.8
            dx, dy = x - sx, y - 20.2
            k = 2.4 / math.hypot(dx, dy)
            bones += "M %.2f,%.2f L %.2f,%.2f " % (sx + dx * k, 20.2 + dy * k, x, y)
    out += detail(bones, inner(team), 1.4)  # Cburnett-thick (Mac)
    eyes = "#000" if team == "white" else "#fff"
    out += circle(20.9, 20.6, 0.9, eyes, "none") + circle(24.1, 20.6, 0.9, eyes, "none")
    return out


# --- The saddle --------------------------------------------------------------------------
SADDLE = ("M 7.6,11.6 C 10.2,11.6 11.8,13.4 13,15.2 C 14.6,17.4 17,17.6 20,17 "
          "C 26,15.6 32,12 35.6,8.6 C 37.6,6.8 40.6,7.6 40.6,10.6 L 40.6,22.4 "
          "C 40.6,27 37.4,29.8 33,29.8 L 24.6,29.8 C 21,29.8 18.6,28 17.4,25.2 "
          "C 16.2,22.4 13.8,20.6 10.6,20 C 6.6,19.4 4.4,17.4 4.4,15.2 C 4.4,13 5.8,11.6 7.6,11.6 Z")
STIRRUP = ("M 19.6,35 L 27.4,35 L 29,41.4 C 29.2,42.4 28.6,43 27.6,43 L 19.4,43 C 18.4,43 17.8,42.4 18,41.4 Z "
           "M 21.2,37 L 25.8,37 L 26.9,41 L 20.1,41 Z")


def squire(team):
    fill, line = colours(team)
    out = shape("M 22,29 L 25,29 L 25,35.5 L 22,35.5 Z", fill)
    out += '<path d="%s" fill="%s" fill-rule="evenodd" stroke="#000" stroke-width="1.5"/>' % (STIRRUP, fill)
    out += shape(SADDLE, fill)
    # The line between the seat and the flap below it.
    # It runs 3.2 inside the outline all the way along (Mac), stopping on the
    # left where the seat gets too narrow to keep that gap.
    out += detail("M 37.4,13.6 L 37.4,22.4 C 37.4,25 35.4,26.6 33,26.6 L 24.6,26.6 "
                  "C 22.4,26.6 21.1,25.6 20.3,23.9 C 19.6,22.5 18.9,21.3 18.05,20.44", inner(team), 1.1)
    return out


def shrink(body, k, centre=(22.5, 24)):
    """Draw `body` at `k` times its size about `centre`, keeping the line widths
    as they were (so outlines stay the usual thickness)."""
    body = re.sub(r'stroke-width="([0-9.]+)"', lambda m: 'stroke-width="%.2f"' % (float(m.group(1)) / k), body)
    cx, cy = centre
    return '<g transform="translate(%.2f %.2f) scale(%s)">%s</g>' % (cx * (1 - k), cy * (1 - k), k, body)


PIECES = {"vampire": vampire, "squire": squire}
# Drawn at 97%: Mac found the full size a bit big, then 92% a bit small.
SHRINK = 0.97

if __name__ == "__main__":
    for name, draw in PIECES.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "..", "pieces", "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + shrink(draw(team), SHRINK) + r16.TAIL)
    print("wrote", len(PIECES) * 2, "files")
