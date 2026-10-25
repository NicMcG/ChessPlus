class_name RuleSet
extends RefCounted

## The game's rules as the online referee needs them: every piece type (as
## Plusfish reads it, PlusfishLink._def_to_dict), which ones armies may buy,
## and the army rules (budget, starting rows, copies). Its version is a short
## fingerprint of all that: the game sends it when creating or joining an
## online game, and the referee (server/supabase/functions/referee) judges the
## game with the rule set of that version, so a changed piece can't be judged
## by old rules. tools/make_rule_set.gd writes each version's file for the
## referee; a version the referee doesn't have yet means "deploy the referee
## first".

static var _data := {}
static var _version := ""

## The rules, as plain data (keys sorted when written as JSON).
static func data() -> Dictionary:
	if _data.is_empty():
		var defs := {}
		for def in PieceCatalog.all_defs():
			defs[def.id] = def
		var buyable: Array = defs.keys()
		for def: PieceDef in defs.values():
			if def.transforms_into:
				defs[def.transforms_into.id] = def.transforms_into
		var ids: Array = defs.keys()
		ids.sort()
		buyable.sort()
		var rules := StandardSetup.create_rules()
		_data = {
			"pieces": ids.map(func(id: String) -> Dictionary: return PlusfishLink._def_to_dict(defs[id])),
			"buyable": buyable,
			"width": 8,
			"height": 8,
			"budget": rules.army_budget,
			"start_rows": rules.army_start_rows,
			"max_copies": rules.army_max_copies,
			"max_extra_royals": rules.army_max_extra_royals,
			"castling_corner": rules.castling_partner_in_corner,
			"known_abilities": PlusfishLink.known_abilities(),
			"judge": PlusfishLink.referee_can_judge(),
		}
	return _data

## The rule set as text, exactly as the referee's file holds it.
static func text() -> String:
	return JSON.stringify(data(), "", true)

## A 12-character fingerprint of the rules.
static func version() -> String:
	if _version == "":
		_version = text().sha256_text().left(12)
	return _version

## Forget the kept rules (tests, after changing a piece).
static func clear_cache() -> void:
	_data = {}
	_version = ""
