# Plusfish

A Stockfish-style analysis and balancing engine for **Chess Plus**
(github.com/TheDarkHorse99/ChessPlus).

It reads the game's own piece files (`data/pieces/*.tres`), so it always plays
by the current rules. Change a piece's moves or cost in the game and Plusfish
picks the change up automatically, no code changes needed. It is a separate
Rust program; the game itself is untouched.

What it's for:

* **Evals**: "who's better here, and what's the best move?" for any position or
  army matchup, with the best lines (`analyse`, `eval`, `uci`).
* **Balancing**: thousands of engine-vs-engine games between random armies,
  then statistics on what each piece is actually worth compared with its cost
  (`selfplay`, `values`), plus head-to-head army tests with Elo and error bars
  (`match`).

## Inside the game: the eval bar

When a game is over, the game screen shows an eval bar beside the board, a
blue arrow for Plusfish's best move, and "best: ..." in the status line, for
the final position and for any earlier position tapped in the move list. Never
during a game. The game side is `res://scenes/game/plusfish_link.gd`
(`PlusfishLink`) and `res://scenes/game/eval_bar.gd` (`EvalBar`).

* PC: the game runs `plusfish evalgame` (this folder's `bin/plusfish.exe`, or a
  fresh `target/release` build) on a background thread, sends the game once,
  and gets one reply line per position.
* Web: `web/plusfish.wasm` (this crate built for WebAssembly) is loaded by
  `web/plusfish.js`, which the page includes; the game calls it through
  JavaScriptBridge, one position at a time.
* The request (see `src/api.rs`) carries the piece types as the game has them
  loaded, the exact starting board and the moves played, so Plusfish never has
  to repeat how armies are set up.

After changing the engine, run `bash engine/plusfish/build.sh`. It rebuilds
both, and both outputs are committed so the game works without Rust.

## Build

Install Rust (rustup.rs), then:

```
cargo build --release
```

The program is `target/release/plusfish` (`plusfish.exe` on Windows). It finds
the piece folder by itself if the ChessPlus repo sits next to it or in the
current folder; otherwise pass `--pieces <ChessPlus>/data/pieces` or set
`CHESSPLUS_PIECES`.

## Armies

Wherever an army is asked for you can give:

* `standard`, `random`, or `random:<seed>`
* a saved army file from the game's army builder (a `.tres` file in
  `%APPDATA%\Godot\app_userdata\<game>\armies\` on Windows)
* text: the owner's back row, `/`, then the row in front, files a to h, using
  FEN letters, two-letter symbols in brackets, digits for empty squares. The
  standard set is `RNBQKBNR/PPPPPPPP`; `R(CV)BWKB(CV)R/PPPP1PPP` swaps the
  knights for Cavalry, the queen for a Wizard, and leaves e2 empty.

`plusfish army "<army>"` shows an army's cost and anything that breaks the
army rules.

As in the game, an army played as Black is turned round as a whole (files
mirrored too), so it looks from Black's side as it was built; `standard` keeps
real chess's d-file queen. Saved army files keep the game's
`mirror_for_black` setting.

## Analysis

```
plusfish analyse --white standard --black "R(CV)BWKB(CV)R/PPPPPPPP" --time 10
plusfish analyse --fen "<fen>" --depth 16 --multipv 3
plusfish analyse --white standard --black standard --moves "e4 e5 Nf3" --time 5
plusfish eval --fen "<fen>"          # static evaluation, biggest terms first
```

Scores are in pawns from White's point of view; `#3` means mate in 3.

FENs are the game's own dialect (`core/fen.gd`): two-letter symbols in
brackets `(PD)`, `'` after a piece = broken shield, `^` = ability used. Two
optional extra fields that the game's reader ignores: `lost=Qn(PD)` (lost
pieces, which matter for Raise Dead) and `promo=QR(CH)` (the promotion
choices; without it, FEN positions promote to Q/R/B/N like the game's FEN
tests). Army games promote like the real game: to any non-king, non-pawn type
on the board at the start.

### UCI-style protocol

`plusfish uci` speaks a UCI-like protocol on stdin/stdout, so a GUI or script
(or later the game itself) can drive it:

