"""Round 21: more Vampire bats and Squire shields, and a saddle (white and black).

Run from this folder:  python make_round21.py
"""
import io
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "round16"))
sys.path.insert(0, os.path.join(HERE, "..", "round20"))
import make_round16 as r16  # noqa: E402
import make_round20 as r20  # noqa: E402

shape, detail, circle, colours, inner = r16.shape, r16.detail, r16.circle, r16.colours, r16.inner


def eyes(team, xs, y, r=0.8):
    colour = "#000" if team == "white" else "#fff"
    return "".join(circle(x, y, r, colour, "none") for x in xs)


# --- Bats -------------------------------------------------------------------------------
def bat_spread(team):
    """A big bat, wings fully spread with scalloped edges, filling the square."""
    fill, line = colours(team)
    wings = ("M 22.5,19 C 17,13 9,10.5 2.5,14 C 5.5,18 5.5,22.5 4,26.5 C 7.5,24.5 11,25 13,28.5 "
             "C 15.5,26 18.5,26.5 20,30.5 C 21,29 21.8,28.5 22.5,28.5 C 23.2,28.5 24,29 25,30.5 "
             "C 26.5,26.5 29.5,26 32,28.5 C 34,25 37.5,24.5 41,26.5 C 39.5,22.5 39.5,18 42.5,14 "
             "C 36,10.5 28,13 22.5,19 Z")
    body = ("M 22.5,16 C 26,16 27.2,19.5 27.2,22.5 C 27.2,27.5 25,31.5 22.5,33.5 "
            "C 20,31.5 17.8,27.5 17.8,22.5 C 17.8,19.5 19,16 22.5,16 Z")
    ears = "M 19.4,17.4 L 19,12.2 L 21.6,15.6 Z M 25.6,17.4 L 26,12.2 L 23.4,15.6 Z"
    out = shape(wings, fill) + shape(ears, fill) + shape(body, fill) + eyes(team, (20.8, 24.2), 20)
    out += detail("M 13,28.5 C 12,24 9.5,19.5 6,16.5 M 20,30.5 C 19,25 17,21 14,18 "
                  "M 32,28.5 C 33,24 35.5,19.5 39,16.5 M 25,30.5 C 26,25 28,21 31,18", inner(team), 0.9)
    return out


def bat_hanging(team):
    """A bat hanging upside down from a branch, wings wrapped round it."""
    fill, line = colours(team)
    out = shape("M 6,7.5 C 15,6.5 30,6.5 39,7.5 L 39,10.5 C 30,9.5 15,9.5 6,10.5 Z", fill)
    out += shape("M 20,10 L 21,13.5 M 25,10 L 24,13.5", fill, "#000", 1.4)
    body = ("M 22.5,12.5 C 29,12.5 32,18 32,25 C 32,31 28.5,35 25.5,36.5 L 19.5,36.5 "
            "C 16.5,35 13,31 13,25 C 13,18 16,12.5 22.5,12.5 Z")
    out += shape(body, fill)
    out += detail("M 22.5,13.5 L 22.5,33 M 16,17 C 18.5,22 18.5,28 16.5,33 M 29,17 C 26.5,22 26.5,28 28.5,33", inner(team), 0.9)
    # Head at the bottom (upside down), ears pointing down.
    head = "M 22.5,33 C 25.5,33 27,35.5 27,37.5 C 27,40 25,41.5 22.5,41.5 C 20,41.5 18,40 18,37.5 C 18,35.5 19.5,33 22.5,33 Z"
    out += shape("M 19.2,40.5 L 18.4,44 L 21,41.6 Z M 25.8,40.5 L 26.6,44 L 24,41.6 Z", fill)
    out += shape(head, fill) + eyes(team, (20.9, 24.1), 37.8, 0.7)
    return out


def bat_flying(team):
    """A bat in flight, wings raised in a V."""
    fill, line = colours(team)
    wings = ("M 22.5,23 C 18,17 13,10 6,6 C 7.5,11 7,15.5 5,19 C 8.5,18.5 11,20 12,23 "
             "C 14.5,22 17,23.5 18,27 L 22.5,27 L 27,27 C 28,23.5 30.5,22 33,23 "
             "C 34,20 36.5,18.5 40,19 C 38,15.5 37.5,11 39,6 C 32,10 27,17 22.5,23 Z")
    body = ("M 22.5,20.5 C 25.5,20.5 26.5,23.5 26.5,26.5 C 26.5,31.5 24.5,35.5 22.5,37.5 "
            "C 20.5,35.5 18.5,31.5 18.5,26.5 C 18.5,23.5 19.5,20.5 22.5,20.5 Z")
    ears = "M 19.8,21.8 L 19.2,17 L 21.6,20 Z M 25.2,21.8 L 25.8,17 L 23.4,20 Z"
    out = shape(wings, fill) + shape(ears, fill) + shape(body, fill) + eyes(team, (21, 24), 24.4)
    out += detail("M 12,23 C 11.5,18 9.5,13 7.5,9 M 33,23 C 33.5,18 35.5,13 37.5,9", inner(team), 0.9)
    return out


