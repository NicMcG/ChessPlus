"""Final Assassin: round 19 ref_x_points_up (Mac's reference dagger, two crossed
in an X at the middle of the whole dagger, points up), a little bigger, with
shorter blades, no bands on the grips, and a dot in the middle of each guard in
the opposite colour instead of the square; no line down the blades and thicker
grips (Mac, Oct 2026). White and black, to ../pieces/.

Run from this folder:  python make_final_assassin.py
"""
import io
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "round19"))
import make_round19 as r19  # noqa: E402

r19.SCALE = 0.94


def assassin(team):
    fill = "#fff" if team == "white" else "#000"
    # Crossing a little further up the blades than the very middle of the
    # dagger, so the two guards don't run into each other.
    along = (31 - r19.HILT) / 2 * r19.SCALE + 3
    # No line down the blades, and thicker grips (Mac, Oct 2026).
    return (r19.dagger(fill, 45, 31, along=along, gem=False, bands=False, dot=True, ridge=False, grip=2.3)
            + r19.dagger(fill, -45, 31, along=along, gem=False, bands=False, dot=True, ridge=False, grip=2.3))


if __name__ == "__main__":
    for team in ("white", "black"):
        path = os.path.join(HERE, "..", "pieces", "%s_assassin.svg" % team)
        io.open(path, "w", encoding="utf-8", newline="\n").write(r19.HEAD + assassin(team) + r19.TAIL)
    print("wrote 2 files")
