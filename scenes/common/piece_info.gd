class_name PieceInfo
extends Control

## The piece card as a pop-up over a game (when you hold a piece). Open it with
## PieceInfo.open(parent, def, team); tap Close or anywhere outside to close it.

signal closed

const SCENE_PATH := "res://scenes/common/piece_info.tscn"

var def: PieceDef
var team := Piece.Team.WHITE

## The card's width inside the pop-up, and the height that fits every piece
## (worked out by prepare(); 0 until then).
const CARD_WIDTH := 612.0
static var card_height := 0.0

## Measure the tallest card ahead of time (the game screen calls this), so every
## pop-up is the same size.
static func prepare(host: Node) -> void:
	if card_height > 0:
		return
	card_height = await PieceCard.tallest_height(host, PieceCatalog.all_defs(), CARD_WIDTH)

## Show the card for `p_def` on top of `parent` (usually the current screen).
static func open(parent: Node, p_def: PieceDef, p_team := Piece.Team.WHITE) -> PieceInfo:
	var info: PieceInfo = load(SCENE_PATH).instantiate()
	info.def = p_def
	info.team = p_team
	parent.add_child(info)
	return info

func _ready() -> void:
	%Card.custom_minimum_size = Vector2(CARD_WIDTH, card_height)
	%Card.show_piece(def, team)
	%Close.pressed.connect(close)
	%Dim.gui_input.connect(func(event: InputEvent) -> void:
		var press := event as InputEventMouseButton
		if press and press.pressed:
			close())

func close() -> void:
	closed.emit()
	queue_free()
