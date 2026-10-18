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

func test_builder_card_and_tray_grow_to_fit() -> void:
	var builder := _open("res://scenes/armies/army_builder.tscn")
	builder.size = Vector2(720, 1280)
	check_eq(builder.card.zoom, builder.CARD_ZOOM_TALL, "Card a little bigger on a phone")
	var button: Button = builder.tray.get_child(0)
	check(button.custom_minimum_size.x >= builder.TRAY_BUTTON_MIN, "Tray buttons at least the minimum")
	check(builder.tray.get_combined_minimum_size().x <= 720, "Tray fits the phone's width")
	builder.size = Vector2(2048, 1280)
	check_eq(builder.card.zoom, builder.CARD_ZOOM_WIDE, "Card bigger on a wide screen")
	check(button.custom_minimum_size.x > builder.TRAY_BUTTON_MIN, "Tray buttons bigger too")
	builder.free()

func test_card_zoom_scales_the_mini_board() -> void:
	var card: PieceCard = load("res://scenes/common/piece_card.tscn").instantiate()
	(Engine.get_main_loop() as SceneTree).root.add_child(card)
	card.show_piece(load("res://data/pieces/knight.tres"))
	card.set_zoom(2.0)
	check_eq(card.get_node("%GuideBoard").custom_minimum_size, Vector2(440, 440), "Mini board twice the size")
	card.free()

func test_builder_card_is_one_size_for_every_piece() -> void:
	var builder := _open("res://scenes/armies/army_builder.tscn")
	builder.size = Vector2(720, 1280)
	# Let the card be measured for every piece.
	for i in 80:
		await (Engine.get_main_loop() as SceneTree).process_frame
	check(builder._card_height > 0, "Measured")
	var heights := {}
	for def: PieceDef in builder._tray_buttons.keys():
		builder.select(def)
		await (Engine.get_main_loop() as SceneTree).process_frame
		heights[builder._card_scroll.custom_minimum_size.y] = true
	check_eq(heights.size(), 1, "The same height whichever piece is shown")
	builder.free()

func test_a_scroll_on_a_tray_button_does_not_pick_it() -> void:
	var builder := _open("res://scenes/armies/army_builder.tscn")
	var queen: PieceDef = load("res://data/pieces/queen.tres")
	var button: Button = builder._tray_buttons[queen]
	check_eq(button.mouse_filter, Control.MOUSE_FILTER_PASS, "Drags pass through to the tray")
	# Pretend the finger went down, then the tray scrolled before it lifted.
	builder._scroll_at_press = builder._tray_scroll.scroll_vertical - 60
	button.button_pressed = true
	check(not button.button_pressed, "Not picked")
	builder._scroll_at_press = builder._tray_scroll.scroll_vertical
	button.button_pressed = true
	check(button.button_pressed, "A plain tap still picks it")
	builder.free()
