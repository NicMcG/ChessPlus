//! The JSON interface the game uses (desktop: `plusfish evalgame` on stdin and
//! stdout; web: the WebAssembly build). One request evaluates positions from a
//! game; the reply is one JSON line per position.
//!
//! Request (one line of JSON):
//!   pieces    every piece type, as the game's PieceDef/MoveRule fields:
//!             {id, name, symbol, value, types, keywords, ability, dies_on_capture,
//!              rules: [{directions: [[x, y], ...], max_steps, first_move_max_steps,
//!              mode, captures_by_hopping, leap_steps, leap_over, path,
//!              mirror_files, mirror_ranks}]}
//!   width, height
//!   board     the starting position: [[piece id, team (0 White, 1 Black), file,
//!             rank, moved, shield_broken, ability_used], ...]
//!   side, halfmove, fullmove, ep ([[file, rank], ...]), ep_victim ([file, rank]
//!             or null), lost ([[piece id, team], ...]), promo ([piece id, ...]),
//!             castling_corner
//!   moves     the moves played since, as Move.to_text() ("e2-e4", "a1!c3", ...)
//!   plies     which positions to evaluate (number of moves played); default all
//!   nodes     search nodes per position (default 100000); depth (optional)
//!
//! Reply lines: {"ply", "cp" (White's point of view; mates are +-(20000 - plies)),
//! "mate" (null, or moves to mate: + White mates, - Black mates), "outcome",
//! "best" (move text), "best_san", "depth", "nodes"}.

use crate::defs::*;
use crate::eval::*;
use crate::game::*;
use crate::json::{quote, Json};
use crate::position::*;
use crate::search::*;
use std::sync::Arc;

fn num(j: &Json, key: &str, default: f64) -> f64 {
    j.get(key).and_then(|v| v.as_f64()).unwrap_or(default)
}

fn flag(j: &Json, key: &str) -> bool {
    match j.get(key) {
        Some(Json::Bool(b)) => *b,
        Some(Json::Num(n)) => *n != 0.0,
        _ => false,
    }
}

fn pairs(j: Option<&Json>) -> Vec<(i32, i32)> {
    j.and_then(|v| v.as_arr())
        .map(|a| {
            a.iter()
                .filter_map(|p| {
                    let p = p.as_arr()?;
                    Some((p.first()?.as_f64()? as i32, p.get(1)?.as_f64()? as i32))
                })
                .collect()
        })
        .unwrap_or_default()
}

fn rule_from_json(j: &Json) -> MoveRule {
    MoveRule {
        directions: pairs(j.get("directions")),
        max_steps: num(j, "max_steps", 1.0) as i32,
        first_move_max_steps: num(j, "first_move_max_steps", 0.0) as i32,
        mode: match num(j, "mode", 0.0) as i32 {
            1 => Mode::MoveOnly,
            2 => Mode::CaptureOnly,
            _ => Mode::MoveOrCapture,
        },
        captures_by_hopping: flag(j, "captures_by_hopping"),
        leap_steps: num(j, "leap_steps", 0.0) as i32,
        leap_over_own: num(j, "leap_over", 0.0) as i32 == 1,
        path: pairs(j.get("path")),
        mirror_files: flag(j, "mirror_files"),
        mirror_ranks: flag(j, "mirror_ranks"),
    }
}

/// Piece types from the request's "pieces" list.
pub fn catalog_from_json(j: &Json) -> Result<Catalog, String> {
    let list = j.as_arr().ok_or("pieces must be a list")?;
    let mut defs = Vec::new();
    for p in list {
        let s = |k: &str| p.get(k).and_then(|v| v.as_str()).unwrap_or("").to_string();
        let def = PieceDef {
            id: s("id"),
            name: s("name"),
            symbol: s("symbol"),
            value: num(p, "value", 0.0),
            rules: p.get("rules").and_then(|r| r.as_arr()).map(|r| r.iter().map(rule_from_json).collect()).unwrap_or_default(),
            types: num(p, "types", 0.0) as u8,
            keywords: num(p, "keywords", 0.0) as u8,
            ability: match num(p, "ability", 0.0) as i32 {
                1 => Ability::CrackShot,
                2 => Ability::RaiseDead,
                _ => Ability::None,
            },
            dies_on_capture: flag(p, "dies_on_capture"),
        };
        if def.id.is_empty() || def.symbol.is_empty() {
            return Err("every piece needs an id and a symbol".into());
        }
        defs.push(def);
    }
    if defs.is_empty() || defs.len() > MAX_KINDS {
        return Err(format!("need 1 to {} piece types", MAX_KINDS));
    }
    Ok(Catalog { defs })
}

