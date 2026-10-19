"""Round 16: more options after Mac's references (Oct 2026): three-masted
square-sailed galleons, catapults (a low one and an upright one), five-point
princess crowns, and crossed daggers for the Assassin. White and black, in the
Cburnett style (45x45, 1.5 black outline; black pieces get thin white details).

Run from this folder:  python make_round16.py
"""
import io
import os

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">'
TAIL = "</g></svg>\n"


def shape(d, fill, stroke="#000", width=1.5):
    return '<path d="%s" fill="%s" stroke="%s" stroke-width="%s"/>' % (d, fill, stroke, width)


def detail(d, color, width=1.1):
    return '<path d="%s" fill="none" stroke="%s" stroke-width="%s"/>' % (d, color, width)


def circle(x, y, r, fill, stroke="#000", width=1.5):
    return '<circle cx="%s" cy="%s" r="%s" fill="%s" stroke="%s" stroke-width="%s"/>' % (x, y, r, fill, stroke, width)


def colours(team):
    return ("#fff", "#000") if team == "white" else ("#000", "#fff")


def inner(team):
    """The colour for small marks inside a piece (portholes, holes)."""
    return "#000" if team == "white" else "#fff"


BASE_TOP = "M 11.5,34 C 17,32 28,32 33.5,34 L 33,37.5 C 27.5,36 17.5,36 12,37.5 Z"
BASE_BOTTOM = "M 12,37.5 C 17.5,36 27.5,36 33,37.5 L 32.5,39.5 L 12.5,39.5 Z"


# --- Galleons -------------------------------------------------------------------------
# A hull with a raised stern (left) and bow (right).
HULL = ("M 4.5,24.5 L 11,24.5 L 12,28.5 L 33,28.5 L 34,26 L 41,26 "
        "C 40,33 36,38.5 29.5,38.5 L 15,38.5 C 9,38.5 5.5,33 4.5,24.5 Z")


def sail(x0, x1, y0, y1):
    """A square sail billowing out: straight-ish sides, curved top and bottom."""
    mid = (x0 + x1) / 2
    return ("M %s,%s C %s,%s %s,%s %s,%s C %s,%s %s,%s %s,%s C %s,%s %s,%s %s,%s C %s,%s %s,%s %s,%s Z" % (
        x0, y0, mid - 3, y0 + 1.6, mid + 3, y0 + 1.6, x1, y0,
        x1 + 1.3, y0 + (y1 - y0) * 0.35, x1 + 1.3, y0 + (y1 - y0) * 0.65, x1, y1,
        mid + 3, y1 - 1.6, mid - 3, y1 - 1.6, x0, y1,
        x0 - 1.3, y0 + (y1 - y0) * 0.65, x0 - 1.3, y0 + (y1 - y0) * 0.35, x0, y0))


_clip_count = [0]


def haloed(d, team, behind=()):
    """A shape that, on a black piece, gets a thin white gap around it (as in
    Mac's reference icon) where it overlaps the shapes `behind`, so it stands
    apart from them; the piece's outer edge stays black."""
    fill, line = colours(team)
    if team != "black" or not behind:
        return shape(d, fill)
    _clip_count[0] += 1
    clip_id = "behind%d" % _clip_count[0]
    clip = '<clipPath id="%s">%s</clipPath>' % (clip_id, "".join('<path d="%s"/>' % b for b in behind))
    halo = '<path d="%s" fill="#fff" stroke="#fff" stroke-width="4" clip-path="url(#%s)"/>' % (d, clip_id)
    return "<defs>%s</defs>%s%s" % (clip, halo, shape(d, fill))


def portholes(team, y=32.5, xs=(16.5, 21, 25.5, 30)):
    return "".join(circle(x, y, 1.15, inner(team), "none") for x in xs)


