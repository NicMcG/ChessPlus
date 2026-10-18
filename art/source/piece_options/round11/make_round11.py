"""Round 11 art options (white versions only, for choosing).

Cburnett style: 45x45 canvas, 1.5 black outline, white fill. Run from this folder:
    python make_round11.py
"""
import io

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="#fff">'
TAIL = "</g></svg>\n"

def thick(d, outer=6.5, inner=3.5):
    return ('<path d="%s" fill="none" stroke="#000" stroke-width="%s"/>' % (d, outer) +
            '<path d="%s" fill="none" stroke="#fff" stroke-width="%s"/>' % (d, inner))

def mirror(body):
    return '<g transform="translate(45,0) scale(-1,1)">%s</g>' % body

OPTIONS = {}

# --- Archer: from Mac's reference. Bow arcs toward the top-right; the string runs
# top-left to bottom-right; the arrow crosses it, pointing at the top-right corner.
BOW = "M 8,15 C 22,1 44,23 30,37"
STRING = '<path d="M 8,15 L 30,37" fill="none" stroke-width="1.6"/>'
SHAFT = "M 7.5,37.5 L 36,9"
HEAD_TIP = "M 41.5,3.5 L 38.5,13.5 L 35.5,11 L 34,9.5 L 31.5,6.5 Z"
FLETCH = "M 7.5,37.5 L 4,35.5 L 6,31 L 12,33 Z M 7.5,37.5 L 9.5,41 L 14,39 L 12,33 Z"
OPTIONS["archer_black_arrow"] = (
    thick(BOW, 6.5, 3)
    + STRING
    + '<path d="%s" fill="none" stroke="#000" stroke-width="3.6"/>' % SHAFT
    + '<path d="%s" fill="#000"/>' % HEAD_TIP
    + '<path d="%s" fill="#000"/>' % FLETCH
)
OPTIONS["archer_white_arrow"] = (
    thick(BOW, 6.5, 3)
    + STRING
    + thick(SHAFT, 4.6, 1.8)
    + '<path d="%s"/>' % HEAD_TIP
    + '<path d="%s"/>' % FLETCH
)
OPTIONS["archer_bold_bow"] = (
    thick(BOW, 8, 4.5)
    + '<path d="M 6.5,13 C 5,11.5 6,9 8.5,9.5 M 32.5,38.5 C 34,40 36.5,39 36,36.5" fill="none" stroke-width="1.6"/>'
    + STRING
    + '<path d="%s" fill="none" stroke="#000" stroke-width="3.6"/>' % SHAFT
    + '<path d="%s" fill="#000"/>' % HEAD_TIP
    + '<path d="%s" fill="#000"/>' % FLETCH
)

# --- Berserker: round 10's "horns out" helmet, simpler base, long horns that hug the
# helm on the way up and turn out at the tips.
HELM = ('<path d="M 10.5,30 C 10.5,18 15.5,12 22.5,12 C 29.5,12 34.5,18 34.5,30 Z"/>'
        '<path d="M 22.5,13 L 22.5,29" fill="none"/>')
BAND = '<path d="M 9,30 L 36,30 L 36,34.5 L 9,34.5 Z"/>'
NOSE = '<path d="M 20.5,34.5 L 24.5,34.5 L 24,40 L 21,40 Z"/>'
def horn_pair(left):
    return left + mirror(left)
HORN_HUG = '<path d="M 12.5,27 C 6.5,26.5 4.5,21.5 5.5,16 C 6.3,11.5 9,8.5 8.5,5 C 8.2,3 6.5,2 3.5,2 C 7,0 11,1.5 12,5 C 13,9 10.5,12.5 10.5,16.5 C 10.5,19.5 12.5,21 14.5,21 Z"/>'
HORN_HUG_TALL = '<path d="M 12.5,27 C 6,26.5 3.5,21 4.5,15 C 5.3,10 8.5,7 8.5,3.5 C 8.5,2 7.5,1 5.5,0.5 C 2.5,0 1,1.5 0.8,3 C 0.5,-0.5 5,-1.5 8,0 C 11,1.5 12,5 11.5,8.5 C 11,12 10,14 10,17 C 10,19.5 12,21 14.5,21 Z"/>'
HORN_HUG_FLARE = '<path d="M 12.5,27 C 6.5,26.5 4.5,21.5 5.5,16 C 6.2,12 8.5,9 8,6 C 7.5,4 5,3 2,4 C 4,0.5 9.5,0.5 11.5,3.5 C 13,6 11.5,10 10.8,13 C 10.2,16 10.5,19.5 14.5,21 Z"/>'
OPTIONS["berserker_hug"] = horn_pair(HORN_HUG) + HELM + BAND + NOSE
OPTIONS["berserker_hug_tall"] = horn_pair(HORN_HUG_TALL) + HELM + BAND + NOSE
OPTIONS["berserker_hug_flare"] = horn_pair(HORN_HUG_FLARE) + HELM + BAND + NOSE

