"""Fifth round: the cannon (round four) with the original eight spokes, enlarged; and
the man as just a medieval cloth cap, the way the king is a crown and the bishop a
mitre. Cburnett conventions."""
import os
OUT = os.path.dirname(os.path.abspath(__file__))

STYLE = {
    "white": dict(fill="#fff", line="#000", detail="#000"),
    "black": dict(fill="#000", line="#000", detail="#fff"),
}

def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'
            '<g stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' + body + '</g></svg>')

def shape(c, d, width=None):
    s = STYLE[c]
    w = f' stroke-width="{width}"' if width else ""
    return f'<path fill="{s["fill"]}" stroke="{s["line"]}"{w} d="{d}"/>'

def detail(c, d, width=1.5):
    return f'<path fill="none" stroke="{STYLE[c]["detail"]}" stroke-width="{width}" d="{d}"/>'

def dot(c, x, y, r):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{STYLE[c]["detail"]}" stroke="none"/>'

def black_only(c, text):
    return text if c == "black" else ""

# --- Cannon: round-four cannon, eight spokes, scaled up 15% from the bottom centre -------
SCALE = 1.15

def cannon(c):
    w = 1.5 / SCALE  # so outlines still come out 1.5 thick after scaling
    return (f'<g transform="translate(22.5 39.5) scale({SCALE}) translate(-22.5 -39.5) translate(0 3.5)">'
            + shape(c, "M 26,28 L 37,34 L 37,36 L 27,36 Z", w)
            + shape(c, "M 9,17.6 L 31.5,15.4 C 35.5,15 35.5,28.6 31.5,28.2 L 9,26 Z", w)
            + shape(c, "M 5.5,16.6 C 5.5,15.8 9.5,15.8 9.5,16.6 L 9.5,27 C 9.5,27.8 5.5,27.8 5.5,27 Z", w)
            + shape(c, "M 35,19.6 C 39.6,18.6 39.6,25 35,24", w)
            + shape(c, "M 21,19.5 A 8.2,8.2 0 1 0 21.01,19.5 Z", w)
            + detail(c, "M 21,22.3 L 21,33.1 M 15.6,27.7 L 26.4,27.7 M 17.2,23.9 L 24.8,31.5 M 24.8,23.9 L 17.2,31.5", 1.2 / SCALE)
            + dot(c, 21, 27.7, 1.8)
            + black_only(c, detail(c, "M 21,21 A 6.7,6.7 0 1 0 21.01,21 M 9.5,17.4 L 9.5,26.2 M 34.6,19.8 L 34.6,23.8", 1.2 / SCALE))
            + '</g>')

# --- Man: just a cap -------------------------------------------------------------------
def cap_p(c):   # Phrygian cap: a soft cone whose tip flops forward
    return (shape(c, "M 15.4,33.5 C 13.4,27.6 12.6,22.2 13.6,17.6 C 11.8,18.2 10.2,19.8 9.4,21.6 "
                     "C 8.8,23 7,22.8 7,21.2 C 7.2,15.4 11.6,9.6 18.2,7.4 C 24.6,5.2 31.2,7.4 34.2,13 "
                     "C 36.6,17.6 36.6,26 34.6,33.5 Z")
            + detail(c, "M 13.6,17.6 C 15.6,14.8 18.8,13.2 22.4,13.2", 1.3)
            + detail(c, "M 23.8,9.6 C 27,13.6 28.4,20.4 28,27", 1.1)
            + shape(c, "M 12,39.5 L 12,34.8 C 18,32.8 27,32.8 33,34.8 L 33,39.5 C 27,38.4 18,38.4 12,39.5 Z")
            + detail(c, "M 13.6,36.9 C 19,35.5 26,35.5 31.4,36.9", 1.1)
            + black_only(c, detail(c, "M 13.4,34.4 C 19,32.9 26,32.9 31.6,34.4", 1.1)))

def cap_q(c):   # Tudor bonnet: a floppy flat crown gathered over a band
    return (shape(c, "M 13,39.5 L 13.6,31 L 31.4,31 L 32,39.5 C 26,38.6 19,38.6 13,39.5 Z")
            + shape(c, "M 4.8,26.6 C 3.4,20.2 12.4,14.6 22.5,14.6 C 32.6,14.6 41.6,20.2 40.2,26.6 "
                       "C 39.4,30.2 31.4,32.2 22.5,32.2 C 13.6,32.2 5.6,30.2 4.8,26.6 Z")
            + detail(c, "M 12,19.4 C 13.6,22.8 14.4,26 14.2,29.6 M 22.5,15.6 L 22.5,30.6 M 33,19.4 C 31.4,22.8 30.6,26 30.8,29.6", 1.1)
            + shape(c, "M 29,12.6 C 31,6.6 36,4.4 40,5.2 C 37.6,7.6 35,11.6 32.4,16.4 Z")
            + dot(c, 31.2, 16.2, 1.5)
            + black_only(c, detail(c, "M 14.4,30.4 C 19.6,31.2 25.4,31.2 30.6,30.4", 1.1)))

def cap_r(c):   # feathered peaked cap ("Robin Hood" cap)
    return (shape(c, "M 30.6,22.8 C 32.6,14.8 35.4,8.6 39.4,5.2 C 38,10.8 36.4,17.8 34.4,24.2 Z")
            + shape(c, "M 4.6,33.6 C 7.6,30 13.2,22.6 19.8,17.4 C 25,13.4 31.2,12.6 35.2,15.4 "
                       "C 38.2,17.6 38.8,22.6 38.4,27.6 L 37.6,33.6 Z")
            + detail(c, "M 35.6,24.8 L 37.4,30.4", 1.1)
            + shape(c, "M 8.6,39.5 L 8.6,33.6 L 38,33.6 L 38,39.5 Z")
            + detail(c, "M 10.4,36.5 L 36.2,36.5", 1.1)
            + detail(c, "M 33.6,7.4 L 37.4,9.2 M 32.6,11.2 L 36.4,13.2 M 31.8,15 L 35.2,16.8", 1)
            + black_only(c, detail(c, "M 10,34.8 L 36.6,34.8", 1.1)))

PIECES = {"cannon": cannon, "man_p": cap_p, "man_q": cap_q, "man_r": cap_r}
for name, f in PIECES.items():
    for c in ("white", "black"):
        open(os.path.join(OUT, f"{c}_{name}.svg"), "w").write(svg(f(c)))
print("ok")