def galleon_three(team):
    """Three masts: a tall main sail in front, smaller fore and aft sails behind,
    a pennant on the main mast, round portholes (like Mac's reference icon)."""
    fill, line = colours(team)
    out = detail("M 10.5,28.5 L 10.5,9.5 M 34.5,26 L 34.5,10.5", "#000", 1.8)
    out += circle(10.5, 9, 1, fill, "#000", 1.2) + circle(34.5, 10, 1, fill, "#000", 1.2)
    out += shape(sail(6, 15, 12.5, 23.5), fill) + shape(sail(30, 39, 13.5, 24), fill)
    out += detail("M 22.5,28.5 L 22.5,3.5", "#000", 1.8)
    out += shape("M 22.5,3.5 L 28,5 L 22.5,6.5 Z", fill)
    behind = [sail(6, 15, 12.5, 23.5), sail(30, 39, 13.5, 24)]
    out += haloed(sail(15.5, 29.5, 8, 24.5), team, behind)
    out += haloed(HULL, team, behind + [sail(15.5, 29.5, 8, 24.5)])
    if team == "black":
        out += detail("M 9,35 L 36,35", "#fff", 0.9)
    return out + portholes(team)


def galleon_three_tiered(team):
    """Three masts, the main mast carrying two sails (upper and lower)."""
    fill, line = colours(team)
    out = detail("M 10.5,28.5 L 10.5,9.5 M 34.5,26 L 34.5,10.5", "#000", 1.8)
    out += circle(10.5, 9, 1, fill, "#000", 1.2) + circle(34.5, 10, 1, fill, "#000", 1.2)
    out += shape(sail(6, 15, 12.5, 23.5), fill) + shape(sail(30, 39, 13.5, 24), fill)
    out += detail("M 22.5,28.5 L 22.5,3", "#000", 1.8)
    out += shape("M 22.5,3 L 28,4.5 L 22.5,6 Z", fill)
    behind = [sail(6, 15, 12.5, 23.5), sail(30, 39, 13.5, 24)]
    out += haloed(sail(17, 28, 7, 14.5), team, behind)
    out += haloed(sail(15.5, 29.5, 16, 25), team, behind + [sail(17, 28, 7, 14.5)])
    out += haloed(HULL, team, behind + [sail(15.5, 29.5, 16, 25)])
    if team == "black":
        out += detail("M 9,35 L 36,35", "#fff", 0.9)
    return out + portholes(team)


def galleon_bold(team):
    """Heavier and simpler: three equal masts with tall sails and a deep hull."""
    fill, line = colours(team)
    hull = ("M 4,23 L 11,23 L 12,27 L 33,27 L 34,24.5 L 41.5,24.5 "
            "C 40.5,32.5 36.5,39 29.5,39 L 15,39 C 8.5,39 4.8,32 4,23 Z")
    out = ""
    for x, top in ((11, 9), (22.5, 5), (34, 9)):
        out += detail("M %s,27 L %s,%s" % (x, x, top - 1.5), "#000", 1.8)
    out += shape("M 22.5,3.5 L 27.5,5 L 22.5,6.5 Z", fill)
    out += shape(sail(6.8, 15.2, 10, 22.5), fill) + shape(sail(29.8, 38.2, 10, 22.5), fill)
    behind = [sail(6.8, 15.2, 10, 22.5), sail(29.8, 38.2, 10, 22.5)]
    out += haloed(sail(16.5, 28.5, 6.5, 23.5), team, behind)
    out += haloed(hull, team, behind + [sail(16.5, 28.5, 6.5, 23.5)])
    if team == "black":
        out += detail("M 9,35.5 L 36,35.5", "#fff", 0.9)
    return out + portholes(team, 31.5, (15.5, 20, 24.5, 29))


# --- Catapults ------------------------------------------------------------------------
def hollow_wheel(team, x, y, r=4.4):
    fill, line = colours(team)
    return circle(x, y, r, fill) + circle(x, y, 1.6, "none" if team == "white" else "#fff", "#000" if team == "white" else "none", 1.2)


def catapult_low(team):
    """After Mac's first reference: a low wheeled cart, an upright block in the
    middle, and the arm reaching from a bucket down at the left up to the right,
    tied off at the top."""
    fill, line = colours(team)
    out = shape("M 21,30.5 L 23,17.5 L 28.5,17.5 L 29.5,30.5 Z", fill)
    # The arm: a thick bar from the bucket up to the top right.
    out += shape("M 13.5,25.5 L 34.5,9 L 36.3,11.4 L 15.5,28 Z", fill)
    out += shape("M 6.5,24 C 7.5,29.5 14,30.5 17.5,27 C 15.5,24.5 10.5,23 6.5,24 Z", fill)
    # The rope and stop post on the right.
    out += detail("M 35.5,10.5 L 37.5,31", "#000", 1.6)
    out += shape("M 33.6,8.2 L 37.2,7.2 L 38,9.6 L 34.4,10.6 Z", fill)
    out += shape("M 8,29.5 L 37,29.5 L 37,33.5 L 8,33.5 Z", fill)
    out += hollow_wheel(team, 10.5, 34) + hollow_wheel(team, 34.5, 34)
    if team == "black":
        out += detail("M 16,25.9 L 34.5,11.3", "#fff", 0.9)
    return out


