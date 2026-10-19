#!/usr/bin/env bash
# Builds the web version and publishes it to GitHub Pages:
#   https://thedarkhorse99.github.io/ChessPlus/
#
# Run from Git Bash in the project folder:   bash tools/deploy_web.sh
#
# What it does:
#   1. Exports the "Web" preset into build/web/ (needs Godot's export templates).
#   2. Patches the service worker (see tools/patch_service_worker.py) and adds
#      Plusfish (web/plusfish.js + web/plusfish.wasm) for the eval bar.
#   3. Copies just those built files into a fresh temporary git repository, plus an
#      empty .nojekyll file (tells GitHub to serve the files exactly as they are).
#   4. Force-pushes that as the gh-pages branch, replacing the previous build.
#      The branch only ever holds the latest build; the source code stays on main.
set -euo pipefail

GODOT="/c/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
PROJECT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cd "$PROJECT"
mkdir -p build/web
"$GODOT" --headless --path . --export-release "Web" build/web/index.html > /dev/null 2>&1
test -f build/web/index.html || { echo "Export failed: no build/web/index.html"; exit 1; }
python tools/patch_service_worker.py build/web/index.service.worker.js
# Plusfish (the eval bar's engine): the page loads plusfish.js, which loads plusfish.wasm.
cp web/plusfish.js web/plusfish.wasm build/web/

cp build/web/* "$TMP/"
: > "$TMP/.nojekyll"
SOURCE_COMMIT="$(git rev-parse --short HEAD)"
REMOTE="$(git remote get-url origin)"

cd "$TMP"
git init -q -b gh-pages
git -c core.autocrlf=false add -A
git commit -q -m "Web build of Chess Plus from main at $SOURCE_COMMIT"
git remote add origin "$REMOTE"
git push -q --force origin gh-pages
echo "Published build of $SOURCE_COMMIT. Live in a minute or two at https://thedarkhorse99.github.io/ChessPlus/"
