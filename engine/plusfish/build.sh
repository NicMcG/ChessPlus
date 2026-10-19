#!/usr/bin/env bash
# Builds Plusfish for the game (needs Rust: https://rustup.rs, plus
# "rustup target add wasm32-unknown-unknown" once for the web version):
#   - engine/plusfish/bin/plusfish(.exe)   the PC program the game runs
#   - web/plusfish.wasm                    the web version's engine
# Run from Git Bash anywhere:   bash engine/plusfish/build.sh
# Both outputs are committed, so the game works without Rust installed; run
# this again after changing the engine.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"
cargo build --release
cargo build --release --lib --target wasm32-unknown-unknown
mkdir -p bin
EXE=plusfish
[ -f target/release/plusfish.exe ] && EXE=plusfish.exe
cp "target/release/$EXE" "bin/$EXE"
cp target/wasm32-unknown-unknown/release/plusfish_core.wasm ../../web/plusfish.wasm
echo "Built bin/$EXE and web/plusfish.wasm"
