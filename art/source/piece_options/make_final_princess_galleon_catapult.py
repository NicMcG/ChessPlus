"""Final Princess (round 16 crown_five_on_base without the dots on the crown;
the black one gets white lines like the white one's black lines; the crown made
taller, Mac Oct 2026), Galleon (round 15 galleon_square without the gun ports;
the black one's mast black over the sails and white between them) and Catapult
(round 16 catapult_low, wheels without the inner circles), white and black,
written to ../pieces/.

Run from this folder:  python make_final_princess_galleon_catapult.py
"""
import io
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "round15"))
sys.path.insert(0, os.path.join(HERE, "round16"))
import make_round15 as r15  # noqa: E402
import make_round16 as r16  # noqa: E402


# The crown stretched upwards from where it meets the base (y 34), so the
# Princess stands a little taller (Mac); the base and the balls' sizes stay.
TALLER = 1.15


def _taller_y(y):
    return 34 - (34 - y) * TALLER


def princess(team):
    fill, line = r16.colours(team)
    crown = (r16.FIVE.replace("M 13,37", "M 12,34")
             .replace("C 26,35.6 19,35.6 13,37 Z", "C 27,32 18,32 12,34 Z")
             .replace("C 35.2,29.6 33.8,32.5 32,37", "C 35.2,29.6 34.5,31.5 33,34")
             .replace("C 11.2,32.5 9.8,29.6 8.2,26.6", "C 10.5,31.5 9.8,29.6 8.2,26.6"))
    crown = re.sub(r"(-?[0-9.]+),(-?[0-9.]+)", lambda m: "%s,%.2f" % (m.group(1), _taller_y(float(m.group(2)))), crown)
    out = r16.shape(crown, fill)
    out += "".join(r16.circle(x, _taller_y(y), r, fill) for x, y, r in r16.FIVE_BALLS)
    out += r16.shape(r16.BASE_TOP, fill) + r16.shape(r16.BASE_BOTTOM, fill)
    if team == "black":
        # White lines where the white crown has black ones: along the base's ribbons.
        out += r16.detail("M 12.8,33.4 C 18,31.6 27,31.6 32.2,33.4", "#fff", 1)
        out += r16.detail("M 12.9,36.6 C 18,35.2 27,35.2 32.1,36.6", "#fff", 1)
    return out


def galleon(team):
    """Round 15's square-sailed galleon without the four gun ports (Mac); on the
    black one the mast is black over the sails and white between them."""
    out = r15.galleon_square(team)
    out = re.sub(r'<rect x="[0-9.]+" y="30.8"[^>]*/>', "", out)
    if team == "black":
        out = out.replace(r15.detail("M 22.5,10.5 L 22.5,14 M 22.5,19.5 L 22.5,24.8", "#fff", 1), "")
        out += r15.detail("M 22.5,15.6 L 22.5,18.4", "#fff", 1)
    return out


def catapult(team):
    """Round 16's low catapult, its wheels without the inner circles (Mac)."""
    fill, line = r16.colours(team)
    out = r16.catapult_low(team)
    for x in (10.5, 34.5):
        out = out.replace(r16.hollow_wheel(team, x, 34), r16.circle(x, 34, 4.4, fill))
    return out


PIECES = {
    "princess": princess,
    "galleon": galleon,
    "catapult": catapult,
}

if __name__ == "__main__":
    out_dir = os.path.join(HERE, "..", "pieces")
    for name, draw in PIECES.items():
        for team in ("white", "black"):
            path = os.path.join(out_dir, "%s_%s.svg" % (team, name))
            io.open(path, "w", encoding="utf-8", newline="\n").write(r16.HEAD + draw(team) + r16.TAIL)
    print("wrote", len(PIECES) * 2, "files")
