# Chess Plus — project briefing

## What this is

Chess Plus is Mac's original PC/mobile game. Phase 1 is a fully working game of standard chess. Phase 2 turns it into Chess Plus: instead of the fixed standard set, each player builds an army by spending a point budget on pieces (including brand-new piece types), saves it, and brings it into games against other players. Possible future feature: pieces larger than one square.

Everything in the rules engine should be built so standard chess is just one configuration of a general system, never hardcoded.

## Tech

* Godot 4.7.2 (standard build, not .NET), GDScript only
* Renderer: Compatibility
* Indent with tabs (GDScript is strict about this)
* Repo: github.com/thedarkhorse99/ChessPlus, branch main
* Mac works on Windows; the project lives at C:\\Users<you>\\Documents\\Godot\\ChessPlus\\ (res:// = this folder)

## How Mac wants to work

* Claude writes the code AND the tests, runs the tests itself, and commits and pushes to main after each working step (clear commit message, tests passing). Mac doesn't need to approve each file before it's written.
* Mac is learning to code as he goes. After each step, explain what each new file and function does and why, in plain language. Don't dump large amounts of code without explanation.
* Always state the full location of every file and folder you reference or create, as both the res:// path and the Windows path.
* Work in small steps, each with its own passing tests and its own commit.
* Claude may create and edit test scenes and other plumbing files itself. Game-facing editor work (the playable scenes and their layout, Inspector work on .tres piece files, art) stays Mac's: give him numbered step-by-step instructions rather than hand-editing those files, unless he asks.
* Only stop to ask Mac about game design, art and content. Before adding any new piece type, mechanic, rule flag, or content, ask Mac what it should be named. Also ask him about art (which images, what they're called) before implementing anything that uses art.
* Design decisions for Chess Plus (budget size, placement rules, promotion rules, piece costs) are Mac's calls. Raise them as questions; don't decide them silently.
* Mac wants rigorous, honest feedback on his ideas, not reflexive praise.

### Decisions made so far

* Promotion options live in one game-wide rules list (standard chess: knight, bishop, rook, queen), so they can later become "pieces in your army".
* The 50-move rule resets on captures and on moves by pieces with a new PieceDef flag (to be named by Mac), which the pawn will have.

## Architecture rules

* `res://core/` is the rules engine: plain GDScript classes extending RefCounted. No Nodes and no scene-tree dependencies. That lets the AI copy game states cheaply and lets a headless server referee online games later.
* `res://data/pieces/` holds piece blueprints as PieceDef resources (.tres), created by Mac in the Inspector.
* `res://scenes/` is the playable game (UI, board visuals, menus). Visuals and animation (planned later with Tweens) must never contain rules logic.
* `res://tests/` holds test scenes and scripts players never see.
* Before naming any class or enum, check that Godot doesn't already use the name. `Side`, `Color`, `Node`, `Object`, `Rect2` are taken. (We already hit this: the team enum is `Piece.Team`, not `Side`.)
* Only Board's own functions touch the square storage. This keeps the door open for multi-square pieces (footprints) later. Don't build footprints yet.

## What exists so far

* `res://core/move\_rule.gd` — `MoveRule` (Resource): `directions: Array\[Vector2i]` as (files, ranks) from the owner's point of view, positive ranks = toward the opponent; `max\_steps` (1 = single step/leap, 0 = unlimited slide, stopping when blocked); `first\_move\_max\_steps` (if > 0, replaces max\_steps while the piece hasn't moved); `mode` (MOVE\_OR\_CAPTURE / MOVE\_ONLY / CAPTURE\_ONLY). A knight is (1,2)-type directions with max\_steps 1, so it can't be blocked.
* `res://core/piece\_def.gd` — `PieceDef` (Resource): id, display\_name, symbol, value, move\_rules: Array\[MoveRule], plus special-rule flags: is\_royal, promotes, en\_passant, can\_castle (king), castle\_partner (rook).
* `res://data/pieces/` — pawn, knight, bishop, rook, queen, king .tres files. The pawn has two rules: forward (0,1) max 1, first-move max 2, MOVE\_ONLY; diagonal (1,1)/(-1,1) max 1, CAPTURE\_ONLY. The king's value is 0 (not purchasable; every army will have exactly one).
* `res://core/piece.gd` — `Piece` (RefCounted): def, team (`Piece.Team.WHITE/BLACK`), has\_moved, letter().
* `res://core/board.gd` — `Board` (RefCounted): width/height (not hardcoded to 8), flat `\_squares` array indexed rank \* width + file, get\_piece (returns null off-board), set\_piece, is\_empty, in\_bounds, static square\_name, to\_text.
* `res://core/standard\_setup.gd` — `StandardSetup.create\_board()` builds the standard starting position.
* `res://tests/test\_board.tscn` + `test\_board.gd` — prints the starting position; passes.

## Current milestone: the move generator

Goal: a rules engine that produces every legal move in standard chess, driven entirely by the MoveRule/PieceDef data.

* Black's directions are White's with the rank component flipped.
* A move is legal if, after making it, the mover's royal piece is not attacked. This must work for any piece definition, not just standard chess.
* Castling, en passant and promotion are driven by the PieceDef flags, not by checking piece ids. Promotion options should be data, not hardcoded to the standard four, because Chess Plus promotion rules are still undecided (ask Mac).
* Needs a game state: board, side to move, en passant target, halfmove clock, position history (threefold repetition, 50-move rule), and checkmate/stalemate detection.
* Verify with perft (count all move sequences to depth N):

  * Starting position: depth 1 = 20, 2 = 400, 3 = 8,902, 4 = 197,281
  * "Kiwipete" (r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1), which exercises castling, en passant and promotion: depth 1 = 48, 2 = 2,039, 3 = 97,862
  * A FEN loader for test positions is fine to add.

## Notation (two different systems, don't mix them up)

* Positions (board text output, FEN): uppercase = White, lowercase = Black. This is the FEN standard, so `Piece.letter()` and `Board.to\_text()` use it, and the FEN loader must too.
* Moves (move list, game history, PGN export) use standard algebraic notation: piece letters are uppercase for BOTH colors (Nf3 ... Nc6); pawns get no letter (e4); "x" for captures, with a pawn capture written using its starting file (exd5); disambiguate by file, then rank (Nbd2, N1d2); castling O-O / O-O-O with the letter O (the PGN standard); promotion e8=Q; "+" for check, "#" for checkmate; results 1-0, 0-1, 1/2-1/2.
* Piece letters come from PieceDef.symbol, so new pieces get notation automatically. In Chess Plus, symbols must stay unique across all pieces. Single letters will eventually run out; how to handle that is Mac's design call, so ask him.

## Running tests

* Godot executable: C:\Tools\Godot\Godot\_v4.7.2-stable\_win64\_console.exe. Use the \_console build so output prints to the terminal.
* All tests: `"<godot console exe>" --headless --path . res://tests/run_tests.tscn`. Only some files: add `-- <word>` (e.g. `-- movegen`) to run files whose names contain that word. Functions named `slow_test_...` (deep perft) only run with `-- --slow`; run them before committing move-generator changes. The exit code is 1 if anything failed. In the editor, Mac can open `res://tests/run_tests.tscn` and press F6 (the Output panel's Log toggle must be on).
* A test file is `res://tests/<name>_test.gd`, extends `TestSuite`, and has functions named `test_...` that call `check(...)` / `check_eq(...)`. The runner finds them automatically; no scene needed.
* GDScript has no exceptions: a runtime error stops that test function early without marking it failed. Always scan test output for `SCRIPT ERROR` as well as the pass/fail summary.
* If a newly added `class\_name` isn't recognized when running headless, refresh Godot's class cache with `"<godot console exe>" --headless --path . --import` (or open the project in the editor once).
* Godot reloads scripts changed on disk. If Mac has the editor open and it asks whether to reload a file, he should choose Reload.
