"""Round 22: options for the third batch of new pieces (Oct 2026): the Ghost
(classic ghost shapes), the Bard (lyres) and the Werewolf (a human form built on
the Man's coif, with fangs, fur or ears, and a wolf form built on the Cburnett
knight's body, like the Ram). White and black, Cburnett style.

Run from this folder:  python make_round22.py
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "round16"))
import make_round16 as r16  # noqa: E402

shape, detail, circle, colours, inner = r16.shape, r16.detail, r16.circle, r16.colours, r16.inner


def mirror_points(points):
    return [(45 - x, y) for x, y in points]


def poly(points):
    return "M " + " L ".join("%.2f,%.2f" % p for p in points) + " Z"


# --- Ghosts ------------------------------------------------------------------------------
def wavy_bottom(right, left, y_tip, y_dip, lobes):
    """A scalloped hem from x=right to x=left: `lobes` rounded waves."""
    d = ""
    step = (right - left) / lobes
    for i in range(lobes):
        x0 = right - i * step
        x1 = x0 - step
        mid = (x0 + x1) / 2
        d += " C %.2f,%.2f %.2f,%.2f %.2f,%.2f" % (x0 - step * 0.15, y_tip - 2.6, mid + step * 0.25, y_dip, mid, y_dip)
        d += " C %.2f,%.2f %.2f,%.2f %.2f,%.2f" % (mid - step * 0.25, y_dip, x1 + step * 0.15, y_tip - 2.6, x1, y_tip)
    return d


def ghost_face(team, cx=22.5, y=17.5, mouth=True):
    eye = inner(team)
    out = ('<ellipse cx="%s" cy="%s" rx="1.9" ry="2.9" fill="%s" stroke="none"/>' % (cx - 4, y, eye)
           + '<ellipse cx="%s" cy="%s" rx="1.9" ry="2.9" fill="%s" stroke="none"/>' % (cx + 4, y, eye))
    if mouth:
        out += '<ellipse cx="%s" cy="%s" rx="1.8" ry="2.3" fill="%s" stroke="none"/>' % (cx, y + 7.2, eye)
    return out


def ghost_round(team):
    """The classic ghost: a dome head and a wavy hem, big oval eyes, an 'oo' mouth."""
    fill, line = colours(team)
    d = "M 9.5,38.5 L 9.5,19 C 9.5,10.5 15.5,5 22.5,5 C 29.5,5 35.5,10.5 35.5,19 L 35.5,38.5"
    d += wavy_bottom(35.5, 9.5, 38.5, 35.2, 4) + " Z"
    return shape(d, fill) + ghost_face(team)


def ghost_arms(team):
    """A ghost with little arms raised, waving, and a wavy hem."""
    fill, line = colours(team)
    arm = "M 12.5,21 C 9,20.5 6,18 4.8,14.6 C 4.6,13.6 5.6,13.2 6.4,13.8 C 8.4,15.4 10.6,16.4 12.8,16.4"
    arm_r = "M 32.5,21 C 36,20.5 39,18 40.2,14.6 C 40.4,13.6 39.4,13.2 38.6,13.8 C 36.6,15.4 34.4,16.4 32.2,16.4"
    out = shape(arm, fill) + shape(arm_r, fill)
    d = "M 11,38.5 L 11,19 C 11,11 16.2,5.5 22.5,5.5 C 28.8,5.5 34,11 34,19 L 34,38.5"
    d += wavy_bottom(34, 11, 38.5, 35.4, 4) + " Z"
    return out + shape(d, fill) + ghost_face(team, y=17)


def ghost_wisp(team):
    """A ghost drifting along, its body thinning into a tail that curls up."""
    fill, line = colours(team)
    d = ("M 20,5 C 27.5,5 32,10.5 32,18 C 32,24.5 30.5,28.5 33.5,32.5 C 35.5,35 38.6,35 40.2,32.6 "
         "C 40.4,37.6 36,40.6 30.5,39.8 C 25,39 21.5,35.6 16.5,36 C 13.5,36.2 11.2,37.4 9.2,39 "
         "C 9,35.2 10.6,32 11.4,29 C 12.2,26 8.5,23.5 8.5,17.5 C 8.5,10.5 13.5,5 20,5 Z")
    out = shape(d, fill) + ghost_face(team, cx=20.2, y=16.5)
    out += detail("M 26,31 C 27.5,34.5 30.5,36.8 34.5,37", inner(team), 1.0)
    return out


# --- Lyres -------------------------------------------------------------------------------
def band(d, team, width=5.0):
    """A thick outlined bar following `d` (black outline, filled inside); on a black
    piece, a thin white line runs down its middle instead."""
    fill, line = colours(team)
    out = '<path d="%s" fill="none" stroke="#000" stroke-width="%s"/>' % (d, width)
    if team == "white":
        out += '<path d="%s" fill="none" stroke="#fff" stroke-width="%s"/>' % (d, width - 3.0)
    else:
        out += '<path d="%s" fill="none" stroke="#fff" stroke-width="0.9"/>' % d
    return out


def strings(team, xs, top, bottom):
    return detail(" ".join("M %s,%s L %s,%s" % (x, top, x, bottom) for x in xs), inner(team), 0.8)


def lyre_curl(team):
    """A classic lyre: two arms rising from the sound box and curling outwards at
    the top, a crossbar with pegs, four strings."""
    fill, line = colours(team)
    left = "M 15.5,33 C 10.5,28.5 9.5,21.5 12,15.5 C 13.6,11.6 11.6,7.6 8.6,8.6 C 6.6,9.4 7.2,12.4 9.4,12"
    right = "M 29.5,33 C 34.5,28.5 35.5,21.5 33,15.5 C 31.4,11.6 33.4,7.6 36.4,8.6 C 38.4,9.4 37.8,12.4 35.6,12"
    out = band(left, team) + band(right, team)
    out += strings(team, (18.6, 21.5, 23.5, 26.4), 15.5, 32)
    out += band("M 11.6,15 L 33.4,15", team, 4.2)
    box = "M 12.5,32 C 17,30.6 28,30.6 32.5,32 L 33.5,38.5 C 27,37.4 18,37.4 11.5,38.5 Z"
    out += shape(box, fill)
    out += detail("M 16,34.8 C 20,34 25,34 29,34.8", inner(team), 0.9)
    return out


def lyre_shell(team):
    """A round-bodied lyre: a rounded sound box like a tortoise shell, horn-like
    arms curving up from it, a crossbar and strings down to a bridge."""
    fill, line = colours(team)
    left = "M 15,30 C 10.5,25.5 8.6,18.5 10.8,12.6 C 12,9.4 14.6,7.6 17,8.4"
    right = "M 30,30 C 34.5,25.5 36.4,18.5 34.2,12.6 C 33,9.4 30.4,7.6 28,8.4"
    out = band(left, team) + band(right, team)
    body = "M 22.5,25 C 30.5,25 34.5,29 34.5,33 C 34.5,37 29.5,39.5 22.5,39.5 C 15.5,39.5 10.5,37 10.5,33 C 10.5,29 14.5,25 22.5,25 Z"
    out += shape(body, fill)
    out += strings(team, (18.8, 21.5, 23.5, 26.2), 12, 33.4)
    out += band("M 10.6,12.2 L 34.4,12.2", team, 4.2)
    out += shape("M 17.4,33.2 L 27.6,33.2 L 27.6,35.2 L 17.4,35.2 Z", fill, "#000", 1.1)
    if team == "black":
        out += detail("M 13.6,30.4 C 16,28 19,27.2 22.5,27.2 C 26,27.2 29,28 31.4,30.4", "#fff", 0.9)
    return out


def lyre_stand(team):
    """The curled lyre standing on a base like the other pieces' bases."""
    fill, line = colours(team)
    left = "M 16,30.5 C 11.5,26.5 10.5,20.5 12.6,15.5 C 14,12.2 12.2,8.8 9.6,9.6 C 7.8,10.2 8.3,12.8 10.2,12.5"
    right = "M 29,30.5 C 33.5,26.5 34.5,20.5 32.4,15.5 C 31,12.2 32.8,8.8 35.4,9.6 C 37.2,10.2 36.7,12.8 34.8,12.5"
    out = band(left, team) + band(right, team)
    out += strings(team, (19, 21.6, 23.4, 26), 15, 30)
    out += band("M 12.2,14.8 L 32.8,14.8", team, 4.2)
    out += shape("M 13.5,29.6 C 17.5,28.6 27.5,28.6 31.5,29.6 L 32.2,33.6 C 26.5,32.8 18.5,32.8 12.8,33.6 Z", fill)
    out += shape(r16.BASE_TOP, fill) + shape(r16.BASE_BOTTOM, fill)
    if team == "black":
        out += detail("M 12.6,36.2 C 18,35 27,35 32.4,36.2", "#fff", 0.9)
    return out


