import os, re, sys
OUT = os.path.dirname(os.path.abspath(__file__))
K = float(sys.argv[1]) if len(sys.argv) > 1 else 0.85   # head scale
AX, AY = (float(v) for v in (sys.argv[2:4] if len(sys.argv) > 3 else (26, 30)))  # point the head shrinks toward
STYLE = {
 "white": dict(fill="#fff", line="#000", detail="#000", eye="#000"),
 "black": dict(fill="#000", line="#000", detail="#fff", eye="#fff"),
}
def shrink(d):
    """Scale every x,y pair in a path toward the anchor point."""
    def f(m):
        x, y = float(m.group(1)), float(m.group(2))
        return f"{AX + (x - AX) * K:.2f},{AY + (y - AY) * K:.2f}"
    return re.sub(r"(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)", f, d)

# The head from option D (dome, ear, trunk, jaw), split off from the neck.
HEAD_FILL = "M 8.2,37.4 C 7.6,34 8.6,29 10,24.5 C 10.2,18.5 11.2,13 14.2,9.3 C 17.7,5.1 24.2,3.9 30.2,4.9 C 34.8,5.7 37.6,7.1 38.6,9.1 C 42,9.3 44,13.1 43.8,17.7 C 43.6,22.1 42,25.9 39.4,27.5 L 30,29 L 20.8,26.4 C 19.6,27 17.8,27.3 16.2,27.1 C 13.8,28.2 12.4,30.4 12.1,32.6 C 11.9,34.6 12,36.4 11.4,37.5 C 10.6,38.6 8.8,38.6 8.2,37.4 Z"
HEAD_OUTLINE = "M 20.8,26.4 C 19.6,27 17.8,27.3 16.2,27.1 C 13.8,28.2 12.4,30.4 12.1,32.6 C 11.9,34.6 12,36.4 11.4,37.5 C 10.6,38.6 8.8,38.6 8.2,37.4 C 7.6,34 8.6,29 10,24.5 C 10.2,18.5 11.2,13 14.2,9.3 C 17.7,5.1 24.2,3.9 30.2,4.9 C 34.8,5.7 37.6,7.1 38.6,9.1 C 42,9.3 44,13.1 43.8,17.7 C 43.6,22.1 42,25.9 39.4,27.5"
EAR = "M 26.4,11 C 24.8,14.3 24,17.9 23.8,21.1 L 27.8,26.2 L 30.4,20.9 C 32.6,25 35.6,27.3 39.4,27.5"
TUSK = "M 21,20.9 C 17.2,21.3 12.8,22.3 9.8,20.9 C 8,20.3 7.2,22.7 8.6,24.1 C 11.8,26.5 17.2,26.3 21.2,25.5 Z"
EYE = (16.8, 14.7)

def svg(c, neck):
    s = STYLE[c]
    ex, ey = (AX + (EYE[0] - AX) * K, AY + (EYE[1] - AY) * K)
    return f'''<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
<path fill="{s["fill"]}" stroke="{s["line"]}" d="{neck}"/>
<path fill="{s["fill"]}" stroke="none" d="{shrink(HEAD_FILL)}"/>
<path fill="none" stroke="{s["line"]}" d="{shrink(HEAD_OUTLINE)}"/>
<path fill="none" stroke="{s["detail"]}" d="{shrink(EAR)}"/>
<path fill="#fff" stroke="#000" d="{shrink(TUSK)}"/>
<ellipse cx="{ex:.2f}" cy="{ey:.2f}" rx="{1.7*K:.2f}" ry="{1.15*K:.2f}" transform="rotate(-25 {ex:.2f} {ey:.2f})" fill="{s["eye"]}" stroke="none"/>
</g></svg>'''

# The neck: widens to a flat bottom like the knight's. Its top is hidden under the head.
NECK = sys.argv[4] if len(sys.argv) > 4 else "M 15,39 L 38.5,39 C 38.6,35 37.6,31 36.6,28 L 30,25 L 21,25 C 20.6,30.5 16.6,33.6 15,39 Z"
for c in ("white", "black"):
    open(os.path.join(OUT, f"{c}_elephant.svg"), "w").write(svg(c, NECK))
print("ok")
