//! `plusfish spsa`: tunes the search constants (`SearchParams`) by SPSA
//! (simultaneous perturbation stochastic approximation). Each step moves
//! every constant up or down by c_k at random (θ+ = θ + c_k Δ, θ- = θ - c_k Δ),
//! plays a pair of games θ+ against θ- (random armies, same opening, colours
//! swapped, fixed nodes per move) and moves θ towards the side that scored
//! more. Games are played in this process (no engine programs to start), the
//! way enginematch's engines play them: hash table and history kept between
//! moves, the same adjudication. Steps run on several threads at once, each
//! using θ as it is when its pair starts.
//!
//! Gains follow fishtest's SPSA: c_k = c / k^0.101 and a_k = a / (A + k)^0.602,
//! with c set so the last steps perturb by each constant's `c` (ParamSpec) and
//! a so the last steps' R = a_k / c_k^2 is --r-end; A = 10% of the steps.

use plusfish_core::army::*;
use plusfish_core::defs::*;
use plusfish_core::eval::*;
use plusfish_core::game::*;
use plusfish_core::position::*;
use plusfish_core::search::*;
use plusfish_core::selfplay::*;
use plusfish_core::util::{Args, Rng};
use std::io::Write;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Instant;

pub const HELP: &str = "\
spsa: tune the search constants (SearchParams) by SPSA self-play.
  --pairs N            steps (one game pair each, θ+ vs θ-; default 10000)
  --nodes N            nodes per move (default 6000)
  --concurrency N      pairs at once (default 4)
  --r-end R            step size at the end, R = a_k / c_k^2 per pair (default 0.0075)
  --c-scale S          multiply every constant's perturbation c (default 1)
  --only a,b,c         tune just these constants   --skip a,b   all but these
  --start <file|a=1;b=2>  start from these values (a log line or name=value list)
  --log <file>         θ every --log-every pairs (default 100), appended
  --hash MB (default 16)  --random-plies N (default 8)  --seed N (default 1)
  --params <file>      evaluation weights (default: the built-in ones)
Prints the final values as name=value;... (for enginematch --uci-a).
";

/// One game between two searchers. Returns A's score (1, 0.5, 0).
#[allow(clippy::too_many_arguments)]
fn play(g0: &Game, et: &EvalTables, params: &Params, opening: &[Move], spa: &SearchParams, spb: &SearchParams, a_white: bool, nodes: u64, hash: usize) -> f32 {
    let mut g = g0.clone();
    for &m in opening {
        g.play(m);
    }
    let rules = g.rules.clone();
    let r = &*rules;
    // Each side's tables, kept between its moves (as the UCI engine does).
    let mut tables: [Option<SearchTables>; 2] = [None, None];
    let mut win_streak = 0i32;
    let mut draw_streak = 0;
    let white_score_of = |res: f32| if a_white { res } else { 1.0 - res };
    for ply in opening.len()..400 {
        let out = g.outcome();
        if out != Outcome::None {
            let res = out.white_score(g.pos.side).unwrap_or(0.5) as f32;
            return white_score_of(res);
        }
        let side = g.pos.side;
        let a_to_move = (side == WHITE) == a_white;
        let mut s = match tables[side].take() {
            Some(t) => Searcher::with_tables(r, et, params, t),
            None => Searcher::new(r, et, params, hash),
        };
        s.sp = if a_to_move { *spa } else { *spb };
        let rep = s.search(&g.pos, &g.keys[..g.keys.len() - 1], Limits { depth: None, nodes: Some(nodes), movetime_ms: None, soft_ms: None }, 1, |_| {});
        tables[side] = Some(s.into_tables());
        let line = &rep.lines[0];
        let m = match line.pv.first() {
            Some(&m) => m,
            None => {
                let res = if side == WHITE { 0.0 } else { 1.0 };
                return white_score_of(res);
            }
        };
        let white_score = if side == WHITE { line.score } else { -line.score };
        if white_score.abs() >= 1000 {
            if white_score.signum() == win_streak.signum() || win_streak == 0 {
                win_streak += white_score.signum();
            } else {
                win_streak = white_score.signum();
            }
        } else {
            win_streak = 0;
        }
        if win_streak.abs() >= 6 {
            return white_score_of(if win_streak > 0 { 1.0 } else { 0.0 });
        }
        if ply >= 120 && white_score.abs() <= 15 {
            draw_streak += 1;
        } else {
            draw_streak = 0;
        }
        if draw_streak >= 24 {
            return 0.5;
        }
        g.play(m);
    }
    0.5
}

