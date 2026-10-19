"""Round 20: options for batch 2 (Parapet, Vampire, Squire, Jester), white and
black, in the Cburnett style (45x45, 1.5 black outline; black pieces get thin
white details).

Run from this folder:  python make_round20.py
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "round16"))
import make_round16 as r16  # noqa: E402

shape, detail, circle, colours, inner = r16.shape, r16.detail, r16.circle, r16.colours, r16.inner
BASE_TOP, BASE_BOTTOM = r16.BASE_TOP, r16.BASE_BOTTOM


# --- Parapet: a stretch of castle wall --------------------------------------------------
def battlements(x0, x1, top, notch, merlons):
    """A wall top from x0 to x1 with `merlons` raised blocks, `notch` deep."""
    width = (x1 - x0) / (merlons * 2 - 1)
    d = "M %s,%s" % (x0, top)
    x = x0
    for i in range(merlons):
        d += " L %s,%s" % (x + width, top)
        if i < merlons - 1:
            d += " L %s,%s L %s,%s L %s,%s" % (x + width, top + notch, x + width * 2, top + notch, x + width * 2, top)
        x += width * 2
    return d


def parapet_wall(team):
    """A low wall with four merlons and brick lines, on a ribbon base."""
    fill, line = colours(team)
    wall = battlements(7, 38, 15, 5, 4) + " L 38,34 L 7,34 Z"
    out = shape(wall, fill)
    out += shape("M 6,34 L 39,34 L 39,38.5 L 6,38.5 Z", fill)
    bricks = ("M 7,24 L 38,24 M 7,29 L 38,29 M 15,20 L 15,24 M 30,20 L 30,24 "
              "M 11,24 L 11,29 M 22.5,24 L 22.5,29 M 34,24 L 34,29 M 17,29 L 17,34 M 28,29 L 28,34")
    out += detail(bricks, inner(team), 1)
    return out


def parapet_slit(team):
    """The wall with three merlons and an arrow slit in the middle."""
    fill, line = colours(team)
    wall = battlements(8, 37, 14, 6, 3) + " L 37,34 L 8,34 Z"
    out = shape(wall, fill)
    out += shape("M 6.5,34 L 38.5,34 L 38.5,38.5 L 6.5,38.5 Z", fill)
    out += shape("M 21.5,21 L 23.5,21 L 23.5,31 L 21.5,31 Z M 19,25 L 26,25 L 26,26.6 L 19,26.6 Z", inner(team), "none")
    out += detail("M 8,20 L 37,20", inner(team), 1)
    return out


def parapet_gate(team):
    """A wall with battlements over an arched gateway."""
    fill, line = colours(team)
    wall = battlements(6.5, 38.5, 13, 5, 5) + " L 38.5,38.5 L 26.5,38.5 L 26.5,31 C 26.5,27.5 24.5,26 22.5,26 C 20.5,26 18.5,27.5 18.5,31 L 18.5,38.5 L 6.5,38.5 Z"
    out = shape(wall, fill)
    out += detail("M 6.5,18 L 38.5,18 M 6.5,24 L 17,24 M 28,24 L 38.5,24", inner(team), 1)
    return out


# --- Vampire ------------------------------------------------------------------------------
def vampire_bat(team):
    """A bat with its wings spread."""
    fill, line = colours(team)
    wings = ("M 22.5,17 C 18,13.5 11,12 4,15 C 7,18 7.5,21 6.5,24 C 9,22.5 11.5,23 13,25.5 "
             "C 15,23.5 17.5,24 19,27 C 20.5,25 21.5,24 22.5,24 C 23.5,24 24.5,25 26,27 "
             "C 27.5,24 30,23.5 32,25.5 C 33.5,23 36,22.5 38.5,24 C 37.5,21 38,18 41,15 "
             "C 34,12 27,13.5 22.5,17 Z")
    body = ("M 22.5,15 C 25.5,15 26.5,18 26.5,21 C 26.5,25 24.5,28.5 22.5,30 "
            "C 20.5,28.5 18.5,25 18.5,21 C 18.5,18 19.5,15 22.5,15 Z")
    ears = "M 19.8,16.2 L 19.6,11.8 L 21.8,14.6 M 25.2,16.2 L 25.4,11.8 L 23.2,14.6"
    out = shape(wings, fill) + shape(ears, fill) + shape(body, fill)
    eyes = "#000" if team == "white" else "#fff"
    out += circle(21, 18.5, 0.75, eyes, "none") + circle(24, 18.5, 0.75, eyes, "none")
    out += detail("M 13,25.5 C 12,22 10,19 7,17.5 M 32,25.5 C 33,22 35,19 38,17.5", inner(team), 0.9)
    # Lowered so it perches on its base.
    return '<g transform="translate(0 4.5)">' + out + "</g>" + shape(BASE_TOP, fill) + shape(BASE_BOTTOM, fill)


def vampire_fangs(team):
    """A vampire's open mouth with two long fangs."""
    fill, line = colours(team)
    lip = ("M 7,16 C 12,13 17,15 22.5,17 C 28,15 33,13 38,16 C 37,24 30,30 22.5,30 "
           "C 15,30 8,24 7,16 Z")
    out = shape(lip, fill)
    out += shape("M 11,19 C 16,22 29,22 34,19 C 31,25 27,27 22.5,27 C 18,27 14,25 11,19 Z", "#000", "#000" if team == "white" else "#fff", 1)
    fang = "#fff"
    out += shape("M 14.5,20.6 L 16.5,28.5 L 18.8,21.6 Z", fang, "#000", 1.1)
    out += shape("M 30.5,20.6 L 28.5,28.5 L 26.2,21.6 Z", fang, "#000", 1.1)
    return '<g transform="translate(0 5)">' + out + "</g>"


