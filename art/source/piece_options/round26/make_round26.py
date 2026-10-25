"""Round 26 art options (Mac, 25 Oct 2026): the Grunt and the Vassal needn't
look like pawns. Grunt = something with a defence that visibly breaks (each
option G<n> comes with its broken look G<n>W, shown once the shield breaks).
Vassal = something vaguely elegant. Also A1: the final Abatis shortened to the
pawn's height, without the white edge on the black piece. Both colours. Run
from this folder:  python make_round26.py  then tools/render_options.gd.

Parts: ("shape", d) filled outlined shape; ("mirror", d) that shape and its
left-right mirror; ("line", d, w) a detail line (black on white, white on
black); ("edge", d, w) a line only on the black piece; ("cut", d) an opening
(white shape on the white piece, white outline on the black one).
"""
import math

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
    return HEAD + "".join(body) + "</svg>\n"


def stake(x0, y0, x1, y1, w, sharp=0.22):
    dx, dy = x1 - x0, y1 - y0
    length = math.hypot(dx, dy)
    ux, uy = dx / length, dy / length
    px, py = -uy, ux
    sx, sy = x0 + dx * (1 - sharp), y0 + dy * (1 - sharp)
    pts = [(x0 + px * w / 2, y0 + py * w / 2), (sx + px * w / 2, sy + py * w / 2), (x1, y1),
           (sx - px * w / 2, sy - py * w / 2), (x0 - px * w / 2, y0 - py * w / 2)]
    return "M %s Z" % " L ".join("%.2f,%.2f" % p for p in pts)


OPTIONS = {}

# --- Abatis, final shape at the pawn's height (top y 9), no white edge. --------------
OPTIONS["A1_abatis_final"] = [("shape", stake(9.5, 39.5, 31.5, 9, 5)), ("shape", stake(35.5, 39.5, 13.5, 9, 5))]

# --- Grunt: a defence that breaks. ----------------------------------------------------
FOOT = ("shape", "M 15,39.5 C 15,36.4 18,34.8 22.5,34.8 C 27,34.8 30,36.4 30,39.5 Z")
# G1: a kite shield standing on a small foot; broken: a crack down it.
KITE = "M 22.5,5 C 29,5 33,8 33,13 C 33,22 28,30 22.5,36.5 C 17,30 12,22 12,13 C 12,8 16,5 22.5,5 Z"
OPTIONS["G1_kite_shield"] = [FOOT, ("shape", KITE), ("line", "M 22.5,8.5 L 22.5,32", 1.6)]
OPTIONS["G1W_kite_cracked"] = [FOOT, ("shape", KITE), ("line", "M 19.5,7 L 24,14 L 20,20 L 25,27 L 22,32", 1.7),
    ("line", "M 24,14 L 28,12 M 20,20 L 16.5,22.5", 1.2)]
# G2: a round shield with a boss and rim; broken: cracked across.
ROUND = "M 22.5,5 A 13,13 0 1 0 22.5,31 A 13,13 0 1 0 22.5,5 Z"
OPTIONS["G2_round_shield"] = [FOOT, ("shape", ROUND), ("line", "M 22.5,8 A 10,10 0 1 0 22.5,28 A 10,10 0 1 0 22.5,8 Z", 1.2),
    ("shape", "M 22.5,14 A 4,4 0 1 0 22.5,22 A 4,4 0 1 0 22.5,14 Z"), ("edge", "M 22.5,14 A 4,4 0 1 0 22.5,22 A 4,4 0 1 0 22.5,14 Z", 1.1)]
OPTIONS["G2W_round_cracked"] = [FOOT, ("shape", ROUND), ("shape", "M 22.5,14 A 4,4 0 1 0 22.5,22 A 4,4 0 1 0 22.5,14 Z"),
    ("edge", "M 22.5,14 A 4,4 0 1 0 22.5,22 A 4,4 0 1 0 22.5,14 Z", 1.1),
    ("line", "M 12,12 L 18,16 L 16,21 M 33,26 L 27.5,21.5 L 29,16.5 L 33.5,14", 1.7)]
# G3: a great helm on a stand; broken: dented and cracked.
HELM = "M 13,26 L 13,9.5 C 13,4 32,4 32,9.5 L 32,26 Z"
STAND = ("shape", "M 15,39.5 C 15,33 17,29.5 19,26 L 26,26 C 28,29.5 30,33 30,39.5 Z")
OPTIONS["G3_great_helm"] = [STAND, ("shape", HELM), ("line", "M 15.5,14 L 29.5,14", 2), ("line", "M 22.5,16.5 L 22.5,26", 1.5),
    ("line", "M 17,20 L 17,21.5 M 20,20 L 20,21.5 M 25,20 L 25,21.5 M 28,20 L 28,21.5", 1.2), ("edge", "M 13,26 L 32,26", 1.2)]