# --- Werewolf, human form: the Man's coif ------------------------------------------------
COIF_FACE = ("M 16.2,31 L 17.4,20.2 C 17.6,15.8 20,13.6 22.5,13.6 C 25,13.6 27.4,15.8 27.6,20.2 "
             "L 28.8,31 C 24.8,32.2 20.2,32.2 16.2,31 Z")
COIF = ("M 22.5,3.6 C 19.6,5.4 13,10.6 10.8,17.8 C 9.8,21.6 10.2,26.4 11.2,30 L 12.6,34.6 L 15.6,31 L 18,28 "
        "L 18,20.6 C 18,16.4 20,14.2 22.5,14.2 C 25,14.2 27,16.4 27,20.6 L 27,28 L 29.4,31 L 32.4,34.6 "
        "L 33.8,30 C 34.8,26.4 35.2,21.6 34.2,17.8 C 31.4,10.6 25.4,5.4 22.5,3.6 Z")
COIF_HEM = "M 16,28.6 L 16,20.4 C 16,15 19,12.2 22.5,12.2 C 26,12.2 29,15 29,20.4 L 29,28.6"
COIF_TIES = "M 12.6,34.6 C 12.4,36.4 12.8,38.2 13.4,39.6 M 32.4,34.6 C 32.6,36.4 32.2,38.2 31.6,39.6"


