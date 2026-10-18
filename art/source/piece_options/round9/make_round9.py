"""Round 9 art options: the eight new pieces (white versions only, for choosing).

Cburnett style: 45x45 canvas, 1.5 black outline, white fill. Run from this folder:
    python make_round9.py
"""
import io

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="#fff">'
TAIL = "</g></svg>\n"

def thick(d, outer=6.5, inner=3.5):
    """A thick white line with a black outline (horns, bones, bows)."""
    return ('<path d="%s" fill="none" stroke="#000" stroke-width="%s"/>' % (d, outer) +
            '<path d="%s" fill="none" stroke="#fff" stroke-width="%s"/>' % (d, inner))

OPTIONS = {}

# --- Wizard: pointed hat, no stars ---------------------------------------------------
OPTIONS["wizard_a"] = """
<ellipse cx="22.5" cy="36" rx="16" ry="4"/>
<path d="M 13.5,35 C 16,25 19,15 22,9.5 C 24,6 28.5,4.5 33,6.5 C 28.5,7.5 26.5,10 25.8,13.5 C 27.5,21 29.5,28 31.5,35 C 26,37 19,37 13.5,35 Z"/>
<path d="M 15,30.5 C 20,32.5 25.5,32.5 30.2,30.5" fill="none"/>
<path d="M 14.3,33 C 20,35 25.5,35 30.8,33" fill="none"/>
"""
OPTIONS["wizard_b"] = """
<path d="M 5,37 C 10,33.5 35,33.5 40,37 C 35,40.5 10,40.5 5,37 Z"/>
<path d="M 13,35.5 L 22.5,4.5 L 32,35.5 C 26,37.5 19,37.5 13,35.5 Z"/>
<path d="M 14.3,31 C 20,33 25,33 30.7,31 L 31.5,34 C 25.5,36 19.5,36 13.5,34 Z" fill="#fff"/>
<rect x="20" y="30.6" width="5" height="4.2" fill="#fff"/>
<path d="M 21.5,32 L 23.5,32 L 23.5,33.6 L 21.5,33.6 Z" fill="#000" stroke-width="0.8"/>
"""

# --- Rogue: hood -------------------------------------------------------------------------
OPTIONS["rogue_a"] = """
<path d="M 22.5,4 C 14,8 10.5,16 10.5,26 L 8,39.5 L 37,39.5 L 34.5,26 C 34.5,16 31,8 22.5,4 Z"/>
<path d="M 22.5,13.5 C 17,14.5 15,19.5 15,25 C 15,30 18,33.5 22.5,33.5 C 27,33.5 30,30 30,25 C 30,19.5 28,14.5 22.5,13.5 Z" fill="#000"/>
<path d="M 18.2,24 L 21,24.8 M 26.8,24 L 24,24.8" fill="none" stroke="#fff" stroke-width="1.6"/>
<path d="M 13,33 C 15,36 17,38 18,39.5 M 32,33 C 30,36 28,38 27,39.5" fill="none"/>
"""
OPTIONS["rogue_b"] = """
<path d="M 22.5,4 C 14,8 10.5,16 10.5,26 L 8,39.5 L 37,39.5 L 34.5,26 C 34.5,16 31,8 22.5,4 Z"/>
<path d="M 22.5,13.5 C 17,14.5 15,19.5 15,25 C 15,30 18,33.5 22.5,33.5 C 27,33.5 30,30 30,25 C 30,19.5 28,14.5 22.5,13.5 Z" fill="#000"/>
<path d="M 18.2,24 L 21,24.8 M 26.8,24 L 24,24.8" fill="none" stroke="#fff" stroke-width="1.6"/>
<path d="M 27,41 L 37,30 L 39,32 L 29,43 Z" />
<path d="M 35,27.5 L 41.5,34" fill="none" stroke-width="2.4"/>
<path d="M 38.5,31 L 42,27.5 C 43,26.5 44,27.5 43,28.5 L 39.8,32.2" />
"""

