"""Round 23 (Mac's picks from round 22): the curled lyre with evenly spaced
strings; the maned wolf with a bigger head and fewer spikes down its neck; the
human Werewolf's coif with no face, with ears (and with fur and ears); and more
ghosts. White and black, Cburnett style.

Run from this folder:  python make_round23.py
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "round16"))
sys.path.insert(0, os.path.join(HERE, "..", "round22"))
import make_round16 as r16  # noqa: E402
import make_round22 as r22  # noqa: E402

shape, detail, circle, colours, inner = r16.shape, r16.detail, r16.circle, r16.colours, r16.inner


# --- Bard: the curled lyre, strings evenly spaced -----------------------------------------
def lyre_even(team):
    fill, line = colours(team)
    left = "M 15.5,33 C 10.5,28.5 9.5,21.5 12,15.5 C 13.6,11.6 11.6,7.6 8.6,8.6 C 6.6,9.4 7.2,12.4 9.4,12"
    right = "M 29.5,33 C 34.5,28.5 35.5,21.5 33,15.5 C 31.4,11.6 33.4,7.6 36.4,8.6 C 38.4,9.4 37.8,12.4 35.6,12"
    out = r22.band(left, team) + r22.band(right, team)
    out += r22.strings(team, (18, 21, 24, 27), 15.5, 32)
    out += r22.band("M 11.6,15 L 33.4,15", team, 4.2)
    out += shape("M 12.5,32 C 17,30.6 28,30.6 32.5,32 L 33.5,38.5 C 27,37.4 18,37.4 11.5,38.5 Z", fill)
    out += detail("M 16,34.8 C 20,34 25,34 29,34.8", inner(team), 0.9)
    return out


# --- Werewolf, wolf: bigger head, fewer spikes ------------------------------------------
MANE_FEW = ("M 22,10 C 25.5,10.3 28.4,11.4 30.6,13.2 L 29.6,15.4 L 33.8,17.8 L 32.6,20.2 "
            "L 36.4,24.2 L 35,26.6 L 37.6,31 C 37.9,33.4 38,36 38,39 L 15,39 C 15,30 25,32.5 23,18")


def wolf_big(team, head_scale):
    fill, line = colours(team)
    out = shape(MANE_FEW, fill)
    out += detail("M 28.4,17.6 L 26.6,20.2 M 31.6,23.4 L 29.8,26", inner(team), 0.9)
    # The head grows about the back of the neck, so it stays joined on.
    cx, cy = 24, 17
    k = head_scale
    head = r22.wolf_head(team)
    head = head.replace('stroke-width="1.5"', 'stroke-width="%.2f"' % (1.5 / k))
    out += '<g transform="translate(%.2f %.2f) scale(%s)">%s</g>' % (cx * (1 - k), cy * (1 - k), k, head)
    return out


# --- Werewolf, human: the coif with no face ---------------------------------------------
def plain_coif(team, behind=""):
    """The Man's coif just as it is (no face inside), with things behind it."""
    fill, line = colours(team)
    detail_colour = "#000" if team == "white" else "#fff"
    out = behind + shape(r22.COIF_FACE, fill) + shape(r22.COIF, fill)
    out += detail(r22.COIF_HEM, detail_colour, 1.1)
    out += detail("M 22.5,4.6 L 22.5,12.6", detail_colour, 1.1)
    out += detail(r22.COIF_TIES, detail_colour, 1.4)
    return out


def ears(team):
    fill, line = colours(team)
    mark = "#000" if team == "white" else "#fff"
    out = shape("M 14,13.6 L 11.6,3.6 L 19.4,8.4 Z", fill) + shape("M 31,13.6 L 33.4,3.6 L 25.6,8.4 Z", fill)
    return out + detail("M 13.6,9.8 L 12.6,5.6 L 16.4,8", mark, 0.9) + detail("M 31.4,9.8 L 32.4,5.6 L 28.6,8", mark, 0.9)


def fur(team):
    fill, line = colours(team)
    left = [(12.4, 12.6), (8.2, 14.2), (10.6, 16.6), (6.6, 19.4), (10, 21.6), (6.6, 25), (10.4, 26.6), (8, 30.4), (11.6, 30.6)]
    return shape(r22.poly(left), fill) + shape(r22.poly(r22.mirror_points(left)), fill)


def human_ears_plain(team):
    return plain_coif(team, ears(team))


def human_fur_ears_plain(team):
    return plain_coif(team, fur(team) + ears(team))


