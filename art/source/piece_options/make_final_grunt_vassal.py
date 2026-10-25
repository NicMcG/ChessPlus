"""Final art for the Grunt and the Vassal (Mac, 25 Oct 2026, rounds 26-28).
Grunt: a great helm on a wide stand (round 26's G3: eye slit and a bar, no
dots, no white line between helm and stand on the black piece), scaled to
the Pawn's height (Mac: smaller). Grunt with
its shield broken (`_wounded`): the helm gone, a bare head on the stand, one
silhouette with no dividing lines. Vassal: kneeling on both knees, head bowed,
one silhouette, scaled to the Pawn's height (top at y 9). Both colours.
Writes art/source/pieces/<team>_grunt.svg, <team>_grunt_wounded.svg and
<team>_vassal.svg; render with tools/render_piece_svg.gd. Run from this folder:
    python make_final_grunt_vassal.py
"""
import os

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'


def group(team, inner, transform="", stroke_width=1.5):
    fill = "#000" if team == "black" else "#fff"
    attrs = 'stroke="#000" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" fill="%s"' % (stroke_width, fill)
    if transform:
        attrs += ' transform="%s"' % transform
    return HEAD + "<g %s>%s</g></svg>\n" % (attrs, inner)


def union(shapes, stroke_width=3):
    """Shapes drawn as one silhouette: a thick outline pass under a fill pass."""
    return ("".join('<path d="%s" stroke-width="%s"/>' % (d, stroke_width) for d in shapes)
            + "".join('<path d="%s" stroke="none"/>' % d for d in shapes))


def line(team, d, w):
    return '<path d="%s" fill="none" stroke="%s" stroke-width="%s"/>' % (d, "#fff" if team == "black" else "#000", w)


# --- Grunt -----------------------------------------------------------------
STAND = "M 10.5,39.5 C 10.5,34 14.5,29.5 18.5,26 L 26.5,26 C 30.5,29.5 34.5,34 34.5,39.5 Z"
HELM = "M 13,26 L 13,9.5 C 13,4 32,4 32,9.5 L 32,26 Z"
NECK = "M 19.5,26 L 19.5,21 L 25.5,21 L 25.5,26 Z"
BARE_HEAD = "M 22.5,8 A 7,7 0 1 0 22.5,22 A 7,7 0 1 0 22.5,8 Z"


# Drawn 35.5 high (y 4..39.5); shown at the Pawn's height (Mac: smaller), scaled about the bottom.
GRUNT_SCALE = 30.5 / 35.5
GRUNT_TRANSFORM = "translate(22.5,39.5) scale(%.4f) translate(-22.5,-39.5)" % GRUNT_SCALE


def grunt(team):
    return group(team, '<path d="%s"/><path d="%s"/>' % (STAND, HELM)
                 + line(team, "M 15.5,14 L 29.5,14", 2 / GRUNT_SCALE) + line(team, "M 22.5,16.5 L 22.5,26", 1.5 / GRUNT_SCALE),
                 GRUNT_TRANSFORM, stroke_width=1.5 / GRUNT_SCALE)


def grunt_wounded(team):
    return group(team, union([STAND, NECK, BARE_HEAD], stroke_width=3 / GRUNT_SCALE), GRUNT_TRANSFORM, stroke_width=1.5 / GRUNT_SCALE)


# --- Vassal: kneeling, scaled from a 34-high drawing (y 5.5..39.5) to the pawn's 30.5 ------
LEGS = "M 9,39.5 L 9,34 C 9,31.5 11,30 13.5,30 L 34,30 C 36,30 37,31.5 37,34 L 37,39.5 Z"
TORSO = "M 15,30 C 14,22 18,14 25,13 C 31,13 35,20 34,30 Z"
HEAD_C = "M 18.5,5.5 A 5,5 0 1 0 18.5,15.5 A 5,5 0 1 0 18.5,5.5 Z"
SCALE = 30.5 / 34.0


def vassal(team):
    transform = "translate(22.5,39.5) scale(%.4f) translate(-22.5,-39.5)" % SCALE
    return group(team, union([LEGS, TORSO, HEAD_C], stroke_width=3 / SCALE), transform, stroke_width=1.5 / SCALE)


here = os.path.dirname(os.path.abspath(__file__))
out = os.path.join(here, "..", "pieces")
for team in ("white", "black"):
    for name, make in (("grunt", grunt), ("grunt_wounded", grunt_wounded), ("vassal", vassal)):
        with open(os.path.join(out, "%s_%s.svg" % (team, name)), "w", encoding="utf-8", newline="\n") as f:
            f.write(make(team))
print("wrote the Grunt (and wounded) and Vassal SVGs, both colours")