# --- Wizard: staff and orb, thicker so they read at board size ---------------------------
def staff(d):
    return thick(d, 6, 3)
BASE = '<path d="M 13,41 C 13,38.5 17,37 22.5,37 C 28,37 32,38.5 32,41 Z"/>'
OPTIONS["wizard_orb_claws"] = (
    staff("M 22.5,39 L 22.5,16")
    + '<path d="M 22.5,17 C 17,16.5 14.5,12 15.5,7.5 C 17,10 18.5,11.5 20,12 M 22.5,17 C 28,16.5 30.5,12 29.5,7.5 C 28,10 26.5,11.5 25,12" fill="none" stroke="#000" stroke-width="4.5"/>'
    + '<path d="M 22.5,17 C 17,16.5 14.5,12 15.5,7.5 C 17,10 18.5,11.5 20,12 M 22.5,17 C 28,16.5 30.5,12 29.5,7.5 C 28,10 26.5,11.5 25,12" fill="none" stroke="#fff" stroke-width="2"/>'
    + '<circle cx="22.5" cy="9" r="5.5"/>'
    + '<path d="M 19.5,7.5 C 20,6 21,5.3 22.3,5" fill="none" stroke-width="1.1"/>'
    + BASE
)
OPTIONS["wizard_orb_crook"] = (
    staff("M 20,39 L 20,18 C 20,9 25,4 31,6 C 36,8 36,15 31.5,16.5")
    + '<circle cx="27.5" cy="12" r="5"/>'
    + '<path d="M 25,10.5 C 25.5,9.2 26.5,8.5 27.6,8.3" fill="none" stroke-width="1.1"/>'
    + BASE
)
OPTIONS["wizard_orb_fork"] = (
    staff("M 22.5,39 L 22.5,19")
    + staff("M 22.5,20 C 17.5,19 15.5,15 16,11.5 M 22.5,20 C 27.5,19 29.5,15 29,11.5")
    + '<circle cx="22.5" cy="10.5" r="6.5"/>'
    + '<path d="M 18.8,9 C 19.3,7.2 20.6,6 22.3,5.7" fill="none" stroke-width="1.1"/>'
    + BASE
)
OPTIONS["wizard_orb_hat"] = (
    '<path d="M 6,38 C 10,35 35,35 39,38 C 35,41 10,41 6,38 Z"/>'
    + '<path d="M 13.5,36.5 C 15,28 17.5,21 20.5,16 L 24.5,16 C 27.5,21 30,28 31.5,36.5 C 26,38.3 19,38.3 13.5,36.5 Z"/>'
    + '<path d="M 14.8,32 C 20,34 25,34 30.2,32" fill="none"/>'
    + '<circle cx="22.5" cy="10" r="7"/>'
    + '<path d="M 18.5,8.5 C 19,6.5 20.5,5 22.5,4.6" fill="none" stroke-width="1.1"/>'
)

# --- Chariot: side (profile) views ---------------------------------------------------------
def wheel(cx, cy, r, spokes):
    import math
    out = '<circle cx="%s" cy="%s" r="%s"/>' % (cx, cy, r)
    lines = []
    for i in range(spokes):
        a = math.pi * 2 * i / spokes
        lines.append("M %.2f,%.2f L %.2f,%.2f" % (cx, cy, cx + (r - 0.8) * math.cos(a), cy + (r - 0.8) * math.sin(a)))
    out += '<path d="%s" fill="none" stroke-width="1.1"/>' % " ".join(lines)
    out += '<circle cx="%s" cy="%s" r="2"/>' % (cx, cy)
    return out
