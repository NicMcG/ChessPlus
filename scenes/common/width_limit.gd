class_name WidthLimit
extends MarginContainer

## A MarginContainer that stops its contents getting wider than `max_width` on
## wide screens, by growing its left and right margins to keep them centred.
## On a phone it changes nothing.

@export var max_width := 900.0

var _base_left := 0
var _base_right := 0

func _ready() -> void:
	_base_left = get_theme_constant("margin_left")
	_base_right = get_theme_constant("margin_right")
	resized.connect(_fit)
	_fit()

func _fit() -> void:
	# The room the parent gives it (its own size can be pushed wider by wide
	# contents, which would make the margins grow without end).
	var room := minf(size.x, get_parent_area_size().x)
	var extra := maxi(0, int((room - _base_left - _base_right - max_width) / 2))
	# Never squeeze the contents below the width they need.
	var needed := 0.0
	for child in get_children():
		if child is Control and (child as Control).visible:
			needed = maxf(needed, (child as Control).get_combined_minimum_size().x)
	extra = mini(extra, maxi(0, int((room - _base_left - _base_right - needed) / 2)))
	add_theme_constant_override("margin_left", _base_left + extra)
	add_theme_constant_override("margin_right", _base_right + extra)
