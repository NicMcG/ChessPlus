"""Eighth round: linen coifs shaped like Mac's photo: slightly pointed top with a centre
seam, sides dropping to angular points at the jaw, long ties. Cburnett conventions."""
import os
OUT = os.path.dirname(os.path.abspath(__file__))

STYLE = {
    "white": dict(fill="#fff", line="#000", detail="#000", inside="#000"),
    "black": dict(fill="#000", line="#000", detail="#fff", inside="#fff"),
}

def svg(body):
    return ('<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'
            '<g stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">' + body + '</g></svg>')

def path(fill, stroke, d, width=None):
    w = f' stroke-width="{width}"' if width else ""
    return f'<path fill="{fill}" stroke="{stroke}"{w} d="{d}"/>'

def outer(peak_y=3.6, peak_sharp=False):
    """The coif: pointed top, sides down to angular tips at the jaw, opening cut out."""
    top = (f"M 22.5,{peak_y} C 19.6,5.4 13,10.6 10.8,17.8" if not peak_sharp
           else f"M 22.5,{peak_y} C 20.4,6.6 13.6,11 10.8,17.8")
    right = ("C 31.4,10.6 25.4,5.4 22.5,{y} Z" if not peak_sharp else "C 31.4,11 24.6,6.6 22.5,{y} Z").format(y=peak_y)
    return (top + " C 9.8,21.6 10.2,26.4 11.2,30 L 12.6,34.6 L 15.6,31 L 18,28 L 18,20.6 "
            "C 18,16.4 20,14.2 22.5,14.2 C 25,14.2 27,16.4 27,20.6 L 27,28 L 29.4,31 L 32.4,34.6 "
            "L 33.8,30 C 34.8,26.4 35.2,21.6 34.2,17.8 " + right)

INSIDE = ("M 16.2,31 L 17.4,20.2 C 17.6,15.8 20,13.6 22.5,13.6 C 25,13.6 27.4,15.8 27.6,20.2 "
          "L 28.8,31 C 24.8,32.2 20.2,32.2 16.2,31 Z")
HEM = "M 16,28.6 L 16,20.4 C 16,15 19,12.2 22.5,12.2 C 26,12.2 29,15 29,20.4 L 29,28.6"

def seam(peak_y):
    return f"M 22.5,{peak_y + 1} L 22.5,12.6"

HANGING_TIES = "M 12.6,34.6 C 12.4,36.4 12.8,38.2 13.4,39.6 M 32.4,34.6 C 32.6,36.4 32.2,38.2 31.6,39.6"
BOW_TIES = ("M 12.6,34.6 C 15,36.2 18.6,36.6 21.2,36.6 M 32.4,34.6 C 30,36.2 26.4,36.6 23.8,36.6 "
            "M 22.5,36.6 C 20.2,34.4 17.6,34.8 18.4,36.8 C 19,38.4 21.2,37.8 22.5,36.6 "
            "C 24.8,34.4 27.4,34.8 26.6,36.8 C 26,38.4 23.8,37.8 22.5,36.6 "
            "M 21.6,37.2 L 19.8,39.6 M 23.4,37.2 L 25.2,39.6")

def coif(c, dark_inside=True, ties=HANGING_TIES, peak_y=3.6, peak_sharp=False, hem=False):
    s = STYLE[c]
    body = path(s["inside"] if dark_inside else s["fill"], s["line"], INSIDE)
    body += path(s["fill"], s["line"], outer(peak_y, peak_sharp))
    if hem:
        body += path("none", s["detail"], HEM, 1.1)
    body += path("none", s["detail"], seam(peak_y), 1.1)
    if ties:
        body += path("none", s["detail"] if c == "black" else s["line"], ties, 1.4)
    return body

PIECES = {
    "coif_1": lambda c: coif(c),
    "coif_2": lambda c: coif(c, dark_inside=False, hem=True),
    "coif_3": lambda c: coif(c, ties=BOW_TIES),
    "coif_4": lambda c: coif(c, peak_y=2.4, peak_sharp=True),
    "coif_5": lambda c: coif(c, ties=None),
}
for name, f in PIECES.items():
    for c in ("white", "black"):
        open(os.path.join(OUT, f"{c}_{name}.svg"), "w").write(svg(f(c)))
print("ok")
