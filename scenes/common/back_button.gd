class_name BackButton
extends Button

## The Back button at the top left of a screen: an arrow and "Back", with no
## box until it's touched (the theme's GhostButton look).

func _init() -> void:
	text = "Back"
	theme_type_variation = &"GhostButton"
	custom_minimum_size = Vector2(140, 70)

func _ready() -> void:
	icon = get_theme_icon("back", "UiIcons")
	alignment = HORIZONTAL_ALIGNMENT_LEFT
