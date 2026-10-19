"""Round 15: options for the third batch's first four pieces (Princess, Galleon,
Catapult, Assassin), white and black, in the Cburnett style (45x45, 1.5 black
outline; black pieces get thin white detail lines).

Run from this folder:  python make_round15.py
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


# The base the Cburnett queen and king stand on (two ribbons).
BASE_TOP = "M 11.5,34 C 17,32 28,32 33.5,34 L 33,37.5 C 27.5,36 17.5,36 12,37.5 Z"
BASE_BOTTOM = "M 12,37.5 C 17.5,36 27.5,36 33,37.5 L 32.5,39.5 L 12.5,39.5 Z"


def base(team):
    fill, line = colours(team)
    return shape(BASE_TOP, fill) + shape(BASE_BOTTOM, fill)


# --- Princess ------------------------------------------------------------------------
def princess_tiara(team):
    """An arched tiara band with a tall jewelled centre peak and two smaller
    side peaks, on the queen's base."""
    fill, line = colours(team)
    band = ("M 9.5,34 C 9.5,24 15,18.5 22.5,18.5 C 30,18.5 35.5,24 35.5,34 L 31.5,34 "
            "C 31.5,27 27.5,22.5 22.5,22.5 C 17.5,22.5 13.5,27 13.5,34 Z")
    centre = "M 19.5,19.2 L 22.5,8.5 L 25.5,19.2"
    left = "M 13.2,23 L 13.5,15.5 L 17.5,20.2"
    right = "M 31.8,23 L 31.5,15.5 L 27.5,20.2"
    out = shape(centre + " Z", fill) + shape(left + " Z", fill) + shape(right + " Z", fill)
    out += shape(band, fill)
    out += circle(22.5, 8.2, 1.5, fill) + circle(13.5, 15.2, 1.3, fill) + circle(31.5, 15.2, 1.3, fill)
    # The jewel in the middle of the band.
    out += shape("M 22.5,17.2 L 24.3,19.8 L 22.5,22.4 L 20.7,19.8 Z", line if team == "white" else "#fff", "none")
    if team == "black":
        out += detail("M 11.5,33 C 11.8,26 16,21 22.5,20.6 C 29,21 33.2,26 33.5,33", "#fff", 1)
    return out + base(team)


def princess_crown(team):
    """A simpler queen's crown: three rounded points with balls, and a band."""
    fill, line = colours(team)
    crown = ("M 12,33.5 L 10.5,19 L 17,26.5 L 22.5,15.5 L 28,26.5 L 34.5,19 L 33,33.5 "
             "C 27.5,31.5 17.5,31.5 12,33.5 Z")
    out = shape(crown, fill)
    out += circle(10.5, 18, 2, fill) + circle(22.5, 14, 2, fill) + circle(34.5, 18, 2, fill)
    if team == "black":
        out += detail("M 13.2,31.7 C 18,30.3 27,30.3 31.8,31.7", "#fff", 1)
    else:
        out += detail("M 13.2,31.7 C 18,30.3 27,30.3 31.8,31.7", "#000", 1)
    return out + base(team)


# --- Galleon -------------------------------------------------------------------------
HULL = ("M 5.5,26.5 L 11.5,26.5 L 12,29.5 L 39,29.5 C 37.5,35.5 33.5,38.5 28.5,38.5 L 14,38.5 "
        "C 9,38.5 6,33.5 5.5,26.5 Z")


def galleon_square(team):
    """Side view: hull with a raised stern, one mast with two big square sails,
    a pennant on top and a bowsprit."""
    fill, line = colours(team)
    out = detail("M 38.5,30 L 42.5,25.5", "#000", 1.5)
    out += detail("M 22.5,29.5 L 22.5,4.5", "#000", 1.8)
    out += shape("M 22.5,4.5 L 28.5,6.2 L 22.5,7.9 Z", fill)
    out += shape("M 15.5,9 C 19.5,10.6 25.5,10.6 29.5,9 C 30.6,11.5 30.6,13.8 29.5,16 "
                 "C 25.5,14.5 19.5,14.5 15.5,16 C 14.4,13.8 14.4,11.5 15.5,9 Z", fill)
    out += shape("M 12.5,17.5 C 18,19.6 27,19.6 32.5,17.5 C 34.2,21 34.2,24 32.5,27 "
                 "C 27,25 18,25 12.5,27 C 10.8,24 10.8,21 12.5,17.5 Z", fill)
    out += shape(HULL, fill)
    seam = "#fff" if team == "black" else "#000"
    out += detail("M 8.5,33.5 L 36.5,33.5", seam, 1)
    if team == "black":
        out += detail("M 22.5,10.5 L 22.5,14 M 22.5,19.5 L 22.5,24.8", "#fff", 1)
    # Gun ports along the hull.
    for x in (16, 21, 26, 31):
        out += '<rect x="%s" y="30.8" width="2.2" height="1.8" fill="%s" stroke="none"/>' % (x, seam)
    return out


