"""Round 28 (Mac, 25 Oct 2026): the Vassal kneeling on both knees (round 27's
V3) drawn as one silhouette, without the lines between head, body and legs;
the Grunt as round 26's G3 (a great helm on a stand) without the four dots
under the visor and with a wider, sturdier base, plus two looks for it once
the shield breaks (the helm gone): the stand alone, or a bare head on the
stand. Both colours. Run from this folder:  python make_round28.py  then
tools/render_options.gd.

Part kinds as round 26 (shape, mirror, line, edge, cut) plus ("union",
[d, ...]): the shapes drawn as one silhouette: a thick outline pass under a
fill pass, so only the outer edge shows.
"""

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'


def render(parts, team):
    black = team == "black"
    fill = "#000" if black else "#fff"
    body = ['<g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="%s">' % fill]
    for part in parts:
        kind, d = part[0], part[1]
        w = part[2] if len(part) > 2 else 1.5
        if kind == "shape":
            body.append('<path d="%s"/>' % d)
        elif kind == "union":
            for sub in d:
                body.append('<path d="%s" stroke-width="3"/>' % sub)
            for sub in d:
                body.append('<path d="%s" stroke="none"/>' % sub)
        elif kind == "mirror":
            body.append('<path d="%s"/>' % d)
            body.append('<g transform="translate(45,0) scale(-1,1)"><path d="%s"/></g>' % d)
        elif kind == "line":
            body.append('<path d="%s" fill="none" stroke="%s" stroke-width="%s"/>' % (d, "#fff" if black else "#000", w))
        elif kind == "edge":
            if black:
                body.append('<path d="%s" fill="none" stroke="#fff" stroke-width="%s"/>' % (d, w))
        elif kind == "cut":
            if black:
                body.append('<path d="%s" fill="none" stroke="#fff" stroke-width="1.2"/>' % d)
            else:
                body.append('<path d="%s"/>' % d)
    body.append("</g>")
    return HEAD + "".join(body) + "</svg>" + "\n"


OPTIONS = {}

# --- Vassal: on both knees, one silhouette. ----------------------------------------
LEGS = "M 9,39.5 L 9,34 C 9,31.5 11,30 13.5,30 L 34,30 C 36,30 37,31.5 37,34 L 37,39.5 Z"
TORSO = "M 15,30 C 14,22 18,14 25,13 C 31,13 35,20 34,30 Z"
HEAD_C = "M 18.5,5.5 A 5,5 0 1 0 18.5,15.5 A 5,5 0 1 0 18.5,5.5 Z"
OPTIONS["V3_both_knees_solid"] = [("union", [LEGS, TORSO, HEAD_C])]

# --- Grunt: a great helm on a wide stand (round 26's G3 without the dots). -------------
STAND = "M 10.5,39.5 C 10.5,34 14.5,29.5 18.5,26 L 26.5,26 C 30.5,29.5 34.5,34 34.5,39.5 Z"
HELM = "M 13,26 L 13,9.5 C 13,4 32,4 32,9.5 L 32,26 Z"
OPTIONS["G3_great_helm"] = [("shape", STAND), ("shape", HELM), ("line", "M 15.5,14 L 29.5,14", 2),
    ("line", "M 22.5,16.5 L 22.5,26", 1.5), ("edge", "M 13,26 L 32,26", 1.2)]
# Broken: the helm gone, the stand alone...
OPTIONS["G3W_stand_only"] = [("shape", STAND)]
# ...or a bare head on the stand.
OPTIONS["G3X_bare_head"] = [("shape", STAND), ("shape", "M 19.5,26 L 19.5,21 L 25.5,21 L 25.5,26 Z"),
    ("shape", "M 22.5,8 A 7,7 0 1 0 22.5,22 A 7,7 0 1 0 22.5,8 Z"), ("edge", "M 19.5,26 L 25.5,26", 1.1)]

for name, parts in OPTIONS.items():
    for team in ("white", "black"):
        with open("%s_%s.svg" % (team, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(render(parts, team))
print("wrote %d options x 2 colours" % len(OPTIONS))
