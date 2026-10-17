"""Draft art for Man, Cannon, Lance and Paladin in the Cburnett style (45x45 canvas,
1.5 outline; white pieces = white fill + black lines, black pieces = black fill +
white detail lines)."""
import os
OUT = os.path.dirname(os.path.abspath(__file__))

STYLE = {
    "white": dict(fill="#fff", line="#000", detail="#000"),
    "black": dict(fill="#000", line="#000", detail="#fff"),
}

def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'
            '<g stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' + body + '</g></svg>')

def shape(c, d):    # filled shape with outline
    s = STYLE[c]
    return f'<path fill="{s["fill"]}" stroke="{s["line"]}" d="{d}"/>'

def detail(c, d, width=1.5):  # inner line: black on white pieces, white on black pieces
    s = STYLE[c]
    return f'<path fill="none" stroke="{s["detail"]}" stroke-width="{width}" d="{d}"/>'

def dot(c, x, y, r):
    s = STYLE[c]
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{s["detail"]}" stroke="none"/>'

BASE = "M 9,39.5 L 36,39.5 L 36,36 L 9,36 Z"

# --- Man: head and shoulders ---------------------------------------------------------
def man(c):
    return (shape(c, "M 9,39.5 C 9,31 13,26.5 18.5,25.2 C 20.2,26.6 24.8,26.6 26.5,25.2 C 32,26.5 36,31 36,39.5 Z")
            + shape(c, "M 19.5,22 L 19.5,26.5 C 21.5,27.8 23.5,27.8 25.5,26.5 L 25.5,22 Z")
            + shape(c, "M 22.5,7.5 C 18.2,7.5 15.6,10.8 15.6,15.2 C 15.6,19.8 18.6,23.4 22.5,23.4 C 26.4,23.4 29.4,19.8 29.4,15.2 C 29.4,10.8 26.8,7.5 22.5,7.5 Z")
            + detail(c, "M 18.5,25.2 L 22.5,31 L 26.5,25.2"))

# --- Cannon A: barrel on a wheel, on a base -------------------------------------------
def cannon_a(c):
    return (shape(c, "M 26,28 L 37,34 L 37,36 L 27,36 Z")                       # trail
            + shape(c, "M 9,17.6 L 31.5,15.4 C 35.5,15 35.5,28.6 31.5,28.2 L 9,26 Z")  # barrel
            + shape(c, "M 5.5,16.6 C 5.5,15.8 9.5,15.8 9.5,16.6 L 9.5,27 C 9.5,27.8 5.5,27.8 5.5,27 Z")  # muzzle
            + shape(c, "M 35,19.6 C 39.6,18.6 39.6,25 35,24")                       # breech knob
            + shape(c, BASE)
            + shape(c, "M 21,19.5 A 8.2,8.2 0 1 0 21.01,19.5 Z")                    # wheel
            + detail(c, "M 21,22.3 L 21,33.1 M 15.6,27.7 L 26.4,27.7 M 17.2,23.9 L 24.8,31.5 M 24.8,23.9 L 17.2,31.5", 1.2)
            + (detail(c, "M 21,21 A 6.7,6.7 0 1 0 21.01,21 M 9.5,17.4 L 9.5,26.2 M 34.6,19.8 L 34.6,23.8", 1.2) if c == "black" else "")
            + dot(c, 21, 27.7, 1.8))

# --- Cannon B: round token with a cannon inside, like the reference --------------------
def cannon_b(c):
    s = STYLE[c]
    inner = "#000" if c == "white" else "#fff"
    return (f'<circle cx="22.5" cy="22.5" r="18.5" fill="{s["fill"]}" stroke="{s["line"]}"/>'
            + f'<circle cx="22.5" cy="22.5" r="15.5" fill="none" stroke="{inner}" stroke-width="1"/>'
            + f'<g fill="none" stroke="{inner}" stroke-width="1.6">'
            + '<path d="M 11,20 L 30,18.4 C 32.6,18.2 32.6,26 30,25.8 L 11,24.2 Z"/>'
            + '<path d="M 9,19.2 L 11,19.2 L 11,25 L 9,25 Z"/>'
            + '<circle cx="22" cy="27.5" r="5"/>'
            + '</g>'
            + f'<circle cx="22" cy="27.5" r="1.4" fill="{inner}" stroke="none"/>')