def galleon_lateen(team):
    """Side view: hull with two masts carrying triangular sails, pennants on top."""
    fill, line = colours(team)
    out = detail("M 38.5,30 L 42.5,25.5", "#000", 1.5)
    out += detail("M 17,29.5 L 17,6 M 29,29.5 L 29,9", "#000", 1.8)
    out += shape("M 17,6 L 21.5,7.3 L 17,8.6 Z", fill) + shape("M 29,9 L 33.5,10.3 L 29,11.6 Z", fill)
    out += shape("M 17.8,9 C 22,14 24,20 23.5,27 L 17.8,27 Z", fill)
    out += shape("M 16.2,10 C 11,15 8.5,21 9.5,27 L 16.2,27 Z", fill)
    out += shape("M 29.8,12 C 34,16.5 36,21.5 35.5,27 L 29.8,27 Z", fill)
    out += shape(HULL, fill)
    seam = "#fff" if team == "black" else "#000"
    out += detail("M 8.5,33.5 L 36.5,33.5", seam, 1)
    for x in (16, 21, 26, 31):
        out += '<rect x="%s" y="30.8" width="2.2" height="1.8" fill="%s" stroke="none"/>' % (x, seam)
    return out


# --- Catapult ------------------------------------------------------------------------
def wheels(team, xs=(12.5, 32.5), y=36, r=3.6):
    fill, line = colours(team)
    out = ""
    for x in xs:
        out += circle(x, y, r, fill)
        out += circle(x, y, 0.9, "#000" if team == "white" else "#fff", "none")
    return out


def catapult_arm(team):
    """A classic catapult: a wheeled frame, an upright A-frame and a throwing arm
    raised back with a stone in its cup."""
    fill, line = colours(team)
    out = shape("M 16,34.5 L 22.5,18.5 L 29,34.5 L 26.2,34.5 L 22.5,24.5 L 18.8,34.5 Z", fill)
    # The arm, from the pivot up and back to the cup.
    out += shape("M 23.5,20.5 L 11,8.5 L 9.2,10.4 L 21.6,22.4 Z", fill)
    out += shape("M 6.2,7.8 C 6.2,11.2 8.8,13.6 12.2,13.4 L 12.6,10.6 C 10.4,10.8 9,9.4 9,7.6 Z", fill)
    out += circle(9.2, 7.4, 2.6, fill)
    out += circle(22.5, 21.5, 1.4, fill)
    out += shape("M 6.5,31.5 L 38.5,31.5 L 38.5,35 L 6.5,35 Z", fill)
    out += wheels(team)
    if team == "black":
        out += detail("M 8,33.2 L 37,33.2", "#fff", 1)
    return out


def catapult_trebuchet(team):
    """A trebuchet: tall frame, a long arm with a sling at one end and a
    counterweight box hanging from the other."""
    fill, line = colours(team)
    out = shape("M 15.5,33 L 22.5,13 L 29.5,33 L 26.7,33 L 22.5,20.5 L 18.3,33 Z", fill)
    out += shape("M 22.5,14.5 L 38,6.5 L 39,8.4 L 23.5,16.4 Z", fill)
    out += shape("M 22.5,14.5 L 12.5,19.6 L 11.5,17.8 L 21.6,12.6 Z", fill)
    out += detail("M 38.5,7.5 L 37,15.5", "#000", 1.2)
    out += circle(36.8, 17.3, 2, fill)
    out += detail("M 12,18.7 L 12,22", "#000", 1.2)
    out += shape("M 8.5,22 L 15.5,22 L 15.5,28 L 8.5,28 Z", fill)
    out += circle(22.5, 14.5, 1.4, fill)
    out += shape("M 6.5,31.5 L 38.5,31.5 L 38.5,35 L 6.5,35 Z", fill)
    out += wheels(team)
    if team == "black":
        out += detail("M 8,33.2 L 37,33.2 M 10,24.5 L 14,24.5", "#fff", 1)
    return out


