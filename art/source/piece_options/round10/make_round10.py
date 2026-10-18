"""Round 10 art options (white versions only, for choosing).

Cburnett style: 45x45 canvas, 1.5 black outline, white fill. Run from this folder:
    python make_round10.py
"""
import io

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="#fff">'
TAIL = "</g></svg>\n"

def thick(d, outer=6.5, inner=3.5):
    """A thick white line with a black outline (horns, bows, staffs)."""
    return ('<path d="%s" fill="none" stroke="#000" stroke-width="%s"/>' % (d, outer) +
            '<path d="%s" fill="none" stroke="#fff" stroke-width="%s"/>' % (d, inner))

def mirror(body):
    return '<g transform="translate(45,0) scale(-1,1)">%s</g>' % body

OPTIONS = {}

# --- Archer: bow and arrow on the diagonal, pointing at a top corner ---------------------
BOW_LEFT = (thick("M 15,4.5 C 27,11 27,34 15,40.5", 5.5, 2.8)
            + '<path d="M 15,4.5 L 32,22.5 L 15,40.5" fill="none" stroke-width="1"/>'
            + '<path d="M 6.5,22.5 L 35,22.5" fill="none" stroke-width="1.8"/>'
            + '<path d="M 3,22.5 L 9,19.5 L 9,25.5 Z"/>'
            + '<path d="M 33,22.5 L 38,18.5 L 41,18.5 L 36.5,22.5 L 41,26.5 L 38,26.5 Z"/>')
OPTIONS["archer_up_left"] = '<g transform="rotate(45 22.5 22.5)">%s</g>' % BOW_LEFT
OPTIONS["archer_up_right"] = mirror('<g transform="rotate(45 22.5 22.5)">%s</g>' % BOW_LEFT)
RECURVE = (thick("M 13,3.5 C 8,5.5 10,9.5 14.5,11.5 C 23,16 23,29 14.5,33.5 C 10,35.5 8,39.5 13,41.5", 5.5, 2.8)
           + '<path d="M 13,3.5 L 31,22.5 L 13,41.5" fill="none" stroke-width="1"/>'
           + '<path d="M 6.5,22.5 L 34,22.5" fill="none" stroke-width="1.8"/>'
           + '<path d="M 2.5,22.5 L 9,19 L 7.5,22.5 L 9,26 Z"/>'
           + '<path d="M 31.5,22.5 L 37,18 L 41,18 L 36,22.5 L 41,27 L 37,27 Z"/>')

# --- Berserker: horned helmets with curvy, pointed horns ---------------------------------
HELMET = ('<path d="M 10.5,30 C 10.5,18 15.5,12 22.5,12 C 29.5,12 34.5,18 34.5,30 Z"/>'
          '<path d="M 9,30 L 36,30 L 36,34 L 9,34 Z"/>'
          '<path d="M 20.5,30 L 24.5,30 L 24,40 L 21,40 Z"/>'
          '<path d="M 22.5,13 L 22.5,29" fill="none"/>')
def horns(left):
    return left + mirror(left)
OPTIONS["berserker_horns_up"] = horns('<path d="M 12.5,25 C 6,24 3,18 4,11 C 4.3,8 5,5.5 6.5,3 C 7,8 8,12 10.5,15.5 C 12,17.5 13.5,18.5 14.5,19.5 Z"/>') + HELMET
OPTIONS["berserker_horns_in"] = horns('<path d="M 12.5,25.5 C 5,25.5 1.5,19 3,12.5 C 4,8 7.5,5 12,4 C 9.5,7.5 8.5,11.5 9.5,15 C 10.5,18 12.5,19.5 14.5,20 Z"/>') + HELMET
OPTIONS["berserker_horns_out"] = horns('<path d="M 12,26 C 7,27 3,24.5 2.5,20.5 C 2,17 4,14 3.5,9.5 C 6,12.5 6.5,16 7.5,18.5 C 8.5,20.5 11,21 14,20.5 Z"/>') + (
    '<path d="M 10.5,30 C 10.5,18 15.5,12 22.5,12 C 29.5,12 34.5,18 34.5,30 Z"/>'
    '<path d="M 9,30 L 36,30 L 36,34 L 9,34 Z"/>'
    '<path d="M 12,34 L 12,40 C 14,40.5 16,39.5 17,38 L 17,34 M 33,34 L 33,40 C 31,40.5 29,39.5 28,38 L 28,34"/>'
    '<path d="M 20.5,30 L 24.5,30 L 24,39 L 21,39 Z"/>'
    '<circle cx="13" cy="32" r="0.8" fill="#000"/><circle cx="32" cy="32" r="0.8" fill="#000"/>'
    '<path d="M 22.5,13 L 22.5,29" fill="none"/>')

