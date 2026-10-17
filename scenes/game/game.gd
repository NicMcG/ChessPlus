extends Control

## The game screen: connects the board view, the text around it and the buttons
## to a GameState. Two players share one device for now (pass and play).

@onready var board_view: BoardView = %BoardView
@onready var status_label: Label = %Status
@onready var moves_label: Label = %Moves
@onready var new_game_button: Button = %NewGame
@onready var undo_button: Button = %Undo
@onready var promotion_overlay: ColorRect = %PromotionOverlay
@onready var promotion_choices: HBoxContainer = %PromotionChoices

var state: GameState

func _ready() -> void:
	board_view.move_chosen.connect(play)
	board_view.choice_needed.connect(_ask_which_move)
	new_game_button.pressed.connect(new_game)
	undo_button.pressed.connect(undo)
	promotion_overlay.gui_input.connect(_on_overlay_input)
	new_game()

func new_game() -> void:
	state = StandardSetup.create_game()
	promotion_overlay.hide()
	board_view.show_game(state)
	_update_text()

## Make a move (it must be legal) and update everything on screen.
func play(move: Move) -> void:
	state.make_move(move)
	board_view.refresh()
	_update_text()

## Take back the last move (also after the game has ended).
func undo() -> void:
	if state.history.is_empty():
		return
	state.undo_move(state.history.back())
	promotion_overlay.hide()
	board_view.refresh()
	_update_text()

## Several moves go between the same two squares: the promotion choices.
## Show a button with each new piece's picture.
func _ask_which_move(moves: Array[Move]) -> void:
	for child in promotion_choices.get_children():
		child.queue_free()
	for move in moves:
		var button := Button.new()
		button.icon = board_view.texture_for(move.promotion, move.piece.team) if move.promotion else null
		if button.icon == null:
			button.text = Notation.san(state, move)
		button.expand_icon = true
		button.custom_minimum_size = Vector2(120, 120)
		button.pressed.connect(func() -> void:
			promotion_overlay.hide()
			play(move))
		promotion_choices.add_child(button)
	promotion_overlay.show()

## Tapping outside the choices cancels.
func _on_overlay_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click and click.pressed:
		promotion_overlay.hide()

func _update_text() -> void:
	var mover := "White" if state.side_to_move == Piece.Team.WHITE else "Black"
	var other := "Black" if state.side_to_move == Piece.Team.WHITE else "White"
	match state.outcome():
		GameState.Outcome.NONE:
			status_label.text = mover + " to move" + (" - check!" if state.is_in_check() else "")
		GameState.Outcome.CHECKMATE:
			status_label.text = "Checkmate! %s wins" % other
		GameState.Outcome.STALEMATE:
			status_label.text = "Draw by stalemate"
		GameState.Outcome.FIFTY_MOVES:
			status_label.text = "Draw by the 50-move rule"
		GameState.Outcome.REPETITION:
			status_label.text = "Draw by repetition"
		GameState.Outcome.INSUFFICIENT_MATERIAL:
			status_label.text = "Draw: checkmate is impossible"
	moves_label.text = Notation.move_list(state)
	undo_button.disabled = state.history.is_empty()
