"""Final Jester (round 20 jester_three's points and bells, standing on the
Cburnett king's base instead of the band (Mac, Oct 2026); the black one gets
white lines down each point and across the base) and Parapet
(round 20 parapet_wall; the black one gets a white line where the wall meets its
base). White and black, written to ../pieces/.

Run from this folder:  python make_final_jester_parapet.py
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "round16"))
sys.path.insert(0, os.path.join(HERE, "round20"))
import make_round16 as r16  # noqa: E402
import make_round20 as r20  # noqa: E402


# The Cburnett king's base (Mac, Oct 2026: the cap stands on the king crown's
# base): a curved bottom edge and two curved lines across it.
KING_BASE = "M 12.5,37 C 18,40.5 27,40.5 32.5,37 L 32.5,30 C 27,27 18,27 12.5,30 Z"
KING_BASE_LINES = "M 12.5,33.5 C 18,30.5 27,30.5 32.5,33.5 M 12.5,37 C 18,34 27,34 32.5,37"


def jester(team):
    fill, line = r16.colours(team)
    lines = "#000" if team == "white" else "#fff"
    left = "M 13,30 C 11,23 8,19 4.5,17.5 C 9,15.5 15,17.5 18,25 Z"
    middle = "M 17,28 C 17,20 19,13 22.5,8.5 C 26,13 28,20 28,28 Z"
    right = "M 32,30 C 34,23 37,19 40.5,17.5 C 36,15.5 30,17.5 27,25 Z"
    out = r16.shape(left, fill) + r16.shape(right, fill) + r16.shape(middle, fill)
    out += r16.circle(4.2, 17.4, 2.3, fill) + r16.circle(22.5, 7.2, 2.3, fill) + r16.circle(40.8, 17.4, 2.3, fill)
    if team == "black":
        out += r16.detail("M 13.4,27.6 C 11.6,23 9.2,20.2 6.6,18.6 M 22.5,11 L 22.5,26.2 "
                          "M 31.6,27.6 C 33.4,23 35.8,20.2 38.4,18.6", "#fff", 0.9)
    out += r16.shape(KING_BASE, fill)
    out += r16.detail(KING_BASE_LINES, lines, 1.5 if team == "white" else 1.2)
    return out


def parapet(team):
    out = r20.parapet_wall(team)
    if team == "black":
        out += r16.detail("M 7.2,35.3 L 37.8,35.3", "#fff", 0.9)
    return out


PIECES = {"jester": jester, "parapet": parapet}
# The jester's cap drawn at 97% (Mac: full size a bit big, 92% a bit small).
SHRINK = {"jester": 0.97}

if __name__ == "__main__":
    sys.path.insert(0, HERE)
    import make_final_vampire_squire as vs  # noqa: E402 (for shrink)
    for name, draw in PIECES.items():
        for team in ("white", "black"):
            path = os.path.join(HERE, "..", "pieces", "%s_%s.svg" % (team, name))
            body = draw(team)
            if name in SHRINK:
                body = vs.shrink(body, SHRINK[name])
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + body + r16.TAIL)
    print("wrote", len(PIECES) * 2, "files")
