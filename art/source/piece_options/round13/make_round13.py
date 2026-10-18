"""Round 13 art options (white versions only, for choosing).

Built on the real Cburnett shapes (from Wikimedia Commons, Category:SVG chess
pieces): the knight's body for the Ram, the bishop's base where a piece needs one.
Run from this folder:  python make_round13.py
"""
import io, math

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="#fff">'
TAIL = "</g></svg>\n"

def thick(d, outer=6.5, inner=3.5):
    return ('<path d="%s" fill="none" stroke="#000" stroke-width="%s"/>' % (d, outer) +
            '<path d="%s" fill="none" stroke="#fff" stroke-width="%s"/>' % (d, inner))

OPTIONS = {}

# Cburnett pieces --------------------------------------------------------------------
KNIGHT_BODY = '<path d="M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"/>'
BISHOP_BASE = ('<path d="M 9,36 C 12.39,35.03 19.11,36.43 22.5,34 C 25.89,36.43 32.61,35.03 36,36 C 36,36 37.65,36.54 39,38 '
               'C 38.32,38.97 37.35,38.99 36,38.5 C 32.61,37.53 25.89,38.96 22.5,37.5 C 19.11,38.96 12.39,37.53 9,38.5 '
               'C 7.65,38.99 6.68,38.97 6,38 C 7.35,36.54 9,36 9,36 Z"/>')

# --- Ram: the knight's body with a ram's head ---------------------------------------
# The head keeps the knight's jaw line but swaps the horse's ears and long face for a
# rounder, Roman-nosed ram's face; a curled horn sits on the side of the head.
RAM_HEAD = ('<path d="M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9,31 6,30 6,27 '
            'C 6,23 8,18.5 11,15 C 13.5,12 17,9.5 22,10"/>'
            '<circle cx="8.8" cy="26.3" r="0.6" fill="#000"/>')
RAM_EYE = '<ellipse cx="13.2" cy="18.2" rx="1.3" ry="0.9" transform="rotate(-30 13.2 18.2)" fill="#000" stroke="none"/>'
HORN_A = thick("M 15.5,11 C 20,5 30,6.5 30.5,14.5 C 31,21 23.5,23 22,18.5 C 21,15 25,13.5 26.5,16", 7.5, 4.5)
HORN_B = thick("M 15,11.5 C 19,6.5 27,7 28,13.5 C 28.8,18.5 23.5,20.5 22,17 C 21.3,15 23.5,13.8 24.8,15.3", 7, 4)
HORN_C = thick("M 15,11 C 20,3.5 33,5 33,15 C 33,23.5 23.5,25.5 21.8,19.5 C 20.8,15.5 25,13.5 27,16.5", 7.5, 4.5)
OPTIONS["ram_knight_a"] = KNIGHT_BODY + RAM_HEAD + RAM_EYE + HORN_A
OPTIONS["ram_knight_b"] = KNIGHT_BODY + RAM_HEAD + RAM_EYE + HORN_B
OPTIONS["ram_knight_c"] = KNIGHT_BODY + RAM_HEAD + RAM_EYE + HORN_C

# --- Necromancer: a stylised skull (no hood) ------------------------------------------
def skull(top=5.5, jaw=True):
    s = ('<path d="M 11,%.1f C 11,%.1f 16,%.1f 22.5,%.1f C 29,%.1f 34,%.1f 34,%.1f C 34,%.1f 31.5,%.1f 30,%.1f L 30,%.1f L 15,%.1f L 15,%.1f C 13.5,%.1f 11,%.1f 11,%.1f Z"/>'
         % (top + 14, top + 5, top, top, top, top + 5, top + 14, top + 19, top + 21.5, top + 22.5, top + 28, top + 28, top + 22.5, top + 21.5, top + 19, top + 14))
    s += ('<path d="M 14.3,%.1f C 14.3,%.1f 21,%.1f 21,%.1f C 21,%.1f 14.3,%.1f 14.3,%.1f Z" fill="#000"/>' % (top + 14.5, top + 11.5, top + 11.5, top + 15, top + 18, top + 18, top + 14.5)
          + '<path d="M 24,%.1f C 24,%.1f 30.7,%.1f 30.7,%.1f C 30.7,%.1f 24,%.1f 24,%.1f Z" fill="#000"/>' % (top + 15, top + 11.5, top + 11.5, top + 14.5, top + 18, top + 18, top + 15)
          + '<path d="M 22.5,%.1f L 20.8,%.1f L 24.2,%.1f Z" fill="#000" stroke-width="0.8"/>' % (top + 18, top + 22, top + 22))
    if jaw:
        s += '<path d="M 18.5,%.1f L 18.5,%.1f M 22.5,%.1f L 22.5,%.1f M 26.5,%.1f L 26.5,%.1f" fill="none" stroke-width="1.2"/>' % (top + 24.5, top + 28, top + 24.5, top + 28, top + 24.5, top + 28)
    return s
