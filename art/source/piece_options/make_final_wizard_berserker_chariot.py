"""Final Wizard (round 12 wizard_ball_wide_round), Berserker (round 12
berserker_bent_b with smoother horn tips) and Chariot (round 13 chariot_ref2,
body moved back past the wheel, with a thick stepped pole), white and black,
written to ../pieces/.

Black versions follow the Cburnett black pieces: black shapes with thin white
detail lines.  Run from this folder:  python make_final_wizard_berserker_chariot.py
"""
import io, math

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">'
TAIL = "</g></svg>\n"

def shape(d, fill):
    return '<path d="%s" fill="%s"/>' % (d, fill)

def detail(d, color, width=1.2):
    return '<path d="%s" fill="none" stroke="%s" stroke-width="%s"/>' % (d, color, width)

def mirror(body):
    return '<g transform="translate(45,0) scale(-1,1)">%s</g>' % body

def colours(team):
    """Fill colour and detail-line colour for a team."""
    return ("#fff", "#000") if team == "white" else ("#000", "#fff")

# --- Wizard: crystal ball on a short, wide, rounded stand ----------------------------
def wizard(team):
    fill, line = colours(team)
    return (shape("M 6.5,40.5 C 6.5,36.5 10,34.5 14,34.5 L 31,34.5 C 35,34.5 38.5,36.5 38.5,40.5 Z", fill)
            + shape("M 13,34.5 C 14,31.5 16.5,29.8 19,29.3 L 26,29.3 C 28.5,29.8 31,31.5 32,34.5", fill)
            + '<circle cx="22.5" cy="17.5" r="12" fill="%s"/>' % fill
            + detail("M 15.5,13.5 C 16.5,10.5 19,8.5 22,8", "#000" if team == "white" else "#fff", 1.6)
            + (detail("M 13.5,34.5 L 31.5,34.5", line, 1) if team == "black" else ""))

# --- Berserker: horned helmet; horns hug the helm and turn out at a rounded tip ------
HORN = ("M 12.5,27.5 C 6.5,27.5 4,22.5 5,17 C 6,12 9.5,9 13.5,8 "
        "C 11.8,7.4 9.8,7.3 8.2,6.6 C 7.2,6.1 7.4,5 8.5,4.6 C 11.5,3.6 15.6,4 16.8,6.5 "
        "C 17.5,8.3 16,10 14,11 C 11.5,12.5 9.8,15 9.8,18 C 9.8,20.5 12,21.8 14.5,21.5 Z")
def berserker(team):
    fill, line = colours(team)
    horn = shape(HORN, fill)
    body = (horn + mirror(horn)
            + shape("M 10.5,30 C 10.5,18 15.5,12 22.5,12 C 29.5,12 34.5,18 34.5,30 Z", fill)
            + shape("M 9,30 L 36,30 L 36,34.5 L 9,34.5 Z", fill)
            + shape("M 20.5,34.5 L 24.5,34.5 L 24,40 L 21,40 Z", fill))
    if team == "white":
        body += detail("M 22.5,13 L 22.5,29", "#000", 1.5)
    else:
        body += detail("M 22.5,14 L 22.5,28.5 M 11,31.2 L 34,31.2", "#fff", 1)
        body += detail("M 11.5,25.5 C 7.5,24.5 6,21 6.8,17 C 7.6,13.5 10,11 12.5,9.8", "#fff", 0.9)
        body += mirror(detail("M 11.5,25.5 C 7.5,24.5 6,21 6.8,17 C 7.6,13.5 10,11 12.5,9.8", "#fff", 0.9))
    return body

# --- Chariot: side view; the body overhangs behind the wheel, a thick stepped pole ----
def wheel(cx, cy, r, spokes, fill, line, rim=2.6):
    out = '<circle cx="%s" cy="%s" r="%s" fill="%s"/>' % (cx, cy, r, fill)
    out += '<circle cx="%s" cy="%s" r="%s" fill="none" stroke="%s" stroke-width="1.2"/>' % (cx, cy, r - rim, line)
    lines = []
    for i in range(spokes):
        a = math.pi * 2 * i / spokes + math.pi / spokes
        lines.append("M %.2f,%.2f L %.2f,%.2f" % (cx + 2 * math.cos(a), cy + 2 * math.sin(a), cx + (r - rim) * math.cos(a), cy + (r - rim) * math.sin(a)))
    out += detail(" ".join(lines), line, 1.6)
    out += '<circle cx="%s" cy="%s" r="2" fill="%s" stroke="%s" stroke-width="1.2"/>' % (cx, cy, fill, line if fill == "#000" else "#000")
    return out
# The pole: a thick band with a step and a rounded end, like the ribbon on the
# Cburnett bishop's base.
POLE = ("M 28,29.5 L 33.5,29.5 C 34.3,29.5 34.8,29 34.8,28.2 L 34.8,27.5 L 41.5,27.5 "
        "C 42.5,27.5 43.2,28.2 43.2,29 C 43.2,29.8 42.5,30.5 41.5,30.5 L 37.6,30.5 L 37.6,31 "
        "C 37.6,32 37,32.5 36.2,32.5 L 28,32.5 Z")
def chariot(team):
    fill, line = colours(team)
    body = shape(POLE, fill)
    body += shape("M 3.5,32 L 3.5,21.5 C 3.5,19 5,17.5 7.5,17.5 L 16.5,17.5 C 19.5,17.5 20.5,16 20.5,13.5 "
                  "C 20.5,11.5 22,10.5 24,10.5 L 29,10.5 L 29,32 Z", fill)
    body += detail("M 6.5,32 L 6.5,22.5 C 6.5,21.3 7.3,20.5 8.5,20.5 L 17,20.5 C 21.5,20.5 23.5,18 23.5,15.5 "
                   "C 23.5,14 24.3,13.5 25.5,13.5 L 26,13.5 L 26,32", line, 1.2)
    body += wheel(16.5, 32, 9.5, 8, fill, line)
    return body

PIECES = {"wizard": wizard, "berserker": berserker, "chariot": chariot}
for name, draw in PIECES.items():
    for team in ["white", "black"]:
        io.open("../pieces/%s_%s.svg" % (team, name), "w", encoding="utf-8", newline="").write(HEAD + draw(team) + TAIL)
print("written")
