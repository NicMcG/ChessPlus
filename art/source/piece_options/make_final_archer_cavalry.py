"""Final Archer (round 11 archer_white_arrow) and Cavalry (round 11
cavalry_lance_behind), white and black, written to ../pieces/.

Black versions follow the Cburnett black pieces: black shapes with thin white
detail lines.  Run from this folder:  python make_final_archer_cavalry.py
"""
import io

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="#fff">'
TAIL = "</g></svg>\n"

def line(d, width, color):
    return '<path d="%s" fill="none" stroke="%s" stroke-width="%s"/>' % (d, color, width)

def mirror(body):
    return '<g transform="translate(45,0) scale(-1,1)">%s</g>' % body

# --- Archer -------------------------------------------------------------------------
BOW = "M 8,15 C 22,1 44,23 30,37"
STRING = "M 8,15 L 30,37"
SHAFT = "M 7.5,37.5 L 36,9"
HEAD_TIP = "M 41.5,3.5 L 38.5,13.5 L 35.5,11 L 34,9.5 L 31.5,6.5 Z"
FLETCH = "M 7.5,37.5 L 4,35.5 L 6,31 L 12,33 Z M 7.5,37.5 L 9.5,41 L 14,39 L 12,33 Z"

white_archer = (line(BOW, 6.5, "#000") + line(BOW, 3, "#fff")
                + line(STRING, 1.6, "#000")
                + line(SHAFT, 4.6, "#000") + line(SHAFT, 1.8, "#fff")
                + '<path d="%s"/>' % HEAD_TIP + '<path d="%s"/>' % FLETCH)
black_archer = (line(BOW, 6.5, "#000") + line("M 9.5,14.5 C 22,3 41,22 30.5,35", 1, "#fff")
                + line(STRING, 1.6, "#000")
                + line(SHAFT, 4.6, "#000") + line("M 11,34 L 34,11", 1, "#fff")
                + '<path d="%s" fill="#000"/>' % HEAD_TIP + '<path d="%s" fill="#000"/>' % FLETCH)

# --- Cavalry: horse facing right (the knight mirrored), lance behind with a pennant ----
LANCE = "M 40,41 L 12,4"
LANCE_TIP = "M 13.5,2 L 9,0.5 L 10,5.5 Z"
PENNANT = "M 16.5,8.5 L 4,9 L 8.5,12.5 L 4,16 L 20,14 Z"
NECK = "M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"
HEAD_PATH = ("M 24,18 C 24.38,20.91 18.45,25.37 16,27 C 13,29 13.18,31.34 11,31 C 9.958,30.06 12.41,27.96 11,28 "
             "C 10,28 11.19,29.23 10,30 C 9,30 5.997,31 6,26 C 6,24 12,14 12,14 C 12,14 13.89,12.1 14,10.5 "
             "C 13.27,9.506 13.5,8.5 13.5,7.5 C 14.5,6.5 16.5,10 16.5,10 L 18.5,10 C 18.5,10 19.28,8.008 21,7 C 22,7 22,10 22,10")
NOSTRIL = "M 9.5,25.5 A 0.5,0.5 0 1 1 8.5,25.5 A 0.5,0.5 0 1 1 9.5,25.5 Z"
EYE = '<path d="M 15,15.5 A 0.5,1.5 0 1 1 14,15.5 A 0.5,1.5 0 1 1 15,15.5 Z" transform="matrix(0.866,0.5,-0.5,0.866,9.693,-5.173)" fill="%s" stroke="%s"/>'
# The white line along the back of the black knight's neck (from the Cburnett set).
MANE_EDGE = ("M 24.55,10.4 L 24.1,11.85 L 24.6,12 C 27.75,13 30.25,14.49 32.5,18.75 C 34.75,23.01 35.75,29.06 35.25,39 "
             "L 35.2,39.5 L 37.45,39.5 L 37.5,39 C 38,28.94 36.62,22.15 34.25,17.66 C 31.88,13.17 28.46,11.02 25.06,10.5 L 24.55,10.4 Z")

white_horse = ('<path d="%s"/>' % NECK + '<path d="%s"/>' % HEAD_PATH
               + '<path d="%s" fill="#000"/>' % NOSTRIL + EYE % ("#000", "#000"))
black_horse = ('<path d="%s" fill="#000"/>' % NECK + '<path d="%s" fill="#000"/>' % HEAD_PATH
               + '<path d="%s" fill="#fff" stroke="#fff"/>' % NOSTRIL + EYE % ("#fff", "#fff")
               + '<path d="%s" fill="#fff" stroke="none"/>' % MANE_EDGE)

white_cavalry = (line(LANCE, 4.5, "#000") + line(LANCE, 2, "#fff")
                 + '<path d="%s"/>' % LANCE_TIP + '<path d="%s"/>' % PENNANT + mirror(white_horse))
black_cavalry = (line(LANCE, 4.5, "#000") + line("M 37.5,37.7 L 14,6.6", 0.9, "#fff")
                 + '<path d="%s" fill="#000"/>' % LANCE_TIP
                 + '<path d="%s" fill="#000"/>' % PENNANT
                 + line("M 15.5,11 L 9,11.2", 0.9, "#fff")
                 + mirror(black_horse))

for name, body in {"white_archer": white_archer, "black_archer": black_archer,
                   "white_cavalry": white_cavalry, "black_cavalry": black_cavalry}.items():
    io.open("../pieces/%s.svg" % name, "w", encoding="utf-8", newline="").write(HEAD + body + TAIL)
print("written")