/// "a=1;b=2" or a log line ("... a=1.23 b=4.5") -> (name, value) pairs.
fn parse_values(text: &str) -> Vec<(String, f64)> {
    text.split(|c: char| c == ';' || c.is_whitespace())
        .filter_map(|w| w.split_once('='))
        .filter_map(|(n, v)| v.trim().parse::<f64>().ok().map(|v| (n.trim().to_string(), v)))
        .collect()
}

fn to_params(theta: &[f64], idx: &[usize]) -> SearchParams {
    let mut sp = SearchParams::default();
    for (k, &i) in idx.iter().enumerate() {
        sp.set(SEARCH_PARAM_SPECS[i].name, theta[k].round() as i32);
    }
    sp
}

pub fn run(cat: &Arc<Catalog>, args: &Args, params: &Params) {
    let pairs: usize = args.num("pairs", 10000);
    let nodes: u64 = args.num("nodes", 6000);
    let conc: usize = args.num("concurrency", 4);
    let r_end: f64 = args.num("r-end", 0.0075);
    let c_scale: f64 = args.num("c-scale", 1.0);
    let hash: usize = args.num("hash", 16);
    let rplies: usize = args.num("random-plies", 8);
    let seed: u64 = args.num("seed", 1);
    let log_every: usize = args.num("log-every", 100);
    let list = |k: &str| -> Vec<String> { args.get(k).map(|s| s.split(',').map(|x| x.trim().to_string()).filter(|x| !x.is_empty()).collect()).unwrap_or_default() };
    let (only, skip) = (list("only"), list("skip"));
    for n in only.iter().chain(skip.iter()) {
        if !SEARCH_PARAM_SPECS.iter().any(|s| s.name == n) {
            panic!("no search constant called {}", n);
        }
    }
    let idx: Vec<usize> = (0..SEARCH_PARAM_SPECS.len())
        .filter(|&i| {
            let n = SEARCH_PARAM_SPECS[i].name.to_string();
            (only.is_empty() || only.contains(&n)) && !skip.contains(&n)
        })
        .collect();
    let specs: Vec<ParamSpec> = idx.iter().map(|&i| SEARCH_PARAM_SPECS[i]).collect();
    let mut theta: Vec<f64> = specs.iter().map(|s| s.default as f64).collect();
    if let Some(st) = args.get("start") {
        let text = std::fs::read_to_string(st).ok().and_then(|t| t.lines().filter(|l| l.contains('=')).last().map(|l| l.to_string())).unwrap_or_else(|| st.to_string());
        for (n, v) in parse_values(&text) {
            if let Some(k) = specs.iter().position(|s| s.name == n) {
                theta[k] = v;
            }
        }
    }
    let n = pairs as f64;
    let big_a = 0.1 * n;
    let (alpha, gamma) = (0.602f64, 0.101f64);
    // Per constant: c (so c_N = c_end) and a (so a_N / c_N^2 = r_end).
    let c0: Vec<f64> = specs.iter().map(|s| s.c * c_scale * n.powf(gamma)).collect();
    let a0: Vec<f64> = specs.iter().map(|s| r_end * (s.c * c_scale).powi(2) * (big_a + n).powf(alpha)).collect();
    let log_path = args.get("log").map(|s| s.to_string());
    let write_log = |line: &str| {
        if let Some(p) = &log_path {
            if let Ok(mut f) = std::fs::OpenOptions::new().create(true).append(true).open(p) {
                let _ = writeln!(f, "{}", line);
            }
        }
    };
    let theta_text = |th: &[f64]| specs.iter().zip(th).map(|(s, v)| format!("{}={:.2}", s.name, v)).collect::<Vec<_>>().join(" ");
    println!("SPSA: {} constants, {} pairs, {} nodes/move, {} at once, r_end {}", specs.len(), pairs, nodes, conc, r_end);
    write_log(&format!("# start {} pairs {} nodes r_end {} c_scale {} seed {}", pairs, nodes, r_end, c_scale, seed));
    write_log(&format!("pairs 0 {}", theta_text(&theta)));
    struct State {
        theta: Vec<f64>,
        done: usize,
        /// θ+'s points minus θ-'s, per game, summed (shows how decisive steps are).
        plus_wins: usize,
        draws: usize,
        minus_wins: usize,
    }
    let state = Mutex::new(State { theta: theta.clone(), done: 0, plus_wins: 0, draws: 0, minus_wins: 0 });
    let next = AtomicUsize::new(0);
    let t0 = Instant::now();
    std::thread::scope(|scope| {
        for _ in 0..conc.max(1) {
            scope.spawn(|| loop {
                let k = next.fetch_add(1, Ordering::SeqCst);
                if k >= pairs {
                    break;
                }
                let mut rng = Rng::new(seed.wrapping_mul(1_000_003).wrapping_add(k as u64));
                let kf = (k + 1) as f64;
                let ck: Vec<f64> = c0.iter().map(|c| c / kf.powf(gamma)).collect();
                let ak: Vec<f64> = a0.iter().map(|a| a / (big_a + kf).powf(alpha)).collect();
                let delta: Vec<f64> = (0..specs.len()).map(|_| if rng.next() & 1 == 0 { 1.0 } else { -1.0 }).collect();
                let th = state.lock().unwrap().theta.clone();
                let clampf = |i: usize, v: f64| v.clamp(specs[i].min as f64, specs[i].max as f64);
                let plus: Vec<f64> = (0..specs.len()).map(|i| clampf(i, th[i] + ck[i] * delta[i])).collect();
                let minus: Vec<f64> = (0..specs.len()).map(|i| clampf(i, th[i] - ck[i] * delta[i])).collect();
                let (spp, spm) = (to_params(&plus, &idx), to_params(&minus, &idx));
                let (w, bl) = random_pair(cat, &mut rng, (BUDGET, BUDGET));
                let mut g = army_game(cat, &w, &bl, 8, 8);
                let g0 = g.clone();
                let rules = g.rules.clone();
                let et = EvalTables::new(&rules);
                let opening = {
                    let mut s = Searcher::new(&rules, &et, params, 4);
                    let mut moves = Vec::new();
                    for _ in 0..rplies {
                        if g.outcome() != Outcome::None {
                            break;
                        }
                        let m = pick_opening_move(&mut s, &g, &mut rng);
                        moves.push(m);
                        g.play(m);
                    }
                    moves
                };
                let s1 = play(&g0, &et, params, &opening, &spp, &spm, true, nodes, hash);
                let s2 = play(&g0, &et, params, &opening, &spp, &spm, false, nodes, hash);
                // θ+'s score minus θ-'s, per game: -1..1.
                let y = (s1 + s2) as f64 - 1.0;
                let mut st = state.lock().unwrap();
                for i in 0..specs.len() {
                    let step = ak[i] / ck[i] * y * delta[i];
                    st.theta[i] = clampf(i, st.theta[i] + step);
                }
                for s in [s1, s2] {
                    if s == 1.0 {
                        st.plus_wins += 1;
                    } else if s == 0.0 {
                        st.minus_wins += 1;
                    } else {
                        st.draws += 1;
                    }
                }
                st.done += 1;
                if st.done % log_every == 0 || st.done == pairs {
                    let line = format!("pairs {} {}", st.done, theta_text(&st.theta));
                    write_log(&line);
                    eprintln!(
                        "  {} pairs ({:.0}s, plus side +{} ={} -{}): {}",
                        st.done,
                        t0.elapsed().as_secs_f64(),
                        st.plus_wins,
                        st.draws,
                        st.minus_wins,
                        theta_text(&st.theta)
                    );
                }
            });
        }
    });
    let st = state.into_inner().unwrap();
    let fin = to_params(&st.theta, &idx);
    println!("\nFinal values (rounded):");
    for (k, s) in specs.iter().enumerate() {
        println!("  {:<18} {:>6} -> {:>6}  ({:.2})", s.name, s.default, fin.get(s.name).unwrap(), st.theta[k]);
    }
    println!("uci: {}", fin.changed_text());
    println!("Time: {:.0}s", t0.elapsed().as_secs_f64());
}