def vampire_collar(team):
    """A vampire's head with slicked hair and fangs, in front of a tall
    pointed cloak collar."""
    fill, line = colours(team)
    collar = ("M 9,35 C 9,26 6,16 5,8 C 10,13 13.5,18 16,23 L 29,23 C 31.5,18 35,13 40,8 "
              "C 39,16 36,26 36,35 Z")
    head = ("M 15.5,20 C 15.5,13 18.5,9 22.5,9 C 26.5,9 29.5,13 29.5,20 C 29.5,26.5 26.5,31 22.5,31 "
            "C 18.5,31 15.5,26.5 15.5,20 Z")
    hair = "M 15.6,18.5 C 16,12 19,9 22.5,9 C 26,9 29,12 29.4,18.5 C 27.5,15 25,13.8 22.5,17.2 C 20,13.8 17.5,15 15.6,18.5 Z"
    out = shape(collar, fill) + shape(head, fill)
    out += shape(hair, "#000", "#000" if team == "white" else "#fff", 1)
    eyes = "#000" if team == "white" else "#fff"
    out += shape("M 18.3,20.2 L 21,21 L 18.6,21.6 Z M 26.7,20.2 L 24,21 L 26.4,21.6 Z", eyes, "none")
    out += detail("M 19.8,26 C 21.5,27 23.5,27 25.2,26", eyes, 1)
    out += shape("M 20.6,26.4 L 21.2,28.6 L 21.8,26.8 Z M 24.4,26.4 L 23.8,28.6 L 23.2,26.8 Z", "#fff", "#000", 0.7)
    return out + shape(BASE_TOP, fill) + shape(BASE_BOTTOM, fill)


# --- Squire -------------------------------------------------------------------------------
KNIGHT_HEAD = ("M 22,14 C 27.5,14.5 30.5,18 30.2,27.5 L 19,27.5 C 19,23 23.7,24.2 22.6,17 "
               "C 22.8,18.4 19.9,20.6 18.7,21.4 C 17.2,22.4 17.3,23.5 16.2,23.3 C 15.2,23.3 13.7,22.8 13.7,21.3 "
               "C 13.7,19.3 14.7,17.1 16.2,15.4 C 17.4,13.9 19.5,12.7 22,14 Z")


def squire_heater(team):
    """A heater shield with a horse's head on it."""
    fill, line = colours(team)
    shield = "M 9,8 L 36,8 L 36,20 C 36,30 30,36 22.5,40 C 15,36 9,30 9,20 Z"
    out = shape(shield, fill)
    out += detail("M 11.5,10.5 L 33.5,10.5 L 33.5,20 C 33.5,28.5 28.5,33.5 22.5,37 C 16.5,33.5 11.5,28.5 11.5,20 Z", inner(team), 1)
    horse_fill = "#000" if team == "white" else "#fff"
    out += shape(KNIGHT_HEAD, horse_fill, "none")
    return out