OPTIONS["chariot_side_tall_front"] = (
    '<path d="M 22,30 L 43,26" fill="none" stroke-width="2.4"/>'
    + '<path d="M 6,30 L 6,20 L 27,20 C 30,20 31,17 31,13 C 31,9 33,7 35,8 C 37,9 36.5,12 35,13.5 C 33.5,16 33,22 31,26 C 30,28.5 28,30 25,30 Z"/>'
    + '<path d="M 6,24 L 29,24" fill="none" stroke-width="1.1"/>'
    + wheel(15.5, 31, 9, 8)
)
OPTIONS["chariot_side_rail"] = (
    '<path d="M 25,31 L 43,28" fill="none" stroke-width="2.4"/>'
    + '<path d="M 5,31 L 5,17 C 5,15 7,14 9,14 L 31,14 C 34,14 35,16 34.5,19 L 33,31 Z"/>'
    + '<path d="M 5,19 L 34.5,19 M 12,14 L 12,31 M 19,14 L 19,31 M 26,14 L 26,31" fill="none" stroke-width="1.1"/>'
    + wheel(16, 31, 9.5, 6)
)
OPTIONS["chariot_side_scythed"] = (
    '<path d="M 24,30 L 43,26" fill="none" stroke-width="2.4"/>'
    + '<path d="M 7,30 L 7,15 C 15,13 23,13 29,16 C 33,18 34,23 33,30 Z"/>'
    + '<path d="M 9,19 C 15,17.5 22,17.5 28,20" fill="none" stroke-width="1.1"/>'
    + wheel(16.5, 31, 9, 8)
    + '<path d="M 18,31 L 26,33 L 30.5,37 L 24,35.5 L 18,32.5" stroke-width="1.2"/>'
)

# --- Ram: more like round 10's ram_knight_neck ---------------------------------------------
KNIGHT_NECK_RAM = '<path d="M 26,12 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"/>'
def ram_head(eye=(16.5, 18.5)):
    return ('<path d="M 31,14 C 27,10.5 20,10.5 15.5,13.5 C 12,16 9,21 7,25.5 C 6,28 7.5,30.5 10,30 '
            'C 13,29.5 16,27.5 19,27 C 22.5,26.5 26,26.5 29,25 C 33,23 35,19 31,14 Z"/>'
            '<ellipse cx="%s" cy="%s" rx="1.4" ry="1" transform="rotate(-25 %s %s)" fill="#000" stroke="none"/>'
            '<path d="M 8.5,26 L 10,26.3" fill="none" stroke-width="1.2"/>' % (eye[0], eye[1], eye[0], eye[1]))
HORN_BIG = thick("M 21,12 C 27.5,4.5 38,8 37,17.5 C 36,25.5 26,26.5 25.5,20 C 25.2,15.5 30.5,15 31,19", 7.5, 4.5)
HORN_TIGHT = thick("M 21,12 C 26,6 35,8 35,16 C 35,22 28.5,23.5 27,19.5 C 26,16.5 29.5,15 30.5,17.5", 7.5, 4.5)
HORN_SWEEP = thick("M 20,12.5 C 26,4 39,6 39,16 C 39,25.5 29,28.5 26.5,22.5 C 24.5,18 29,15.5 31.5,18 C 33,19.5 32.5,22 31,22.5", 7.5, 4.5)
EAR = '<path d="M 22,19 C 19.5,21 17.5,21.5 16,21 C 17.5,19 19.5,18 22,18 Z" stroke-width="1.1"/>'
OPTIONS["ram_knight_big_horn"] = KNIGHT_NECK_RAM + ram_head() + HORN_BIG
OPTIONS["ram_knight_tight_horn"] = KNIGHT_NECK_RAM + ram_head() + HORN_TIGHT
OPTIONS["ram_knight_sweeping_horn"] = KNIGHT_NECK_RAM + ram_head() + HORN_SWEEP
OPTIONS["ram_knight_chest"] = (KNIGHT_NECK_RAM
    + '<path d="M 20,30 C 21.5,28.5 23.5,29 24,30.5 C 25.5,29 27.5,29.5 28,31 M 18,34.5 C 19.5,33 21.5,33.5 22,35 C 23.5,33.5 25.5,34 26,35.5" fill="none" stroke-width="1.1"/>'
    + ram_head() + HORN_BIG)

