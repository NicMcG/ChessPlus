extends Control

## Before an online game. Pick your army, then either create a game (choosing
## your side and the time limit) and send its code to a friend, or type in a
## friend's code to join theirs. When both players are in, game_ready hands the
## OnlineSession to the main scene, which opens the game.

signal closed
signal game_ready(session: OnlineSession)

@onready var army_pick: OptionButton = %Army
@onready var side_pick: OptionButton = %Side
@onready var time_pick: OptionButton = %Time
@onready var create_button: Button = %Create
@onready var code_edit: LineEdit = %CodeEdit
@onready var join_button: Button = %Join
@onready var form: Control = %Form
@onready var waiting: Control = %Waiting
@onready var code_label: Label = %Code
@onready var message_label: Label = %Message

var library: ArmyLibrary
## Where games are stored. Null = the real server (tests use a MemoryBackend).
var backend: OnlineBackend
## The player ID to use; "" = a fresh one (tests set their own).
var player_id := ""
## The game being created or joined.
var session: OnlineSession
var rules := StandardSetup.create_rules()
## What the army list offers (see ArmyChoices).
var choices: ArmyChoices

func _ready() -> void:
	choices = ArmyChoices.new(library, rules)
	choices.fill(army_pick)
	for side in ["White", "Black", "Random"]:
		side_pick.add_item(side)
	for time_control in OnlineSession.TIME_CONTROLS:
		time_pick.add_item(time_control[0])
	PhoneTextInput.attach(code_edit, "Game code")
	code_edit.text_changed.connect(func(text: String) -> void:
		# Codes are in capitals; keep the cursor where it was.
		var caret := code_edit.caret_column
		code_edit.text = text.to_upper()
		code_edit.caret_column = caret)
	create_button.pressed.connect(create)
	join_button.pressed.connect(join)
	%Cancel.pressed.connect(cancel_waiting)
	%Copy.pressed.connect(func() -> void:
		DisplayServer.clipboard_set(session.code if session else "")
		%Copy.text = "Copied!")
	%Back.pressed.connect(_back)
	if backend == null and not OnlineConfig.is_configured():
		_show_message("Online play isn't connected to a server yet.")
		create_button.disabled = true
		join_button.disabled = true

## The army choice, as a Callable(team) -> Army: the side isn't known yet when
## it's Random, or when joining.
func chosen_army() -> Callable:
	return choices.resolver(army_pick.selected)

## Create a game and wait for a friend to join it.
func create() -> void:
	_set_busy(true, "Creating a game...")
	session = _new_session()
	var time_ms: int = OnlineSession.TIME_CONTROLS[time_pick.selected][1]
	var result := await session.create_game(chosen_army(), side_pick.selected, time_ms)
	_set_busy(false)
	if not result.ok:
		_drop_session()
		_show_message("Couldn't create a game: " + result.error)
		return
	code_label.text = session.code
	%Copy.text = "Copy code"
	form.hide()
	waiting.show()
	session.changed.connect(_on_changed)
	session.start_polling()

## Join the game whose code was typed in.
func join() -> void:
	if code_edit.text.strip_edges().length() != OnlineSession.CODE_LENGTH:
		_show_message("Game codes are %d letters and numbers long." % OnlineSession.CODE_LENGTH)
		return
	_set_busy(true, "Joining...")
	session = _new_session()
	var result := await session.join_game(code_edit.text, chosen_army())
	_set_busy(false)
	if not result.ok:
		_drop_session()
		_show_message(result.error)
		return
	_start()

## Stop waiting and remove the game from the server.
func cancel_waiting() -> void:
	if session:
		session.stop_polling()
		await session.cancel()
		_drop_session()
	waiting.hide()
	form.show()

## The friend joined: off to the game.
func _on_changed(_row: Dictionary) -> void:
	if session.status() == OnlineSession.PLAYING:
		_start()

func _start() -> void:
	session.stop_polling()
	if session.changed.is_connected(_on_changed):
		session.changed.disconnect(_on_changed)
	game_ready.emit(session)

func _back() -> void:
	if waiting.visible:
		await cancel_waiting()
	closed.emit()

func _new_session() -> OnlineSession:
	var new_session := OnlineSession.new(backend.duplicate() if backend else null, player_id)
	add_child(new_session)
	return new_session

func _drop_session() -> void:
	if session:
		session.queue_free()
		session = null

func _set_busy(busy: bool, text := "") -> void:
	create_button.disabled = busy
	join_button.disabled = busy
	_show_message(text)

func _show_message(text: String) -> void:
	message_label.text = text