def bat_moon(team):
    """A bat flying in front of a crescent moon."""
    fill, line = colours(team)
    moon = ("M 31,5 C 22,5.5 15.5,12.5 15.5,21.5 C 15.5,30.5 22.5,37.5 31.5,38 "
            "C 25,34 21.5,28 21.5,21.5 C 21.5,15 25,9 31,5 Z")
    out = shape(moon, "#fff" if team == "white" else "#000")
    wings = ("M 25,22 C 21.5,18.5 16,17 11,19 C 13,21.5 13,24 12,26.5 C 14.5,25.5 17,26 18,28.5 "
             "C 19.5,27 21.5,27.5 22.5,30 L 25,29 L 27.5,30 C 28.5,27.5 30.5,27 32,28.5 "
             "C 33,26 35.5,25.5 38,26.5 C 37,24 37,21.5 39,19 C 34,17 28.5,18.5 25,22 Z")
    body = "M 25,20 C 27,20 28,22 28,24 C 28,27.5 26.5,30 25,31.5 C 23.5,30 22,27.5 22,24 C 22,22 23,20 25,20 Z"
    out += shape(wings, fill) + shape("M 23,21 L 22.7,17.8 L 24.3,20 Z M 27,21 L 27.3,17.8 L 25.7,20 Z", fill)
    out += shape(body, fill) + eyes(team, (24, 26), 23.2, 0.6)
    return out


# --- Squire: shields and a saddle --------------------------------------------------------
HORSE = r20.KNIGHT_HEAD


def horse(team, dx=0, dy=0, scale=1.0):
    colour = "#000" if team == "white" else "#fff"
    return '<g transform="translate(%s %s) scale(%s)">%s</g>' % (dx, dy, scale, shape(HORSE, colour, "none"))


def shield_kite(team):
    """A tall kite shield (rounded top, long point) with a horse's head."""
    fill, line = colours(team)
    out = shape("M 11,7 C 16,5 29,5 34,7 C 35,18 31,32 22.5,41 C 14,32 10,18 11,7 Z", fill)
    out += detail("M 13.5,9.2 C 18,7.8 27,7.8 31.5,9.2 C 32.2,18.5 28.8,30 22.5,37.6 C 16.2,30 12.8,18.5 13.5,9.2 Z", inner(team), 1)
    return out + horse(team, -0.5, -2)


def shield_bend(team):
    """A heater shield with a diagonal band, and a horse's head above it."""
    fill, line = colours(team)
    shield = "M 9,7 L 36,7 L 36,19 C 36,29 30,35 22.5,39.5 C 15,35 9,29 9,19 Z"
    out = shape(shield, fill)
    band = "M 9,23 L 36,9.5 L 36,15.5 L 11.5,31 C 10.2,28.8 9.4,26 9,23 Z"
    out += shape(band, inner(team), "none")
    # The horse in the plain corner above the band.
    return out + horse(team, 4.6, 2.4, 0.55)


def shield_horseshoe(team):
    """A heater shield with a horseshoe on it."""
    fill, line = colours(team)
    shield = "M 9,7 L 36,7 L 36,19 C 36,29 30,35 22.5,39.5 C 15,35 9,29 9,19 Z"
    out = shape(shield, fill)
    shoe = ("M 15.5,30 C 13,25 13,15.5 22.5,13 C 32,15.5 32,25 29.5,30 L 26,30 "
            "C 28,25.5 27.5,18.5 22.5,17 C 17.5,18.5 17,25.5 19,30 Z")
    colour = "#000" if team == "white" else "#fff"
    out += shape(shoe, colour, "none")
    for x, y in ((16, 21), (16.8, 26.5), (29, 21), (28.2, 26.5), (19.5, 16), (25.5, 16)):
        out += circle(x, y, 0.65, "#fff" if team == "white" else "#000", "none")
    return out


def shield_quartered(team):
    """A heraldic shield in quarters: two filled, two plain, a horse's head in one."""
    fill, line = colours(team)
    shield = "M 9,7 L 36,7 L 36,19 C 36,29 30,35 22.5,39.5 C 15,35 9,29 9,19 Z"
    out = shape(shield, fill)
    colour = "#000" if team == "white" else "#fff"
    out += shape("M 22.5,7 L 36,7 L 36,21 L 22.5,21 Z", colour, "none")
    out += shape("M 9,21 L 22.5,21 L 22.5,39.5 C 15,35 9,29 9,21 Z", colour, "none")
    out += shape(shield, "none")
    flip = "#fff" if team == "white" else "#000"
    # A horse's head in each plain quarter (top left, bottom right).
    out += '<g transform="translate(3.6 2.8) scale(0.55)">%s</g>' % shape(HORSE, colour, "none")
    out += '<g transform="translate(16.6 16.4) scale(0.55)">%s</g>' % shape(HORSE, colour, "none")
    return out


def saddle(team):
    """A riding saddle from the side: the seat dipping between a raised pommel and
    cantle, a flap hanging down and a stirrup."""
    fill, line = colours(team)
    seat = ("M 7,17 C 9,15 11,15.5 12.5,18 C 15,22 27,22 31,17 C 33,14 36,12.5 38.5,13.5 "
            "C 38.5,17 36.5,20.5 34,23 C 30,27 15,28 10,24 C 7.5,22 6.5,19.5 7,17 Z")
    flap = "M 13,25.5 L 30.5,25 C 31,29 30,32.5 28,35 L 15.5,35 C 13.5,32 12.5,28.5 13,25.5 Z"
    out = shape(flap, fill) + shape(seat, fill)
    out += detail("M 21.5,26 L 21.5,32.5", inner(team), 1.2)
    out += shape("M 18,37 L 25,37 C 25,40.5 18,40.5 18,37 Z", fill)
    out += detail("M 15.5,24 C 20,25.6 26,25.4 31,23", inner(team), 1)
    return out


OPTIONS = {
    "bat_spread": bat_spread,
    "bat_hanging": bat_hanging,
    "bat_flying": bat_flying,
    "bat_moon": bat_moon,
    "shield_kite": shield_kite,
    "shield_bend": shield_bend,
    "shield_horseshoe": shield_horseshoe,
    "shield_quartered": shield_quartered,
    "saddle": saddle,
}

if __name__ == "__main__":
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
