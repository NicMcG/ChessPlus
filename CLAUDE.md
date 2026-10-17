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

* Mac is learning to code as he goes. Explain what each new file and function does and why, in plain language. Don't dump large amounts of code without explanation.
* Always state the full location of every file and folder you reference or create, as both the res:// path and the Windows path.
* Work in small steps. After each working step, remind Mac to commit and push.
* Anything done by clicking in the Godot editor (scenes, nodes, Inspector, .tres piece files, art) is Mac's to do. Give him numbered step-by-step instructions rather than hand-editing .tscn/.tres files, unless he asks.
* Before adding any new piece type, mechanic, or content, ask Mac what it should be named. Also ask him about art (which images, what they're called) before implementing anything that uses art.
* Design decisions for Chess Plus (budget size, placement rules, promotion rules, piece costs) are Mac's calls. Raise them as questions; don't decide them silently.
* Mac wants rigorous, honest feedback on his ideas, not reflexive praise.

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

* Godot executable: C:\\Tools\\Godot\\Godot\_v4.7.2-stable\_win64\_console.exe. Use the \_console build so output prints to the terminal.
* Run a test scene headless: `"<godot console exe>" --headless --path . res://tests/<scene>.tscn`. Test scripts must call `get\_tree().quit()` when finished, or the process won't exit.
* If a newly added `class\_name` isn't recognized when running headless, refresh Godot's class cache with `"<godot console exe>" --headless --path . --import` (or open the project in the editor once).
* Before editing any file, remind Mac to save everything in the Godot editor, so unsaved editor changes don't collide with your edits.

