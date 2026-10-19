"""Final Cannon: round 5's cannon (barrel pointing left on its wheel, trail
behind, 15% bigger), with the Chariot's wheel (Mac, Oct 2026): a rim ring,
eight spokes and a hub. White and black, written to ../pieces/.

Run from this folder:  python make_final_cannon.py
"""
import io
import math
import os

HERE = os.path.dirname(os.path.abspath(__file__))
SCALE = 1.15
W = 1.5 / SCALE  # so outlines still come out 1.5 thick after scaling


def colours(team):
    return ("#fff", "#000") if team == "white" else ("#000", "#fff")


def shape(d, fill):
    return '<path fill="%s" stroke="#000" stroke-width="%.3f" d="%s"/>' % (fill, W, d)


def wheel(cx, cy, r, fill, line):
    """The Chariot's wheel (make_final_wizard_berserker_chariot.py), sized to fit."""
    k = r / 9.5
    rim = 2.6 * k
    out = '<circle cx="%s" cy="%s" r="%s" fill="%s" stroke="#000" stroke-width="%.3f"/>' % (cx, cy, r, fill, W)
    out += '<circle cx="%s" cy="%s" r="%.3f" fill="none" stroke="%s" stroke-width="%.3f"/>' % (cx, cy, r - rim, line, 1.2 / SCALE)
    spokes = []
    for i in range(8):
        a = math.pi * 2 * i / 8 + math.pi / 8
        spokes.append("M %.2f,%.2f L %.2f,%.2f" % (cx + 2 * k * math.cos(a), cy + 2 * k * math.sin(a),
                                                   cx + (r - rim) * math.cos(a), cy + (r - rim) * math.sin(a)))
    out += '<path fill="none" stroke="%s" stroke-width="%.3f" d="%s"/>' % (line, 1.6 * k / SCALE, " ".join(spokes))
    out += '<circle cx="%s" cy="%s" r="%.3f" fill="%s" stroke="%s" stroke-width="%.3f"/>' % (
        cx, cy, 2 * k, fill, line if fill == "#000" else "#000", 1.2 / SCALE)
    return out


def cannon(team):
    fill, line = colours(team)
    out = '<g transform="translate(22.5 39.5) scale(%s) translate(-22.5 -39.5) translate(0 3.5)">' % SCALE
    out += shape("M 26,28 L 37,34 L 37,36 L 27,36 Z", fill)
    out += shape("M 9,17.6 L 31.5,15.4 C 35.5,15 35.5,28.6 31.5,28.2 L 9,26 Z", fill)
    out += shape("M 5.5,16.6 C 5.5,15.8 9.5,15.8 9.5,16.6 L 9.5,27 C 9.5,27.8 5.5,27.8 5.5,27 Z", fill)
    out += shape("M 35,19.6 C 39.6,18.6 39.6,25 35,24", fill)
    if team == "black":
        out += '<path fill="none" stroke="#fff" stroke-width="%.3f" d="M 9.5,17.4 L 9.5,26.2 M 34.6,19.8 L 34.6,23.8"/>' % (1.2 / SCALE)
    out += wheel(21, 27.7, 8.2, fill, line)
    return out + "</g>"


HEAD = ('<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'
        '<g stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">')
TAIL = "</g></svg>\n"

if __name__ == "__main__":
    for team in ("white", "black"):
        path = os.path.join(HERE, "..", "pieces", "%s_cannon.svg" % team)
        io.open(path, "w", encoding="utf-8", newline="\n").write(HEAD + cannon(team) + TAIL)
    print("wrote 2 files")
