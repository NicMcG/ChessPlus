extends TestSuite

## Screens rearrange themselves for wide windows (PC) and tall ones (phones).

func _open(path: String) -> Control:
	var screen: Control = load(path).instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(screen)
	# Screens normally fill the window; unpin them so tests can pick the size.
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	return screen

func test_game_puts_the_board_beside_the_rest_when_wide() -> void:
	var game := _open("res://scenes/game/game.tscn")
	game.size = Vector2(720, 1280)
	check(not game.wide, "Tall: one column")
	check(game.status_label.get_parent() == game.board_view.get_parent().get_parent(), "Status above the board")
	game.size = Vector2(2048, 1280)
	check(game.wide, "Wide: side by side")
	check(game.status_label.get_parent() != game.board_view.get_parent().get_parent(), "Status beside the board")
	check(game.status_label.is_visible_in_tree() and game.board_view.is_visible_in_tree(), "Both shown")
	game.size = Vector2(720, 1280)
	check(not game.wide, "Back to one column")
	check(game.status_label.get_index() == 0, "Status back on top")
	check(game.status_label.is_visible_in_tree() and game.board_view.is_visible_in_tree(), "Both shown again")
	game.free()

func test_builder_puts_the_card_beside_the_board_when_wide() -> void:
	var builder := _open("res://scenes/armies/army_builder.tscn")
	builder.size = Vector2(2048, 1280)
	check(builder.wide, "Wide")
	check(builder.card.is_visible_in_tree() and builder.army_board.is_visible_in_tree(), "Card and board shown")
	builder.size = Vector2(720, 1280)
	check(not builder.wide, "Tall")
	check(builder.card.get_parent().get_index() < builder.save_button.get_index(), "Card above the Save button")
	check(builder.card.is_visible_in_tree(), "Card shown")
	builder.free()
