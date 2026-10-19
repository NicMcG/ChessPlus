"""Final Jester (round 20 jester_three; the black one gets white lines down each
point, along the band and on the base so the details stand out) and Parapet
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


def jester(team):
    out = r20.jester_three(team)
    if team == "black":
        out += r16.detail("M 13.4,27.6 C 11.6,23 9.2,20.2 6.6,18.6 M 22.5,11 L 22.5,26.2 "
                          "M 31.6,27.6 C 33.4,23 35.8,20.2 38.4,18.6", "#fff", 0.9)
        out += r16.detail("M 12.2,32 C 17.5,30.6 27.5,30.6 32.8,32", "#fff", 0.9)
        out += r16.detail("M 12.8,35.4 C 18,34 27,34 32.2,35.4 M 12.9,38 C 18,36.8 27,36.8 32.1,38", "#fff", 0.9)
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
