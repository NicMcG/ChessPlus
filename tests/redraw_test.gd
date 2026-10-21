extends TestSuite

## The game only redraws the screen when something on it changes (Project
## Settings > Application > Run > Low Processor Mode), which saves battery on
## phones. So anything that keeps moving without a move being made (a king in
## check trembling, aiming rings, a Vampire's pulsing aura, a haunting Ghost)
## must keep asking to be redrawn, and a still board must not.

func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree

## A board view on screen showing the position in `fen`.
func _board(fen: String) -> BoardView:
	var view := BoardView.new()
	view.size = Vector2(640, 640)
	_tree().root.add_child(view)
	view.show_game(Fen.parse(fen, PieceCatalog.all_defs(), StandardSetup.create_rules()))
	return view

## How many times `item` was drawn over the next few frames.
func _draws(item: CanvasItem, frames := 6) -> int:
	# Let any redraw already asked for happen first.
	await _tree().process_frame
	await _tree().process_frame
	var count := [0]
	var counter := func() -> void: count[0] += 1
	item.draw.connect(counter)
	for i in frames:
		await _tree().process_frame
	item.draw.disconnect(counter)
	return count[0]

func test_low_processor_mode_is_on() -> void:
	check(ProjectSettings.get_setting("application/run/low_processor_mode"), "Low processor mode in the project settings")

func test_a_still_board_is_not_redrawn() -> void:
	var view := _board("4k3/8/8/8/8/8/3(BD)(WW)3/(NC)3K2(V) w - - 0 1")
	check_eq(await _draws(view), 0, "Nothing changes, so nothing is drawn again")
	view.free()

func test_a_king_in_check_keeps_trembling() -> void:
	var view := _board("R3k3/8/8/8/8/8/8/4K3 b - - 0 1")
	check_eq(await _draws(view), 6, "Drawn every frame")
	view.free()

func test_aiming_keeps_the_rings_moving() -> void:
	var view := _board("4k3/8/8/3p4/8/1A6/8/4K3 w - - 0 1")
	view.tap(Board.parse_square("b3"))
	view.aim_ability()
	check(view.aiming, "Aiming Crack Shot")
	check_eq(await _draws(view), 6, "Drawn every frame")
	view.free()

func test_a_vampires_aura_keeps_pulsing() -> void:
	var view := _board("4k3/8/8/8/8/8/8/V+3K3 w - - 0 1")
	check(view.state.board.get_piece(Board.parse_square("a1")).gained_shield, "The Vampire has its shield")
	check_eq(await _draws(view), 6, "Drawn every frame")
	view.free()

func test_a_move_is_drawn_until_it_lands() -> void:
	var view := _board("4k3/8/8/8/8/8/8/R3K3 w - - 0 1")
	var move := view.state.find_move("a1-a5")
	view.state.make_move(move)
	view.show_move(move)
	check_eq(await _draws(view, 3), 3, "Drawn every frame while it slides")
	while view.is_animating():
		await _tree().process_frame
	check_eq(await _draws(view), 0, "Still again once it has landed")
	view.free()

func test_a_haunting_ghost_keeps_glowing() -> void:
	var row := CapturedRow.new()
	row.size = Vector2(400, 40)
	_tree().root.add_child(row)
	var ghost := Piece.new(load("res://data/pieces/ghost.tres"), Piece.Team.WHITE)
	row.pieces = [ghost]
	row.haunting = ghost
	check_eq(await _draws(row), 6, "Drawn every frame while choosing")
	row.haunting = null
	check_eq(await _draws(row), 0, "Still once chosen")
	row.free()
