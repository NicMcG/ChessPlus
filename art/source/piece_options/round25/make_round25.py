"""Round 25 art options: the Grunt and the Vassal redone (Mac turned down round
24's; the Abatis "cross in the middle" is final), in both colours. Each option
is named by a code (G1.., W1.. for the Grunt without its helmet, V1..) that
the contact sheet labels. Run from this folder:  python make_round25.py
then  godot --headless --path . -s res://tools/render_options.gd -- <this folder> <sheet.png> 3 110

Cburnett style: 45x45 canvas, 1.5 outline. White pieces: white fill, black
lines. Black pieces: black fill, white detail lines (as Chess_pdt45 etc.).
Parts: ("shape", d) a filled outlined shape; ("line", d, width) a detail
line (black on white, white on black); ("edge", d, width) a line drawn only
on the black piece, where two black shapes meet; ("cut", d) an opening: a
white shape on the white piece, a white outline on the black one.
"""

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45">'
PAWN = ('m 22.5,9 c -2.21,0 -4,1.79 -4,4 0,0.89 0.29,1.71 0.78,2.38 C 17.33,16.5 16,18.59 16,21 '
        'c 0,2.03 0.94,3.84 2.41,5.03 C 15.41,27.09 11,31.58 11,39.5 H 34 C 34,31.58 29.59,27.09 26.59,26.03 '
        '28.06,24.84 29,23.03 29,21 29,18.59 27.67,16.5 25.72,15.38 26.21,14.71 26.5,13.89 26.5,13 c 0,-2.21 -1.79,-4 -4,-4 z')


def mirror_d(d):
    """Mirror a path left-right (only absolute commands with x,y pairs and C/L/M/Z/A are used here)."""
    import re
    out = []
    for token in re.findall(r"[A-Za-z]|-?\d+\.?\d*", d):
        out.append(token)
    # Simpler: wrap in a transform group instead.
    return None


def render(parts, team):
    black = team == "black"
    fill, stroke = ("#000", "#000") if black else ("#fff", "#000")
    body = ['<g stroke="%s" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="%s">' % (stroke, fill)]
    for part in parts:
        kind, d = part[0], part[1]
        w = part[2] if len(part) > 2 else 1.5
        if kind == "shape":
            body.append('<path d="%s"/>' % d)
        elif kind == "mirror":   # a shape drawn twice, the second mirrored
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
    return HEAD + "".join(body) + "</svg>\n"


OPTIONS = {}

# --- Grunt: a helmeted pawn. --------------------------------------------------------
# G1: a great helm (a bucket over the whole head) with an eye slit.
OPTIONS["G1_great_helm"] = [("shape", PAWN),
    ("shape", "M 16.3,16.8 L 16.3,8.6 C 16.3,5.2 28.7,5.2 28.7,8.6 L 28.7,16.8 Z"),
    ("line", "M 18.3,11.3 L 26.7,11.3", 1.7), ("line", "M 22.5,12.6 L 22.5,16", 1.2),
    ("edge", "M 16.3,16.8 L 28.7,16.8", 1.2)]
# G2: a kettle hat with a wide round brim.
OPTIONS["G2_kettle_wide"] = [("shape", PAWN),
    ("shape", "M 17,12.2 C 17,7.6 19.5,5.6 22.5,5.6 C 25.5,5.6 28,7.6 28,12.2 Z"),
    ("shape", "M 12.8,12.4 A 9.7,2.4 0 1 0 32.2,12.4 A 9.7,2.4 0 1 0 12.8,12.4 Z"),
    ("edge", "M 12.8,12.4 A 9.7,2.4 0 1 0 32.2,12.4 A 9.7,2.4 0 1 0 12.8,12.4 Z", 1.2)]
# G3: a tall conical helm with a nose bar and a chin strap.
OPTIONS["G3_conical"] = [("shape", PAWN),
    ("shape", "M 16.8,14 C 16.8,8 20,4 22.5,2.5 C 25,4 28.2,8 28.2,14 Z"),
    ("line", "M 16.8,14 L 28.2,14", 2), ("line", "M 22.5,14.6 L 22.5,17.6", 2.2),
    ("line", "M 17.6,14.6 C 19,18.6 26,18.6 27.4,14.6", 1.2)]
# G4: a barbute: the helm reaches the collar, the face shows through a T opening.
OPTIONS["G4_barbute"] = [("shape", PAWN),
    ("shape", "M 16.3,16.8 L 16.3,12 C 16.3,7.5 19,5.5 22.5,5.5 C 26,5.5 28.7,7.5 28.7,12 L 28.7,16.8 Z"),
    ("cut", "M 19.3,10.2 L 25.7,10.2 L 24.6,12.6 L 23.7,12.6 L 23.7,16.8 L 21.3,16.8 L 21.3,12.6 L 20.4,12.6 Z")]
# G5: a morion: a dome with a spike on top and a swept brim.
OPTIONS["G5_spiked"] = [("shape", PAWN),
    ("shape", "M 16.5,13 C 16.5,8 19.5,6 22.5,6 C 25.5,6 28.5,8 28.5,13 Z"),
    ("shape", "M 21.5,6.6 L 22.5,1.4 L 23.5,6.6 Z"),
    ("shape", "M 13.2,13.3 C 15,11.3 30,11.3 31.8,13.3 C 30,15.2 15,15.2 13.2,13.3 Z"),
    ("edge", "M 13.2,13.3 C 15,11.3 30,11.3 31.8,13.3 C 30,15.2 15,15.2 13.2,13.3 Z", 1.2)]