def catapult_upright(team):
    """After Mac's second reference: two wheels on an axle bar, a tall post braced
    by a little A-frame, and the arm rising to a big bucket at the top left."""
    fill, line = colours(team)
    out = shape("M 17,33.5 L 21.5,24 L 23.5,24 L 23.5,33.5 Z M 28,33.5 L 23.5,24 L 25.5,24 L 32,33.5 Z", fill)
    out += shape("M 22,33.5 L 22,12 C 22,10.5 23,9.8 24,9.8 C 25,9.8 26,10.5 26,12 L 26,33.5 Z", fill)
    out += shape("M 24.5,27.5 L 13,13.5 L 15.2,11.8 L 26.5,25.6 Z", fill)
    out += shape("M 6,12.5 C 6,7 10.5,4 15,5.5 C 16.5,6 17.5,7.5 17.5,8.5 L 10.5,14.5 C 8,14.8 6,14 6,12.5 Z", fill)
    out += shape("M 9,33 L 36,33 L 36,36.5 L 9,36.5 Z", fill)
    out += hollow_wheel(team, 12, 36.5) + hollow_wheel(team, 33, 36.5)
    if team == "black":
        out += detail("M 24,13 L 24,22 M 23.6,25.6 L 15,15", "#fff", 0.9)
    return out


def catapult_loaded(team):
    """The low catapult with a stone sitting in its bucket."""
    fill, line = colours(team)
    return catapult_low(team) + circle(11, 24.2, 2.6, fill)


# --- Princess crowns ------------------------------------------------------------------
# Mac's reference: five points with balls (tallest in the middle, the next two
# smallest, the outer two leaning out), concave sides, a curved bottom edge.
FIVE = ("M 13,37 C 11.2,32.5 9.8,29.6 8.2,26.6 C 11,28.6 13.6,29.6 16.2,28.2 "
        "C 15.8,25.8 15.4,23.6 15,21.6 C 16.8,24.4 18.4,26.4 20,26.8 C 21.2,22 22,18 22.5,15.6 "
        "C 23,18 23.8,22 25,26.8 C 26.6,26.4 28.2,24.4 30,21.6 C 29.6,23.6 29.2,25.8 28.8,28.2 "
        "C 31.4,29.6 34,28.6 36.8,26.6 C 35.2,29.6 33.8,32.5 32,37 C 26,35.6 19,35.6 13,37 Z")
FIVE_BALLS = ((7.6, 25.8, 2.3), (14.8, 20.5, 1.8), (22.5, 14.2, 2.4), (30.2, 20.5, 1.8), (37.4, 25.8, 2.3))


def crown_five(team):
    fill, line = colours(team)
    out = shape(FIVE, fill)
    out += "".join(circle(x, y, r, fill) for x, y, r in FIVE_BALLS)
    if team == "black":
        out += detail("M 14.2,34.6 C 19.5,33.4 25.5,33.4 30.8,34.6", "#fff", 1)
    return out


def crown_five_on_base(team):
    """The five-point crown standing on the queen's base, with a row of jewels."""
    fill, line = colours(team)
    crown = FIVE.replace("M 13,37", "M 12,34").replace("C 26,35.6 19,35.6 13,37 Z", "C 27,32 18,32 12,34 Z").replace("C 35.2,29.6 33.8,32.5 32,37", "C 35.2,29.6 34.5,31.5 33,34").replace("C 11.2,32.5 9.8,29.6 8.2,26.6", "C 10.5,31.5 9.8,29.6 8.2,26.6")
    out = shape(crown, fill)
    out += "".join(circle(x, y, r, fill) for x, y, r in FIVE_BALLS)
    out += shape(BASE_TOP, fill) + shape(BASE_BOTTOM, fill)
    for x in (17, 22.5, 28):
        out += circle(x, 30.5, 1, inner(team), "none")
    return out