# --- Ram: head with curled horns ------------------------------------------------------
OPTIONS["ram_a"] = (
    '<path d="M 16.5,12 C 19,9 26,9 28.5,12 L 28,27 C 27.5,33.5 25.5,38.5 22.5,38.5 C 19.5,38.5 17.5,33.5 17,27 Z"/>'
    + thick("M 18,12 C 13,6 4.5,9 5,17 C 5.5,24 13.5,25.5 15,20 C 16,16 11.5,14.5 10.5,17.5")
    + thick("M 27,12 C 32,6 40.5,9 40,17 C 39.5,24 31.5,25.5 30,20 C 29,16 33.5,14.5 34.5,17.5")
    + '<circle cx="19.8" cy="20" r="1.4" fill="#000"/><circle cx="25.2" cy="20" r="1.4" fill="#000"/>'
    + '<path d="M 20.5,34.5 L 21.5,35.5 M 24.5,34.5 L 23.5,35.5" fill="none" stroke-width="1.2"/>'
)
OPTIONS["ram_b"] = (
    '<path d="M 33,39.5 L 33,27 C 33,19 29,13.5 22,12 C 16.5,11 12,13 9,17 C 7,20 7.5,23.5 10,24.5 C 12.5,25.5 15.5,24.5 17.5,23.5 C 19,28 19,34 16.5,39.5 Z"/>'
    + thick("M 20,12.5 C 26,5.5 35.5,9 34.5,18 C 33.5,26 24.5,27 24,20.5 C 23.7,16.5 28.5,16 28.8,19.5", 7, 4)
    + '<circle cx="15.5" cy="17" r="1.4" fill="#000"/>'
    + '<path d="M 9.5,21.5 L 11,21.8" fill="none" stroke-width="1.2"/>'
)

# --- Archer: drawn bow and arrow --------------------------------------------------------
OPTIONS["archer_a"] = (
    thick("M 15,4.5 C 27,11 27,34 15,40.5", 5.5, 2.8)
    + '<path d="M 15,4.5 L 32,22.5 L 15,40.5" fill="none" stroke-width="1"/>'
    + '<path d="M 6.5,22.5 L 35,22.5" fill="none" stroke-width="1.8"/>'
    + '<path d="M 3,22.5 L 9,19.5 L 9,25.5 Z"/>'
    + '<path d="M 33,22.5 L 38,18.5 L 41,18.5 L 36.5,22.5 L 41,26.5 L 38,26.5 Z"/>'
)
OPTIONS["archer_b"] = (
    '<path d="M 15,40.5 L 30,40.5 L 28,22 L 17,22 Z"/>'
    + '<path d="M 17,25.5 L 28,25.5" fill="none"/>'
    + '<path d="M 19,22 L 15,5.5 M 22.5,22 L 22.5,4.5 M 26,22 L 30,5.5" fill="none" stroke-width="1.6"/>'
    + '<path d="M 15,5.5 L 12.5,10 L 16.7,9.5 Z M 22.5,4.5 L 20.5,9 L 24.5,9 Z M 30,5.5 L 28.3,9.5 L 32.5,10 Z"/>'
    + '<path d="M 20,32 L 25,32" fill="none"/>'
)

