"""Round 14 art options from Mac's reference pictures (white versions, for choosing).

Necromancer: a round skull (reference 1) and a horned, angry skull (reference 5).
Rogue: a pointed hood over a cloak split at the bottom (reference 2).
Ram: a ram's head with a big ridged horn curling round the ear (references 3 and 4),
on the Cburnett knight's body.  Run from this folder:  python make_round14.py
"""
import io

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="#fff">'
TAIL = "</g></svg>\n"

def mirror(body):
    return '<g transform="translate(45,0) scale(-1,1)">%s</g>' % body

OPTIONS = {}

# --- Necromancer -----------------------------------------------------------------------
ROUND_SKULL = ('<path d="M 8.5,21.5 C 8.5,11 15,5 22.5,5 C 30,5 36.5,11 36.5,21.5 C 36.5,26.5 35.5,29.5 33,31 L 29.5,31 '
               'L 29.5,36.5 C 29.5,37.8 28.6,38.8 27.3,38.8 L 17.7,38.8 C 16.4,38.8 15.5,37.8 15.5,36.5 L 15.5,31 L 12,31 '
               'C 9.5,29.5 8.5,26.5 8.5,21.5 Z"/>')
ROUND_TEETH = '<path d="M 18.8,35.5 L 18.8,38.8 M 21.3,35.5 L 21.3,38.8 M 23.8,35.5 L 23.8,38.8 M 26.3,35.5 L 26.3,38.8" fill="none" stroke-width="1.2"/>'
ROUND_NOSE = '<path d="M 22.5,24.5 L 20.3,29.3 C 21.5,30 23.5,30 24.7,29.3 Z" fill="#000"/>'
OPTIONS["necromancer_round_skull"] = (
    ROUND_SKULL
    + '<circle cx="16" cy="20.5" r="4.4" fill="#000"/><circle cx="29" cy="20.5" r="4.4" fill="#000"/>'
    + ROUND_NOSE + ROUND_TEETH
)
OPTIONS["necromancer_round_skull_shaded"] = (
    ROUND_SKULL
    + '<path d="M 13,10.5 C 10.5,14 10,19 11,24 C 11.5,27 13,29 15,30" fill="none" stroke-width="1"/>'
    + '<circle cx="16" cy="20.5" r="4.4" fill="#000"/><circle cx="29" cy="20.5" r="4.4" fill="#000"/>'
    + '<path d="M 13.5,19.5 C 14,18 15.5,17.3 17,17.6 M 26.5,19.5 C 27,18 28.5,17.3 30,17.6" fill="none" stroke="#fff" stroke-width="1"/>'
    + ROUND_NOSE + ROUND_TEETH
)
HORN = '<path d="M 14.5,16.5 C 9,15 5.5,10.5 6.5,6 C 7.3,3.2 10,2.4 13,3 C 10.3,4.6 9.6,7.4 10.6,10 C 11.6,12.4 14,13.6 16.3,13.8 Z"/>'
ANGRY_SKULL = ('<path d="M 11.5,22.5 C 11.5,15 16.5,11 22.5,11 C 28.5,11 33.5,15 33.5,22.5 C 33.5,25.5 32.5,27.5 33,29.5 '
               'C 33.8,32 32.8,34.5 30,35 L 28.5,35 L 28.5,38.8 L 16.5,38.8 L 16.5,35 L 15,35 C 12.2,34.5 11.2,32 12,29.5 '
               'C 12.5,27.5 11.5,25.5 11.5,22.5 Z"/>')
ANGRY_FACE = ('<path d="M 15,22.5 L 21,24 C 21,26.8 19.6,28.3 17.8,28.3 C 15.8,28.3 14.6,25.8 15,22.5 Z" fill="#000"/>'
              '<path d="M 30,22.5 L 24,24 C 24,26.8 25.4,28.3 27.2,28.3 C 29.2,28.3 30.4,25.8 30,22.5 Z" fill="#000"/>'
              '<path d="M 21.2,32 L 22.5,29.8 L 23.8,32" fill="none" stroke-width="1.3"/>'
              '<path d="M 19.5,35.5 L 19.5,38.8 M 22.5,35.5 L 22.5,38.8 M 25.5,35.5 L 25.5,38.8" fill="none" stroke-width="1.2"/>')
CHEEKS = ('<path d="M 14.2,20 C 13.8,18.6 14.6,17.6 15.8,17.4 M 30.8,20 C 31.2,18.6 30.4,17.6 29.2,17.4 '
          'M 14.5,33 C 14.3,31.6 15,30.6 16.2,30.4 M 30.5,33 C 30.7,31.6 30,30.6 28.8,30.4" fill="none" stroke-width="1"/>')
OPTIONS["necromancer_horned_skull"] = HORN + mirror(HORN) + ANGRY_SKULL + ANGRY_FACE + CHEEKS
OPTIONS["necromancer_horned_skull_plain"] = HORN + mirror(HORN) + ANGRY_SKULL + ANGRY_FACE

