"""Third round: the cannon and lance symbols on their own (no token, no tile), drawn
as standing Cburnett-style pieces, and more man options (F-J)."""
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
    return f'<path fill="none" stroke="{STYLE[c]["detail"]}" stroke-width="{width}" d="{d}"/>'

def dot(c, x, y, r):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{STYLE[c]["detail"]}" stroke="none"/>'

def circle(c, x, y, r):
    s = STYLE[c]
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{s["fill"]}" stroke="{s["line"]}"/>'

# --- Cannon: just the cannon from the token, scaled up, standing on wheel and trail ----
def cannon(c):
    # The token's cannon, scaled about 1.9x: barrel pointing right with a domed back,
    # a hooked trail curling down to the left, a wheel under the back half.
    return (shape(c, "M 4.5,37.5 C 3.5,36 4.5,34 7,33.5 C 10.5,32.8 13.5,32.2 15.8,30.2 "
                     "C 17.6,28.4 17.8,22.5 19.8,19 C 21,16.8 23,15.6 25.6,15.7 L 31.5,16.2 "
                     "C 35,16.6 37.8,18 39.6,20.4 C 41.2,22.4 42.4,24 41.6,25.6 C 41,26.6 39.8,26.7 38.6,26.6 "
                     "L 28,26.2 L 26.5,37 L 6.5,38.8 C 5.6,38.8 5,38.3 4.5,37.5 Z")
            + circle(c, 24.5, 30.8, 8.2)
            + circle(c, 24.5, 30.8, 2.6)
            + (detail(c, "M 24.5,24.1 A 6.7,6.7 0 1 0 24.51,24.1 M 24.5,29.2 A 1.6,1.6 0 1 0 24.51,29.2", 1.2) if c == "black" else ""))

# --- Lance: just the symbol from the tile, scaled up: barbed arrowhead on a bell base --
def lance(c):
    return shape(c, "M 22.5,4 C 24.4,8.8 26.6,12.6 31,16.8 C 28.2,17.2 26,18 24.8,19 "
                    "L 24.8,24.5 C 25.4,29.6 31.6,32.4 35.6,34.6 C 37.6,35.8 37.2,39 34.6,39.3 "
                    "C 26.6,40 18.4,40 10.4,39.3 C 7.8,39 7.4,35.8 9.4,34.6 "
                    "C 13.4,32.4 19.6,29.6 20.2,24.5 L 20.2,19 C 19,18 16.8,17.2 14,16.8 "
                    "C 18.4,12.6 20.6,8.8 22.5,4 Z")

# --- More man options ----------------------------------------------------------------
SHOULDERS = "M 9,39.5 C 9,31 13,26.5 18.5,25.2 C 20.2,26.6 24.8,26.6 26.5,25.2 C 32,26.5 36,31 36,39.5 Z"
NECK = "M 19.5,22 L 19.5,26.5 C 21.5,27.8 23.5,27.8 25.5,26.5 L 25.5,22 Z"

def head(cy, r=7):
    return (f"M 22.5,{cy-r} C {22.5-r*0.6},{cy-r} {22.5-r},{cy-r*0.6} {22.5-r},{cy} "
            f"C {22.5-r},{cy+r*0.65} {22.5-r*0.55},{cy+r*1.1} 22.5,{cy+r*1.1} "
            f"C {22.5+r*0.55},{cy+r*1.1} {22.5+r},{cy+r*0.65} {22.5+r},{cy} "
            f"C {22.5+r},{cy-r*0.6} {22.5+r*0.6},{cy-r} 22.5,{cy-r} Z")