# --- Chariot: front-facing designs ---------------------------------------------------------
def wheels(rx=4, cy=31, ry=9):
    return ('<ellipse cx="7.5" cy="%s" rx="%s" ry="%s"/><ellipse cx="37.5" cy="%s" rx="%s" ry="%s"/>' % (cy, rx, ry, cy, rx, ry)
            + '<path d="M 7.5,%s L 7.5,%s M 37.5,%s L 37.5,%s M %s,%s L %s,%s M %s,%s L %s,%s" fill="none" stroke-width="1"/>'
            % (cy - ry, cy + ry, cy - ry, cy + ry, 7.5 - rx, cy, 7.5 + rx, cy, 37.5 - rx, cy, 37.5 + rx, cy)
            + '<circle cx="7.5" cy="%s" r="1.3" fill="#000"/><circle cx="37.5" cy="%s" r="1.3" fill="#000"/>' % (cy, cy))
OPTIONS["chariot_front_rim"] = (
    '<path d="M 11.5,32 L 11.5,32 L 33.5,32" fill="none" stroke-width="2.4"/>'
    + wheels()
    + '<path d="M 12,31 L 10,10 C 15,6 30,6 35,10 L 33,31 Z"/>'
    + '<path d="M 10,10 C 15,13 30,13 35,10" fill="none"/>'
    + '<path d="M 14.5,16.5 C 19,18.5 26,18.5 30.5,16.5 M 13.5,23.5 C 19,25.5 26,25.5 31.5,23.5" fill="none" stroke-width="1.1"/>'
    + '<path d="M 22.5,31 L 22.5,41.5" fill="none" stroke-width="2.4"/>'
)
OPTIONS["chariot_front_shield"] = (
    wheels(4.5, 30, 9.5)
    + '<path d="M 12,32 L 33,32" fill="none" stroke-width="2.4"/>'
    + '<path d="M 11,8 C 17,5 28,5 34,8 L 33,24 C 31,29 26,32 22.5,33 C 19,32 14,29 12,24 Z"/>'
    + '<circle cx="22.5" cy="18" r="5"/><circle cx="22.5" cy="18" r="1.6" fill="#000"/>'
    + '<path d="M 22.5,13 L 22.5,23 M 17.5,18 L 27.5,18" fill="none" stroke-width="1"/>'
    + '<path d="M 22.5,33 L 22.5,41.5 M 16,41.5 L 29,41.5" fill="none" stroke-width="2.4"/>'
)
OPTIONS["chariot_front_tall"] = (
    wheels(5, 32, 8.5)
    + '<path d="M 12.5,33 L 32.5,33" fill="none" stroke-width="2.4"/>'
    + '<path d="M 13,33 L 11,15 C 11,9 14,4 17,4.5 C 18.5,7 20,8 22.5,8 C 25,8 26.5,7 28,4.5 C 31,4 34,9 34,15 L 32,33 Z"/>'
    + '<path d="M 15,15 L 30,15 M 14.5,24 L 30.5,24" fill="none" stroke-width="1.1"/>'
    + '<path d="M 22.5,15 L 22.5,24" fill="none" stroke-width="1.1"/>'
)

