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
* Claude does editor-type work itself whenever it can by editing files directly: scenes (.tscn), resources such as piece files (.tres), ticking flags, project settings. Only hand Mac a task when Claude literally can't do it (e.g. something that only works by clicking in the running editor, or creating art), and then give numbered step-by-step instructions.
* Only stop to ask Mac about game design, art and content. Before adding any new piece type, mechanic, rule flag, or content, ask Mac what it should be named. Also ask him about art (which images, what they're called) before implementing anything that uses art.
* Design decisions for Chess Plus (budget size, placement rules, promotion rules, piece costs) are Mac's calls. Raise them as questions; don't decide them silently.
* Mac wants rigorous, honest feedback on his ideas, not reflexive praise.

### Decisions made so far

* Promotion options live in one game-wide rules list (standard chess: knight, bishop, rook, queen), so they can later become "pieces in your army".
* Piece tags (Mac's design; future pieces reuse them). Types: **King** (the checkmate objective; exactly 1 per army, starting on the middle back-rank square(s) — d/e on 8 files; can castle), **Royal** (at most 1 royal piece besides the king), **Pawn** (any number; promotes on the far rank to any non-pawn, non-king piece type that started the game, from either army; takes part in en passant; resets the 50-move count). Keywords: **Jump** (label only: its moves are single leaps that can't be blocked), **Castle** (the king can castle with it). King = King+Royal, Queen = Royal, Pawn = Pawn, Knight/Elephant = Jump, Rook = Castle. Untagged pieces: at most 2 per army.
* The 50-move rule resets on captures and on pawn-type moves.
* Any unmoved pawn gets its first-move double step, even from the back row.
* Mobile is a must: portrait layout (720x1280 viewport, scales to any screen; 450x800 window on PC), tap-to-move (a mouse click works the same). Board uses classic light/dark squares (#F0D9B5 / #B58863).
* Piece art: the "Cburnett" set from Wikimedia Commons (Mac supplied the sprite sheet). It is licensed (CC BY-SA 3.0 / GPL / BSD / GFDL), so a published game must credit it (e.g. "Chess pieces by Cburnett, CC BY-SA 3.0") — remind Mac before any release. Style folder: `res://art/pieces/standard/`. New piece types will need matching art (ask Mac).
* Board orientation: White always at the bottom, nothing drawn upside down (no flipping).
* First custom piece: the **Elephant** (`res://data/pieces/elephant.tres`, symbol E): jumps exactly 2 squares diagonally (can't be blocked, stays on one colour), captures the same way. Value 1.5 (`PieceDef.value` is a float). Art: option F in `res://art/source/elephant_options/` — option D (side view facing left, dome head, hanging trunk, curved ivory tusk, notched ear sticking out behind) with the head shrunk to 85% and the base removed: the neck flares to a wide flat bottom like the knight's. `make_option_f.py` there regenerates it (head scale and anchor are arguments). A–E kept as earlier attempts.
* Custom piece art is drawn by Claude as SVG in the Cburnett style (45x45 canvas, 1.5 black outline, white or black fill, white detail lines on black pieces), saved in `res://art/source/pieces/<team>_<id>.svg`, rendered to PNG with `tools/render_piece_svg.gd`. Offer Mac a few options per piece.
* Armies (Mac's rules, set in `GameRules`): budget 39 points (pawns count too); pieces start only on the owner's first two rows; plus the tag limits above.
* Army builder (Mac's design): starts with an empty board; players name and save armies (max 10 saved); armies are edited outside games; before a match each player picks one of their saved armies.
* Castling only with a castle partner in a corner of its owner's back rank (`GameRules.castling_partner_in_corner`). King moves 2 squares toward it, as before.
* Promotion in army games: to any piece type on the board at the start (either army) except king and pawn types — so a queen is allowed. Most valuable listed first.
* Draws end the game automatically: 50-move rule, threefold repetition, and positions where checkmate is impossible (worked out from move data; custom pieces will need more thought later).

## Architecture rules

* `res://core/` is the rules engine: plain GDScript classes extending RefCounted. No Nodes and no scene-tree dependencies. That lets the AI copy game states cheaply and lets a headless server referee online games later.
* `res://data/pieces/` holds piece blueprints as PieceDef resources (.tres). Claude may create/edit them as text; Mac decides their names, rules and costs.
* `res://scenes/` is the playable game (UI, board visuals, menus). Visuals and animation (planned later with Tweens) must never contain rules logic.
* `res://tests/` holds test scenes and scripts players never see.
* Before naming any class or enum, check that Godot doesn't already use the name. `Side`, `Color`, `Node`, `Object`, `Rect2` are taken. (We already hit this: the team enum is `Piece.Team`, not `Side`.)
* Only Board's own functions touch the square storage. This keeps the door open for multi-square pieces (footprints) later. Don't build footprints yet.

## What exists so far

* `res://core/move\_rule.gd` — `MoveRule` (Resource): `directions: Array\[Vector2i]` as (files, ranks) from the owner's point of view, positive ranks = toward the opponent; `max\_steps` (1 = single step/leap, 0 = unlimited slide, stopping when blocked); `first\_move\_max\_steps` (if > 0, replaces max\_steps while the piece hasn't moved); `mode` (MOVE\_OR\_CAPTURE / MOVE\_ONLY / CAPTURE\_ONLY). `captures_by_hopping` (cannon-style: the first piece in the way is a screen; capture the first enemy beyond it; attack detection skips one screen too). A knight is (1,2)-type directions with max\_steps 1, so it can't be blocked.
* `res://core/piece\_def.gd` — `PieceDef` (Resource): id, display\_name, symbol, value, move\_rules: Array\[MoveRule], plus `types` (flags: King, Royal, Pawn) and `keywords` (flags: Jump, Castle, Promote, Shield) with helpers is_king_type(), is_royal_type(), is_pawn_type(), has_jump(), has_castle(), has_promote(), has_shield(), can_promote() (pawn type or Promote). The engine keys checkmate/castling off King type, en passant/promotion/50-move off Pawn type, castling partners off Castle.
* `res://data/pieces/` — pawn, knight, bishop, rook, queen, king .tres files. The pawn has two rules: forward (0,1) max 1, first-move max 2, MOVE\_ONLY; diagonal (1,1)/(-1,1) max 1, CAPTURE\_ONLY. The king's value is 0 (not purchasable; every army will have exactly one).
* `res://core/piece.gd` — `Piece` (RefCounted): def, team (`Piece.Team.WHITE/BLACK`), has\_moved, letter(), static other\_team().
* `res://core/board.gd` — `Board` (RefCounted): width/height (not hardcoded to 8), flat `\_squares` array indexed rank \* width + file, get\_piece (returns null off-board), set\_piece, is\_empty, in\_bounds, static square\_name / parse\_square, `NO_SQUARE`, to\_text.
* `res://core/game_rules.gd` — `GameRules` (Resource): game-wide rules; so far `promotion_options: Array[PieceDef]`.
* `res://core/move.gd` — `Move` (RefCounted): from, to, piece, captured, capture\_square (differs from `to` only for en passant), skipped\_squares (en passant targets created), promotion, castling partner/partner\_from/partner\_to, plus `prev_...` fields that make\_move fills in for undo. to\_text() gives test text like `e2-e4`, `e4xd5`, `e7-e8=Q` (not real notation).
* `res://core/game_state.gd` — `GameState` (RefCounted): board, rules, side\_to\_move, en\_passant\_squares/victim, halfmove\_clock, fullmove\_number, history (moves played); moves() (legal), is\_in\_check(), outcome() / result\_text(), make\_move / undo\_move (undo in reverse order), find\_move(text) for tests.
* `res://core/move_generator.gd` — `MoveGenerator` (static): legal\_moves (make, check royals, undo), pseudo\_legal\_moves, is\_in\_check, is\_attacked (walks each enemy piece type's capture rays backwards from the square). En passant, castling and promotion all keyed off PieceDef flags + GameRules.
* `res://core/fen.gd` — `Fen.parse(text, defs, rules)` / `Fen.write(state)`. Board size comes from the FEN; has\_moved is inferred from castling rights and pawns' starting ranks.
* `res://core/notation.gd` — `Notation`: san(state, move), find_move(state, san) (check marks optional), move_list(state) ("1. e4 e5 2. Nf3", plus the result if the game is over).
* `res://core/standard_setup.gd` — `StandardSetup`: piece\_defs(), create\_rules(), create\_board(), create\_game(), from\_fen(fen).
* `res://art/source/chess_pieces_sprite.webp` — the original piece sheet (folder has a .gdignore so it isn't imported). `res://tools/slice_piece_sprite.gd` cuts it into `res://art/pieces/standard/<team>_<piece id>.png` (mipmaps on in the .import files). Run: `"<godot console exe>" --headless --path . -s res://tools/slice_piece_sprite.gd`.
* `res://tools/render_piece_svg.gd` — renders every SVG in `res://art/source/pieces/` to a 320px PNG in `res://art/pieces/standard/` (then set `mipmaps/generate=true` in the new .import files). Run: `"<godot console exe>" --headless --path . -s res://tools/render_piece_svg.gd`.
* `res://core/army.gd` — `Army` (Resource): army_name, pieces: Array[ArmyPiece]; place/remove_at/def_at, cost(), count_of(), static max_copies(def, rules), static king_files(width), problems(rules, width) -> plain-English list of rule breaks (empty = legal), is_valid().
* `res://core/army_piece.gd` — `ArmyPiece` (Resource): def + square as (file, row from the owner's edge). Files aren't mirrored for Black.
* `res://core/army_setup.gd` — `ArmySetup.create_game(white, black, rules)`: builds a GameState from two armies (Black's rows flipped), with a duplicated GameRules whose promotion_options come from promotion_options_for(board). `StandardSetup.army()` is the standard set as an Army.
* `res://core/piece_catalog.gd` — `PieceCatalog.all_defs()`: every PieceDef in `res://data/pieces/`. Use it (not `StandardSetup.piece_defs()`) when any piece type may appear.
* `res://scenes/sandbox/elephant_sandbox.tscn` — the game screen starting from a custom FEN (`game.gd`'s `start_fen` export), with elephants on c3/f3/c6/f6. Open it and press F6 to try the elephant.
* `res://tools/screenshot.gd` — opens the game screen, plays SAN moves / `tap:e2` / `hold:g1>f3` (drag held partway) / `fen:<fen with _ for spaces>`, saves a PNG. Needs a window (no --headless): `"<godot console exe>" --path . --resolution 720x1280 -s res://tools/screenshot.gd -- <out.png> e4 e5 tap:g1`. Use it to check UI changes visually.
* `res://scenes/main/main.tscn` + `main.gd` — the app's main scene: shows one screen at a time (main menu, My armies, army builder, Choose armies, game) and owns the ArmyLibrary.
* `res://scenes/menu/` — `main_menu` (Play / My armies) and `match_setup` (each side picks Standard or a saved legal army, then Start).
* `res://scenes/armies/` — `army_list` (saved armies with cost, tap to edit, Delete with confirmation, New army disabled at 10), `army_builder` (name box, points counter, `ArmyBoard` showing the two starting rows with allowed king squares highlighted, tray of every PieceCatalog type with cost and "N left"; tap type then squares to place, tap a placed piece to remove/swap; problems in red; Save only when legal; edits a copy), `army_board.gd` (`ArmyBoard`).
* `res://core/army_library.gd` — `ArmyLibrary`: saves armies as .tres in `user://armies/` (max 10), armies() loads fresh copies sorted by name, save() overwrites an army's own file or makes a new one, delete(). Tests use their own folder (`user://test_armies/`).
* `res://scenes/common/piece_art.gd` — `PieceArt.texture_for(def, team)`: shared piece-image lookup.
* `res://scenes/theme.tres` — project theme (default font size 30), set in Project Settings > GUI > Theme.
* `res://scenes/game/game.tscn` + `game.gd` — the game screen (pass-and-play): status line, board, move list, Undo / Menu / New game buttons, promotion picker overlay. Plays two armies if `white_army`/`black_army` are set (New game replays them), else `start_fen`, else standard. Menu only shows when the main scene listens for `menu_requested`.
* `res://scenes/game/board_view.gd` — `BoardView` (Control): draws board/pieces/highlights (last move, selection, check, move dots/rings), tap(square) and pointer_down/move/up (drag to move; tap-tap still works), signals move_chosen / choice_needed. Images looked up by piece id; falls back to drawing the letter if a piece has no image.
* `res://tests/` — `run_tests.tscn` runs every `*_test.gd` (see Running tests). Perft matches the start position (depth 4), Kiwipete (depth 3), and CPW positions 3 (depth 5), 4 (depth 4) and 5 (depth 3).

## Current milestone: armies (Chess Plus phase 2)

Steps 1–4 DONE: army data and rules, army builder screen, saving up to 10 armies, choosing armies before a pass-and-play match. Possible next: a computer opponent, more custom pieces, polish (animation, sounds).

## Custom pieces (Mac's designs)

* Man (M, 3): one step any direction, no tags.
* Cannon (C, 4): moves like a rook; captures only by hopping exactly one piece (`captures_by_hopping`). No keywords.
* Lance (L, 2.5): slides straight forward only; Promote keyword (same choices as pawns). Its moves do NOT reset the 50-move count (Mac's call).
* Paladin (PD, 2): one step orthogonally; Shield keyword. First capture only breaks the shield: attacker stays put, turn used, counts as a capture for the 50-move rule; the shield never returns. Consequence (told to Mac): a shielded piece giving check can't be removed by "capturing" it — the king must move or block.
* Symbols: one or two capital letters (Mac's decision). Notation writes them as-is (PDe4); FEN wraps two-letter symbols in brackets ((PD)/(pd)) and marks a broken shield with ' after the piece. A shield break is written like a capture with * on the end (Rxd5*); it moves nothing, so it never gives check.
* Art: paladin approved (armoured knight behind a big cross shield; `<team>_paladin_wounded` without it, shown once the shield breaks via `PieceArt` variant "wounded"). Cannon and lance: only the symbols from Mac's references, as standing pieces (no token, no tile): a cannon pointing right on its wheel and hooked trail; a barbed arrowhead on a bell-shaped base. Man: Mac choosing between options A–E (`piece_options/round2/`) and F–J (`piece_options/round3/`); A, plain bust, is in use. Sources in `res://art/source/piece_options/` (`make_pieces.py` scripts draw them).

## Previous milestone: playable board (pass and play)

Done: tap- and drag-to-move board, undo, promotion picker, results, move list, Cburnett pieces. Possible later: move animation (Tweens), menus, sounds.

## Previous milestone: the move generator

Status: DONE. Legal moves, en passant, castling, promotion, 50-move rule, threefold repetition, insufficient material and checkmate/stalemate (`GameState.outcome()` / `result_text()`), all tested and perft-verified. Standard algebraic notation (`Notation`) is done too.

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
* Piece letters come from PieceDef.symbol, so new pieces get notation automatically. In Chess Plus, symbols must stay unique across all pieces. Mac's decision: single letters for now; revisit only when they actually run out.
* Only the piece whose symbol is "P" goes without a letter (`Notation.NO_LETTER_SYMBOL`), so a bare square always means exactly one piece type.

## Running tests

* Godot executable: C:\Tools\Godot\Godot\_v4.7.2-stable\_win64\_console.exe. Use the \_console build so output prints to the terminal.
* All tests: `"<godot console exe>" --headless --path . res://tests/run_tests.tscn`. Only some files: add `-- <word>` (e.g. `-- movegen`) to run files whose names contain that word. Functions named `slow_test_...` (deep perft) only run with `-- --slow`; run them before committing move-generator changes. The exit code is 1 if anything failed. In the editor, Mac can open `res://tests/run_tests.tscn` and press F6 (the Output panel's Log toggle must be on).
* A test file is `res://tests/<name>_test.gd`, extends `TestSuite`, and has functions named `test_...` that call `check(...)` / `check_eq(...)`. The runner finds them automatically; no scene needed.
* GDScript has no exceptions: a runtime error stops that test function early. The runner counts every logged error (a `Logger` registered with `OS.add_logger`) and fails the test it happened in, so errors can't hide behind a PASS. Tests may add scenes to the tree (`Engine.get_main_loop().root`); free them at the end.
* If a newly added `class\_name` isn't recognized when running headless, refresh Godot's class cache with `"<godot console exe>" --headless --path . --import` (or open the project in the editor once).
* Godot reloads scripts changed on disk. If Mac has the editor open and it asks whether to reload a file, he should choose Reload.
* Before deleting or renaming a scene or script, ask Mac to close its tab in the editor (or close Godot). Otherwise the editor re-saves open scenes on exit, re-creating deleted files that then fail to load (this happened with the old test_board/test_movegen scenes).