# --- Rogue and Necromancer: cleaner, smoother hooded busts -----------------------------------
# A front-facing hood: a smooth arch with a soft point, falling into a cloak over the
# shoulders that widens into the base.
CLOAK = '<path d="M 5,40.5 C 5,34 9,30 15,28.5 L 30,28.5 C 36,30 40,34 40,40.5 Z"/>'
CLOAK_FOLDS = '<path d="M 15.5,31 C 15,34 15.5,37.5 16.5,40.5 M 29.5,31 C 30,34 29.5,37.5 28.5,40.5" fill="none" stroke-width="1.1"/>'
HOOD = ('<path d="M 22.5,3.5 C 26,6 33,9.5 33.5,19 C 33.8,24 32.5,28 30,31.5 L 15,31.5 '
        'C 12.5,28 11.2,24 11.5,19 C 12,9.5 19,6 22.5,3.5 Z"/>')
OPENING = '<path d="M 22.5,11.5 C 18,12.5 16,17 16,22 C 16,26.5 18.5,30 22.5,30 C 26.5,30 29,26.5 29,22 C 29,17 27,12.5 22.5,11.5 Z" fill="#000"/>'
HOOD_RIM = '<path d="M 22.5,9.5 C 16.5,10.5 13.8,16 14,22 C 14.2,26.5 16,30 18,31.5 M 22.5,9.5 C 28.5,10.5 31.2,16 31,22 C 30.8,26.5 29,30 27,31.5" fill="none" stroke-width="1.1"/>'
EYES = '<path d="M 18.6,21.5 L 21,22.2 M 26.4,21.5 L 24,22.2" fill="none" stroke="#fff" stroke-width="1.7"/>'
MASK = ('<path d="M 16.2,24 C 19,25.5 26,25.5 28.8,24 C 28.5,27.5 26,30 22.5,30 C 19,30 16.5,27.5 16.2,24 Z" stroke-width="1.1"/>'
        '<path d="M 19,26.5 C 21,27.3 24,27.3 26,26.5" fill="none" stroke-width="0.9"/>')
SKULL = ('<path d="M 18,19.5 C 18,15.5 20,13.5 22.5,13.5 C 25,13.5 27,15.5 27,19.5 C 27,22 26,23.5 25.3,24 L 25.3,28 L 19.7,28 L 19.7,24 C 19,23.5 18,22 18,19.5 Z" stroke-width="1"/>'
         '<path d="M 19.4,19.6 C 19.4,17.9 22,17.9 22,19.8 C 22,21.3 19.4,21.3 19.4,19.6 Z M 23,19.8 C 23,17.9 25.6,17.9 25.6,19.6 C 25.6,21.3 23,21.3 23,19.8 Z" fill="#000" stroke-width="0.6"/>'
         '<path d="M 22.5,21.8 L 21.7,23.6 L 23.3,23.6 Z" fill="#000" stroke-width="0.5"/>'
         '<path d="M 21,25.3 L 21,28 M 22.5,25.3 L 22.5,28 M 24,25.3 L 24,28" fill="none" stroke-width="0.8"/>')
OPTIONS["rogue_bust"] = CLOAK + CLOAK_FOLDS + HOOD + HOOD_RIM + OPENING + EYES
OPTIONS["rogue_bust_masked"] = CLOAK + CLOAK_FOLDS + HOOD + HOOD_RIM + OPENING + EYES + MASK
OPTIONS["necromancer_bust"] = CLOAK + CLOAK_FOLDS + HOOD + HOOD_RIM + OPENING + SKULL
OPTIONS["necromancer_bust_collar"] = (
    CLOAK
    + '<path d="M 11,30 L 7,24.5 L 13.5,27 Z M 34,30 L 38,24.5 L 31.5,27 Z"/>'
    + CLOAK_FOLDS + HOOD + HOOD_RIM + OPENING + SKULL)
# A hooded head in profile, facing left like the knight, on a flared base.
PROFILE_HOOD = ('<path d="M 15,40.5 C 15,35 17,31.5 20,29.5 C 14,28.5 10.5,24 10.5,18.5 C 10.5,11 16,5.5 23,5.5 '
                'C 25.5,5.5 28,4.5 30.5,2.5 C 30.5,5 29.5,6.5 28.5,7.5 C 33,10 35,15 35,21 C 35,27 36,33 39,40.5 Z"/>'
                '<path d="M 21,8.5 C 15.5,10 13.5,15 13.5,19.5 C 13.5,23.5 15.5,26.5 18.5,28" fill="none" stroke-width="1.1"/>')
