"""Fourth round: the first standing cannon without its base and with simpler spokes,
a squarer lance, and men in medieval cloth caps (K-O). Cburnett conventions."""
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

def black_only(c, text):
    return text if c == "black" else ""

# --- Cannon: round-one design, no base, moved down to stand on the bottom edge ---------
def cannon(c):
    return ('<g transform="translate(0 3.5)">'
            + shape(c, "M 26,28 L 37,34 L 37,36 L 27,36 Z")                                   # trail
            + shape(c, "M 9,17.6 L 31.5,15.4 C 35.5,15 35.5,28.6 31.5,28.2 L 9,26 Z")         # barrel
            + shape(c, "M 5.5,16.6 C 5.5,15.8 9.5,15.8 9.5,16.6 L 9.5,27 C 9.5,27.8 5.5,27.8 5.5,27 Z")  # muzzle
            + shape(c, "M 35,19.6 C 39.6,18.6 39.6,25 35,24")                                 # breech knob
            + shape(c, "M 21,19.5 A 8.2,8.2 0 1 0 21.01,19.5 Z")                              # wheel
            + detail(c, "M 21,20.6 L 21,34.8 M 13.9,27.7 L 28.1,27.7", 1.3)                    # four spokes
            + shape(c, "M 21,25.5 A 2.2,2.2 0 1 0 21.01,25.5 Z")                              # hub
            + black_only(c, detail(c, "M 21,21 A 6.7,6.7 0 1 0 21.01,21 M 9.5,17.4 L 9.5,26.2 "
                                      "M 34.6,19.8 L 34.6,23.8 M 21,26.2 A 1.5,1.5 0 1 0 21.01,26.2", 1.2))
            + '</g>')

# --- Lance: squarer base, longer stem, flat underside to the arrowhead ------------------
def lance(c):
    return shape(c, "M 22.5,4 C 24.4,8.6 26.8,12.6 31.2,17 L 24.8,17.6 L 24.8,27 "
                    "C 25.2,30.4 31,32.6 34.6,34.2 L 35.2,39.5 L 9.8,39.5 L 10.4,34.2 "
                    "C 14,32.6 19.8,30.4 20.2,27 L 20.2,17.6 L 13.8,17 C 18.2,12.6 20.6,8.6 22.5,4 Z")

# --- Men in medieval cloth caps --------------------------------------------------------
SHOULDERS = "M 9,39.5 C 9,31 13,26.5 18.5,25.2 C 20.2,26.6 24.8,26.6 26.5,25.2 C 32,26.5 36,31 36,39.5 Z"
NECK = "M 19.5,22 L 19.5,26.5 C 21.5,27.8 23.5,27.8 25.5,26.5 L 25.5,22 Z"
COLLAR = "M 18.5,25.2 L 22.5,31 L 26.5,25.2"

def head(cy, r=7):
    return (f"M 22.5,{cy-r} C {22.5-r*0.6},{cy-r} {22.5-r},{cy-r*0.6} {22.5-r},{cy} "
            f"C {22.5-r},{cy+r*0.65} {22.5-r*0.55},{cy+r*1.1} 22.5,{cy+r*1.1} "
            f"C {22.5+r*0.55},{cy+r*1.1} {22.5+r},{cy+r*0.65} {22.5+r},{cy} "
            f"C {22.5+r},{cy-r*0.6} {22.5+r*0.6},{cy-r} 22.5,{cy-r} Z")

# Side-profile body and head facing left (the top of the head is hidden by the cap).
PROFILE_BODY = "M 9,39.5 C 9,31 13,26.5 18.5,25.4 L 27.5,25 C 32.5,26.4 36,31 36,39.5 Z"
PROFILE_HEAD = ("M 27.8,25.6 C 29.8,22 30.8,17.5 30,13 C 29.6,11 28.4,9.6 27,8.8 L 17.4,9.8 "
                "C 15.6,10.8 14.8,12.4 14.8,14 L 12.8,17.6 L 14.8,18.4 C 14.6,19.6 15.2,20.6 15.2,21.4 "
                "C 15.4,23 17,23.8 18.6,23.8 L 19,26 Z")

def profile_face(c):
    return dot(c, 18.4, 15.2, 1.1) + detail(c, "M 25.4,15.6 C 27,15.6 27.6,18 26,18.8", 1.2)

