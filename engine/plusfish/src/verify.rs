//! Checking Plusfish's rules against the game's own GDScript engine: perft on
//! known positions, and replaying random games traced by the game itself
//! (`verify/plusfish_trace.gd`), comparing every position's FEN, legal moves,
//! check and outcome.

use crate::army::*;
use crate::defs::*;
use crate::game::*;
use crate::json::Json;
use crate::position::*;
use crate::util::Rng;
use std::sync::Arc;

/// Known perft counts (standard chess) from the Chess Programming Wiki, the
/// same ones the game's perft_test.gd checks.
pub const PERFT_SUITE: &[(&str, &[u64])] = &[
    (STANDARD_FEN, &[20, 400, 8902, 197281, 4865609]),
    ("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1", &[48, 2039, 97862, 4085603]),
    ("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1", &[14, 191, 2812, 43238, 674624]),
    ("r3k2r/Pppp1ppp/1b3nbN/nP6/BBP1P3/q4N2/Pp1P2PP/R2Q1RK1 w kq - 0 1", &[6, 264, 9467, 422333]),
    ("rnbq1k1r/pp1Pbppp/2p5/8/2B5/8/PPP1NnPP/RNBQK2R w KQ - 1 8", &[44, 1486, 62379, 2103487]),
];

pub fn run_perft_suite(cat: &Arc<Catalog>) -> bool {
    let mut ok = true;
    for (fen, counts) in PERFT_SUITE {
        let g = game_from_fen(cat, fen, None).expect("bad suite FEN");
        for (d, &want) in counts.iter().enumerate() {
            let t = std::time::Instant::now();
            let got = perft(&g.pos, &g.rules, d as u32 + 1);
            let pass = got == want;
            ok &= pass;
            println!(
                "{} depth {}: {} (expected {}) {:.2}s{}",
                if pass { "PASS" } else { "FAIL" },
                d + 1,
                got,
                want,
                t.elapsed().as_secs_f64(),
                if d == 0 { format!("  {}", fen) } else { String::new() }
            );
        }
    }
    ok
}

fn army_line(cat: &Catalog, a: &Army) -> String {
    a.pieces.iter().map(|p| format!("{}@{},{}", cat.defs[p.0].id, p.1, p.2)).collect::<Vec<_>>().join(";")
}

/// Writes random army pairs for the GDScript tracer.
pub fn write_trace_games(cat: &Catalog, count: usize, seed: u64, plies: usize) -> String {
    let mut rng = Rng::new(seed);
    let mut out = String::new();
    for i in 0..count {
        let w = random_army(cat, &mut rng);
        let b = if i % 5 == 0 { w.clone() } else { random_army(cat, &mut rng) };
        out += &format!("{}|{}|{}|{}\n", army_line(cat, &w), army_line(cat, &b), seed * 1000 + i as u64, plies);
    }
    out
}

fn parse_army_line(cat: &Catalog, s: &str) -> Army {
    let mut pieces = Vec::new();
    for item in s.split(';').filter(|x| !x.is_empty()) {
        let (id, sq) = item.split_once('@').unwrap();
        let (f, r) = sq.split_once(',').unwrap();
        pieces.push((cat.kind_by_id(id).unwrap(), f.parse().unwrap(), r.parse().unwrap()));
    }
    // The game's tracer builds a plain Army, which is mirrored for Black.
    Army { name: String::new(), pieces, mirror: true }
}

fn outcome_code(o: Outcome) -> i64 {
    match o {
        Outcome::None => 0,
        Outcome::Checkmate => 1,
        Outcome::Stalemate => 2,
        Outcome::FiftyMoves => 3,
        Outcome::Repetition => 4,
        Outcome::Insufficient => 5,
    }
}

/// Replays the traced games; returns (positions checked, mismatches).
pub fn check_trace(cat: &Arc<Catalog>, games_text: &str, trace_text: &str, max_report: usize) -> (usize, usize) {
    let games: Vec<(Army, Army)> = games_text
        .lines()
        .filter(|l| !l.trim().is_empty())
        .map(|l| {
            let p: Vec<&str> = l.split('|').collect();
            (parse_army_line(cat, p[0]), parse_army_line(cat, p[1]))
        })
        .collect();
    let mut checked = 0;
    let mut bad = 0;
    let mut current: Option<(usize, Game)> = None;
    let mut skip_game = usize::MAX;
    for line in trace_text.lines() {
        if line.trim().is_empty() {
            continue;
        }
        let rec = match Json::parse(line) {
            Ok(r) => r,
            Err(e) => {
                println!("bad trace line: {}", e);
                continue;
            }
        };
        let gi = rec.get("g").and_then(|v| v.as_f64()).unwrap() as usize;
        if gi == skip_game {
            continue;
        }
        if current.as_ref().map(|c| c.0) != Some(gi) {
            let (w, b) = &games[gi];
            current = Some((gi, army_game(cat, w, b, 8, 8)));
        }
        let (_, game) = current.as_mut().unwrap();
        let ply = rec.get("ply").and_then(|v| v.as_f64()).unwrap() as usize;
        let r = game.rules.clone();
        let mut problems = Vec::new();
        let want_fen = rec.get("fen").and_then(|v| v.as_str()).unwrap();
        let got_fen = fen(&game.pos, &r, false);
        if want_fen != got_fen {
            problems.push(format!("FEN differs:\n  game:     {}\n  plusfish: {}", want_fen, got_fen));
        }
        let want: Vec<String> = rec.get("moves").and_then(|v| v.as_arr()).unwrap().iter().map(|m| m.as_str().unwrap().to_string()).collect();
        let mut got: Vec<String> = game.pos.legal_moves(&r).into_iter().map(|m| move_text(&r, m)).collect();
        got.sort();
        if want != got {
            let missing: Vec<_> = want.iter().filter(|m| !got.contains(m)).collect();
            let extra: Vec<_> = got.iter().filter(|m| !want.contains(m)).collect();
            problems.push(format!("moves differ: missing {:?}, extra {:?} (counts {} vs {})", missing, extra, want.len(), got.len()));
        }
        let want_check = rec.get("check").and_then(|v| v.as_bool()).unwrap();
        if want_check != game.pos.in_check(&r, game.pos.side) {
            problems.push(format!("check differs: game says {}", want_check));
        }
        let want_out = rec.get("outcome").and_then(|v| v.as_f64()).unwrap() as i64;
        let got_out = outcome_code(game.outcome());
        if want_out != got_out {
            problems.push(format!("outcome differs: game {} plusfish {}", want_out, got_out));
        }
        checked += 1;
        if !problems.is_empty() {
            bad += 1;
            if bad <= max_report {
                println!("game {} ply {}: {}", gi, ply, want_fen);
                for p in &problems {
                    println!("  {}", p);
                }
                println!("  moves so far: {}", game.moves.iter().map(|&m| move_text(&r, m)).collect::<Vec<_>>().join(" "));
            }
            skip_game = gi;
            continue;
        }
        if let Some(played) = rec.get("played").and_then(|v| v.as_str()) {
            if game.play_text(played).is_err() {
                println!("game {} ply {}: can't play {}", gi, ply, played);
                bad += 1;
                skip_game = gi;
            }
        }
    }
    (checked, bad)
}