def coif_with_face(team, behind=""):
    """The Man's coif with a shadowed face inside: two glinting eyes and fangs."""
    fill, line = colours(team)
    detail_colour = "#000" if team == "white" else "#fff"
    out = behind
    out += shape(COIF_FACE, "#000")
    out += shape(COIF, fill)
    out += detail(COIF_HEM, detail_colour, 1.1)
    out += detail("M 22.5,4.6 L 22.5,12.6", detail_colour, 1.1)
    out += detail(COIF_TIES, detail_colour, 1.4)
    if team == "black":
        out += detail("M 18.2,27.6 L 18.2,20.6 C 18.2,16.6 20.1,14.6 22.5,14.6 C 24.9,14.6 26.8,16.6 26.8,20.6 L 26.8,27.6", "#fff", 0.8)
    # Slanted eyes and two fangs, white in the dark face.
    out += shape("M 19.2,19.6 L 21.6,20.8 L 19.8,21.4 Z", "#fff", "none")
    out += shape("M 25.8,19.6 L 23.4,20.8 L 25.2,21.4 Z", "#fff", "none")
    out += shape("M 19.6,25.6 L 20.5,28.6 L 21.4,25.6 Z M 23.6,25.6 L 24.5,28.6 L 25.4,25.6 Z", "#fff", "none")
    out += detail("M 19,25.6 C 21,26.2 24,26.2 26,25.6", "#fff", 0.8)
    return out


def human_fangs(team):
    """The coif, its face in shadow with glinting eyes and fangs."""
    return coif_with_face(team)


def human_fur(team):
    """The coif with tufts of fur bristling out at the sides."""
    fill, line = colours(team)
    left = [(12.4, 12.6), (8.2, 14.2), (10.6, 16.6), (6.6, 19.4), (10, 21.6), (6.6, 25), (10.4, 26.6), (8, 30.4), (11.6, 30.6)]
    fur = shape(poly(left), fill) + shape(poly(mirror_points(left)), fill)
    return coif_with_face(team, fur)


def human_ears(team):
    """The coif with a wolf's pointed ears pushing up through it."""
    fill, line = colours(team)
    ears = shape("M 14,13.6 L 11.6,3.6 L 19.4,8.4 Z", fill) + shape("M 31,13.6 L 33.4,3.6 L 25.6,8.4 Z", fill)
    if team == "white":
        ears += detail("M 13.6,9.8 L 12.6,5.6 L 16.4,8", "#000", 0.9) + detail("M 31.4,9.8 L 32.4,5.6 L 28.6,8", "#000", 0.9)
    else:
        ears += detail("M 13.6,9.8 L 12.6,5.6 L 16.4,8", "#fff", 0.9) + detail("M 31.4,9.8 L 32.4,5.6 L 28.6,8", "#fff", 0.9)
    return coif_with_face(team, ears)