OPTIONS["G3W_helm_cracked"] = [STAND, ("shape", "M 13,26 L 13,9.5 C 13,6 18,4.5 21,5.5 L 24,10 L 26.5,5 C 30,5.5 32,7 32,9.5 L 32,26 Z"),
    ("line", "M 15.5,14 L 29.5,14", 2), ("line", "M 22.5,16.5 L 22.5,26", 1.5), ("line", "M 24,10 L 22,18 L 25.5,24", 1.6), ("edge", "M 13,26 L 32,26", 1.2)]
# G4: a heater shield with a chevron; broken: the top corner gone and a crack.
HEATER = "M 11,7 L 34,7 L 34,18 C 34,27 29,33 22.5,37 C 16,33 11,27 11,18 Z"
OPTIONS["G4_heater_shield"] = [FOOT, ("shape", HEATER), ("line", "M 14,21 L 22.5,13 L 31,21", 2.2)]
OPTIONS["G4W_heater_broken"] = [FOOT, ("shape", "M 11,7 L 26,7 L 28,11.5 L 31.5,9 L 34,12 L 34,18 C 34,27 29,33 22.5,37 C 16,33 11,27 11,18 Z"),
    ("line", "M 14,21 L 22.5,13 L 31,21", 2.2), ("line", "M 28,11.5 L 25,19 L 27.5,25 L 24,31", 1.7)]
# G5: a pavise (tall shield with a ridge); broken: split top, a chunk out of the side.
OPTIONS["G5_pavise"] = [FOOT, ("shape", "M 12.5,6 L 32.5,6 L 32.5,34 C 32.5,36.5 12.5,36.5 12.5,34 Z"),
    ("shape", "M 20,6 L 25,6 L 25,34.5 L 20,34.5 Z"), ("edge", "M 20,6 L 20,34.5 M 25,6 L 25,34.5", 1.1)]
OPTIONS["G5W_pavise_broken"] = [FOOT, ("shape", "M 12.5,6 L 20,6 L 22.5,11 L 25,6 L 32.5,6 L 32.5,20 L 29.5,23 L 32.5,26 L 32.5,34 C 32.5,36.5 12.5,36.5 12.5,34 Z"),
    ("line", "M 22.5,11 L 21,20 L 23.5,28 L 22,34", 1.7)]
# G6: a spangenhelm (banded cone helm with cheek guards) on a stand; broken: a band torn, a crack.
CONE = "M 13.5,23 C 13.5,11 18,5.5 22.5,4 C 27,5.5 31.5,11 31.5,23 Z"
GUARD = "M 14,23 C 13.5,27 15,30 18.5,31 L 20,23 Z"
OPTIONS["G6_banded_helm"] = [STAND, ("shape", CONE), ("mirror", GUARD), ("line", "M 22.5,4.5 L 22.5,23", 1.6),
    ("line", "M 14.5,16 C 18,13 27,13 30.5,16", 1.6), ("edge", "M 13.5,23 L 31.5,23", 1.2)]
OPTIONS["G6W_banded_cracked"] = [STAND, ("shape", "M 13.5,23 C 13.5,11 18,5.5 22.5,4 C 24,6 24,8 26,9 C 28.5,12 31.5,15 31.5,23 Z"),
    ("mirror", GUARD), ("line", "M 22.5,4.5 L 22.5,23", 1.6), ("line", "M 14.5,16 C 18,13 24,13 26,14", 1.6),
    ("line", "M 26,9 L 24.5,15 L 27.5,20", 1.7), ("edge", "M 13.5,23 L 31.5,23", 1.2)]

# --- Vassal: vaguely elegant. -----------------------------------------------------------
# V1: a fleur-de-lis.
OPTIONS["V1_fleur_de_lis"] = [
    ("shape", "M 22.5,4 C 26,9 26.5,16.5 22.5,22.5 C 18.5,16.5 19,9 22.5,4 Z"),
    ("mirror", "M 21.5,21.5 C 15.5,21.5 10.5,17.5 9.5,12 C 12.5,14.5 17.5,15.5 21.5,19.5 Z"),
    ("shape", "M 17,21.5 L 28,21.5 L 27.3,25.5 L 17.7,25.5 Z"),
    ("shape", "M 22.5,25.5 C 24.8,29.5 24.8,34.5 22.5,38.5 C 20.2,34.5 20.2,29.5 22.5,25.5 Z"),
    ("mirror", "M 20.8,25.5 C 15,27.5 11,32 11.5,38 C 14,34.5 17.5,31.5 21.2,28.5 Z")]
