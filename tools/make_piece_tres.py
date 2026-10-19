"""Writes PieceDef .tres files for pieces described below (the third batch of
custom pieces). Run from the project folder:  python tools/make_piece_tres.py

Each rule: (directions, max_steps, mode, extra fields). Modes: 0 move or
capture, 1 move only, 2 capture only. Directions are (files, ranks) from the
owner's side, positive ranks = towards the opponent.
"""
import io

ORTHO = [(1, 0), (-1, 0), (0, 1), (0, -1)]
DIAG = [(1, 1), (1, -1), (-1, 1), (-1, -1)]
ALL8 = ORTHO + DIAG
TWO_AWAY = [(2 * x, 2 * y) for x, y in ALL8]

PIECES = {
    "princess": dict(name="Princess", symbol="PR", value=7, rules=[(ALL8, 4, 0, {})]),
    "galleon": dict(name="Galleon", symbol="GA", value=4.5, rules=[
        (ALL8, 0, 1, {}),
        (DIAG + [(1, 0), (-1, 0)], 1, 2, {}),
    ]),
    "catapult": dict(name="Catapult", symbol="CT", value=3, keywords=1, rules=[
        (ALL8, 1, 1, {}),
        (TWO_AWAY, 1, 2, {}),
    ]),
    "assassin": dict(name="Assassin", symbol="AS", value=2, rules=[
        ([(0, 1)], 2, 1, {}),
        ([(1, 1), (-1, 1)], 1, 1, {}),
        ([(0, -1), (1, -1), (-1, -1)], 1, 2, {}),
    ]),
}


def vec_list(dirs):
    return "Array[Vector2i]([%s])" % ", ".join("Vector2i(%d, %d)" % d for d in dirs)


def write(piece_id, spec):
    lines = ['[gd_resource type="Resource" script_class="PieceDef" format=3]', "",
             '[ext_resource type="Script" path="res://core/move_rule.gd" id="1_rule"]',
             '[ext_resource type="Script" path="res://core/piece_def.gd" id="2_def"]', ""]
    names = []
    for i, (dirs, steps, mode, extra) in enumerate(spec["rules"]):
        name = "Resource_rule%d" % (i + 1)
        names.append(name)
        lines.append('[sub_resource type="Resource" id="%s"]' % name)
        lines.append('script = ExtResource("1_rule")')
        lines.append("directions = " + vec_list(dirs))
        lines.append("max_steps = %d" % steps)
        if mode:
            lines.append("mode = %d" % mode)
        for key, value in extra.items():
            lines.append("%s = %s" % (key, value))
        lines.append("")
    lines += ["[resource]", 'script = ExtResource("2_def")', 'id = "%s"' % piece_id,
              'display_name = "%s"' % spec["name"], 'symbol = "%s"' % spec["symbol"],
              "value = %s" % spec["value"],
              'move_rules = Array[ExtResource("1_rule")]([%s])' % ", ".join('SubResource("%s")' % n for n in names)]
    if spec.get("types"):
        lines.append("types = %d" % spec["types"])
    if spec.get("keywords"):
        lines.append("keywords = %d" % spec["keywords"])
    for key in ("special_rule", "ability_name", "ability_text"):
        if spec.get(key):
            lines.append('%s = "%s"' % (key, spec[key]))
    io.open("data/pieces/%s.tres" % piece_id, "w", encoding="utf-8", newline="\n").write("\n".join(lines) + "\n")


if __name__ == "__main__":
    for piece_id, spec in PIECES.items():
        write(piece_id, spec)
        print("wrote", piece_id)
