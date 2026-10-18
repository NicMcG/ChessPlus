class_name Piece
extends RefCounted

## One actual piece in a game. PieceDef is the blueprint; this is the instance.

enum Team { WHITE, BLACK }

var def: PieceDef
var team: Team
var has_moved: bool = false
## For pieces with the Shield keyword: true once the shield has been broken.
var shield_broken: bool = false
## For pieces with a special ability: true once it has been used (once per game).
var ability_used: bool = false

func _init(p_def: PieceDef, p_team: Team) -> void:
	def = p_def
	team = p_team

## True if this piece has a Shield that hasn't been broken yet.
func has_active_shield() -> bool:
	return def.has_shield() and not shield_broken

## True if this piece has a special ability it hasn't used yet.
func can_use_ability() -> bool:
	return def.ability != PieceDef.Ability.NONE and not ability_used

## The other team: WHITE gives BLACK, BLACK gives WHITE.
static func other_team(p_team: Team) -> Team:
	return Team.BLACK if p_team == Team.WHITE else Team.WHITE

## Uppercase for White, lowercase for Black (standard chess text notation).
func letter() -> String:
	if team == Team.WHITE:
		return def.symbol.to_upper()
	return def.symbol.to_lower()