/// Builds the game the request describes (start position plus moves).
pub fn game_from_request(req: &Json, cat: &Arc<Catalog>) -> Result<Game, String> {
    let w = num(req, "width", 8.0) as i32;
    let h = num(req, "height", 8.0) as i32;
    if w < 1 || h < 1 || (w * h) as usize > MAX_SQ || w > 26 {
        return Err(format!("board {}x{} is too big", w, h));
    }
    let kind = |id: &str| cat.kind_by_id(id).ok_or(format!("unknown piece {}", id));
    let mut placed: Vec<(usize, usize, usize, u16)> = Vec::new(); // square, kind, team, flags
    for e in req.get("board").and_then(|v| v.as_arr()).ok_or("board missing")? {
        let a = e.as_arr().ok_or("bad board entry")?;
        let id = a.first().and_then(|v| v.as_str()).ok_or("bad board entry")?;
        let n = |i: usize| a.get(i).and_then(|v| v.as_f64()).unwrap_or(0.0);
        let b = |i: usize| matches!(a.get(i), Some(Json::Bool(true))) || n(i) != 0.0;
        let (team, file, rank) = (n(1) as usize, n(2) as i32, n(3) as i32);
        if file < 0 || rank < 0 || file >= w || rank >= h || team > 1 {
            return Err("board entry off the board".into());
        }
        let mut flags = 0;
        if b(4) {
            flags |= MOVED;
        }
        if b(5) {
            flags |= BROKEN;
        }
        if b(6) {
            flags |= USED;
        }
        placed.push(((rank * w + file) as usize, kind(id)?, team, flags));
    }
    let mut promo: Vec<usize> = Vec::new();
    for p in req.get("promo").and_then(|v| v.as_arr()).map(|v| v.as_slice()).unwrap_or(&[]) {
        promo.push(kind(p.as_str().unwrap_or(""))?);
    }
    let mut lost: Vec<(usize, usize)> = Vec::new();
    for e in req.get("lost").and_then(|v| v.as_arr()).map(|v| v.as_slice()).unwrap_or(&[]) {
        let a = e.as_arr().ok_or("bad lost entry")?;
        lost.push((kind(a.first().and_then(|v| v.as_str()).unwrap_or(""))?, a.get(1).and_then(|v| v.as_f64()).unwrap_or(0.0) as usize));
    }
    let mut present: Vec<usize> = placed.iter().map(|p| p.1).collect();
    present.extend(promo.iter().copied());
    present.extend(lost.iter().map(|l| l.0));
    let corner = req.get("castling_corner").map(|_| flag(req, "castling_corner")).unwrap_or(true);
    let rules = Arc::new(Rules::new(cat.clone(), w, h, promo.iter().map(|&k| k as u8).collect(), corner, kinds_mask(present)));
    let r = &*rules;
    let mut p = Position::empty();
    for &(s, k, team, flags) in &placed {
        if p.sq[s] != 0 {
            return Err("two pieces on one square".into());
        }
        p.put(r, s, code(k, team) | flags);
    }
    p.set_side(r, if num(req, "side", 0.0) as i32 == 1 { BLACK } else { WHITE });
    p.halfmove = num(req, "halfmove", 0.0) as u32;
    p.fullmove = num(req, "fullmove", 1.0) as u32;
    for (x, y) in pairs(req.get("ep")) {
        if x >= 0 && y >= 0 && x < w && y < h {
            p.ep |= 1u128 << (y * w + x);
        }
    }
    if let Some(v) = req.get("ep_victim").and_then(|v| v.as_arr()) {
        if let (Some(x), Some(y)) = (v.first().and_then(|a| a.as_f64()), v.get(1).and_then(|a| a.as_f64())) {
            p.ep_victim = (y as i32 * w + x as i32) as u8;
        }
    }
    for (k, team) in lost {
        let n = p.lost[team.min(1)][k] + 1;
        p.set_lost(r, team.min(1), k, n);
    }
    let mut game = Game::new(rules.clone(), p);
    for mv in req.get("moves").and_then(|v| v.as_arr()).map(|v| v.as_slice()).unwrap_or(&[]) {
        let t = mv.as_str().unwrap_or("");
        game.play_text(t)?;
    }
    Ok(game)
}

