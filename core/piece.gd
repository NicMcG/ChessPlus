class_name Piece
extends RefCounted

## One actual piece in a game. PieceDef is the blueprint; this is the instance.

enum Team { WHITE, BLACK }

var def: PieceDef
var team: Team
var has_moved: bool = false

func _init(p_def: PieceDef, p_team: Team) -> void:
	def = p_def
	team = p_team

## The other team: WHITE gives BLACK, BLACK gives WHITE.
static func other_team(p_team: Team) -> Team:
	return Team.BLACK if p_team == Team.WHITE else Team.WHITE

## Uppercase for White, lowercase for Black (standard chess text notation).
func letter() -> String:
	if team == Team.WHITE:
		return def.symbol.to_upper()
	return def.symbol.to_lower()
