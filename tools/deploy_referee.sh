#!/usr/bin/env bash
# Builds, tests and uploads the online referee (server/supabase/functions/referee)
# to Mac's Supabase project. Run it whenever pieces, army rules or Plusfish
# change, BEFORE deploying the game (tools/deploy_web.sh): the referee must
# know a rule set before any game asks for it.
#
#   bash tools/deploy_referee.sh            build, test and upload
#   bash tools/deploy_referee.sh --test     build and test only
#
# Needs: Godot (writes the rule set), Deno (C:\Tools\deno, runs the tests),
# Supabase's command-line tool (C:\Tools\supabase-cli) signed in once with
# "supabase login" (Mac does that in his browser).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="/c/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
DENO="/c/Tools/deno/deno.exe"
SUPABASE="/c/Tools/supabase-cli/supabase.exe"
FUNCTION=server/supabase/functions/referee

echo "Writing the rule set..."
"$GODOT" --headless --path . -s res://tools/make_rule_set.gd 2>&1 | grep "Rule set"

echo "Bundling Plusfish (web/plusfish.wasm)..."
python - <<'PY'
import base64
data = base64.b64encode(open("web/plusfish.wasm", "rb").read()).decode()
with open("server/supabase/functions/referee/plusfish_wasm.ts", "w") as f:
    f.write("// Written by tools/deploy_referee.sh from web/plusfish.wasm (not kept in git).\n")
    f.write("export const PLUSFISH_WASM: Uint8Array<ArrayBuffer> = Uint8Array.from(atob(\"%s\"), (c) => c.charCodeAt(0));\n" % data)
PY

echo "Testing..."
"$DENO" check "$FUNCTION/index.ts"
"$DENO" test --allow-read "$FUNCTION/referee_test.ts"

if [ "${1:-}" = "--test" ]; then
	exit 0
fi
echo "Uploading..."
"$SUPABASE" functions deploy referee --project-ref mwifzxkilmlgqcbkswkn --use-api --no-verify-jwt --workdir server
# Record which rule sets the uploaded referee knows (tools/deploy_web.sh checks).
ls "$FUNCTION/rules" | sed 's/\.json$//' > "$FUNCTION/DEPLOYED"
echo "Uploaded. Rule sets it knows: $(tr '
' ' ' < "$FUNCTION/DEPLOYED")"
