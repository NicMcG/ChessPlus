class_name OnlineConfig
extends RefCounted

## Mac's Supabase project (see "Online play" in CLAUDE.md for how it was set up).
## Both values are public: the key only allows what the table's rules allow, and
## it has to be in the app for the app to reach the server.
const SUPABASE_URL := "https://mwifzxkilmlgqcbkswkn.supabase.co"
const SUPABASE_KEY := "sb_publishable_WJylNeFRlVo1zXt9xJCIvg_NclDzIaA"

static func is_configured() -> bool:
	return SUPABASE_URL != "" and SUPABASE_KEY != ""
