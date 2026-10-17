"""Seventh round: more front-view linen coifs between S and U. Cburnett conventions."""
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
    s = STYLE[c]
    return f'<path fill="{s["inside"]}" stroke="{s["line"]}" d="{d}"/>'

# --- Shapes ------------------------------------------------------------------------------
# A: the S/U shape (straight sides).
OUTER_A = ("M 22.5,5 C 14.2,5 9.6,11.2 9.6,19.4 L 9.6,30.4 C 9.6,32.4 10.8,33.6 12.6,33.6 "
           "L 15.6,33.6 C 16.8,33.6 17.6,32.8 17.6,31.6 L 17.6,31 L 27.4,31 L 27.4,31.6 "
           "C 27.4,32.8 28.2,33.6 29.4,33.6 L 32.4,33.6 C 34.2,33.6 35.4,32.4 35.4,30.4 "
           "L 35.4,19.4 C 35.4,11.2 30.8,5 22.5,5 Z")
OPENING_A = "M 17.6,31 L 17.6,21.2 C 17.6,16.4 19.8,13.2 22.5,13.2 C 25.2,13.2 27.4,16.4 27.4,21.2 L 27.4,31 Z"
HEM_A = "M 15.6,32.2 L 15.6,21 C 15.6,15 18.6,11.2 22.5,11.2 C 26.4,11.2 29.4,15 29.4,21 L 29.4,32.2"
TIES_A = (14, 31)    # where the ties leave the cheek flaps (x left, x right) at y 33.6

# B: cheek flaps curving in toward the chin, face-shaped opening.
OUTER_B = ("M 22.5,4.6 C 14,4.6 9.4,11 9.4,19.4 C 9.4,25 10.6,29.6 13,32.4 C 14.2,33.8 16.2,34 17.4,32.8 "
           "L 18.6,31.4 L 26.4,31.4 L 27.6,32.8 C 28.8,34 30.8,33.8 32,32.4 C 34.4,29.6 35.6,25 35.6,19.4 "
           "C 35.6,11 31,4.6 22.5,4.6 Z")
OPENING_B = ("M 18.6,31.4 C 17.6,28.4 17.2,24.6 17.4,21.2 C 17.6,16.2 19.8,13 22.5,13 "
             "C 25.2,13 27.4,16.2 27.6,21.2 C 27.8,24.6 27.4,28.4 26.4,31.4 Z")
HEM_B = ("M 16.2,32 C 15.4,28.6 15.2,24.6 15.4,21 C 15.8,14.8 18.6,11 22.5,11 "
         "C 26.4,11 29.2,14.8 29.6,21 C 29.8,24.6 29.6,28.6 28.8,32")
TIES_B = (15.4, 29.6)

# C: B with a taller, puffier crown.
OUTER_C = ("M 22.5,3.6 C 13,3.6 8.6,10.6 8.8,19.4 C 8.9,25 10.4,29.6 13,32.4 C 14.2,33.8 16.2,34 17.4,32.8 "
           "L 18.6,31.4 L 26.4,31.4 L 27.6,32.8 C 28.8,34 30.8,33.8 32,32.4 C 34.6,29.6 36.1,25 36.2,19.4 "
           "C 36.4,10.6 32,3.6 22.5,3.6 Z")
GATHERS = "M 17.6,5.4 L 18.6,8.2 M 22.5,4.4 L 22.5,7.6 M 27.4,5.4 L 26.4,8.2"
SEAM = "M 22.5,5.4 L 22.5,10.8"

# --- Ties ----------------------------------------------------------------------------------
def bow(lx, rx):
    return (f"M {lx},33.6 C {lx+1.6},35.2 18.6,36.2 21.2,36.4 M {rx},33.6 C {rx-1.6},35.2 26.4,36.2 23.8,36.4 "
            "M 22.5,36.4 C 20.2,34.2 17.6,34.6 18.4,36.6 C 19,38.2 21.2,37.6 22.5,36.4 "
            "C 24.8,34.2 27.4,34.6 26.6,36.6 C 26,38.2 23.8,37.6 22.5,36.4 "
            "M 21.6,37 L 19.8,39.6 M 23.4,37 L 25.2,39.6")

def hanging(lx, rx):
    return f"M {lx},33.6 C {lx+0.4},35.6 {lx+1.6},37.8 {lx+2.8},39.6 M {rx},33.6 C {rx-0.4},35.6 {rx-1.6},37.8 {rx-2.8},39.6"

def knot(lx, rx):
    return (f"M {lx},33.6 C {lx+2},35.4 19.6,36.4 22.5,36.6 M {rx},33.6 C {rx-2},35.4 25.4,36.4 22.5,36.6 "
            "M 22.5,36.6 L 20.6,39.6 M 22.5,36.6 L 24.4,39.6")

def knot_dot(c):
    return f'<circle cx="22.5" cy="36.6" r="1.3" fill="{STYLE[c]["detail"]}" stroke="none"/>'

# --- Variants ------------------------------------------------------------------------------
def man_s2(c):
    return shape(c, OUTER_B) + shape(c, OPENING_B) + detail(c, HEM_B, 1.1) + detail(c, bow(*TIES_B), 1.4)

def man_s3(c):
    return (shape(c, OUTER_C) + shape(c, OPENING_B) + detail(c, HEM_B, 1.1)
            + detail(c, GATHERS, 1.1) + detail(c, bow(*TIES_B), 1.4))

def man_s4(c):
    return (shape(c, OUTER_A) + shape(c, OPENING_A) + detail(c, HEM_A, 1.1)
            + detail(c, GATHERS.replace("4.4", "5.6").replace("5.4", "6.6"), 1.1) + detail(c, hanging(*TIES_A), 1.4))

def man_u2(c):
    return (shape(c, OUTER_B) + inside(c, OPENING_B) + detail(c, HEM_B, 1.1)
            + detail(c, SEAM, 1.1) + detail(c, hanging(*TIES_B), 1.4))

def man_u3(c):
    return (shape(c, OUTER_B) + inside(c, OPENING_B) + detail(c, HEM_B, 1.1)
            + detail(c, SEAM, 1.1) + detail(c, bow(*TIES_B), 1.4))

def man_u4(c):
    return (shape(c, OUTER_A) + inside(c, OPENING_A) + detail(c, HEM_A, 1.1)
            + detail(c, SEAM, 1.1) + detail(c, knot(*TIES_A), 1.4) + knot_dot(c))

PIECES = {"man_s2": man_s2, "man_s3": man_s3, "man_s4": man_s4,
          "man_u2": man_u2, "man_u3": man_u3, "man_u4": man_u4}
for name, f in PIECES.items():
    for c in ("white", "black"):
        open(os.path.join(OUT, f"{c}_{name}.svg"), "w").write(svg(f(c)))
print("ok")