/// Runs a request, calling `emit` with each reply line as it's ready.
pub fn eval_request(input: &str, emit: &mut dyn FnMut(String)) -> Result<(), String> {
    let req = Json::parse(input)?;
    let cat = Arc::new(catalog_from_json(req.get("pieces").ok_or("pieces missing")?)?);
    let game = game_from_request(&req, &cat)?;
    let r = &*game.rules;
    let mut params = Params::defaults(&cat);
    params.load_over(&cat, BUILTIN_PARAMS);
    let et = EvalTables::new(r);
    let total = game.moves.len();
    let plies: Vec<usize> = match req.get("plies").and_then(|v| v.as_arr()) {
        Some(list) => list.iter().filter_map(|v| v.as_f64()).map(|v| v as usize).filter(|&i| i <= total).collect(),
        None => (0..=total).collect(),
    };
    let limits = Limits {
        depth: req.get("depth").and_then(|v| v.as_f64()).map(|d| d as i32),
        nodes: Some(num(&req, "nodes", 100_000.0) as u64),
        movetime_ms: None,
    };
    // The position after each number of moves.
    let mut positions = vec![game.start.clone()];
    for &m in &game.moves {
        let mut next = positions.last().unwrap().clone();
        next.make(r, m);
        positions.push(next);
    }
    let mut searcher = Searcher::new(r, &et, &params, num(&req, "hash_mb", 16.0) as usize);
    for ply in plies {
        let pos = &positions[ply];
        let keys = &game.keys[..=ply];
        let outcome = pos.outcome(r, keys);
        let white = pos.side == WHITE;
        let (mut cp, mut mate, mut best, mut best_san, mut depth, mut nodes) = (0i32, None::<i32>, String::new(), String::new(), 0, 0u64);
        if outcome == Outcome::Checkmate {
            // The side to move has been mated.
            cp = if white { -20000 } else { 20000 };
            mate = Some(0);
        } else if outcome == Outcome::None {
            let rep = searcher.search(pos, &keys[..ply], limits, 1, |_| {});
            if let Some(line) = rep.lines.first() {
                let s = if white { line.score } else { -line.score };
                if s.abs() >= MATE_BOUND {
                    let moves = (MATE - s.abs() + 1) / 2;
                    mate = Some(if s > 0 { moves } else { -moves });
                    cp = s.signum() * (20000 - (MATE - s.abs()));
                } else {
                    cp = s;
                }
                if let Some(&m) = line.pv.first() {
                    best = move_text(r, m);
                    best_san = san(pos, r, m);
                }
            }
            depth = rep.depth;
            nodes = rep.nodes;
        }
        emit(format!(
            "{{\"ply\":{},\"cp\":{},\"mate\":{},\"outcome\":{},\"best\":{},\"best_san\":{},\"depth\":{},\"nodes\":{}}}",
            ply,
            cp,
            mate.map(|m| m.to_string()).unwrap_or("null".into()),
            quote(outcome_name(outcome)),
            quote(&best),
            quote(&best_san),
            depth,
            nodes
        ));
    }
    Ok(())
}