# --- Assassin: the Rogue's hood and cloak, with twin daggers --------------------------
CLOAK = "M 13.5,28.5 C 9,30.5 7.5,34 5.5,40.5 L 20,40.5 L 22.5,33.5 L 25,40.5 L 39.5,40.5 C 37.5,34 36,30.5 31.5,28.5 Z"
HOOD = "M 22.5,3.5 C 27,8 32.5,13 33.5,19.5 C 34.2,24.5 32.5,28 29.5,30 L 15.5,30 C 12.5,28 10.8,24.5 11.5,19.5 C 12.5,13 18,8 22.5,3.5 Z"
OPENING = "M 22.5,12.5 C 25.8,15.3 28.8,18 28.8,21.8 C 28.8,24.8 26.8,26.5 24.6,26.5 L 20.4,26.5 C 18.2,26.5 16.2,24.8 16.2,21.8 C 16.2,18 19.2,15.3 22.5,12.5 Z"


def dagger(fill, x, y, angle, length=15):
    """A dagger with its grip at (x, y), pointing at `angle` degrees (0 = up).
    On a black piece the blade gets a white line down its middle, so it shows
    against the black cloak."""
    blade = "M 0,0 L -1.6,-2 L -1.3,-%s L 0,-%s L 1.3,-%s L 1.6,-2 Z" % (length - 3, length, length - 3)
    guard = "M -3.6,0 L 3.6,0 L 3.6,1.6 L -3.6,1.6 Z"
    grip = "M -1,1.6 L 1,1.6 L 1,5.4 L -1,5.4 Z"
    pommel = '<circle cx="0" cy="6.4" r="1.2" fill="%s" stroke="#000" stroke-width="1.2"/>' % fill
    group = '<g transform="translate(%s %s) rotate(%s)">' % (x, y, angle)
    for d in (blade, guard, grip):
        group += shape(d, fill, "#000", 1.2)
    if fill == "#000":
        group += detail("M 0,-2.4 L 0,-%s" % (length - 3.5), "#fff", 0.8)
    return group + pommel + "</g>"


def hooded(team):
    fill, line = colours(team)
    out = shape(CLOAK, fill) + shape(HOOD, fill)
    if team == "white":
        out += shape(OPENING, "#000")
    else:
        out += shape(OPENING, "#000", "#fff", 1.2)
        out += detail("M 15.8,30.8 L 29.2,30.8", "#fff", 1.1)
    return out


def assassin_crossed_behind(team):
    """Two daggers crossed behind the shoulders, blades up past the hood."""
    fill, line = colours(team)
    return dagger(fill, 31, 36, -44, 33) + dagger(fill, 14, 36, 44, 33) + hooded(team)


def assassin_at_sides(team):
    """A dagger held at each side of the cloak, blades pointing down and out."""
    fill, line = colours(team)
    return hooded(team) + dagger(fill, 9, 27.5, 205, 15) + dagger(fill, 36, 27.5, 155, 15)


def assassin_crossed_front(team):
    """Two daggers crossed in front of the cloak, blades up."""
    fill, line = colours(team)
    return hooded(team) + dagger(fill, 30, 39, -30, 16) + dagger(fill, 15, 39, 30, 16)


OPTIONS = {
    "princess_tiara": princess_tiara,
    "princess_crown": princess_crown,
    "galleon_square": galleon_square,
    "galleon_lateen": galleon_lateen,
    "catapult_arm": catapult_arm,
    "catapult_trebuchet": catapult_trebuchet,
    "assassin_crossed_behind": assassin_crossed_behind,
    "assassin_at_sides": assassin_at_sides,
    "assassin_crossed_front": assassin_crossed_front,
}

if __name__ == "__main__":
    here = os.path.dirname(os.path.abspath(__file__))
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(here, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(HEAD + draw(team) + TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
