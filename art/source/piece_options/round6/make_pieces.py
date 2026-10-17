"""Sixth round: the man as just a linen coif (close cap covering top, back and sides of
the head, tied under the chin), no person. Cburnett conventions."""
import os
OUT = os.path.dirname(os.path.abspath(__file__))

STYLE = {
    "white": dict(fill="#fff", line="#000", detail="#000", inside="#000"),
    "black": dict(fill="#000", line="#000", detail="#fff", inside="#fff"),
}

def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'
            '<g stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' + body + '</g></svg>')

def shape(c, d):
    s = STYLE[c]
    return f'<path fill="{s["fill"]}" stroke="{s["line"]}" d="{d}"/>'

def detail(c, d, width=1.5):
    return f'<path fill="none" stroke="{STYLE[c]["detail"]}" stroke-width="{width}" d="{d}"/>'

def inside(c, d):
    """The inside of the cap, in the opposite colour (dark for White, light for Black)."""
    s = STYLE[c]
    return f'<path fill="{s["inside"]}" stroke="{s["line"]}" d="{d}"/>'

# Front view: outer coif, face opening, hem.
FRONT_OUTER = ("M 22.5,5 C 14.2,5 9.6,11.2 9.6,19.4 L 9.6,30.4 C 9.6,32.4 10.8,33.6 12.6,33.6 "
               "L 15.6,33.6 C 16.8,33.6 17.6,32.8 17.6,31.6 L 17.6,31 L 27.4,31 L 27.4,31.6 "
               "C 27.4,32.8 28.2,33.6 29.4,33.6 L 32.4,33.6 C 34.2,33.6 35.4,32.4 35.4,30.4 "
               "L 35.4,19.4 C 35.4,11.2 30.8,5 22.5,5 Z")
FRONT_OPENING = ("M 17.6,31 L 17.6,21.2 C 17.6,16.4 19.8,13.2 22.5,13.2 C 25.2,13.2 27.4,16.4 27.4,21.2 "
                 "L 27.4,31 Z")
FRONT_HEM = "M 15.6,32.2 L 15.6,21 C 15.6,15 18.6,11.2 22.5,11.2 C 26.4,11.2 29.4,15 29.4,21 L 29.4,32.2"
TIES_BOW = ("M 13.8,33.6 C 15.4,35.2 18.6,36.2 21.2,36.4 M 31.2,33.6 C 29.6,35.2 26.4,36.2 23.8,36.4 "
            "M 22.5,36.4 C 20.2,34.2 17.6,34.6 18.4,36.6 C 19,38.2 21.2,37.6 22.5,36.4 "
            "C 24.8,34.2 27.4,34.6 26.6,36.6 C 26,38.2 23.8,37.6 22.5,36.4 "
            "M 21.6,37 L 19.8,39.6 M 23.4,37 L 25.2,39.6")
BASE = "M 10.5,39.5 L 34.5,39.5 L 34.5,36.4 C 28.4,35 16.6,35 10.5,36.4 Z"

def coif_s(c):   # front view, inside the same colour, bow at the bottom
    return (shape(c, FRONT_OUTER)
            + shape(c, FRONT_OPENING)
            + detail(c, FRONT_HEM, 1.1)
            + detail(c, TIES_BOW, 1.4))

def coif_u(c):   # front view, dark inside, centre seam, ties hanging straight down
    return (shape(c, FRONT_OUTER)
            + inside(c, FRONT_OPENING)
            + detail(c, FRONT_HEM, 1.1)
            + detail(c, "M 22.5,5.6 L 22.5,11", 1.1)
            + detail(c, "M 13.8,33.6 C 14.2,35.6 15.4,37.8 16.6,39.6 M 31.2,33.6 C 30.8,35.6 29.6,37.8 28.4,39.6", 1.4))

def coif_w(c):   # front view, dark inside, standing on a base
    return (shape(c, BASE)
            + '<g transform="translate(0 2)">'
            + shape(c, FRONT_OUTER)
            + inside(c, FRONT_OPENING)
            + detail(c, FRONT_HEM, 1.1)
            + detail(c, "M 22.5,5.6 L 22.5,11", 1.1)
            + '</g>'
            + (detail(c, "M 12,36.9 C 18,35.6 27,35.6 33,36.9", 1.1) if c == "black" else ""))

# Side view facing left (like the knight): round back, hem along the front edge.
SIDE = ("M 12.6,30 L 12.4,13.4 C 14.6,8.4 20,5.4 26.2,5.4 C 33.4,5.4 38,11 38,18.4 "
        "C 38,24.4 35.4,29 30.4,31 L 23.2,32 C 19,32.4 15.2,32.2 12.6,30 Z")
SIDE_DETAILS = "M 15,13 L 15.2,30.4 M 14.6,11.2 C 21.6,8.2 30.2,9 36.2,15"

def coif_t(c):   # side view with ties hanging down to a bow
    return (shape(c, SIDE)
            + detail(c, SIDE_DETAILS, 1.1)
            + detail(c, "M 14,31 C 14.6,32.8 15.6,34.2 16.6,35 "
                        "M 16.6,35 C 14.4,33 11.8,33.6 12.8,35.6 C 13.4,37 15.4,36.4 16.6,35 "
                        "C 18.8,33 21.4,33.6 20.4,35.6 C 19.8,37 17.8,36.4 16.6,35 "
                        "M 16,35.8 L 14.8,39.6 M 17.2,35.8 L 18.6,39.6", 1.4))

def coif_v(c):   # side view standing on a base
    return (shape(c, BASE)
            + '<g transform="translate(0 3.4)">'
            + shape(c, SIDE)
            + detail(c, SIDE_DETAILS, 1.1)
            + '</g>'
            + (detail(c, "M 12,36.9 C 18,35.6 27,35.6 33,36.9", 1.1) if c == "black" else ""))

PIECES = {"man_s": coif_s, "man_t": coif_t, "man_u": coif_u, "man_v": coif_v, "man_w": coif_w}
for name, f in PIECES.items():
    for c in ("white", "black"):
        open(os.path.join(OUT, f"{c}_{name}.svg"), "w").write(svg(f(c)))
print("ok")
