class_name ArmyShare
extends RefCounted

## Sharing armies (Mac's design): "Share" in the army builder uploads the army
## to the game's server and gives a short code, like an online game's; a friend
## types the code into "Import army" in My armies and gets a copy in their own
## saved armies. (The server table is set up by server/supabase_update_2.sql.)

## Upload `army`. Returns {"ok", "code", "error"}.
static func share(backend: OnlineBackend, army: Army) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var data := SavedGame.army_to_dict(army)
	var result := OnlineBackend.failed("couldn't share the army")
	# A new code clashing with an old one is very unlikely; try again if so.
	for attempt in 5:
		var code := ""
		for i in OnlineSession.CODE_LENGTH:
			code += OnlineSession.CODE_LETTERS[rng.randi_range(0, OnlineSession.CODE_LETTERS.length() - 1)]
		result = await backend.insert_shared_army({"code": code, "army": data})
		if result.ok:
			return {"ok": true, "code": code, "error": ""}
		if not ("exist" in result.error or "409" in result.error):
			break
	return {"ok": false, "code": "", "error": result.error}

## Download the army shared under `code` and save a copy in `library`.
## Returns "" if it worked, otherwise what went wrong (in plain words).
static func import_army(backend: OnlineBackend, library: ArmyLibrary, code: String) -> String:
	var wanted := code.strip_edges().to_upper()
	if wanted.length() != OnlineSession.CODE_LENGTH:
		return "Army codes are %d letters and numbers long." % OnlineSession.CODE_LENGTH
	if library.is_full():
		return "You already have %d saved armies; delete one first." % ArmyLibrary.MAX_ARMIES
	var found: Dictionary = await backend.fetch_shared_army(wanted)
	if not found.ok:
		return "Couldn't reach the server: " + found.error
	if found.rows.is_empty():
		return "There's no army with the code %s." % wanted
	var data: Variant = found.rows[0].get("army")
	var army := SavedGame.army_from_dict(data) if data is Dictionary else null
	if army == null:
		return "That army uses a piece this version of the game doesn't have yet."
	# Shared armies are always built ones (turned round when played as Black).
	army.mirror_for_black = bool((data as Dictionary).get("mirror", true))
	if not army.is_valid(StandardSetup.create_rules(), 8):
		return "That army doesn't follow the army rules any more."
	army.army_name = unique_name(library, army.army_name)
	if library.save(army) != OK:
		return "Couldn't save the army."
	return ""

## `wanted`, or "wanted (2)", "wanted (3)"... if a saved army already has that name.
static func unique_name(library: ArmyLibrary, wanted: String) -> String:
	var taken := library.armies().map(func(a: Army) -> String: return a.army_name)
	if not wanted in taken:
		return wanted
	var n := 2
	while "%s (%d)" % [wanted, n] in taken:
		n += 1
	return "%s (%d)" % [wanted, n]