# --- More ghosts -------------------------------------------------------------------------
def ghost_sheet(team):
    """A bedsheet ghost: draped folds, eye holes, a ragged, uneven hem."""
    fill, line = colours(team)
    d = ("M 22.5,4.5 C 29.5,4.5 33.5,10 33.5,17 C 33.5,23 35,28 38,33 C 39,34.8 38.2,36.6 36.4,36.2 "
         "L 33.6,35.2 L 31.8,38.4 L 28.6,36.4 L 25.8,39.6 L 22.6,36.6 L 19.4,39.4 L 16.6,36.2 L 13.2,38.4 "
         "L 11.2,35.2 L 8.6,36.2 C 6.8,36.6 6,34.8 7,33 C 10,28 11.5,23 11.5,17 C 11.5,10 15.5,4.5 22.5,4.5 Z")
    out = shape(d, fill)
    out += detail("M 16.6,25 C 16.2,29 15.4,32.6 13.6,35.6 M 28.4,25 C 28.8,29 29.6,32.6 31.4,35.6 "
                  "M 22.5,27.5 L 22.5,34.6", inner(team), 1.0)
    eye = inner(team)
    out += shape("M 16.6,15.6 C 16.6,13.6 20.2,13.6 20.2,15.6 C 20.2,18.4 16.6,18.4 16.6,15.6 Z", eye, "none")
    out += shape("M 24.8,15.6 C 24.8,13.6 28.4,13.6 28.4,15.6 C 28.4,18.4 24.8,18.4 24.8,15.6 Z", eye, "none")
    return out


def ghost_spooky(team):
    """A menacing ghost: slanted eyes, a jagged grin, arms reaching out, a
    pointed, tattered hem."""
    fill, line = colours(team)
    arms = ("M 12,19.5 C 8.6,20.4 5.8,22.8 4.6,25.6 L 6.8,25.2 L 6.4,27.4 L 8.6,26.4 L 9.2,28.4 C 10.4,26 11.6,24.6 12.4,24 "
            "M 33,19.5 C 36.4,20.4 39.2,22.8 40.4,25.6 L 38.2,25.2 L 38.6,27.4 L 36.4,26.4 L 35.8,28.4 C 34.6,26 33.4,24.6 32.6,24")
    out = shape(arms, fill)
    d = ("M 11,38 L 11,18 C 11,10.5 16.2,5 22.5,5 C 28.8,5 34,10.5 34,18 L 34,38 "
         "L 30,34.6 L 26.6,39.6 L 22.5,35 L 18.4,39.6 L 15,34.6 Z")
    out += shape(d, fill)
    eye = inner(team)
    out += shape("M 15.4,14.6 L 21,17 L 20.2,19.6 C 17.6,19.8 15.6,18 15.4,14.6 Z", eye, "none")
    out += shape("M 29.6,14.6 L 24,17 L 24.8,19.6 C 27.4,19.8 29.4,18 29.6,14.6 Z", eye, "none")
    out += shape("M 16.6,23.6 C 20,25.6 25,25.6 28.4,23.6 C 27.6,27.6 25.4,29.4 22.5,29.4 C 19.6,29.4 17.4,27.6 16.6,23.6 Z", eye, "none")
    teeth = "#fff" if team == "white" else "#000"
    out += shape("M 18.6,24.7 L 19.6,26.8 L 20.6,25.1 L 21.6,27.2 L 22.5,25.3 L 23.4,27.2 L 24.4,25.1 L 25.4,26.8 L 26.4,24.7 "
                 "C 25,25.3 20,25.3 18.6,24.7 Z", teeth, "none")
    return out


def ghost_tongue(team):
    """A cheeky ghost: one eye winking, tongue out, leaning as it floats."""
    fill, line = colours(team)
    d = "M 9.5,38.5 L 9.5,19 C 9.5,10.5 15.5,5 22.5,5 C 29.5,5 35.5,10.5 35.5,19 L 35.5,38.5"
    d += r22.wavy_bottom(35.5, 9.5, 38.5, 35.2, 4) + " Z"
    out = '<g transform="rotate(-8 22.5 22)">' + shape(d, fill)
    eye = inner(team)
    out += '<ellipse cx="17.6" cy="17" rx="1.9" ry="2.9" fill="%s" stroke="none"/>' % eye
    out += detail("M 24.4,17.4 C 25.4,16 27.4,16 28.4,17.4", eye, 1.4)
    out += detail("M 17.6,23.6 C 20,25.8 25,25.8 27.4,23.6", eye, 1.3)
    tongue_fill = "#fff" if team == "white" else "#000"
    out += shape("M 21.4,24.9 L 21.4,27.6 C 21.4,29.6 25,29.6 25,27.6 L 25,24.8", tongue_fill, eye, 1.1)
    out += detail("M 23.2,25.4 L 23.2,27.4", eye, 0.8)
    return out + "</g>"


OPTIONS = {
    "lyre_even": lyre_even,
    "werewolf_wolf_big_head": lambda team: wolf_big(team, 1.12),
    "werewolf_wolf_bigger_head": lambda team: wolf_big(team, 1.2),
    "werewolf_human_ears_plain": human_ears_plain,
    "werewolf_human_fur_ears_plain": human_fur_ears_plain,
    "ghost_sheet": ghost_sheet,
    "ghost_spooky": ghost_spooky,
    "ghost_tongue": ghost_tongue,
}

if __name__ == "__main__":
    for name, draw in OPTIONS.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(OPTIONS) * 2, "files")