OPTIONS["necromancer_skull_cracked"] = (skull(7) +
    '<path d="M 25,7.5 L 23.5,11 L 26,13.5 L 24.5,16" fill="none" stroke-width="1.2"/>')
# An angular skull: narrow chin, sharp cheekbones, long teeth.
OPTIONS["necromancer_skull_angular"] = (
    '<path d="M 10.5,19 C 10.5,10 16,5 22.5,5 C 29,5 34.5,10 34.5,19 C 34.5,23 33,25.5 31,27 L 29,34 C 27.5,38 25,40 22.5,40 C 20,40 17.5,38 16,34 L 14,27 C 12,25.5 10.5,23 10.5,19 Z"/>'
    + '<path d="M 13.5,19.5 L 20.5,18 L 20,24 C 17,24 14.5,22.5 13.5,19.5 Z M 31.5,19.5 L 24.5,18 L 25,24 C 28,24 30.5,22.5 31.5,19.5 Z" fill="#000"/>'
    + '<path d="M 22.5,24 L 20.8,28.5 L 24.2,28.5 Z" fill="#000" stroke-width="0.8"/>'
    + '<path d="M 17.5,31.5 C 20.5,33 24.5,33 27.5,31.5 M 20,31.8 L 20.3,35.5 M 22.5,32.3 L 22.5,36.5 M 25,31.8 L 24.7,35.5" fill="none" stroke-width="1.1"/>'
)

# --- Rogue: just a hood (no face, no body); the opening is in shadow ------------------
OPTIONS["rogue_hood_round"] = (
    '<path d="M 22.5,4 C 15,5 9.5,12 9,22 C 8.6,30 9.5,36 8,40.5 C 13,39 17,40 22.5,40 C 28,40 32,39 37,40.5 C 35.5,36 36.4,30 36,22 C 35.5,12 30,5 22.5,4 Z"/>'
    + '<path d="M 22.5,11 C 17,12 14.5,17.5 14.5,24 C 14.5,30.5 17.5,36 22.5,37.5 C 27.5,36 30.5,30.5 30.5,24 C 30.5,17.5 28,12 22.5,11 Z" fill="#000"/>'
)
OPTIONS["rogue_hood_peaked"] = (
    '<path d="M 22.5,2.5 C 26,6 33,10 35,19 C 36.5,26 35.5,33 38,40.5 C 33,39.5 28,40.5 22.5,40.5 C 17,40.5 12,39.5 7,40.5 C 9.5,33 8.5,26 10,19 C 12,10 19,6 22.5,2.5 Z"/>'
    + '<path d="M 22.5,11 C 17,12.5 14.5,18 14.5,24.5 C 14.5,31 17.5,36.5 22.5,38 C 27.5,36.5 30.5,31 30.5,24.5 C 30.5,18 28,12.5 22.5,11 Z" fill="#000"/>'
    + '<path d="M 22.5,8 C 15.5,9.5 12,16 12,24 C 12,30.5 14,36 17,39.5 M 22.5,8 C 29.5,9.5 33,16 33,24 C 33,30.5 31,36 28,39.5" fill="none" stroke-width="1"/>'
)
OPTIONS["rogue_hood_tip_back"] = (
    '<path d="M 21,5 C 25,2 31,2 34,5.5 C 31.5,5 29.5,5.5 28.5,7 C 33,10.5 35.5,16 36,23 C 36.5,30 35.5,35 37.5,40.5 C 32,39.5 27.5,40.5 22.5,40.5 C 17.5,40.5 13,39.5 7.5,40.5 C 9.5,35 8.5,30 9,23 C 9.5,14 14,7.5 21,5 Z"/>'
    + '<path d="M 22.5,11.5 C 17,12.5 14.5,18 14.5,24.5 C 14.5,31 17.5,36.5 22.5,38 C 27.5,36.5 30.5,31 30.5,24.5 C 30.5,18 28,12.5 22.5,11.5 Z" fill="#000"/>'
)

