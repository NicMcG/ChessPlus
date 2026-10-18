class_name Board
extends RefCounted

## The grid of squares and what's on each one.
## Squares are Vector2i(file, rank): (0, 0) is a1, (4, 3) is e4.

const FILE_LETTERS := "abcdefghijklmnopqrstuvwxyz"
## Stands for "no square" wherever a square is optional.
const NO_SQUARE := Vector2i(-1, -1)

var width: int
var height: int
var _squares: Array[Piece] = []
## Each team's pieces, as {square: piece}. Kept in step with _squares by
## set_piece, so a side's pieces can be found without scanning every square.
var _team_pieces: Array[Dictionary] = [{}, {}]

func _init(p_width: int = 8, p_height: int = 8) -> void:
	width = p_width
	height = p_height
	_squares.resize(width * height)

func in_bounds(pos: Vector2i) -> bool:
	return pos.x >= 0 and pos.x < width and pos.y >= 0 and pos.y < height

func get_piece(pos: Vector2i) -> Piece:
	if not in_bounds(pos):
		return null
	return _squares[_index(pos)]

func set_piece(pos: Vector2i, piece: Piece) -> void:
	assert(in_bounds(pos), "Tried to place a piece off the board")
	var index := _index(pos)
	var old := _squares[index]
	if old:
		_team_pieces[old.team].erase(pos)
	_squares[index] = piece
	if piece:
		_team_pieces[piece.team][pos] = piece

## One team's pieces as {square: piece}. Read it, don't change it: only
## set_piece changes the board.
func pieces_of(team: Piece.Team) -> Dictionary:
	return _team_pieces[team]

func is_empty(pos: Vector2i) -> bool:
	return get_piece(pos) == null

## Turns Vector2i(4, 3) into "e4".
static func square_name(pos: Vector2i) -> String:
	return FILE_LETTERS[pos.x] + str(pos.y + 1)

## Turns "e4" into Vector2i(4, 3). Returns NO_SQUARE if the text isn't a square name.
static func parse_square(text: String) -> Vector2i:
	if text.length() < 2:
		return NO_SQUARE
	var file := FILE_LETTERS.find(text[0])
	var rank_text := text.substr(1)
	if file < 0 or not rank_text.is_valid_int():
		return NO_SQUARE
	return Vector2i(file, rank_text.to_int() - 1)

## The board as text, White at the bottom. Used for testing.
func to_text() -> String:
	var lines: PackedStringArray = []
	for rank in range(height - 1, -1, -1):
		var row := str(rank + 1).lpad(2) + " "
		for file in range(width):
			var piece := get_piece(Vector2i(file, rank))
			row += (piece.letter() if piece else ".") + " "
		lines.append(row)
	var footer := "   "
	for file in range(width):
		footer += FILE_LETTERS[file] + " "
	lines.append(footer)
	return "\n".join(lines)

func _index(pos: Vector2i) -> int:
	return pos.y * width + pos.x