# --- Berserker: horned helmet, club, armour, sword ---------------------------------------
OPTIONS["berserker_helmet"] = (
    thick("M 13,23 C 7,21 4,15 5,8", 6, 3)
    + thick("M 32,23 C 38,21 41,15 40,8", 6, 3)
    + '<path d="M 10.5,30 C 10.5,18 15.5,12 22.5,12 C 29.5,12 34.5,18 34.5,30 Z"/>'
    + '<path d="M 9,30 L 36,30 L 36,34 L 9,34 Z"/>'
    + '<path d="M 20.5,30 L 24.5,30 L 24,40 L 21,40 Z"/>'
    + '<path d="M 22.5,13 L 22.5,29" fill="none"/>'
)
OPTIONS["berserker_club"] = (
    '<path d="M 20,40.5 L 25,40.5 L 26,24 C 31,23 33,17 31.5,11 C 30,5.5 24.5,3.5 22.5,3.5 C 20.5,3.5 15,5.5 13.5,11 C 12,17 14,23 19,24 Z"/>'
    + '<path d="M 13.2,10 L 10,8.5 L 13.5,13.5 M 31.8,10 L 35,8.5 L 31.5,13.5 M 14,19 L 10.5,20 L 15.3,21.5 M 31,19 L 34.5,20 L 29.7,21.5 M 22.5,3.5 L 22.5,0.8 L 24.5,4"/>'
    + '<path d="M 20.3,33 L 24.7,33 M 20.5,36.5 L 24.5,36.5" fill="none"/>'
)
OPTIONS["berserker_armour"] = (
    '<path d="M 7,14 C 10,10 15,9 17.5,10 C 19,13.5 26,13.5 27.5,10 C 30,9 35,10 38,14 L 35,21 L 33,20 L 32.5,36 C 26,40 19,40 12.5,36 L 12,20 L 10,21 Z"/>'
    + '<path d="M 22.5,13 L 22.5,37.5 M 15,24 C 19,26 26,26 30,24 M 15,30.5 C 19,32.5 26,32.5 30,30.5" fill="none"/>'
    + '<path d="M 7,14 L 10,21 M 38,14 L 35,21" fill="none"/>'
)
OPTIONS["berserker_sword"] = (
    '<path d="M 22.5,2.5 L 26,8 L 26,30 L 19,30 L 19,8 Z"/>'
    + '<path d="M 22.5,8 L 22.5,28.5" fill="none" stroke-width="1"/>'
    + '<path d="M 11,30 L 34,30 C 35,31.5 35,32.5 34,34 L 11,34 C 10,32.5 10,31.5 11,30 Z"/>'
    + '<path d="M 20.5,34 L 24.5,34 L 24.5,39 L 20.5,39 Z"/>'
    + '<circle cx="22.5" cy="41" r="2.5"/>'
)

# --- Chariot: wheel and chariot front ---------------------------------------------------
OPTIONS["chariot_a"] = (
    '<path d="M 9,29 L 9,14 C 9,10 12,8 16,8 L 37,8 C 39,8 39.5,10 38,11.5 C 33,15 31,22 31,29 Z"/>'
    + '<path d="M 13,12.5 L 34,12.5" fill="none"/>'
    + '<path d="M 31,26 L 43,26" fill="none" stroke-width="2.2"/>'
    + '<circle cx="18" cy="31" r="9"/><circle cx="18" cy="31" r="2"/>'
    + '<path d="M 18,22 L 18,40 M 9,31 L 27,31 M 11.6,24.6 L 24.4,37.4 M 24.4,24.6 L 11.6,37.4" fill="none" stroke-width="1.1"/>'
)
OPTIONS["chariot_b"] = (
    '<path d="M 12,30 L 10.5,11 C 15,7 30,7 34.5,11 L 33,30 Z"/>'
    + '<path d="M 14.5,14 C 18.5,11.5 26.5,11.5 30.5,14 M 15,22 L 30,22" fill="none"/>'
    + '<path d="M 22.5,22 L 22.5,40" fill="none" stroke-width="2.2"/>'
    + '<ellipse cx="8" cy="31" rx="3.3" ry="9"/><ellipse cx="37" cy="31" rx="3.3" ry="9"/>'
    + '<path d="M 8,22 L 8,40 M 37,22 L 37,40" fill="none" stroke-width="1"/>'
    + '<path d="M 11.3,31 L 33.7,31" fill="none" stroke-width="2"/>'
)

# --- Cavalry: lance with pennant; another horse ------------------------------------------
OPTIONS["cavalry_lance"] = (
    '<path d="M 9,41 L 29,8" fill="none" stroke="#000" stroke-width="4.5"/>'
    + '<path d="M 9,41 L 29,8" fill="none" stroke="#fff" stroke-width="2"/>'
    + '<path d="M 27,7 L 33,1.5 L 31.5,9.5 Z"/>'
    + '<path d="M 26.2,13 L 41,15.5 L 35,19.5 L 40,24 L 21.5,21 Z"/>'
    + '<path d="M 9.5,33.5 L 16,37.5" fill="none" stroke-width="2.4"/>'
)
KNIGHT = ('<path d="M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"/>'
          '<path d="M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9.958,30.06 12.41,27.96 11,28 C 10,28 11.19,29.23 10,30 C 9,30 5.997,31 6,26 C 6,24 12,14 12,14 C 12,14 13.89,12.1 14,10.5 C 13.27,9.506 13.5,8.5 13.5,7.5 C 14.5,6.5 16.5,10 16.5,10 L 18.5,10 C 18.5,10 19.28,8.008 21,7 C 22,7 22,10 22,10"/>'
          '<circle cx="9" cy="25.5" r="0.5" fill="#000"/>'
          '<path d="M 15,15.5 A 0.5,1.5 0 1 1 14,15.5 A 0.5,1.5 0 1 1 15,15.5 Z" transform="matrix(0.866,0.5,-0.5,0.866,9.693,-5.173)" fill="#000"/>')