```
position army RNBQKBNR/PPPPPPPP R(CV)BWKB(CV)R/PPPPPPPP moves e2-e4
go movetime 2000
...
info depth 10 seldepth 21 multipv 1 score cp -143 nodes 555819 nps 398722 time 1394 pv e7-e6 b1-c3 f8-e7 d1-f3 ...
bestmove e7-e6
```

Also `position fen ...`, `position startpos`, `go depth N / nodes N /
wtime .. btime .. / infinite` + `stop`, `setoption name MultiPV value 3`,
`d` (board, FEN, legal moves) and `eval`. Moves use the game's move text
(`e2-e4`, `e7-e8=Q`, Crack Shot `a1!c3`, Raise Dead `d2!=Q`); SAN like `Nf3`
is accepted too.

## Balancing

### Head-to-head

```
plusfish match --white "<army A>" --black "<army B>" --games 400
```

A and B swap colours every game. You get A's score, the Elo difference with a
95% margin, how games ended, and White's overall score. `--out games.jsonl`
saves the games. With `--armies random --params a.txt --params-b b.txt` it
A/B-tests two evaluation files over random army pairs instead, and with
`--armies pool:armies/pool.txt` over pairs from the army pool (below).

### Piece values

```
plusfish selfplay --games 20000 --out games.jsonl   # ~1 hour on 24 cores
plusfish values games.jsonl --html report.html
```

`values` fits two logistic regressions to the results:

* **Worth (army)**: each game's result against the difference in each piece
  type between the two starting armies. This is the number that matters for
  army building: what an extra piece of that type is worth at the start,
  counting everything (abilities, one-shot pieces, how often it gets traded).
  Self-play varies each side's budget between 33 and 39 points
  (`--budget-spread`). Without that, every army costs about 39, and a piece's
  strength can't be told apart from how much points are worth in general.
* **Worth (on board)**: results against the material on the board in quiet
  positions during games. Much more precise, but it only sees pieces while
  they're on the board (the Ram's whole point is the capture that removes it).

Both are put on the army-cost scale (scaled so that worth equals cost on
average across pieces), with 95% ranges. A piece is flagged under/overpriced
when it's at least half a point off and outside its range. The numbers come
from engine play, which isn't human play; treat them as strong hints, and
re-run after changing costs.

### The army pool

`armies/pool.txt` is a fixed pool of varied, decent-to-strong armies for
repeatable engine tests and for checking piece values on real builds (see
`reports/ARMY_POOL.md`). Each line is `<army> | <name> | niche | style |
cost | Elo`; only the army is required, `#` starts a comment. `armies/*.tres`
are the same armies in the game's saved-army format.

```
plusfish match --armies pool:armies/pool.txt --params new.txt --params-b none --games 1000
plusfish tournament --armies pool:armies/pool.txt --with-standard --games 40 --nodes 6000
plusfish export-tres --armies pool:armies/pool.txt --dir armies
```

* `match --armies pool:<file>` plays ordered pairs of pool armies, each pair
  twice (side A as White, then as Black), so only the evaluations differ.
* `tournament` takes `pool:<file>`, `"a;b;c"` or a folder of `.tres` armies;
  `--with-standard` adds Standard and then also shows each army's Elo against
  Standard, its head-to-head score against it, and its Elo within the pool
  (relative to the pool average, without Standard). Pairings where a king
  starts attacked are skipped.
* `export-tres` writes each army as a `.tres` and checks it reads back the
  same. `verify/check_saved_armies.gd` loads them with the game's own classes
  and checks them against `Army.problems`.

### Evolving armies

```
plusfish evolve --dir run1 --seed 1 --threads 6 --nodes 4000 --minutes 120
```

Quality-diversity search (MAP-Elites, `src/evolve.rs`). Plain evolution
collapses onto one build, so armies are sorted into 9 niches and each niche
keeps its best army:

* **Niches**: extra royal (Queen / Wizard / none) x number of pawns (0-3 /
  4-6 / 7+). Style (most points in sliders, leapers or steppers, plus ability
  pieces) is reported, not a niche, so each niche gets enough tries.
* **Mutations** (1 to 3 per child): swap a piece for another type, move a
  piece (the king only between d1 and e1), swap two squares, add a piece,
  remove one, or trade one piece for one or two others. Children must pass
  `Army::problems` and cost at least `--min-cost` (36). 15% of each batch are
  fresh random armies.
