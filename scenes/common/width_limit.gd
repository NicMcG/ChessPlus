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
	var extra := maxi(0, int((size.x - _base_left - _base_right - max_width) / 2))
	add_theme_constant_override("margin_left", _base_left + extra)
	add_theme_constant_override("margin_right", _base_right + extra)