# --- Wizard: other ideas ------------------------------------------------------------------
OPTIONS["wizard_bearded"] = (
    '<path d="M 15,22 C 15,30 17,36 22.5,41 C 28,36 30,30 30,22 Z"/>'
    + '<path d="M 18.5,27 C 20,29 25,29 26.5,27 M 19.5,32 L 22.5,37 L 25.5,32" fill="none" stroke-width="1.1"/>'
    + '<path d="M 15.5,22 L 15.5,19 L 29.5,19 L 29.5,22 Z"/>'
    + '<circle cx="19.3" cy="21" r="0.9" fill="#000" stroke="none"/><circle cx="25.7" cy="21" r="0.9" fill="#000" stroke="none"/>'
    + '<ellipse cx="22.5" cy="18.5" rx="13.5" ry="3"/>'
    + '<path d="M 13.5,17.5 C 15.5,12 18,7.5 21,5 C 23.5,3 27.5,2.5 31,4.5 C 27,5 25,7 24.5,10 C 26,12.5 29,15 31.5,17.5 C 26,19.5 19,19.5 13.5,17.5 Z"/>'
)
OPTIONS["wizard_staff"] = (
    thick("M 24,13 L 21,41", 5, 2.2)
    + '<path d="M 24.5,13 C 20,12 17.5,8.5 18.5,5 C 19.5,8 22,9.5 25,9 C 27.5,8.5 28.5,6 27.5,3.5 C 31,5 31.5,10 28.5,12.5 C 27.5,13.3 26,13.4 24.5,13 Z"/>'
    + '<circle cx="23.8" cy="6.8" r="3.2"/>'
    + '<path d="M 15,41 L 28,41" fill="none" stroke-width="2.4"/>'
)
OPTIONS["wizard_crystal_ball"] = (
    '<path d="M 12.5,40.5 L 32.5,40.5 L 30,33 L 15,33 Z"/>'
    + '<path d="M 15,33 C 15.5,30 17.5,28.5 19,28 L 26,28 C 27.5,28.5 29.5,30 30,33" fill="#fff"/>'
    + '<circle cx="22.5" cy="17" r="12"/>'
    + '<path d="M 15.5,13 C 16.5,10 19,8 22,7.5" fill="none" stroke-width="1.6"/>'
    + '<path d="M 16.5,37 L 28.5,37" fill="none" stroke-width="1"/>'
)
OPTIONS["wizard_droopy_hat"] = (
    '<path d="M 4.5,37 C 9,33.5 36,33.5 40.5,37 C 36,40.5 9,40.5 4.5,37 Z"/>'
    + '<path d="M 12.5,35.5 C 14,26 17,17 20.5,11 C 23.5,6 28,3.5 32,5 C 35.5,6.5 37,10.5 36,15.5 C 35,13 33.5,11.5 31,11.5 C 28.5,11.5 27,14 27,18 C 27.5,24 29.5,30 31.5,35.5 C 25.5,37.5 18.5,37.5 12.5,35.5 Z"/>'
    + '<path d="M 14,30.5 C 19.5,32.5 25.5,32.5 30.5,30.5" fill="none"/>'
)

# --- Cavalry: other horses ------------------------------------------------------------------
KNIGHT_NECK = '<path d="M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"/>'
KNIGHT_HEAD = ('<path d="M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9.958,30.06 12.41,27.96 11,28 C 10,28 11.19,29.23 10,30 C 9,30 5.997,31 6,26 C 6,24 12,14 12,14 C 12,14 13.89,12.1 14,10.5 C 13.27,9.506 13.5,8.5 13.5,7.5 C 14.5,6.5 16.5,10 16.5,10 L 18.5,10 C 18.5,10 19.28,8.008 21,7 C 22,7 22,10 22,10"/>'
               '<circle cx="9" cy="25.5" r="0.5" fill="#000"/>'
               '<path d="M 15,15.5 A 0.5,1.5 0 1 1 14,15.5 A 0.5,1.5 0 1 1 15,15.5 Z" transform="matrix(0.866,0.5,-0.5,0.866,9.693,-5.173)" fill="#000"/>')