def squire_round(team):
    """A round shield with a horse's head and a rim of rivets."""
    fill, line = colours(team)
    out = circle(22.5, 23, 15.5, fill)
    out += circle(22.5, 23, 12.6, "none", inner(team), 1)
    for i in range(8):
        import math
        a = math.radians(i * 45 + 22.5)
        out += circle(22.5 + 14 * math.cos(a), 23 + 14 * math.sin(a), 0.75, inner(team), "none")
    horse_fill = "#000" if team == "white" else "#fff"
    out += '<g transform="translate(0.5 2.5)">' + shape(KNIGHT_HEAD, horse_fill, "none") + "</g>"
    return out


def squire_helmet(team):
    """A squire's kettle helmet (a round cap with a wide brim)."""
    fill, line = colours(team)
    cap = "M 12.5,27 C 12.5,16 17,10 22.5,10 C 28,10 32.5,16 32.5,27 Z"
    brim = "M 5.5,28.5 C 10,25.5 35,25.5 39.5,28.5 C 37.5,32 7.5,32 5.5,28.5 Z"
    out = shape(cap, fill) + shape(brim, fill)
    out += detail("M 22.5,10.5 L 22.5,26.5 M 15,18 C 19,16.5 26,16.5 30,18", inner(team), 1)
    return '<g transform="translate(0 5)">' + out + "</g>"


# --- Jester -------------------------------------------------------------------------------
def jester_three(team):
    """A jester's cap: three floppy points with bells, on a band."""
    fill, line = colours(team)
    left = "M 13,30 C 11,23 8,19 4.5,17.5 C 9,15.5 15,17.5 18,25 Z"
    middle = "M 17,28 C 17,20 19,13 22.5,8.5 C 26,13 28,20 28,28 Z"
    right = "M 32,30 C 34,23 37,19 40.5,17.5 C 36,15.5 30,17.5 27,25 Z"
    out = shape(left, fill) + shape(right, fill) + shape(middle, fill)
    out += circle(4.2, 17.4, 2.3, fill) + circle(22.5, 7.2, 2.3, fill) + circle(40.8, 17.4, 2.3, fill)
    band = "M 11,28 C 17,26 28,26 34,28 L 33.5,33 C 28,31.5 17,31.5 11.5,33 Z"
    out += shape(band, fill)
    for x in (15, 19.5, 25.5, 30):
        out += circle(x, 30.2, 0.9, inner(team), "none")
    return out + shape(BASE_TOP.replace("34", "35").replace("32,28", "33,28"), fill) + shape(BASE_BOTTOM, fill)


def jester_two(team):
    """A two-pointed jester's cap with bells, the points curling down."""
    fill, line = colours(team)
    left = "M 12,31 C 10,22 7,16 3.5,15 C 9,10 17,12 22.5,22 Z"
    right = "M 33,31 C 35,22 38,16 41.5,15 C 36,10 28,12 22.5,22 Z"
    out = shape(left, fill) + shape(right, fill)
    out += detail("M 22.5,22 L 22.5,29", inner(team), 1)
    out += circle(3.6, 17.8, 2.3, fill) + circle(41.4, 17.8, 2.3, fill)
    band = "M 11,29 C 17,27 28,27 34,29 L 33.5,34 C 28,32.5 17,32.5 11.5,34 Z"
    out += shape(band, fill)
    out += shape(BASE_BOTTOM, fill)
    return out


OPTIONS = {
    "parapet_wall": parapet_wall,
    "parapet_slit": parapet_slit,
    "parapet_gate": parapet_gate,
    "vampire_bat": vampire_bat,
    "vampire_fangs": vampire_fangs,
    "vampire_collar": vampire_collar,
    "squire_heater": squire_heater,
    "squire_round": squire_round,
    "squire_helmet": squire_helmet,
    "jester_three": jester_three,
    "jester_two": jester_two,
}

if __name__ == "__main__":
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