# --- Rogue: pointed hood over a cloak split at the bottom ---------------------------------
CLOAK_SPLIT = '<path d="M 13.5,28.5 C 9,30.5 7.5,34 5.5,40.5 L 20,40.5 L 22.5,33.5 L 25,40.5 L 39.5,40.5 C 37.5,34 36,30.5 31.5,28.5 Z"/>'
HOOD_POINTED = '<path d="M 22.5,3.5 C 27,8 32.5,13 33.5,19.5 C 34.2,24.5 32.5,28 29.5,30 L 15.5,30 C 12.5,28 10.8,24.5 11.5,19.5 C 12.5,13 18,8 22.5,3.5 Z"/>'
OPENING = '<path d="M 22.5,12.5 C 25.8,15.3 28.8,18 28.8,21.8 C 28.8,24.8 26.8,26.5 24.6,26.5 L 20.4,26.5 C 18.2,26.5 16.2,24.8 16.2,21.8 C 16.2,18 19.2,15.3 22.5,12.5 Z" fill="#000"/>'
OPTIONS["rogue_hood_cloak"] = CLOAK_SPLIT + HOOD_POINTED + OPENING
OPTIONS["rogue_hood_cloak_rim"] = (CLOAK_SPLIT + HOOD_POINTED
    + '<path d="M 22.5,10 C 26.8,13.5 30.8,17 30.8,22 C 30.8,26 28,28.3 25,28.3 L 20,28.3 C 17,28.3 14.2,26 14.2,22 C 14.2,17 18.2,13.5 22.5,10 Z" fill="none" stroke-width="1"/>'
    + OPENING)
OPTIONS["rogue_hood_cloak_folds"] = (
    '<path d="M 13.5,28.5 C 9,30.5 7.5,34 5.5,40.5 L 39.5,40.5 C 37.5,34 36,30.5 31.5,28.5 Z"/>'
    + '<path d="M 16,31 C 15,34 14.5,37.5 14.8,40.5 M 29,31 C 30,34 30.5,37.5 30.2,40.5 M 22.5,32 L 22.5,40.5" fill="none" stroke-width="1"/>'
    + HOOD_POINTED + OPENING)

# --- Ram: big ridged horn curling round the ear, on the Cburnett knight's body ------------
KNIGHT_BODY = '<path d="M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"/>'
RAM_FACE = ('<path d="M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9,31 6,30 6,27 '
            'C 6,23 8,18.5 11,15 C 13.5,12 17,9.5 22,10"/>'
            '<circle cx="8.8" cy="26.3" r="0.6" fill="#000"/>'
            '<path d="M 11.5,17.8 C 12.5,16.8 14,16.8 15,17.6" fill="none" stroke-width="1.1"/>'
            '<ellipse cx="13.3" cy="18.6" rx="1.1" ry="0.7" fill="#000" stroke="none"/>')
# The horn: from the top of the head it sweeps back, round and down, and curls
# forward to end inside its own curl.
RAM_HORN = ('<path d="M 16,11 C 20,5 28,3.8 33.5,7.5 C 38.5,11 40,18 37.5,23.5 C 35.5,28 30.5,30.2 27,28.8 '
            'C 24,27.5 23,24.5 24.3,22 C 25.5,23.8 27.8,24.5 29.7,23.6 C 32.5,22.2 33.6,17.8 32.2,14.2 '
            'C 30.5,10.2 25.5,9 21.5,10.4 C 19.8,11 18.6,11.8 17.6,12.8 Z"/>')
RIDGES = ('<path d="M 21.5,6.8 L 22.6,10 M 26,5.3 L 25.8,9.2 M 30.5,6 L 28.8,9.8 M 34.8,9.3 L 31.5,12 '
          'M 37.6,14 L 32.8,15.5 M 38.2,19.5 L 33.4,19.5 M 36.6,25 L 32.5,22.5 M 32.5,28.8 L 30.3,24.2" fill="none" stroke-width="1"/>')
EAR = '<path d="M 23,18.5 C 25,16.5 28.3,16.8 30,18.8 C 27.8,20.5 25,20.6 23,18.5 Z" stroke-width="1.1"/>'
OPTIONS["ram_ridged_horn"] = KNIGHT_BODY + RAM_FACE + RAM_HORN + RIDGES + EAR
OPTIONS["ram_smooth_horn"] = KNIGHT_BODY + RAM_FACE + RAM_HORN + EAR
OPTIONS["ram_ridged_horn_neck_lines"] = (KNIGHT_BODY
    + '<path d="M 27,24 C 25,28 25,32 26.5,36.5 M 31,27 C 30,30.5 30.5,34 32,37.5" fill="none" stroke-width="1"/>'
    + RAM_FACE + RAM_HORN + RIDGES + EAR)

for name, body in OPTIONS.items():
    io.open("white_%s.svg" % name, "w", encoding="utf-8", newline="").write(HEAD + body + TAIL)
print(len(OPTIONS), "options written")