# --- Lance A: a spear standing on a base -----------------------------------------------
def lance_a(c):
    return (shape(c, BASE)
            + shape(c, "M 13,36 C 13,33.5 17,32 22.5,32 C 28,32 32,33.5 32,36 Z")
            + shape(c, "M 21.2,32 L 21.2,17 L 23.8,17 L 23.8,32 Z")                  # shaft
            + shape(c, "M 17.5,17 L 27.5,17 L 27.5,19 L 17.5,19 Z")                  # crossguard
            + shape(c, "M 22.5,4.5 C 25.8,8.5 27,12.5 25.5,17 L 19.5,17 C 18,12.5 19.2,8.5 22.5,4.5 Z")  # blade
            + detail(c, "M 22.5,8 L 22.5,15", 1.2))

# --- Lance B: shogi-style tile with a spear, like the reference -------------------------
def lance_b(c):
    s = STYLE[c]
    mark = "#000" if c == "white" else "#fff"
    return (shape(c, "M 22.5,4.5 L 32,9.5 L 35.5,39.5 L 9.5,39.5 L 13,9.5 Z")
            + f'<path fill="{mark}" stroke="none" d="M 22.5,11 C 25.4,14.5 26.4,18 25,21.5 L 23.4,21.5 L 23.4,35 L 21.6,35 L 21.6,21.5 L 20,21.5 C 18.6,18 19.6,14.5 22.5,11 Z"/>'
            + f'<path fill="{mark}" stroke="none" d="M 18.2,21 L 26.8,21 L 26.8,23 L 18.2,23 Z"/>')

# --- Paladin: armoured knight behind a big shield; wounded = no shield -------------------
def paladin_body(c):
    return (shape(c, "M 8.5,39.5 C 8.5,31 10,25 15,22.5 L 30,22.5 C 35,25 36.5,31 36.5,39.5 Z")    # shoulders/torso
            + shape(c, "M 22.5,6 C 17,6 15,10 15,15 L 15,22.5 L 30,22.5 L 30,15 C 30,10 28,6 22.5,6 Z")  # helmet
            + shape(c, "M 22.5,6 C 23.5,3.5 26.5,2.5 29,4 C 26.5,4 24.5,5 23.5,7")                       # plume
            + detail(c, "M 17,14.5 L 28,14.5", 1.8)                                                       # visor slit
            + detail(c, "M 22.5,16 L 22.5,22", 1.2))

def paladin(c):
    s = STYLE[c]
    return (paladin_body(c)
            + shape(c, "M 9.5,16 L 35.5,16 L 35.5,26 C 35.5,33 29.5,37.5 22.5,40.5 C 15.5,37.5 9.5,33 9.5,26 Z")  # shield
            + (detail(c, "M 11.8,18.2 L 33.2,18.2 L 33.2,26 C 33.2,31.8 28.3,35.8 22.5,38.2 C 16.7,35.8 11.8,31.8 11.8,26 Z", 1.2) if c == "black" else "")
            + detail(c, "M 22.5,20 L 22.5,35 M 15.5,25 L 29.5,25", 2.2))                                               # cross

def paladin_wounded(c):
    return (paladin_body(c)
            + detail(c, "M 15,30 L 30,30", 1.5)                # belt
            + detail(c, "M 22.5,24.5 L 22.5,29.5", 1.2))       # breastplate ridge

PIECES = {
    "man": man,
    "cannon_a": cannon_a, "cannon_b": cannon_b,
    "lance_a": lance_a, "lance_b": lance_b,
    "paladin": paladin, "paladin_wounded": paladin_wounded,
}
for name, f in PIECES.items():
    for c in ("white", "black"):
        open(os.path.join(OUT, f"{c}_{name}.svg"), "w").write(svg(f(c)))
print("ok")