OPTIONS["cavalry_horse"] = (
    '<g transform="translate(45,0) scale(-1,1)">' + KNIGHT
    + '<path d="M 20.5,8.5 C 17.5,6 17.5,1.5 21,1 C 24.5,0.5 27.5,2.5 27,5 C 26.5,6.5 24.5,6.8 23,8.8 Z" />'
    + '<path d="M 21,3 C 22.5,3.5 23.5,5 23.2,7.5" fill="none" stroke-width="1"/>'
    + '<path d="M 11,17.5 L 17.5,20 L 13.5,26" fill="none" stroke-width="1.2"/>'
    + '<path d="M 18,31 C 22,33 27,33.5 31,33" fill="none"/></g>'
)

# --- Necromancer: skull; hooded skull ----------------------------------------------------
SKULL = ('<path d="M 11,19.5 C 11,10.5 16,5.5 22.5,5.5 C 29,5.5 34,10.5 34,19.5 C 34,24.5 31.5,27 30,28 L 30,33.5 L 15,33.5 L 15,28 C 13.5,27 11,24.5 11,19.5 Z"/>'
         '<path d="M 14.3,20 C 14.3,17 21,17 21,20.5 C 21,23.5 14.3,23.5 14.3,20 Z" fill="#000"/>'
         '<path d="M 24,20.5 C 24,17 30.7,17 30.7,20 C 30.7,23.5 24,23.5 24,20.5 Z" fill="#000"/>'
         '<path d="M 22.5,23.5 L 20.8,27.5 L 24.2,27.5 Z" fill="#000" stroke-width="0.8"/>'
         '<path d="M 18.5,30 L 18.5,33.5 M 22.5,30 L 22.5,33.5 M 26.5,30 L 26.5,33.5" fill="none" stroke-width="1.2"/>')
OPTIONS["necromancer_skull"] = SKULL + '<path d="M 15,33.5 L 15,38 C 20,40 25,40 30,38 L 30,33.5" /><path d="M 18.5,36.5 L 26.5,36.5" fill="none" stroke-width="1"/>'
OPTIONS["necromancer_hooded"] = (
    '<path d="M 22.5,3 C 13,7 9.5,16 9.5,26 L 7,40.5 L 38,40.5 L 35.5,26 C 35.5,16 32,7 22.5,3 Z"/>'
    + '<path d="M 22.5,11 C 16.5,12 13.5,17 13.5,24 C 13.5,31 17,36.5 22.5,36.5 C 28,36.5 31.5,31 31.5,24 C 31.5,17 28.5,12 22.5,11 Z" fill="#000"/>'
    + '<path d="M 16.5,22 C 16.5,16.5 19.5,14 22.5,14 C 25.5,14 28.5,16.5 28.5,22 C 28.5,25 27,26.5 26.2,27 L 26.2,31.5 L 18.8,31.5 L 18.8,27 C 18,26.5 16.5,25 16.5,22 Z" stroke-width="1"/>'
    + '<path d="M 18.3,22 C 18.3,20 21.8,20 21.8,22.2 C 21.8,24 18.3,24 18.3,22 Z M 23.2,22.2 C 23.2,20 26.7,20 26.7,22 C 26.7,24 23.2,24 23.2,22.2 Z" fill="#000" stroke-width="0.6"/>'
    + '<path d="M 22.5,24.5 L 21.6,26.6 L 23.4,26.6 Z" fill="#000" stroke-width="0.5"/>'
    + '<path d="M 20.5,28.5 L 20.5,31.5 M 22.5,28.5 L 22.5,31.5 M 24.5,28.5 L 24.5,31.5" fill="none" stroke-width="0.8"/>'
)

for name, body in OPTIONS.items():
    io.open("white_%s.svg" % name, "w", encoding="utf-8", newline="").write(HEAD + body + TAIL)
print(len(OPTIONS), "options written")
