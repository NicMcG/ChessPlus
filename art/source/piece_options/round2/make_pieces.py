"""Second round: cannon and lance redrawn from Mac's reference pictures, and five
options for the man. Cburnett conventions: 45x45 canvas, 1.5 outline; white pieces
are white with black lines, black pieces are black with white lines."""
import os
OUT = os.path.dirname(os.path.abspath(__file__))

STYLE = {
    "white": dict(fill="#fff", line="#000", detail="#000"),
    "black": dict(fill="#000", line="#000", detail="#fff"),
}

def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'
            '<g stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' + body + '</g></svg>')

def shape(c, d):
    s = STYLE[c]
    return f'<path fill="{s["fill"]}" stroke="{s["line"]}" d="{d}"/>'

def detail(c, d, width=1.5):
    s = STYLE[c]
    return f'<path fill="none" stroke="{s["detail"]}" stroke-width="{width}" d="{d}"/>'

def dot(c, x, y, r):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{STYLE[c]["detail"]}" stroke="none"/>'

def ink(c):
    """The colour of line art drawn on the piece's own fill."""
    return "#000" if c == "white" else "#fff"

# --- Cannon: round token, line-art cannon pointing right (from the reference) ----------
def cannon(c):
    s, k = STYLE[c], ink(c)
    return (f'<circle cx="22.5" cy="22.5" r="19" fill="{s["fill"]}" stroke="{s["line"]}"/>'
            + f'<circle cx="22.5" cy="22.5" r="16.6" fill="none" stroke="{k}" stroke-width="1"/>'
            # Barrel (domed back, narrow muzzle on the right) running into the hooked trail.
            + f'<path fill="none" stroke="{k}" stroke-width="1.7" d="M 27.2,24.8 L 37.4,25.4 C 38.2,25.2 38.4,24.2 37.6,23.5 '
              'C 36.2,22.4 33.8,21.4 31.3,20 C 30,19 28,18.4 25.4,18.2 L 18.8,17.9 C 17.4,17.9 16.2,18.8 15.8,20.2 '
              'C 15.2,22.4 14.6,24.8 13,25.8 C 11.6,26.6 9.6,26.8 8.6,27.6 C 7.6,28.4 7.8,29.6 9,29.6 L 18.2,29.2"/>'
            # Wheel and hub, drawn over the carriage.
            + f'<circle cx="22.4" cy="27.2" r="4.6" fill="{s["fill"]}" stroke="{k}" stroke-width="1.7"/>'
            + f'<circle cx="22.4" cy="27.2" r="1.6" fill="none" stroke="{k}" stroke-width="1.4"/>')

# --- Lance: shogi tile with an arrowhead on a bell-shaped base (from the reference) -----
def lance(c):
    k = ink(c)
    return (shape(c, "M 22.5,5.5 L 32.5,8 L 36.5,40 L 8.5,40 L 12.5,8 Z")
            + f'<path fill="{k}" stroke="none" d="M 22.5,10.5 C 23.6,13.5 25,16 27.5,18.6 C 25.8,18.8 24.4,19.2 23.6,19.8 '
              'L 23.6,24 C 24,27.5 28,29.5 30.6,31 C 31.8,31.8 31.6,33.6 30,33.8 C 25,34.3 20,34.3 15,33.8 '
              'C 13.4,33.6 13.2,31.8 14.4,31 C 17,29.5 21,27.5 21.4,24 L 21.4,19.8 C 20.6,19.2 19.2,18.8 17.5,18.6 '
              'C 20,16 21.4,13.5 22.5,10.5 Z"/>')

# --- Man options ---------------------------------------------------------------------
SHOULDERS = "M 9,39.5 C 9,31 13,26.5 18.5,25.2 C 20.2,26.6 24.8,26.6 26.5,25.2 C 32,26.5 36,31 36,39.5 Z"
NECK = "M 19.5,22 L 19.5,26.5 C 21.5,27.8 23.5,27.8 25.5,26.5 L 25.5,22 Z"

def head(cy):
    return f"M 22.5,{cy-8} C 18.2,{cy-8} 15.6,{cy-4.7} 15.6,{cy-0.3} C 15.6,{cy+4.3} 18.6,{cy+7.9} 22.5,{cy+7.9} C 26.4,{cy+7.9} 29.4,{cy+4.3} 29.4,{cy-0.3} C 29.4,{cy-4.7} 26.8,{cy-8} 22.5,{cy-8} Z"

def man_a(c):   # plain head and shoulders
    return shape(c, SHOULDERS) + shape(c, NECK) + shape(c, head(15.5)) + detail(c, "M 18.5,25.2 L 22.5,31 L 26.5,25.2")

def man_b(c):   # soldier with a helmet
    return (shape(c, SHOULDERS) + shape(c, NECK) + shape(c, head(16.5))
            + shape(c, "M 15,15 C 15,9 18.2,6 22.5,6 C 26.8,6 30,9 30,15 Z")
            + shape(c, "M 12,14.6 L 33,14.6 C 33,16.4 12,16.4 12,14.6 Z")
            + detail(c, "M 18.5,25.2 L 22.5,31 L 26.5,25.2"))

def man_c(c):   # wide-brimmed hat
    return (shape(c, SHOULDERS) + shape(c, NECK) + shape(c, head(16.5))
            + shape(c, "M 16.8,13 L 17.8,6.2 C 20,5.2 25,5.2 27.2,6.2 L 28.2,13 Z")
            + shape(c, "M 10,13.6 C 10,11.6 35,11.6 35,13.6 C 35,15.6 10,15.6 10,13.6 Z")
            + detail(c, "M 17.6,11.2 L 27.4,11.2", 1.2)
            + detail(c, "M 18.5,25.2 L 22.5,31 L 26.5,25.2"))

def man_d(c):   # side profile facing left, like the knight
    return (shape(c, "M 9,39.5 C 9,31 13,26.5 18.5,25.4 L 27.5,25 C 32.5,26.4 36,31 36,39.5 Z")
            + shape(c, "M 27.8,25.6 C 29.8,22 30.8,17.5 30,12.8 C 29.2,8.4 25.8,6 21.8,6.2 "
                       "C 17.4,6.4 14.8,9.6 14.8,13.2 L 12.8,17 L 14.8,17.8 C 14.6,19 15.2,20 15.2,21 "
                       "C 15.4,22.6 17,23.4 18.6,23.4 L 19,26 Z")
            + dot(c, 18.2, 13.6, 1.1)
            + detail(c, "M 25.2,14 C 26.8,14 27.4,16.4 25.8,17.2", 1.2))

def man_e(c):   # simple standing figure on a base
    return (shape(c, "M 10,39.5 L 35,39.5 L 35,36.5 L 10,36.5 Z")
            + shape(c, "M 14.5,36.5 L 16.4,23.8 C 16.8,18 19.4,15.4 22.5,15.4 C 25.6,15.4 28.2,18 28.6,23.8 L 30.5,36.5 Z")
            + shape(c, "M 22.5,5.4 A 4.6,4.6 0 1 0 22.51,5.4 Z")
            + detail(c, "M 17.6,27.5 L 27.4,27.5", 1.3)
            + detail(c, "M 18.4,19 L 17.2,27 M 26.6,19 L 27.8,27", 1.2))

PIECES = {"cannon": cannon, "lance": lance,
          "man_a": man_a, "man_b": man_b, "man_c": man_c, "man_d": man_d, "man_e": man_e}
for name, f in PIECES.items():
    for c in ("white", "black"):
        open(os.path.join(OUT, f"{c}_{name}.svg"), "w").write(svg(f(c)))
print("ok")