* **Fitness**: an Elo rating on one scale with Standard = 0. A short round
  robin at the start rates the fixed reference armies (Standard, the Berserker
  build from FINDINGS.md, 4 random armies) and White's first-move edge. A
  candidate's rating is its performance against its opponents' ratings
  (references and current elites, both colours), with a weak prior (mean 0,
  sd 200) so a few lucky games don't crown a champion.
* **Racing**: every candidate plays 12 games; it plays 12 more if within 60
  Elo of its niche's elite, 24 more if within 25, and 48 more (96 in all) if
  ahead; it replaces the elite only if still rated higher after that. From
  the third stage on, the elite is topped up to the same number of games.
  The last stage matters: with only 48 games, the luckiest of hundreds of
  challengers took over niches at +400 to +500, and over-rated elites
  inflated the ratings of everyone who played them. An empty niche takes the
  first army that lands in it.
* **The king-capture bug**: pairings where a king starts attacked are never
  played, and candidates whose king is attacked, or who attack the other
  king, at the start against more than `--max-exposure` (3%) of 300 random
  armies are thrown out before playing.
* Options: `--batch` (30 candidates per generation), `--generations` (60),
  `--minutes` (150), `--patience` (stop after this many generations without a
  new elite once all niches are filled; 12), `--nodes`, `--threads` (6 by
  default), `--seed`.
* **Checkpoints**: `<dir>/state.txt` (reference ratings, elites, generation)
  and `<dir>/games.txt` (every game) are written after each generation; run
  the same command again to carry on. `<dir>/archive.txt` lists the current
  elites with niche, style, cost, rating and exposure.

The ratings during evolution are noisy and biased upwards for the winners
(they won the races), so the pool's numbers come from a separate tournament.

### Tuning the engine

```
plusfish tune games.jsonl --out params.txt
plusfish match --armies random --params params.txt --params-b none --games 1000
```

The evaluation is a weighted sum of features: material, mobility, shield and
ability terms for each piece type, plus pawn advancement, passed pawns, king
shelter, king-zone attacks, Raise Dead potential and so on. `tune` fits the
weights to self-play results (Texel tuning). The tuned weights in
`params/tuned.txt` are built into the program; `--params none` falls back to
weights derived from army costs, which is also what any new piece type gets
until you re-tune.

## How we know the rules are right

The engine is a line-by-line port of `core/move_generator.gd` and
`core/game_state.gd`, checked two ways:

* `plusfish perft-suite`: the standard perft counts (start position,
  Kiwipete, CPW positions 3 to 5), the same ones the game's tests use, one
  depth deeper.
* `trace-games` / `trace-check`: the game's own engine (running headless in
  Godot, `verify/plusfish_trace.gd`) plays hundreds of random custom-army
  games biased towards captures, abilities, promotions and castling, and logs
  every position's FEN, full legal move list, check status and outcome.
  Plusfish replays them and must match exactly. 630 games, 142,000 positions,
  zero mismatches, covering Crack Shot, Raise Dead, shields, Rams, cannons,
  en passant, castling, promotions and all five game endings.

```
plusfish trace-games --count 40 --seed 1 > games.txt
godot --headless --path <ChessPlus> -s res://tools/plusfish_trace.gd -- games.txt trace.jsonl
plusfish trace-check games.txt trace.jsonl
```

(Copy `verify/plusfish_trace.gd` into the game's `tools/` folder first.)

## Engine details

Mailbox board up to 128 squares, precomputed rays for every piece type, team
and square, reverse attack tables (as in the game), copy-make, Zobrist keys
that follow the game's repetition rule exactly. Search: iterative deepening,
aspiration windows, principal variation search, transposition table,
null-move pruning, reverse futility pruning, late move reductions and pruning,
check extensions, killer and history moves, MultiPV, and a quiescence search
over captures, shield breaks, Crack Shots and promotions. About 5M perft
nodes/s and 0.5M search nodes/s per core; the game's GDScript bot does about
4,500.

Limits: boards up to 128 squares (16x8, 11x11, ...) and 32 piece types.