PROFILE_FACE = '<path d="M 14.8,14 C 17,13 19.5,14 20.3,16.5 C 21,19.5 20.8,23.5 19.5,26 C 17.5,27 15.3,26 14.5,24 C 13.7,21 13.7,16.5 14.8,14 Z" fill="#000"/>'
OPTIONS["rogue_profile"] = PROFILE_HOOD + PROFILE_FACE + '<path d="M 15.5,19.3 L 17.6,19.8" fill="none" stroke="#fff" stroke-width="1.6"/>'
OPTIONS["necromancer_profile"] = (PROFILE_HOOD + PROFILE_FACE
    + '<path d="M 15.3,15.5 C 17,14.8 18.8,15.6 19.2,17.5 C 19.6,19.5 19.4,21.5 18.6,23 L 18.6,25.5 L 15.8,25.5 L 15.3,23.5 C 14.6,21 14.6,17.5 15.3,15.5 Z" stroke-width="0.9"/>'
    + '<circle cx="16.4" cy="18.5" r="1.1" fill="#000" stroke="none"/>'
    + '<path d="M 16.5,23.8 L 16.5,25.5 M 17.6,23.8 L 17.6,25.5" fill="none" stroke-width="0.6"/>')

# --- Cavalry: horse and lance -------------------------------------------------------------
KNIGHT_NECK = '<path d="M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"/>'
KNIGHT_HEAD = ('<path d="M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9.958,30.06 12.41,27.96 11,28 C 10,28 11.19,29.23 10,30 C 9,30 5.997,31 6,26 C 6,24 12,14 12,14 C 12,14 13.89,12.1 14,10.5 C 13.27,9.506 13.5,8.5 13.5,7.5 C 14.5,6.5 16.5,10 16.5,10 L 18.5,10 C 18.5,10 19.28,8.008 21,7 C 22,7 22,10 22,10"/>'
               '<circle cx="9" cy="25.5" r="0.5" fill="#000"/>'
               '<path d="M 15,15.5 A 0.5,1.5 0 1 1 14,15.5 A 0.5,1.5 0 1 1 15,15.5 Z" transform="matrix(0.866,0.5,-0.5,0.866,9.693,-5.173)" fill="#000"/>')
HORSE = KNIGHT_NECK + KNIGHT_HEAD
def lance(x1, y1, x2, y2):
    return ('<path d="M %s,%s L %s,%s" fill="none" stroke="#000" stroke-width="4.5"/>' % (x1, y1, x2, y2)
            + '<path d="M %s,%s L %s,%s" fill="none" stroke="#fff" stroke-width="2"/>' % (x1, y1, x2, y2))
# Horse facing right (mirrored knight), lance behind it rising to the top-left, pennant.
OPTIONS["cavalry_lance_behind"] = (
    lance(40, 41, 12, 4)
    + '<path d="M 13.5,2 L 9,0.5 L 10,5.5 Z"/>'
    + '<path d="M 16.5,8.5 L 4,9 L 8.5,12.5 L 4,16 L 20,14 Z"/>'
    + mirror(HORSE)
)
# Horse facing left like the knight, lance couched under its neck pointing forward-up.
OPTIONS["cavalry_lance_couched"] = (
    HORSE
    + lance(42, 33, 4, 12)
    + '<path d="M 3,11.5 L 0.5,9 L 5.5,9.5 Z"/>'
    + '<path d="M 9,14.5 L 6,22 L 10.5,20.5 L 11.5,25.5 L 14.5,18 Z" />'
)
# Horse facing left, lance held upright behind its neck, pennant flying back.
OPTIONS["cavalry_lance_upright"] = (
    lance(31, 41, 31, 3)
    + '<path d="M 31,0.5 L 33,4 L 29,4 Z"/>'
    + '<path d="M 32,5 L 43,7 L 39,9.5 L 43,12 L 32,14 Z"/>'
    + HORSE
)
# Horse facing right, lance across in front, pointing up-right, pennant.
OPTIONS["cavalry_lance_front"] = (
    mirror(HORSE)
    + lance(6, 39, 38, 6)
    + '<path d="M 39.5,4.5 L 42.5,2 L 41.5,7 Z"/>'
    + '<path d="M 34.5,10 L 42,15.5 L 37,16 L 38.5,21 L 30.5,14 Z"/>'
)

for name, body in OPTIONS.items():
    io.open("white_%s.svg" % name, "w", encoding="utf-8", newline="").write(HEAD + body + TAIL)
print(len(OPTIONS), "options written")