def man_k(c):   # floppy Tudor bonnet
    return (shape(c, SHOULDERS) + shape(c, NECK) + shape(c, head(17.5))
            + shape(c, "M 15.4,15.6 L 15.6,12.6 L 29.4,12.6 L 29.6,15.6 Z")
            + shape(c, "M 11,10.6 C 10.4,7.2 18,5 24.4,5.2 C 31,5.4 35.4,7.6 34.4,10.4 "
                       "C 33.6,12.6 27.4,13.4 22.5,13.4 C 17,13.4 11.4,12.8 11,10.6 Z")
            + detail(c, COLLAR))

def man_l(c):   # coif: close linen cap tied under the chin
    return (shape(c, SHOULDERS) + shape(c, NECK)
            + shape(c, "M 22.5,5.8 C 17.2,5.8 14.4,9.8 14.4,15.4 C 14.4,20.2 15.6,23.4 17.6,25 "
                       "L 27.4,25 C 29.4,23.4 30.6,20.2 30.6,15.4 C 30.6,9.8 27.8,5.8 22.5,5.8 Z")
            + shape(c, "M 22.5,11.2 C 19.6,11.2 17.8,13.6 17.8,17.2 C 17.8,20.8 19.8,23.4 22.5,23.4 "
                       "C 25.2,23.4 27.2,20.8 27.2,17.2 C 27.2,13.6 25.4,11.2 22.5,11.2 Z")
            + detail(c, "M 17.6,25 L 22.5,23.4 L 27.4,25", 1.2)
            + black_only(c, detail(c, "M 22.5,12.6 C 20.4,12.6 19.2,14.6 19.2,17.2 C 19.2,20 20.6,22 22.5,22 C 24.4,22 25.8,20 25.8,17.2 C 25.8,14.6 24.6,12.6 22.5,12.6 Z", 1.1))
            + detail(c, COLLAR))

def man_m(c):   # Phrygian cap flopping over to one side
    return (shape(c, SHOULDERS) + shape(c, NECK) + shape(c, head(17))
            + shape(c, "M 22.4,6.2 C 17.6,2.4 10.8,3.4 8.8,8.8 C 8.2,10.6 10,11.8 11.4,10.6 "
                       "C 12.8,9.4 14.8,8.8 16.6,9.2 Z")
            + shape(c, "M 15.4,15.2 C 15.2,10 17.6,6.2 22.4,6 C 27,5.8 29.8,9.2 29.8,13.4 L 29.6,15.2 Z")
            + detail(c, "M 15.6,13 L 29.6,13", 1.2)
            + detail(c, COLLAR))

def man_n(c):   # side profile in a Phrygian cap drooping forward
    return (shape(c, PROFILE_BODY) + shape(c, PROFILE_HEAD)
            + shape(c, "M 31,12.8 C 31.6,7.6 28.6,3.6 23.6,3.4 C 18.4,3.2 13.6,5.4 11,10 "
                       "C 10.2,11.6 11.4,13.2 13,12.4 C 13.8,11.8 14.6,11 15.6,10.8 L 16,12.8 Z")
            + black_only(c, detail(c, "M 16.2,12.8 L 30.8,12.8 M 15.6,10.8 C 17,8.6 19,7.4 21.2,7", 1.2))
            + profile_face(c))

def man_o(c):   # side profile in a hood-cap with a long tail hanging down the back
    return (shape(c, PROFILE_BODY)
            + shape(c, "M 29.4,9.6 C 33,12 34.6,18 34.2,25.4 C 34,28 32.2,28.6 31.2,27 "
                       "C 31.6,21.4 30.8,15.4 28.6,12 Z")
            + shape(c, PROFILE_HEAD)
            + shape(c, "M 30.6,12.8 C 31,8.6 28.4,5.6 23.8,5.4 C 19.4,5.2 15.8,7.2 14.6,10.6 "
                       "C 14.2,11.8 14.8,12.8 16,12.8 Z")
            + black_only(c, detail(c, "M 16.2,12.8 L 30.4,12.8 M 30,13.4 C 31.4,17 31.8,21.6 31.4,26", 1.2))
            + profile_face(c))

PIECES = {"cannon": cannon, "lance": lance,
          "man_k": man_k, "man_l": man_l, "man_m": man_m, "man_n": man_n, "man_o": man_o}
for name, f in PIECES.items():
    for c in ("white", "black"):
        open(os.path.join(OUT, f"{c}_{name}.svg"), "w").write(svg(f(c)))
print("ok")
