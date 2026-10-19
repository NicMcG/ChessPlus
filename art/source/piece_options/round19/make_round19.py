"""Round 19: Assassin, the daggers from Mac's reference (a cross-shaped guard
with rounded arms and a square centre, a short banded grip, a flared pommel and
a blade that steps in near the guard before tapering to the point), crossed
in an X. This time each dagger crosses the other at the middle of the WHOLE
dagger, pommel to tip, so the X is centred on the square. Also the reference's
own layout (side by side, pointing opposite ways) for comparison.

Run from this folder:  python make_round19.py
"""
import io
import math
import os

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">'
TAIL = "</g></svg>\n"
HERE = os.path.dirname(os.path.abspath(__file__))
CENTRE = (22.5, 22.5)
# How far the pommel's end is behind the guard (the grip and pommel together).
HILT = 12.5
# The daggers are drawn a little smaller than the shapes are written, with long
# blades, so the guards sit apart when they cross.
SCALE = 0.82


def parts(length):
    """The dagger's outline pieces, with the guard's centre at (0, 0) and the
    blade pointing up (-y), `length` from the guard to the point."""
    blade = ("M -3.3,-2 L -3.3,-4.6 L -2.5,-5.6 L -2.5,-7.6 L -3.1,-8.6 L 0,-%s L 3.1,-8.6 "
             "L 2.5,-7.6 L 2.5,-5.6 L 3.3,-4.6 L 3.3,-2 Z" % length)
    guard = ("M -2,-2.2 L -5.6,-2.2 C -6.4,-3.6 -8.6,-3.4 -8.6,-1.4 L -8.6,1.4 C -8.6,3.4 -6.4,3.6 -5.6,2.2 "
             "L -2,2.2 L -2,3 L 2,3 L 2,2.2 L 5.6,2.2 C 6.4,3.6 8.6,3.4 8.6,1.4 L 8.6,-1.4 "
             "C 8.6,-3.4 6.4,-3.6 5.6,-2.2 L 2,-2.2 L 2,-3 L -2,-3 Z")
    grip = "M -1.7,3 L 1.7,3 L 1.5,9 L -1.5,9 Z"
    pommel = "M -1.8,9 L 1.8,9 L 3.6,12.2 C 1.2,13.1 -1.2,13.1 -3.6,12.2 Z"
    return blade, guard, grip, pommel


def dagger(fill, angle, length, centre=CENTRE, along=None, gem=True, bands=True):
    """A dagger pointing at `angle` degrees (0 = up, clockwise). The point
    `along` from the guard towards the tip (default: the middle of the whole
    dagger, pommel to tip) is put on `centre`."""
    if along is None:
        along = (length - HILT) / 2 * SCALE
    rad = math.radians(angle)
    ux, uy = math.sin(rad), -math.cos(rad)
    gx, gy = centre[0] - ux * along, centre[1] - uy * along
    blade, guard, grip, pommel = parts(length)
    line = "#fff" if fill == "#000" else "#000"
    out = '<g transform="translate(%.2f %.2f) rotate(%s) scale(%s)">' % (gx, gy, angle, SCALE)
    for d in (blade, grip, pommel, guard):
        out += '<path d="%s" fill="%s" stroke="#000" stroke-width="%.2f"/>' % (d, fill, 1.4 / SCALE)
    # The blade's ridge, the guard's square centre and the grip's bands.
    out += '<path d="M 0,-2.4 L 0,-%s" fill="none" stroke="%s" stroke-width="0.8"/>' % (length - 3, line)
    if gem:
        out += '<rect x="-1.2" y="-1.2" width="2.4" height="2.4" fill="none" stroke="%s" stroke-width="0.8"/>' % line
    if bands:
        out += '<path d="M -1.6,5 L 1.6,5 M -1.5,7 L 1.5,7" fill="none" stroke="%s" stroke-width="0.8"/>' % line
    return out + "</g>"


def crossed(team, back_angle, front_angle, length):
    fill = "#fff" if team == "white" else "#000"
    return dagger(fill, back_angle, length) + dagger(fill, front_angle, length)


def side_by_side(team):
    """The reference's own layout: side by side on a slant, pointing opposite ways."""
    fill = "#fff" if team == "white" else "#000"
    return dagger(fill, 45, 34, (17.5, 17.5)) + dagger(fill, -135, 34, (27.5, 27.5))


OPTIONS = {
    "ref_x_points_down": lambda team: crossed(team, 135, -135, 36),
    "ref_x_points_up": lambda team: crossed(team, 45, -45, 36),
    "ref_x_longer": lambda team: crossed(team, 135, -135, 40),
    "ref_side_by_side": side_by_side,
}

if __name__ == "__main__":
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(HEAD + draw(team) + TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
