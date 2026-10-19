"""Final Princess (round 16 crown_five_on_base without the dots on the crown;
the black one gets white lines like the white one's black lines), Galleon
(round 15 galleon_square) and Catapult (round 16 catapult_low), white and
black, written to ../pieces/.

Run from this folder:  python make_final_princess_galleon_catapult.py
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "round15"))
sys.path.insert(0, os.path.join(HERE, "round16"))
import make_round15 as r15  # noqa: E402
import make_round16 as r16  # noqa: E402


def princess(team):
    fill, line = r16.colours(team)
    crown = (r16.FIVE.replace("M 13,37", "M 12,34")
             .replace("C 26,35.6 19,35.6 13,37 Z", "C 27,32 18,32 12,34 Z")
             .replace("C 35.2,29.6 33.8,32.5 32,37", "C 35.2,29.6 34.5,31.5 33,34")
             .replace("C 11.2,32.5 9.8,29.6 8.2,26.6", "C 10.5,31.5 9.8,29.6 8.2,26.6"))
    out = r16.shape(crown, fill)
    out += "".join(r16.circle(x, y, r, fill) for x, y, r in r16.FIVE_BALLS)
    out += r16.shape(r16.BASE_TOP, fill) + r16.shape(r16.BASE_BOTTOM, fill)
    if team == "black":
        # White lines where the white crown has black ones: along the base's ribbons.
        out += r16.detail("M 12.8,33.4 C 18,31.6 27,31.6 32.2,33.4", "#fff", 1)
        out += r16.detail("M 12.9,36.6 C 18,35.2 27,35.2 32.1,36.6", "#fff", 1)
    return out


PIECES = {
    "princess": princess,
    "galleon": r15.galleon_square,
    "catapult": r16.catapult_low,
}

if __name__ == "__main__":
    out_dir = os.path.join(HERE, "..", "pieces")
    for name, draw in PIECES.items():
        for team in ("white", "black"):
            path = os.path.join(out_dir, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(PIECES) * 2, "files")
