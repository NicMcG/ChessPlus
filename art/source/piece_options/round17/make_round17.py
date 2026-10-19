"""Round 17: Assassin options, just daggers, after Mac's references (Oct 2026):
an X, two daggers parallel at an angle, three crossing, a dagger crossing its
sheath, and two curved daggers turned round each other. White and black.

Run from this folder:  python make_round17.py
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "round16"))
import make_round16 as r16  # noqa: E402

shape, detail, colours = r16.shape, r16.detail, r16.colours


def dagger(fill, x, y, angle, length=24):
    """A straight double-edged dagger: the guard at (x, y), the blade `length`
    long pointing at `angle` degrees (0 = up, clockwise), the grip behind."""
    blade = "M -2.1,0 L -2.1,-%s L 0,-%s L 2.1,-%s L 2.1,0 Z" % (length - 6, length, length - 6)
    guard = "M -5.2,0 C -5.2,-1 -4.4,-1.4 -3.4,-1.2 L 3.4,-1.2 C 4.4,-1.4 5.2,-1 5.2,0 C 5.2,1.2 4.4,1.6 3.4,1.4 L -3.4,1.4 C -4.4,1.6 -5.2,1.2 -5.2,0 Z"
    grip = "M -1.5,1.4 L 1.5,1.4 L 1.3,8.6 L -1.3,8.6 Z"
    out = '<g transform="translate(%s %s) rotate(%s)">' % (x, y, angle)
    out += shape(blade, fill, "#000", 1.3) + shape(grip, fill, "#000", 1.3) + shape(guard, fill, "#000", 1.3)
    out += '<circle cx="0" cy="10.2" r="1.9" fill="%s" stroke="#000" stroke-width="1.3"/>' % fill
    groove = "#fff" if fill == "#000" else "#000"
    out += detail("M 0,-2.4 L 0,-%s" % (length - 6.5), groove, 0.8)
    return out + "</g>"


def sheath(fill, x, y, angle, length=22):
    """A dagger's sheath: a tapering scabbard with a metal tip and a band near
    its mouth at (x, y), pointing along `angle`."""
    body = "M -3.2,0 L -2.6,-%s C -2.6,-%s 2.6,-%s 2.6,-%s L 3.2,0 Z" % (length - 3, length + 1, length + 1, length - 3)
    mouth = "M -3.8,0.2 L 3.8,0.2 L 3.6,2.6 L -3.6,2.6 Z"
    tip = "M -2.6,-%s C -2.6,-%s 2.6,-%s 2.6,-%s Z" % (length - 4, length + 1, length + 1, length - 4)
    out = '<g transform="translate(%s %s) rotate(%s)">' % (x, y, angle)
    out += shape(body, fill, "#000", 1.3) + shape(mouth, fill, "#000", 1.3) + shape(tip, fill, "#000", 1.3)
    line = "#fff" if fill == "#000" else "#000"
    out += detail("M -2.9,-7 L 2.9,-7", line, 0.9)
    return out + "</g>"


def daggers_x(team):
    """Two daggers crossed in an X, handles up in the top corners, blades down."""
    fill, line = colours(team)
    return dagger(fill, 11.5, 11.5, 135, 30) + dagger(fill, 33.5, 11.5, -135, 30)


def daggers_parallel(team):
    """Two daggers side by side on a slant, pointing opposite ways."""
    fill, line = colours(team)
    return dagger(fill, 12, 24.5, 45, 24) + dagger(fill, 33, 20.5, -135, 24)


def daggers_three(team):
    """One dagger upright, point down, with two more crossed behind it."""
    fill, line = colours(team)
    out = dagger(fill, 12.5, 15, 148, 24) + dagger(fill, 32.5, 15, -148, 24)
    return out + dagger(fill, 22.5, 14.5, 180, 25)


def dagger_and_sheath(team):
    """A dagger crossed with its sheath."""
    fill, line = colours(team)
    return sheath(fill, 11, 11, 135, 29) + dagger(fill, 33.5, 11.5, -135, 30)


def daggers_curved_pair(team):
    """Two curved daggers, one turned upside down round the other."""
    fill, line = colours(team)
    return r16.curved_dagger(fill, 11.5, 27.5, 35) + r16.curved_dagger(fill, 33.5, 17.5, 215)


OPTIONS = {
    "daggers_x": daggers_x,
    "daggers_parallel": daggers_parallel,
    "daggers_three": daggers_three,
    "dagger_and_sheath": dagger_and_sheath,
    "daggers_curved_pair": daggers_curved_pair,
}

if __name__ == "__main__":
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
