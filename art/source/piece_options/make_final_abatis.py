"""The Abatis's final art (Mac picked round 24's "cross in the middle", 25 Oct
2026, then: pawn height, no white edge on the black piece): two sharpened
stakes crossing in the middle, single colour like the Pawn, the tips at the
pawn's head height (y 9). Writes art/source/pieces/white_abatis.svg and
black_abatis.svg; render them with tools/render_piece_svg.gd. Run from this
folder:
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


BACK = stake(9.5, 39.5, 31.5, 9, 5)
FRONT = stake(35.5, 39.5, 13.5, 9, 5)


def svg(team):
    fill = "#000" if team == "black" else "#fff"
    return (HEAD + '<g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="%s">' % fill
            + '<path d="%s"/><path d="%s"/></g></svg>\n' % (BACK, FRONT))


here = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(here, "..", "pieces")
for team in ("white", "black"):
    with open(os.path.join(out, "%s_abatis.svg" % team), "w", encoding="utf-8", newline="\n") as f:
        f.write(svg(team))
print("wrote white_abatis.svg and black_abatis.svg")
