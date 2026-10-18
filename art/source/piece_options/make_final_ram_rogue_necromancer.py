"""Final Ram (round 13 ram_knight_c, horn ending in a point), Rogue (round 14
rogue_hood_cloak) and Necromancer (round 14 horned skull without the horns),
white and black, written to ../pieces/.

Black versions follow the Cburnett black pieces: black shapes with thin white
detail lines.  Run from this folder:  python make_final_ram_rogue_necromancer.py
"""
import io

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">'
TAIL = "</g></svg>\n"

def shape(d, fill, stroke="#000", width=1.5):
    return '<path d="%s" fill="%s" stroke="%s" stroke-width="%s"/>' % (d, fill, stroke, width)

def detail(d, color, width=1.1):
    return '<path d="%s" fill="none" stroke="%s" stroke-width="%s"/>' % (d, color, width)

def colours(team):
    return ("#fff", "#000") if team == "white" else ("#000", "#fff")

# --- Ram: Cburnett knight body, ram's face, big horn tapering to a point ----------------
KNIGHT_BODY = "M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"
MANE_EDGE = ("M 24.55,10.4 L 24.1,11.85 L 24.6,12 C 27.75,13 30.25,14.49 32.5,18.75 C 34.75,23.01 35.75,29.06 35.25,39 "
             "L 35.2,39.5 L 37.45,39.5 L 37.5,39 C 38,28.94 36.62,22.15 34.25,17.66 C 31.88,13.17 28.46,11.02 25.06,10.5 L 24.55,10.4 Z")
RAM_FACE = ("M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9,31 6,30 6,27 "
            "C 6,23 8,18.5 11,15 C 13.5,12 17,9.5 22,10")
# The horn as a filled band: from the top of the head up and over, down behind,
# round the bottom and up into its own curl, ending in a sharp point.
RAM_HORN = ("M 12.5,10 C 17.5,2 36.8,1 36.8,15 C 36.8,24 29,28 23,26 C 18.5,24.5 17.5,19.5 19,16 "
            "C 20.5,12.5 24.5,11 27.5,13 C 29.2,14.2 29.6,16 28.6,18 "
            "C 27.9,16.6 26.8,16 25.8,16.2 C 24.7,16.5 24.2,17.7 24.8,18.8 C 25.6,20.3 28,20.7 29.6,19.3 "
            "C 31.6,17.4 31.3,12.9 29,10.5 C 26.5,8 21,8.2 17.3,12.8 Z")
def ram(team):
    fill, line = colours(team)
    out = shape(KNIGHT_BODY, fill) + shape(RAM_FACE, fill)
    if team == "black":
        out += shape(MANE_EDGE, "#fff", "none")
    out += '<circle cx="8.8" cy="26.3" r="0.7" fill="%s" stroke="none"/>' % line
    out += '<ellipse cx="13.2" cy="18.2" rx="1.3" ry="0.9" transform="rotate(-30 13.2 18.2)" fill="%s" stroke="none"/>' % line
    out += shape(RAM_HORN, fill)
    if team == "black":
        out += detail("M 16,9 C 21,3.8 33.8,3.8 34.2,14.5 C 34.5,22 28.5,25.3 23.8,23.8 C 20.6,22.7 20.2,18.5 21.6,16.2", "#fff", 0.9)
    return out

# --- Rogue: pointed hood with a dark opening, over a cloak split at the bottom ----------
CLOAK = "M 13.5,28.5 C 9,30.5 7.5,34 5.5,40.5 L 20,40.5 L 22.5,33.5 L 25,40.5 L 39.5,40.5 C 37.5,34 36,30.5 31.5,28.5 Z"
HOOD = "M 22.5,3.5 C 27,8 32.5,13 33.5,19.5 C 34.2,24.5 32.5,28 29.5,30 L 15.5,30 C 12.5,28 10.8,24.5 11.5,19.5 C 12.5,13 18,8 22.5,3.5 Z"
OPENING = "M 22.5,12.5 C 25.8,15.3 28.8,18 28.8,21.8 C 28.8,24.8 26.8,26.5 24.6,26.5 L 20.4,26.5 C 18.2,26.5 16.2,24.8 16.2,21.8 C 16.2,18 19.2,15.3 22.5,12.5 Z"
def rogue(team):
    fill, line = colours(team)
    out = shape(CLOAK, fill) + shape(HOOD, fill)
    if team == "white":
        out += shape(OPENING, "#000")
    else:
        # On a black piece the opening gets a white rim, and the hood a white
        # edge where it meets the cloak (as in Mac's reference).
        out += shape(OPENING, "#000", "#fff", 1.2)
        out += detail("M 15.8,30.8 L 29.2,30.8", "#fff", 1.1)
    return out

# --- Necromancer: angry skull (no horns) ------------------------------------------------
SKULL = ("M 11.5,22.5 C 11.5,15 16.5,11 22.5,11 C 28.5,11 33.5,15 33.5,22.5 C 33.5,25.5 32.5,27.5 33,29.5 "
         "C 33.8,32 32.8,34.5 30,35 L 28.5,35 L 28.5,38.8 L 16.5,38.8 L 16.5,35 L 15,35 C 12.2,34.5 11.2,32 12,29.5 "
         "C 12.5,27.5 11.5,25.5 11.5,22.5 Z")
EYE_L = "M 15,22.5 L 21,24 C 21,26.8 19.6,28.3 17.8,28.3 C 15.8,28.3 14.6,25.8 15,22.5 Z"
EYE_R = "M 30,22.5 L 24,24 C 24,26.8 25.4,28.3 27.2,28.3 C 29.2,28.3 30.4,25.8 30,22.5 Z"
CHEEKS = ("M 14.2,20 C 13.8,18.6 14.6,17.6 15.8,17.4 M 30.8,20 C 31.2,18.6 30.4,17.6 29.2,17.4 "
          "M 14.5,33 C 14.3,31.6 15,30.6 16.2,30.4 M 30.5,33 C 30.7,31.6 30,30.6 28.8,30.4")
def necromancer(team):
    fill, line = colours(team)
    out = shape(SKULL, fill)
    eye_stroke = "#000" if team == "white" else "#fff"
    out += shape(EYE_L, "#000", eye_stroke, 1.2) + shape(EYE_R, "#000", eye_stroke, 1.2)
    out += detail("M 21.2,32 L 22.5,29.8 L 23.8,32", line, 1.3)
    out += detail("M 19.5,35.5 L 19.5,38.8 M 22.5,35.5 L 22.5,38.8 M 25.5,35.5 L 25.5,38.8", line, 1.2)
    out += detail(CHEEKS, line, 1)
    return out

PIECES = {"ram": ram, "rogue": rogue, "necromancer": necromancer}
for name, draw in PIECES.items():
    for team in ["white", "black"]:
        io.open("../pieces/%s_%s.svg" % (team, name), "w", encoding="utf-8", newline="").write(HEAD + draw(team) + TAIL)
print("written")
