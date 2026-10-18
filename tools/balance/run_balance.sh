#!/usr/bin/env bash
# Runs the balancing games: several copies of balance_match.gd at once (one per
# processor core you can spare), each with its own seed, all writing into one
# folder. Then analyse with:  python tools/balance/analyse_balance.py balance/results/<round>
#
#   bash tools/balance/run_balance.sh <round name> <copies> <games each> [depth] [values.json]
# e.g.
#   bash tools/balance/run_balance.sh round1 12 330 2
set -euo pipefail
GODOT="/c/Tools/Godot/Godot_v4.7.2-stable_win64_console.exe"
ROUND="$1"; COPIES="$2"; GAMES="$3"; DEPTH="${4:-2}"; VALUES="${5:-}"
cd "$(dirname "$0")/../.."
mkdir -p "balance/results/$ROUND"
for i in $(seq 1 "$COPIES"); do
	extra=()
	if [ -n "$VALUES" ]; then extra=(--values "$VALUES"); fi
	"$GODOT" --headless --path . -s res://tools/balance/balance_match.gd -- \
		--games "$GAMES" --seed "$((i * 1000 + RANDOM))" --depth "$DEPTH" \
		--out "balance/results/$ROUND/seed_$i.csv" ${extra[@]+"${extra[@]}"} > "balance/results/$ROUND/log_$i.txt" 2>&1 &
done
wait
echo "Done: $(cat balance/results/$ROUND/*.csv | wc -l) games in balance/results/$ROUND"
