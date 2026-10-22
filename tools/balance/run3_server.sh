#!/usr/bin/env bash
# Balance run 3 (colour swings), the part that plays games. Runs on the sims
# server (see tools/sims_server.sh), from ~/ChessPlus after updating and
# building Plusfish:
#
#   nohup bash tools/balance/run3_server.sh > ~/plusfish-work/run3/run.log 2>&1 &
#
# Part 1: a round robin of the meta pool's 10 armies plus Standard. Every
#   pairing plays 40 games, 20 with each colour (plusfish match swaps colours
#   every game). 16 pairings at a time, 4 threads each, so all 64 cores work.
# Part 3: Standard against Standard, 4,000 games at 8,000 nodes per move and
#   4,000 at 32,000.
# Both use --random-plies 4 (the first 4 plies picked among good moves), so
# they compare directly. Every game is saved. Part 2 needs no games: it reads
# run 2's (tools/balance/run3_analyse.py).
#
# Writes into ~/plusfish-work/run3/: armies.txt (name|army), pairings.txt
# (number|army A|army B, numbers into armies.txt), pairs/p<n>.jsonl,
# standard_8k.jsonl, standard_32k.jsonl, logs/, progress.log, and DONE at the
# end. It doesn't switch the server off: the idle check does that 20 minutes
# after the last game if nobody stops it sooner.
set -u
export PF=~/ChessPlus/engine/plusfish/target/release/plusfish
export OUT=~/plusfish-work/run3
NODES=8000
PLIES=4
mkdir -p "$OUT/pairs" "$OUT/logs"
rm -f "$OUT/DONE"
log() { echo "[$(date -u '+%Y-%m-%d %H:%M:%S UTC')] $*" >> "$OUT/progress.log"; }
cd ~/ChessPlus
log "start; game version $(git rev-parse --short HEAD); $(nproc) cores"

# The pool's armies (name|army text), then Standard.
grep -v '^#' engine/plusfish/reports/meta_pool.txt | grep -v '^ *$' \
	| awk -F' [|] ' '{ print $2 "|" $1 }' > "$OUT/armies.txt"
echo "Standard|standard" >> "$OUT/armies.txt"
count=$(wc -l < "$OUT/armies.txt")

# Every pairing once: number|A|B.
: > "$OUT/pairings.txt"
k=0
for ((i = 0; i < count; i++)); do
	for ((j = i + 1; j < count; j++)); do
		echo "$k|$i|$j" >> "$OUT/pairings.txt"
		k=$((k + 1))
	done
done

# One pairing: 40 games, A White in the even-numbered ones. Seed 3000 + its number.
run_pair() {
	local line i j a b
	line=$(sed -n "$(($1 + 1))p" "$OUT/pairings.txt")
	i=$(echo "$line" | cut -d'|' -f2)
	j=$(echo "$line" | cut -d'|' -f3)
	a=$(sed -n "$((i + 1))p" "$OUT/armies.txt" | cut -d'|' -f2)
	b=$(sed -n "$((j + 1))p" "$OUT/armies.txt" | cut -d'|' -f2)
	"$PF" match --white "$a" --black "$b" --games 40 --nodes 8000 --random-plies 4 \
		--threads 4 --seed $((3000 + $1)) --out "$OUT/pairs/p$1.jsonl" > "$OUT/logs/p$1.txt" 2>&1
	echo "pairing $1 done (exit $?)" >> "$OUT/logs/pairs_done.txt"
}
export -f run_pair

log "part 1: $k pairings of $count armies, 40 games each, $NODES nodes, random plies $PLIES, seeds 3000-$((3000 + k - 1))"
seq 0 $((k - 1)) | xargs -P 16 -I{} bash -c 'run_pair {}'
log "part 1 finished ($(ls "$OUT"/pairs/*.jsonl | wc -l) pairing files)"

for setting in "8000 301 standard_8k" "32000 302 standard_32k"; do
	set -- $setting
	log "part 3: Standard vs Standard, 4000 games, $1 nodes, random plies $PLIES, seed $2"
	"$PF" match --white standard --black standard --games 4000 --nodes "$1" --random-plies $PLIES \
		--threads 64 --seed "$2" --out "$OUT/$3.jsonl" > "$OUT/logs/$3.txt" 2>&1
	log "part 3 $3 finished (exit $?)"
done

log "all done"
touch "$OUT/DONE"
