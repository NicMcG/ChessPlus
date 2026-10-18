class_name ScreenShape
extends RefCounted

## Helpers for fitting screens to the window's shape: tall (phones held upright)
## or wide (PC windows, tablets on their side).

## Wide enough to put things side by side.
static func is_wide(area: Vector2) -> bool:
	return area.x > area.y * 1.15

## Move `nodes` (in order) to the end of `new_parent`.
static func move_to(nodes: Array, new_parent: Node) -> void:
	for node: Node in nodes:
		if node.get_parent() != new_parent:
			node.reparent(new_parent, false)
		new_parent.move_child(node, -1)
