class_name Piece
extends RefCounted

## One actual piece in a game. PieceDef is the blueprint; this is the instance.

enum Team { WHITE, BLACK }

var def: PieceDef
var team: Team
var has_moved: bool = false
## For pieces with the Shield keyword: true once the shield has been broken.
var shield_broken: bool = false
## For pieces that gain a shield by capturing (the Vampire): true while it has one.
var gained_shield: bool = false
## For pieces with a special ability: true once it has been used (once per game).
var ability_used: bool = false
## For a piece that has changed into another type (a Werewolf after Full Moon):
## the type it started the game as. Null if it hasn't changed.
var base_def: PieceDef

func _init(p_def: PieceDef, p_team: Team) -> void:
	def = p_def
	team = p_team

## True if this piece has a Shield that hasn't been broken yet (or a shield it
## gained by capturing, for the Vampire).
func has_active_shield() -> bool:
	return (def.has_shield() and not shield_broken) or gained_shield

## True if this piece has a special ability it hasn't used yet.
func can_use_ability() -> bool:
	return def.ability != PieceDef.Ability.NONE and not ability_used

## The type this piece started the game as (what Raise Dead brings back).
func starting_def() -> PieceDef:
	return base_def if base_def else def

## The other team: WHITE gives BLACK, BLACK gives WHITE.
static func other_team(p_team: Team) -> Team:
	return Team.BLACK if p_team == Team.WHITE else Team.WHITE

## Uppercase for White, lowercase for Black (standard chess text notation).
func letter() -> String:
	if team == Team.WHITE:
		return def.symbol.to_upper()
	return def.symbol.to_lower()