OPTIONS["cavalry_armoured"] = (
    KNIGHT_NECK + KNIGHT_HEAD
    + '<path d="M 12.5,13.5 L 20.5,13 L 21,19.5 L 13,26 L 9,25 Z" stroke-width="1.2"/>'
    + '<path d="M 14,17.5 L 19,17.2" fill="none" stroke-width="1"/>'
    + '<path d="M 19,8 C 18.5,4 21,1.5 24,2 C 27.5,2.5 28.5,5.5 26.5,7.5 C 25,8.5 23,9 21.5,10.5 Z"/>'
    + '<path d="M 23,20 C 28,22 31,26 32,32 M 25,14 C 30,16 33.5,21 35,28" fill="none" stroke-width="1"/>'
)
OPTIONS["cavalry_mane"] = (
    KNIGHT_NECK + KNIGHT_HEAD
    + '<path d="M 22,10 C 27,9.5 31,12 33,15 C 31,14.5 30,15 30.5,16.5 C 33,18 35,21 35.5,24 C 33.5,23 32,23.5 32.5,25 C 34.5,27 36,30 36,33 L 30,26 C 28,21 26,16 22,10 Z" stroke-width="1.2"/>'
    + '<path d="M 11,28.5 C 13,26 15.5,24 17.5,22.5 M 17.5,22.5 L 22.5,22" fill="none" stroke-width="1"/>'
)
OPTIONS["cavalry_lance_and_horse"] = (
    '<path d="M 4,41 L 31,3" fill="none" stroke="#000" stroke-width="4.5"/><path d="M 4,41 L 31,3" fill="none" stroke="#fff" stroke-width="2"/>'
    + '<path d="M 29.5,2.5 L 34,0.5 L 33,5.5 Z"/>'
    + '<path d="M 28,7 L 41,8.5 L 36,11.5 L 40,15 L 24.5,13 Z"/>'
    + mirror(KNIGHT_NECK + KNIGHT_HEAD)
)

# --- Rogue and Necromancer: curvier, flowing hoods -------------------------------------------
HOOD_A = ('<path d="M 24,4 C 30.5,4.5 34.5,10 35.5,17 C 36.5,24 35.5,30 37.5,34.5 C 38.5,37 40,39 41.5,40.5 '
          'C 36,41.5 31,39.5 26.5,40.8 C 21,42.2 15,40 9.5,41 C 7,41.4 5,40.8 3.5,40.5 C 6.5,37 8.5,32 9,26 '
          'C 9.5,18 12.5,10.5 17.5,7 C 19.5,5.5 21.5,4.5 24,4 Z"/>'
          '<path d="M 24,4 C 27.5,1.5 32.5,1.5 35,5 C 32,4 29.5,4.5 28,6.5" />'
          '<path d="M 12.5,33 C 14,36 15,38.5 15,41 M 32.5,33 C 31.5,36 31.5,38.5 32.5,40.5" fill="none"/>')
HOOD_B = ('<path d="M 23,3.5 C 29,3 33.5,8 34.5,15 C 35.5,21 34,26 36,30 C 38.5,34 42,36.5 43,41 '
          'C 37,40 33,41.5 28,40.5 C 24.5,39.8 20.5,39.8 17,40.5 C 12,41.5 8,40 2,41 '
          'C 3,36.5 6.5,34 9,30 C 11,26 9.5,21 10.5,15 C 11.5,8.5 16.5,4 23,3.5 Z"/>'
          '<path d="M 8,33 C 11,35 14,35.5 16.5,34.5 M 37,33 C 34,35 31,35.5 28.5,34.5" fill="none"/>'
          '<path d="M 23,3.5 C 24.5,1 28,0.8 30,2.5 C 28,2.8 26.5,3.5 25.5,5" />')
