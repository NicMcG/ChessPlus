"""Round 27 art options (Mac, 25 Oct 2026). Grunt: a figure with a shield or
helmet; the broken look (G<n>W) is the same figure with it taken away, not
cracked. Vassal: a figure bowing or kneeling, simple, mono colour, Cburnett
style. Both colours. Run from this folder:  python make_round27.py  then
tools/render_options.gd.

Parts: ("shape", d) filled outlined shape; ("mirror", d) that shape and its
left-right mirror; ("line", d, w) a detail line (black on white, white on
black); ("edge", d, w) a line only on the black piece; ("cut", d) an opening
(white shape on the white piece, white outline on the black one).
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

# --- Grunt: a soldier's bust; the shield or helmet goes when the shield breaks. -------------
HEAD_C = "M 22.5,8 A 5.5,5.5 0 1 0 22.5,19 A 5.5,5.5 0 1 0 22.5,8 Z"
NECK = "M 20,18 L 25,18 L 25.5,23 L 19.5,23 Z"
TORSO = "M 9.5,39.5 C 9.5,29.5 14,23 22.5,23 C 31,23 35.5,29.5 35.5,39.5 Z"
BUST = [("shape", TORSO), ("shape", NECK), ("shape", HEAD_C), ("edge", "M 19.5,23 C 20.5,22 24.5,22 25.5,23", 1.1)]
# G1: a round shield held in front of the chest.
ROUND = "M 22.5,22 A 9.5,9.5 0 1 0 22.5,41 A 9.5,9.5 0 1 0 22.5,22 Z"
OPTIONS["G1_round_shield"] = BUST + [("shape", ROUND), ("line", "M 22.5,24.5 A 7,7 0 1 0 22.5,38.5 A 7,7 0 1 0 22.5,24.5 Z", 1.1),
    ("shape", "M 22.5,28.5 A 3,3 0 1 0 22.5,34.5 A 3,3 0 1 0 22.5,28.5 Z"), ("edge", "M 22.5,28.5 A 3,3 0 1 0 22.5,34.5 A 3,3 0 1 0 22.5,28.5 Z", 1.1)]
OPTIONS["G1W_no_shield"] = BUST
# G2: a great helm instead of the bare head.
GREAT_HELM = "M 15.5,20 L 15.5,9 C 15.5,4 29.5,4 29.5,9 L 29.5,20 Z"
OPTIONS["G2_great_helm"] = [("shape", TORSO), ("shape", NECK), ("shape", GREAT_HELM), ("line", "M 17.5,12.5 L 27.5,12.5", 1.8),
    ("line", "M 22.5,14 L 22.5,20", 1.3), ("edge", "M 15.5,20 L 29.5,20", 1.2)]
OPTIONS["G2W_bare_head"] = BUST
# G3: a kite shield held at the side, covering half the bust.
KITE = "M 14,8 C 19.5,8 23,10.5 23,14.5 C 23,22 19,29 14,35.5 C 9,29 5,22 5,14.5 C 5,10.5 8.5,8 14,8 Z"
OPTIONS["G3_kite_shield"] = BUST + [("shape", KITE), ("line", "M 14,11 L 14,31.5", 1.5), ("edge", KITE, 1.0)]
OPTIONS["G3W_no_shield"] = BUST
# G4: a nasal helm with cheek guards over the head.
NASAL = "M 16,17 C 16,9.5 19,5.5 22.5,4.5 C 26,5.5 29,9.5 29,17 Z"
GUARD = "M 16.3,17 C 16,20 17,22 19.5,22.5 L 20.5,17.5 Z"
OPTIONS["G4_nasal_helm"] = BUST + [("shape", NASAL), ("mirror", GUARD), ("line", "M 16,17 L 29,17", 1.8), ("line", "M 22.5,17.5 L 22.5,21.5", 2)]
OPTIONS["G4W_bare_head"] = BUST
# G5: a tall tower shield in front, the head showing above it.
TOWER = "M 13,16 L 32,16 L 32,36 C 32,38.5 13,38.5 13,36 Z"
OPTIONS["G5_tower_shield"] = BUST + [("shape", TOWER), ("line", "M 22.5,19 L 22.5,35", 1.5), ("line", "M 16,24 L 29,24", 1.3), ("edge", "M 13,16 L 32,16", 1.1)]
OPTIONS["G5W_no_shield"] = BUST
# G6: a kettle hat on the head.
OPTIONS["G6_kettle_hat"] = BUST + [("shape", "M 16,12.5 C 16,7.5 19,5 22.5,5 C 26,5 29,7.5 29,12.5 Z"),
    ("shape", "M 11.5,12.8 A 11,2.6 0 1 0 33.5,12.8 A 11,2.6 0 1 0 11.5,12.8 Z"),
    ("edge", "M 11.5,12.8 A 11,2.6 0 1 0 33.5,12.8 A 11,2.6 0 1 0 11.5,12.8 Z", 1.1)]
OPTIONS["G6W_bare_head"] = BUST

# --- Vassal: bowing or kneeling, in profile facing left; bold simple blocks. ---------------
# V1: on one knee, head bowed.
OPTIONS["V1_one_knee"] = [
    ("shape", "M 24,33.5 L 37,33.5 L 37,39.5 L 24,39.5 Z"),                                   # back shin on the ground
    ("shape", "M 10,27 C 10,24.5 11.5,23.5 13.5,23.5 L 26,23.5 L 26,30.5 L 13,30.5 L 13,39.5 L 7,39.5 L 7,30 C 7,28 8,27 10,27 Z"),  # front thigh and shin
    ("shape", "M 20,31 C 18.5,23 20.5,14.5 26,11.5 C 31.5,11.5 33.5,18.5 32.5,31 Z"),          # torso leaning forward
    ("shape", "M 20.5,5.5 A 4.8,4.8 0 1 0 20.5,15.1 A 4.8,4.8 0 1 0 20.5,5.5 Z"),              # bowed head
    ("edge", "M 20,31 L 32.5,31 M 13,30.5 L 26,30.5", 1.1)]
# V2: a deep bow from the waist, standing.
OPTIONS["V2_deep_bow"] = [
    ("shape", "M 25,39.5 L 25,21 L 34,21 L 34,39.5 Z"),                                       # legs
    ("shape", "M 25,22 C 23.5,15.5 18.5,12 11,13 L 11,17.5 C 17,17 21,19.5 22,26 L 34,23.5 L 34,21 Z"),  # torso bent forward
    ("shape", "M 9,15.5 A 4.6,4.6 0 1 0 9,24.7 A 4.6,4.6 0 1 0 9,15.5 Z"),                     # head hanging
    ("shape", "M 16,17.5 C 14,21.5 13.5,25.5 14,29.5 L 17.5,29.5 C 17.5,26 18,22.5 20,19.5 Z"), # arm hanging
    ("edge", "M 25,22 L 34,22", 1.1)]
# V3: kneeling on both knees, sitting on the heels, head bowed.
OPTIONS["V3_both_knees"] = [
    ("shape", "M 9,39.5 L 9,34 C 9,31.5 11,30 13.5,30 L 34,30 C 36,30 37,31.5 37,34 L 37,39.5 Z"),  # legs folded under
    ("shape", "M 15,30 C 14,22 18,14 25,13 C 31,13 35,20 34,30 Z"),                             # torso, a little forward
    ("shape", "M 18.5,5.5 A 5,5 0 1 0 18.5,15.5 A 5,5 0 1 0 18.5,5.5 Z"),                       # head bowed forward
    ("edge", "M 15,30 L 34,30", 1.1)]
# V4: one knee with a sword planted in front, hands on the pommel (an oath).
OPTIONS["V4_sword_oath"] = [
    ("shape", "M 26,33.5 L 38,33.5 L 38,39.5 L 26,39.5 Z"),
    ("shape", "M 13,27 C 13,24.5 14.5,23.5 16.5,23.5 L 28,23.5 L 28,30.5 L 16,30.5 L 16,39.5 L 10,39.5 L 10,30 C 10,28 11,27 13,27 Z"),
    ("shape", "M 22,31 C 20.5,23 22.5,14.5 28,11.5 C 33.5,11.5 35.5,18.5 34.5,31 Z"),
    ("shape", "M 23.5,5.5 A 4.8,4.8 0 1 0 23.5,15.1 A 4.8,4.8 0 1 0 23.5,5.5 Z"),
    ("shape", "M 5.8,16.5 L 8.2,16.5 L 8.2,39.5 L 5.8,39.5 Z"),                                 # blade, point down
    ("shape", "M 2,15 L 12,15 L 12,17.5 L 2,17.5 Z"),                                           # crossguard
    ("shape", "M 7,10 A 2.4,2.4 0 1 0 7,14.8 A 2.4,2.4 0 1 0 7,10 Z"),                          # pommel
    ("shape", "M 25,18 C 19,18 13,16 9.5,12.5 L 7.5,15.5 C 11.5,20 18.5,22.5 25.5,22 Z"),       # arms to the pommel
    ("edge", "M 22,31 L 34.5,31 M 16,30.5 L 28,30.5", 1.1)]

for name, parts in OPTIONS.items():
    for team in ("white", "black"):
        with open("%s_%s.svg" % (team, name), "w", encoding="utf-8", newline="\n") as f:
            f.write(render(parts, team))
print("wrote %d options x 2 colours" % len(OPTIONS))
