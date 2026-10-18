"""Round 12: tweaks to the chosen Berserker and Wizard (white versions, for approval).

    python make_round12.py
"""
import io

HEAD = '<svg xmlns="http://www.w3.org/2000/svg" width="45" height="45" viewBox="0 0 45 45"><g stroke="#000" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" fill="#fff">'
TAIL = "</g></svg>\n"

def mirror(body):
    return '<g transform="translate(45,0) scale(-1,1)">%s</g>' % body

OPTIONS = {}

# Berserker: round 11's hug_flare, horns bent down to follow the helmet's curve,
# still turning out at the tips. Base unchanged (band + nose guard).
HELM = ('<path d="M 10.5,30 C 10.5,18 15.5,12 22.5,12 C 29.5,12 34.5,18 34.5,30 Z"/>'
        '<path d="M 22.5,13 L 22.5,29" fill="none"/>'
        '<path d="M 9,30 L 36,30 L 36,34.5 L 9,34.5 Z"/>'
        '<path d="M 20.5,34.5 L 24.5,34.5 L 24,40 L 21,40 Z"/>')
HORN_A = ('<path d="M 12.5,27.5 C 6,27 4.5,21 6,16 C 7.5,11 11,8 13.5,6.5 C 12,5.2 10,4.8 7.5,5.3 '
          'C 10.5,2.5 15,3 16,5.5 C 16.5,7 15,8.5 13.5,10 C 11,12.5 9.5,15.5 9.8,18.5 C 10,20.5 12,21.5 14.5,21.5 Z"/>')
HORN_B = ('<path d="M 12.5,27.5 C 6.5,27.5 4,22.5 5,17 C 6,12 9.5,9 13.5,8 C 12.5,6.3 10.5,5.8 8,6.3 '
          'C 10.5,3.3 15.5,3.5 16.8,6.5 C 17.5,8.3 16,10 14,11 C 11.5,12.5 9.8,15 9.8,18 C 9.8,20.5 12,21.8 14.5,21.5 Z"/>')
OPTIONS["berserker_bent_a"] = HORN_A + mirror(HORN_A) + HELM
OPTIONS["berserker_bent_b"] = HORN_B + mirror(HORN_B) + HELM

# Wizard: the crystal ball, on a shorter, wider stand.
BALL = ('<circle cx="22.5" cy="17.5" r="12"/>'
        '<path d="M 15.5,13.5 C 16.5,10.5 19,8.5 22,8" fill="none" stroke-width="1.6"/>')
OPTIONS["wizard_ball_wide"] = (
    '<path d="M 7,40.5 L 38,40.5 L 35.5,35 L 9.5,35 Z"/>'
    + '<path d="M 12.5,35 C 13.5,31.5 16.5,29.8 19,29.3 L 26,29.3 C 28.5,29.8 31.5,31.5 32.5,35" />'
    + '<path d="M 10.5,38 L 34.5,38" fill="none" stroke-width="1"/>'
    + BALL
)
OPTIONS["wizard_ball_wide_round"] = (
    '<path d="M 6.5,40.5 C 6.5,36.5 10,34.5 14,34.5 L 31,34.5 C 35,34.5 38.5,36.5 38.5,40.5 Z"/>'
    + '<path d="M 13,34.5 C 14,31.5 16.5,29.8 19,29.3 L 26,29.3 C 28.5,29.8 31,31.5 32,34.5" />'
    + BALL
)

for name, body in OPTIONS.items():
    io.open("white_%s.svg" % name, "w", encoding="utf-8", newline="").write(HEAD + body + TAIL)
print(len(OPTIONS), "options written")