FACE = '<path d="M 22.5,13 C 17,14 15,19 15,24.5 C 15,29.5 18,33 22.5,33 C 27,33 30,29.5 30,24.5 C 30,19 28,14 22.5,13 Z" fill="#000"/>'
EYES = '<path d="M 18.2,23.5 L 21,24.3 M 26.8,23.5 L 24,24.3" fill="none" stroke="#fff" stroke-width="1.6"/>'
SKULL_IN_HOOD = ('<path d="M 17.5,21 C 17.5,16.5 20,14.5 22.5,14.5 C 25,14.5 27.5,16.5 27.5,21 C 27.5,23.5 26.3,24.8 25.6,25.3 L 25.6,29 L 19.4,29 L 19.4,25.3 C 18.7,24.8 17.5,23.5 17.5,21 Z" stroke-width="1"/>'
                 '<path d="M 19,21 C 19,19.3 21.8,19.3 21.8,21.2 C 21.8,22.7 19,22.7 19,21 Z M 23.2,21.2 C 23.2,19.3 26,19.3 26,21 C 26,22.7 23.2,22.7 23.2,21.2 Z" fill="#000" stroke-width="0.6"/>'
                 '<path d="M 22.5,23.2 L 21.7,25 L 23.3,25 Z" fill="#000" stroke-width="0.5"/>'
                 '<path d="M 20.9,26.5 L 20.9,29 M 22.5,26.5 L 22.5,29 M 24.1,26.5 L 24.1,29" fill="none" stroke-width="0.8"/>')
OPTIONS["rogue_flowing_a"] = HOOD_A + FACE + EYES
OPTIONS["rogue_flowing_b"] = HOOD_B + FACE + EYES
OPTIONS["necromancer_flowing_a"] = HOOD_A + FACE + SKULL_IN_HOOD
OPTIONS["necromancer_flowing_b"] = HOOD_B + FACE + SKULL_IN_HOOD

# --- Ram: in the style of the knight and elephant (head on a flared neck) --------------------
RAM_NECK = '<path d="M 15,39 L 38.5,39 C 38.6,34 37.5,29 35.5,25 L 29,23 L 21,24.5 C 20.6,30.5 16.6,33.6 15,39 Z"/>'
RAM_HEAD = ('<path d="M 31,14 C 27,10.5 20,10.5 15.5,13.5 C 12,16 9,21 7,25.5 C 6,28 7.5,30.5 10,30 '
            'C 13,29.5 16,27.5 19,27 C 22.5,26.5 26,26.5 29,25 C 33,23 35,19 31,14 Z"/>'
            '<ellipse cx="16.5" cy="18.5" rx="1.4" ry="1" transform="rotate(-25 16.5 18.5)" fill="#000" stroke="none"/>'
            '<path d="M 8.5,26 L 10,26.3" fill="none" stroke-width="1.2"/>')
RAM_HORN = thick("M 21,12 C 27.5,4.5 38,8 37,17.5 C 36,25.5 26,26.5 25.5,20 C 25.2,15.5 30.5,15 31,19", 7.5, 4.5)
OPTIONS["ram_neck"] = RAM_NECK + RAM_HEAD + RAM_HORN
OPTIONS["ram_knight_neck"] = KNIGHT_NECK.replace("M 22,10", "M 26,12") + RAM_HEAD + RAM_HORN
OPTIONS["ram_woolly"] = (RAM_NECK
    + '<path d="M 20,30 C 21.5,28.5 23.5,29 24,30.5 C 25.5,29 27.5,29.5 28,31 C 29.5,29.5 31.5,30 32,31.5 C 33.5,30.5 35.5,31 35.8,32.5 '
      'M 18,35 C 19.5,33.5 21.5,34 22,35.5 C 23.5,34 25.5,34.5 26,36 C 27.5,34.5 29.5,35 30,36.5 C 31.5,35.5 33.5,36 34,37.5" fill="none" stroke-width="1.1"/>'
    + RAM_HEAD + RAM_HORN)

for name, body in OPTIONS.items():
    io.open("white_%s.svg" % name, "w", encoding="utf-8", newline="").write(HEAD + body + TAIL)
print(len(OPTIONS), "options written")