# V2: a chalice.
OPTIONS["V2_chalice"] = [("shape", "M 12,39.5 C 12,35.5 17,33.2 22.5,33.2 C 28,33.2 33,35.5 33,39.5 Z"),
    ("shape", "M 21,22.5 L 24,22.5 L 24,33.2 L 21,33.2 Z"), ("edge", "M 21,33.2 L 24,33.2", 1.1),
    ("shape", "M 13,7 L 32,7 C 32,16.5 28,22 22.5,23 C 17,22 13,16.5 13,7 Z"),
    ("line", "M 15,12 C 18,14 27,14 30,12", 1.2), ("edge", "M 13,7 L 32,7", 1.2)]
# V3: a plume (a single feather) on a small stand.
OPTIONS["V3_plume"] = [("shape", "M 16,39.5 C 16,36.5 19,35 22.5,35 C 26,35 29,36.5 29,39.5 Z"),
    ("shape", "M 19.5,35 C 14.5,25 15.5,11 24.5,3 C 31.5,11 30.5,25 25.5,35 Z"),
    ("line", "M 22.5,34.5 C 21.5,24 22,13 24.5,4.5", 1.3),
    ("line", "M 22,26 C 19,24 18,21 18,18 M 22,19 C 20,17 19.5,14.5 20,12 M 23,27 C 26,25 27.5,22 27.5,19 M 23.5,19 C 26,17 27,14 26.8,11", 1.1)]
# V4: a scroll with a hanging seal.
OPTIONS["V4_scroll_seal"] = [("shape", "M 13,11 L 32,11 L 32,30 L 13,30 Z"),
    ("shape", "M 11.5,11 A 11,3 0 1 0 33.5,11 A 11,3 0 1 0 11.5,11 Z"),
    ("shape", "M 11.5,30 A 11,3 0 1 0 33.5,30 A 11,3 0 1 0 11.5,30 Z"),
    ("line", "M 17,16.5 L 28,16.5 M 17,20.5 L 28,20.5 M 17,24.5 L 25,24.5", 1.2),
    ("line", "M 27.5,32.5 L 27.5,35", 1.3), ("shape", "M 27.5,34.5 A 3,3 0 1 0 27.5,40.5 A 3,3 0 1 0 27.5,34.5 Z"),
    ("edge", "M 11.5,11 A 11,3 0 1 0 33.5,11 A 11,3 0 1 0 11.5,11 Z M 11.5,30 A 11,3 0 1 0 33.5,30 A 11,3 0 1 0 11.5,30 Z", 1.1)]
# V5: a slender urn.
OPTIONS["V5_urn"] = [("shape", "M 13.5,39.5 C 13.5,37.3 17.5,36 22.5,36 C 27.5,36 31.5,37.3 31.5,39.5 Z"),
    ("shape", "M 18.5,5 L 26.5,5 L 25.5,9 C 30.5,12 31.5,20 28.5,30 C 27.5,33 26.5,35 26.5,36.5 L 18.5,36.5 C 18.5,35 17.5,33 16.5,30 C 13.5,20 14.5,12 19.5,9 Z"),
    ("line", "M 16.5,12 C 12,12.5 11,18 14,21 M 28.5,12 C 33,12.5 34,18 31,21", 1.5),
    ("line", "M 18.5,9 L 26.5,9", 1.2), ("edge", "M 18.5,5 L 26.5,5 M 18.5,36.5 L 26.5,36.5", 1.1)]
# V6: a plumed cap on a stand.
OPTIONS["V6_plumed_cap"] = [("shape", "M 14,39.5 C 14,33 17,29 19,28 L 26,28 C 28,29 31,33 31,39.5 Z"),
    ("shape", "M 24,11.5 C 28,5.5 35,3.5 41.5,4.5 C 36.5,7 32.5,10.5 29.5,14 Z"),
    ("line", "M 26.5,11.5 C 30,8 34,6 38.5,5.5", 1.1),
    ("shape", "M 12,24.5 C 12,14.5 18,10.5 24,10.5 C 31,10.5 34,15.5 33,24.5 Z"),
    ("shape", "M 10.5,24.5 L 34.5,24.5 L 34,28.5 L 11,28.5 Z"), ("edge", "M 10.5,24.5 L 34.5,24.5", 1.1)]

for name, parts in OPTIONS.items():
    for team in ("white", "black"):
        with open("%s_%s.svg" % (team, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(render(parts, team))
print("wrote %d options x 2 colours" % len(OPTIONS))
