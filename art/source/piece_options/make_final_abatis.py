"""The Abatis's final art (Mac picked round 24's "cross in the middle", 25 Oct
2026): two sharpened stakes crossing in the middle, single colour like the
Pawn. Writes art/source/pieces/white_abatis.svg and black_abatis.svg; render
them with tools/render_piece_svg.gd. Run from this folder:
    python make_final_abatis.py
"""
import math
import os

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'


def stake(x0, y0, x1, y1, w, sharp=0.22):
    """A stake from (x0,y0) to the point (x1,y1), w wide, sharpened over the last part."""
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy)
    ux, uy = dx / length, dy / length
    px, py = -uy, ux
    sx, sy = x0 + dx * (1 - sharp), y0 + dy * (1 - sharp)
    pts = [(x0 + px * w / 2, y0 + py * w / 2), (sx + px * w / 2, sy + py * w / 2), (x1, y1),
           (sx - px * w / 2, sy - py * w / 2), (x0 - px * w / 2, y0 - py * w / 2)]
    return "M %s Z" % " L ".join("%.2f,%.2f" % p for p in pts)


BACK = stake(8, 39.5, 33, 5.5, 5)
FRONT = stake(37, 39.5, 12, 5.5, 5)


def svg(team):
    black = team == "black"
    fill = "#000" if black else "#fff"
    parts = ['<g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="%s">' % fill,
             '<path d="%s"/>' % BACK, '<path d="%s"/>' % FRONT]
    if black:
        # The front stake's outline in white, so the crossing shows on the black piece.
        parts.append('<path d="%s" fill="none" stroke="#fff" stroke-width="1.1"/>' % FRONT)
    parts.append("</g>")
    return HEAD + "".join(parts) + "</svg>\n"


here = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(here, "..", "pieces")
for team in ("white", "black"):
    with open(os.path.join(out, "%s_abatis.svg" % team), "w", encoding="utf-8", newline="\n") as f:
        f.write(svg(team))
print("wrote white_abatis.svg and black_abatis.svg")
