"""Round 18: Assassin, two daggers crossed in a symmetrical X (Mac: they should
cross near the middle of the blades, not near the tips). Each dagger is placed
so the middle of its blade sits on the centre of the square. White and black;
on black pieces the dagger in front gets a thin white gap where it crosses the
one behind, so the X reads clearly.

Run from this folder:  python make_round18.py
"""
import io
import math
import os

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">'
TAIL = "</g></svg>\n"
HERE = os.path.dirname(os.path.abspath(__file__))
CENTRE = (22.5, 22.5)


def dagger_parts(length, style):
    """The dagger's outline pieces, guard at (0, 0), blade pointing up (-y)."""
    half = 3.1 if style == "broad" else 2.1
    if style == "broad":
        blade = "M -%s,0 C -%s,-%s -%s,-%s 0,-%s C %s,-%s %s,-%s %s,0 Z" % (
            half, half + 1.2, length * 0.45, half, length * 0.8, length, half, length * 0.8, half + 1.2, length * 0.45, half)
    else:
        blade = "M -%s,0 L -%s,-%s L 0,-%s L %s,-%s L %s,0 Z" % (half, half, length - 6, length, half, length - 6, half)
    if style == "curved":
        guard = "M -6,-2.6 C -5,-0.6 -3,0 0,0 C 3,0 5,-0.6 6,-2.6 C 5.4,1 3,2 0,2 C -3,2 -5.4,1 -6,-2.6 Z"
    else:
        guard = ("M -5.4,0 C -5.4,-1 -4.6,-1.4 -3.6,-1.2 L 3.6,-1.2 C 4.6,-1.4 5.4,-1 5.4,0 "
                 "C 5.4,1.2 4.6,1.6 3.6,1.4 L -3.6,1.4 C -4.6,1.6 -5.4,1.2 -5.4,0 Z")
    grip = "M -1.5,1.4 L 1.5,1.4 L 1.3,8.4 L -1.3,8.4 Z"
    return blade, grip, guard


def placed(angle, length):
    """The transform putting a dagger's blade middle on the centre, pointing at `angle`."""
    rad = math.radians(angle)
    ux, uy = math.sin(rad), -math.cos(rad)
    gx, gy = CENTRE[0] - ux * length / 2, CENTRE[1] - uy * length / 2
    return "translate(%.2f %.2f) rotate(%s)" % (gx, gy, angle)


def dagger(fill, angle, length, style):
    transform = placed(angle, length)
    blade, grip, guard = dagger_parts(length, style)
    out = '<g transform="%s">' % transform
    for d in (blade, grip, guard):
        out += '<path d="%s" fill="%s" stroke="#000" stroke-width="1.3"/>' % (d, fill)
    out += '<circle cx="0" cy="10" r="1.9" fill="%s" stroke="#000" stroke-width="1.3"/>' % fill
    groove = "#fff" if fill == "#000" else "#000"
    out += '<path d="M 0,-2.4 L 0,-%s" fill="none" stroke="%s" stroke-width="0.8"/>' % (length - 6.5, groove)
    return out + "</g>"


def halo(front_angle, back_angle, length, style):
    """On black pieces: a white edge round the front dagger, only where it lies
    over the dagger behind (clipped to that dagger's shape)."""
    blade, grip, guard = dagger_parts(length, style)
    back = placed(back_angle, length)
    clip = '<clipPath id="behind">%s</clipPath>' % "".join(
        '<path d="%s" transform="%s"/>' % (d, back) for d in (blade, grip, guard))
    front = placed(front_angle, length)
    edge = "".join('<path d="%s" transform="%s" fill="#fff" stroke="#fff" stroke-width="3.6" clip-path="url(#behind)"/>' % (d, front)
                   for d in (blade, guard))
    return "<defs>%s</defs>%s" % (clip, edge)


def crossed(team, back_angle, front_angle, length, style="straight"):
    fill = "#fff" if team == "white" else "#000"
    out = dagger(fill, back_angle, length, style)
    if team == "black":
        out += halo(front_angle, back_angle, length, style)
    return out + dagger(fill, front_angle, length, style)


OPTIONS = {
    "x_points_down": lambda team: crossed(team, 135, -135, 26),
    "x_points_up": lambda team: crossed(team, 45, -45, 26),
    "x_long": lambda team: crossed(team, 135, -135, 29),
    "x_broad": lambda team: crossed(team, 45, -45, 25, "broad"),
    "x_curved_guard": lambda team: crossed(team, 135, -135, 26, "curved"),
}

if __name__ == "__main__":
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(HEAD + draw(team) + TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