# --- Chariot: side view, after Mac's three references --------------------------------
def wheel(cx, cy, r, spokes, rim=2.6):
    out = '<circle cx="%s" cy="%s" r="%s" fill="#fff"/>' % (cx, cy, r)
    out += '<circle cx="%s" cy="%s" r="%s" fill="none"/>' % (cx, cy, r - rim)
    lines = []
    for i in range(spokes):
        a = math.pi * 2 * i / spokes + math.pi / spokes
        lines.append("M %.2f,%.2f L %.2f,%.2f" % (cx + 2 * math.cos(a), cy + 2 * math.sin(a), cx + (r - rim) * math.cos(a), cy + (r - rim) * math.sin(a)))
    out += '<path d="%s" fill="none" stroke-width="1.6"/>' % " ".join(lines)
    out += '<circle cx="%s" cy="%s" r="2"/>' % (cx, cy)
    return out
# Reference 1: boxy body, the back rising in a step to a tall front with a fancy edge.
OPTIONS["chariot_ref1"] = (
    '<path d="M 4.5,33 L 4.5,26 C 4.5,23 6.5,21 9.5,21 L 17.5,21 L 23.5,13.5 C 24.5,12.2 26,11.5 27.5,11.5 L 34.5,11.5 L 34.5,33 Z"/>'
    + '<path d="M 31.5,14.5 L 29.5,17 L 30.5,18.5 L 28.5,20.5 L 30.5,22.5 L 29.5,24 L 31.5,26.5" fill="none" stroke-width="1.3"/>'
    + '<path d="M 34.5,28.5 L 41.5,28.5 L 41.5,33 L 34.5,33 Z"/>'
    + wheel(15, 33, 9, 6)
)
# Reference 2: rounded body with a raised rim, a shorter rise to the front.
OPTIONS["chariot_ref2"] = (
    '<path d="M 9,32 L 9,21.5 C 9,19 10.5,17.5 13,17.5 L 21.5,17.5 C 24.5,17.5 25.5,16 25.5,13 C 25.5,10.5 27,9 29.5,9 L 34.5,9 L 34.5,32 Z"/>'
    + '<path d="M 12,32 L 12,22.5 C 12,21.3 12.8,20.5 14,20.5 L 22,20.5 C 26.5,20.5 28.5,18 28.5,14.5 C 28.5,12.8 29.3,12 31,12 L 31.5,12 L 31.5,32" fill="none" stroke-width="1.2"/>'
    + '<path d="M 34.5,30 L 42,30" fill="none" stroke-width="2.8"/>'
    + wheel(15, 32, 9.5, 8)
)
# Reference 3: a front sweeping up in one curve, a long low pole.
OPTIONS["chariot_ref3"] = (
    '<path d="M 4,31 L 7,22.5 C 15,21 22.5,16.5 27.5,10.5 L 30.5,10.5 L 30.5,31 Z"/>'
    + '<path d="M 30.5,31 L 36,31 L 36,29 L 43,29" fill="none" stroke-width="2.6"/>'
    + wheel(15, 31.5, 10, 12, 2.4)
)

for name, body in OPTIONS.items():
    io.open("white_%s.svg" % name, "w", encoding="utf-8", newline="").write(HEAD + body + TAIL)
print(len(OPTIONS), "options written")