# --- Werewolf, wolf form: the Cburnett knight's body with a wolf's head -------------------
KNIGHT_BODY = "M 22,10 C 32.5,11 38.5,18 38,39 L 15,39 C 15,30 25,32.5 23,18"
MANE_BODY = ("M 22,10 L 26.4,10.4 L 25.2,12.2 L 30,12.8 L 28.6,14.6 L 33.2,16.4 L 31.6,18 L 35.6,21 "
             "L 33.8,22.6 L 37,26.6 L 35.2,28 L 37.8,32.4 L 36.4,33.8 L 38,39 L 15,39 C 15,30 25,32.5 23,18")
# Black knight's white highlight down its back (from Chess_ndt45).
BLACK_BACK = ("M 24.55,10.4 L 24.1,11.85 L 24.6,12 C 27.75,13 30.25,14.49 32.5,18.75 C 34.75,23.01 35.75,29.06 35.25,39 "
              "L 35.2,39.5 L 37.45,39.5 L 37.5,39 C 38,28.94 36.62,22.15 34.25,17.66 C 31.88,13.17 28.46,11.02 25.06,10.5 L 24.55,10.4 Z")
WOLF_HEAD = ("M 24,18 C 23.6,21.4 20.2,24 17.2,25.6 L 10.4,28.6 C 9.4,29 8.6,28.4 9,27.4 L 15,23.4 "
             "L 6.6,22.2 C 5,22 4.6,19.8 6.2,19.4 L 12.6,17.2 C 13.4,15.4 14.4,14.2 15.6,13.2 "
             "L 15.4,5.8 L 19.4,10.2 L 21.6,5.6 L 23.6,10.4")


def wolf_head(team):
    fill, line = colours(team)
    mark = inner(team)
    out = shape(WOLF_HEAD, fill)
    # Fangs in the open mouth, the eye, the nose.
    out += shape("M 8.4,22.4 L 9.2,24.4 L 10,22.6 Z M 11.4,26.6 L 11.8,24.6 L 12.8,25.8 Z", "#fff", "#000", 0.7)
    out += shape("M 14.4,15.6 L 18,15.2 L 15.6,16.8 Z", mark, "none")
    out += circle(6.2, 20.6, 0.7, mark, "none")
    # Inside each ear.
    out += detail("M 16.4,11.2 L 16.3,8.4 M 20.4,10.2 L 21.4,8", mark, 0.9)
    return out


def wolf_knight(team):
    """The knight's body with a wolf's head: pointed ears, long snout, open jaws."""
    fill, line = colours(team)
    out = shape(KNIGHT_BODY, fill)
    if team == "black":
        out += shape(BLACK_BACK, "#fff", "none")
    return out + wolf_head(team)


def wolf_mane(team):
    """The wolf with a shaggy mane bristling down the back of its neck."""
    fill, line = colours(team)
    out = shape(MANE_BODY, fill)
    out += detail("M 27.6,17.2 L 25.8,19.6 M 31,22 L 29,24.4 M 33.4,27.6 L 31.6,30", inner(team), 0.9)
    return out + wolf_head(team)


def wolf_howl(team):
    """The wolf howling: its head thrown back, snout pointing up."""
    fill, line = colours(team)
    out = shape(KNIGHT_BODY, fill)
    if team == "black":
        out += shape(BLACK_BACK, "#fff", "none")
    return out + '<g transform="rotate(32 23 17)">%s</g>' % wolf_head(team)


OPTIONS = {
    "ghost_round": ghost_round,
    "ghost_arms": ghost_arms,
    "ghost_wisp": ghost_wisp,
    "lyre_curl": lyre_curl,
    "lyre_shell": lyre_shell,
    "lyre_stand": lyre_stand,
    "werewolf_human_fangs": human_fangs,
    "werewolf_human_fur": human_fur,
    "werewolf_human_ears": human_ears,
    "werewolf_wolf_knight": wolf_knight,
    "werewolf_wolf_mane": wolf_mane,
    "werewolf_wolf_howl": wolf_howl,
}

if __name__ == "__main__":
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