# G6: a dome with a ridge crest front to back and a short brim.
OPTIONS["G6_crested"] = [("shape", PAWN),
    ("shape", "M 16.3,13.2 C 16.3,8.4 19,6.2 22.5,6.2 C 26,6.2 28.7,8.4 28.7,13.2 Z"),
    ("shape", "M 21.4,9.2 C 21.2,6.4 21.6,4.2 22.5,2.6 C 23.4,4.2 23.8,6.4 23.6,9.2 Z"),
    ("line", "M 14.5,13.3 L 30.5,13.3", 2.4), ("edge", "M 14.5,13.3 L 30.5,13.3", 1.2)]
# Without the helmet (shield broken): plain, a neck band, or a bandage round the head.
OPTIONS["W1_plain"] = [("shape", PAWN)]
OPTIONS["W2_neck_band"] = [("shape", PAWN), ("line", "M 17.6,16.4 C 19.2,17.9 25.8,17.9 27.4,16.4", 1.8)]
OPTIONS["W3_bandage"] = [("shape", PAWN),
    ("line", "M 18.7,11.2 C 20.5,10 24.5,10 26.3,11.2", 1.3), ("line", "M 18.6,13.2 C 20.5,12 24.5,12 26.4,13.2", 1.3)]

# --- Vassal: the pawn in a cloak. ------------------------------------------------------
COLLAR = ("line", "M 17.8,17.6 C 19.6,15.9 25.4,15.9 27.2,17.6", 1.3)
CAPE_SHORT = ("shape", "M 22.5,16 C 17.6,16.4 14.6,20.4 14,26.2 L 31,26.2 C 30.4,20.4 27.4,16.4 22.5,16 Z")
# V1: hood down behind the neck, a short cape over the shoulders, the base showing.
OPTIONS["V1_hood_down"] = [("shape", "M 16.6,16.6 C 15,13.2 30,13.2 28.4,16.6 Z"), ("shape", PAWN), CAPE_SHORT, COLLAR,
    ("edge", "M 14,26.2 L 31,26.2", 1.2)]
# V2: two cloak panels down the sides, a clasp at the throat, the body between.
PANEL = "M 18.6,16.6 C 15,18.2 13,24 12,39.5 L 17.6,39.5 C 17.2,30 17.6,23 19.6,19 Z"
OPTIONS["V2_panels_clasp"] = [("shape", PAWN), ("mirror", PANEL),
    ("shape", "M 22.5,15.9 A 1.4,1.4 0 1 0 22.5,18.7 A 1.4,1.4 0 1 0 22.5,15.9 Z"),
    ("edge", PANEL, 1.0), ("edge", "M 26.4,16.6 C 30,18.2 32,24 33,39.5 L 27.4,39.5 C 27.8,30 27.4,23 25.4,19 Z", 1.0)]
# V3: hood up, the face in the opening, a short cape.
COWL = "M 22.5,5 C 17,5 15.2,10 16,14.5 C 16.4,16.5 17.4,17.6 18.6,18.2 L 26.4,18.2 C 27.6,17.6 28.6,16.5 29,14.5 C 29.8,10 28,5 22.5,5 Z"
FACE = "M 22.5,9.4 A 3.6,3.6 0 1 0 22.5,16.6 A 3.6,3.6 0 1 0 22.5,9.4 Z"
OPTIONS["V3_hood_up"] = [("shape", PAWN), CAPE_SHORT, ("shape", COWL), ("cut", FACE), ("edge", "M 14,26.2 L 31,26.2", 1.2)]
# V4: a cape swept to one side, the body showing.
OPTIONS["V4_cape_side"] = [("shape", PAWN),
    ("shape", "M 22.5,16 C 26.2,16 30.4,19 34,26 C 36,30 36.6,35 35.2,39.5 L 27.2,39.5 C 27.8,32 26.4,24 23,19 Z"),
    COLLAR, ("edge", "M 27.2,39.5 C 27.8,32 26.4,24 23,19", 1.0)]
# V5: a short mantle with a scalloped hem.
OPTIONS["V5_mantle"] = [("shape", PAWN),
    ("shape", "M 22.5,15.6 C 17,16.2 14,19.4 13.4,24.4 L 15.9,22.6 L 18.3,24.8 L 20.6,22.6 L 22.5,24.8 L 24.4,22.6 L 26.7,24.8 L 29.1,22.6 L 31.6,24.4 C 31,19.4 28,16.2 22.5,15.6 Z"),
    COLLAR, ("edge", "M 13.4,24.4 L 15.9,22.6 L 18.3,24.8 L 20.6,22.6 L 22.5,24.8 L 24.4,22.6 L 26.7,24.8 L 29.1,22.6 L 31.6,24.4", 1.0)]
# V6: hood up and the cloak closed to the ground, with folds.
OPTIONS["V6_hooded_cloak"] = [("shape", PAWN),
    ("shape", "M 18.6,18.2 C 15.4,21 13,28 11,39.5 L 34,39.5 C 32,28 29.6,21 26.4,18.2 Z"),
    ("shape", COWL), ("cut", FACE),
    ("line", "M 17.6,22.5 C 15.8,28 14.8,33.5 14.2,39.5 M 27.4,22.5 C 29.2,28 30.2,33.5 30.8,39.5", 1.1)]

for name, parts in OPTIONS.items():
    for team in ("white", "black"):
        with open("%s_%s.svg" % (team, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(render(parts, team))
print("wrote %d options x 2 colours" % len(OPTIONS))