def crown_three_curved(team):
    """The earlier three-point crown, with Mac's curved sides and bottom edge."""
    fill, line = colours(team)
    crown = ("M 12.5,36.5 C 11.5,30.5 10.5,24.5 9.5,19.5 C 12.5,23.5 15,25.5 17.5,26 "
             "C 19.5,22.5 21.2,18.5 22.5,15 C 23.8,18.5 25.5,22.5 27.5,26 C 30,25.5 32.5,23.5 35.5,19.5 "
             "C 34.5,24.5 33.5,30.5 32.5,36.5 C 26,34.8 19,34.8 12.5,36.5 Z")
    out = shape(crown, fill)
    out += circle(9.3, 18.3, 2.2, fill) + circle(22.5, 13.3, 2.4, fill) + circle(35.7, 18.3, 2.2, fill)
    out += detail("M 13.6,33.8 C 19.3,32.4 25.7,32.4 31.4,33.8", inner(team), 1)
    return out


# --- Crossed daggers ------------------------------------------------------------------
def curved_dagger(fill, x, y, angle, mirror=False):
    """A dagger with a curved blade (like Mac's reference), grip at (x, y),
    leaning `angle` degrees; `mirror` curves it the other way."""
    blade = "M -2.2,0 C -3.4,-8 -1.6,-17 3.8,-25 C 2.6,-16 3,-7 2.2,0 Z"
    guard = "M -4.2,0.2 C -2,-1.3 2,-1.3 4.2,0.2 L 4,2 C 2,1 -2,1 -4,2 Z"
    grip = "M -1.6,2 C -2.2,5 -2.6,8 -3.6,10.5 L -0.4,11 C 0.6,8.5 1.2,5 1.6,2 Z"
    pommel = "M -4.6,10 C -4.6,12 -2.6,13 -0.6,12.6 C 0.6,12.2 0.8,10.8 0.2,10.2 Z"
    flip = " scale(-1 1)" if mirror else ""
    group = '<g transform="translate(%s %s) rotate(%s)%s">' % (x, y, angle, flip)
    for d in (blade, grip, pommel, guard):
        group += shape(d, fill, "#000", 1.3)
    if fill == "#000":
        group += detail("M 0,-2.5 C -0.4,-9 0.4,-15 2.6,-21", "#fff", 0.8)
    return group + "</g>"


def straight_dagger(fill, x, y, angle):
    blade = "M -2,0 L -2,-18 L 0,-23.5 L 2,-18 L 2,0 Z"
    guard = "M -5,0 L 5,0 L 5,2 L -5,2 Z"
    grip = "M -1.4,2 L 1.4,2 L 1.4,8.5 L -1.4,8.5 Z"
    group = '<g transform="translate(%s %s) rotate(%s)">' % (x, y, angle)
    for d in (blade, guard, grip):
        group += shape(d, fill, "#000", 1.3)
    group += '<circle cx="0" cy="9.8" r="1.6" fill="%s" stroke="#000" stroke-width="1.3"/>' % fill
    if fill == "#000":
        group += detail("M 0,-2.5 L 0,-19", "#fff", 0.8)
    return group + "</g>"


def daggers_curved(team):
    fill, line = colours(team)
    return curved_dagger(fill, 31.5, 31, -32, True) + curved_dagger(fill, 13.5, 31, 32)


def daggers_curved_wide(team):
    """The curved daggers crossed lower and further apart, blades sweeping out."""
    fill, line = colours(team)
    return curved_dagger(fill, 33, 33, -38, True) + curved_dagger(fill, 12, 33, 38)


def daggers_straight(team):
    fill, line = colours(team)
    return straight_dagger(fill, 31, 32, -34) + straight_dagger(fill, 14, 32, 34)


OPTIONS = {
    "galleon_three": galleon_three,
    "galleon_three_tiered": galleon_three_tiered,
    "galleon_bold": galleon_bold,
    "catapult_low": catapult_low,
    "catapult_upright": catapult_upright,
    "catapult_loaded": catapult_loaded,
    "crown_five": crown_five,
    "crown_five_on_base": crown_five_on_base,
    "crown_three_curved": crown_three_curved,
    "daggers_curved": daggers_curved,
    "daggers_curved_wide": daggers_curved_wide,
    "daggers_straight": daggers_straight,
}

if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(here, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(HEAD + draw(team) + TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