def man_f(c):   # hooded figure
    return (shape(c, "M 22.5,4.5 C 27.5,7.5 32,12.5 32,19.5 C 32,23.5 30.6,25.8 29.4,27 "
                     "C 33.6,29 36,33 36,39.5 L 9,39.5 C 9,33 11.4,29 15.6,27 "
                     "C 14.4,25.8 13,23.5 13,19.5 C 13,12.5 17.5,7.5 22.5,4.5 Z")
            + shape(c, "M 22.5,11.5 C 19.4,11.5 17.8,14.6 17.8,18.4 C 17.8,22.2 19.8,25 22.5,25 "
                       "C 25.2,25 27.2,22.2 27.2,18.4 C 27.2,14.6 25.6,11.5 22.5,11.5 Z")
            + (detail(c, "M 22.5,13 C 20.3,13 19.3,15.6 19.3,18.4 C 19.3,21.4 20.7,23.5 22.5,23.5 C 24.3,23.5 25.7,21.4 25.7,18.4 C 25.7,15.6 24.7,13 22.5,13 Z", 1.1) if c == "black" else ""))

def man_g(c):   # bearded man
    return (shape(c, SHOULDERS) + shape(c, NECK) + shape(c, head(14.5))
            + shape(c, "M 15.8,15.5 C 15.8,23.5 18.8,28.5 22.5,28.8 C 26.2,28.5 29.2,23.5 29.2,15.5 "
                       "C 27.6,18.6 25.4,19.6 22.5,19.6 C 19.6,19.6 17.4,18.6 15.8,15.5 Z")
            + detail(c, "M 19.6,19.8 C 21.2,18.8 23.8,18.8 25.4,19.8", 1.2))

def man_h(c):   # statue bust on a plinth
    return (shape(c, "M 11,39.5 L 34,39.5 L 34,35.5 L 11,35.5 Z")
            + shape(c, "M 17,35.5 L 18,33 L 27,33 L 28,35.5 Z")
            + shape(c, "M 12.5,33 C 12.5,27.5 15.8,24.2 19.4,23.4 C 20.8,24.6 24.2,24.6 25.6,23.4 C 29.2,24.2 32.5,27.5 32.5,33 Z")
            + shape(c, "M 20,20 L 20,24.2 C 21.6,25.2 23.4,25.2 25,24.2 L 25,20 Z")
            + shape(c, head(13.2, 6.2)))

def man_i(c):   # side profile with a flat cap
    return (shape(c, "M 9,39.5 C 9,31 13,26.5 18.5,25.4 L 27.5,25 C 32.5,26.4 36,31 36,39.5 Z")
            + shape(c, "M 27.8,25.6 C 29.8,22 30.8,17.5 30,13 C 29.6,11 28.4,9.6 27,8.8 "
                       "L 17.4,9.8 C 15.6,10.8 14.8,12.4 14.8,14 L 12.8,17.6 L 14.8,18.4 "
                       "C 14.6,19.6 15.2,20.6 15.2,21.4 C 15.4,23 17,23.8 18.6,23.8 L 19,26 Z")
            + shape(c, "M 31,11.4 C 30.6,7.6 27,5.6 22.6,5.8 C 18.6,6 16,7.8 15.4,10 L 10.6,11.2 C 10,11.4 10.2,12.4 10.8,12.4 L 31,12.4 Z")
            + dot(c, 18.4, 15, 1.1)
            + detail(c, "M 25.4,15.4 C 27,15.4 27.6,17.8 26,18.6", 1.2))

def man_j(c):   # soldier in a wide-brimmed kettle helmet
    return (shape(c, SHOULDERS) + shape(c, NECK) + shape(c, head(17))
            + shape(c, "M 15.4,14.5 C 15.4,8 18.6,5 22.5,5 C 26.4,5 29.6,8 29.6,14.5 Z")
            + shape(c, "M 9.5,17.5 C 13,14.2 32,14.2 35.5,17.5 C 32,16.6 13,16.6 9.5,17.5 Z")
            + detail(c, "M 22.5,5.5 L 22.5,14", 1.2)
            + detail(c, "M 18.5,25.2 L 22.5,31 L 26.5,25.2"))

PIECES = {"cannon": cannon, "lance": lance,
          "man_f": man_f, "man_g": man_g, "man_h": man_h, "man_i": man_i, "man_j": man_j}
for name, f in PIECES.items():
    for c in ("white", "black"):
        open(os.path.join(OUT, f"{c}_{name}.svg"), "w").write(svg(f(c)))
print("ok")
