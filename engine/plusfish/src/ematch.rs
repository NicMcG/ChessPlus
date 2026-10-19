//! `plusfish enginematch`: two engine programs play each other through the UCI
//! protocol, so changes to the engine's code (not just its weights) can be
//! measured. Random army pairs; each pair is played twice from the same
//! opening with colours swapped. Results are counted per pair (pentanomial),
//! which gives honest error bars, and an SPRT can stop the match early.
//!
//! This is a native-only tool (processes and threads), so it lives in the
//! program, not the library the WebAssembly build uses.

use plusfish_core::army::*;
use plusfish_core::defs::*;
use plusfish_core::eval::*;
use plusfish_core::game::*;
use plusfish_core::position::*;
use plusfish_core::search::*;
use plusfish_core::selfplay::*;
use plusfish_core::util::{Args, Rng};
use std::io::{BufRead, BufReader, Write};
use std::process::{Child, ChildStdin, ChildStdout, Command, Stdio};
use std::sync::atomic::{AtomicBool, AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};
use std::time::Instant;

pub const HELP: &str = "\
enginematch: two engine programs play each other over UCI (random armies,
each pair of games from the same opening with colours swapped).
  --engine-a <exe> --engine-b <exe>    (A is the one being tested)
  --nodes N             nodes per move (default 6000); --nodes-b N gives B
                        a different number (to calibrate)
  --tc BASE+INC         or a clock per game, seconds (e.g. 10+0.1)
  --movetime MS         or a fixed time per move
  --pairs N             most pairs to play (default 1000)
  --sprt E0,E1          stop early once A is shown to be E0 or E1 Elo better
                        (e.g. 0,5; 95% confidence both ways)
  --concurrency N       games at once (default: all cores)
  --hash MB             (default 16)   --uci-a / --uci-b \"Name=Value;...\"
  --random-plies N      opening plies picked among good moves (default 8)
  --seed N              which army pairs and openings (default 1)
  --standard            standard armies instead of random ones
  --pool <file>         armies from a pool file (first column of each line,
                        as armies/pool.txt): every ordered pair of different
                        armies in turn, a new random opening each time
";

struct Engine {
    child: Child,
    stdin: ChildStdin,
    stdout: BufReader<ChildStdout>,
    name: String,
}

impl Engine {
    fn start(exe: &str, pieces: &str, hash: usize, options: &str) -> Engine {
        let mut child = Command::new(exe)
            .args(["uci", "--pieces", pieces])
            .stdin(Stdio::piped())
            .stdout(Stdio::piped())
            .stderr(Stdio::null())
            .spawn()
            .unwrap_or_else(|e| panic!("can't start {}: {}", exe, e));
        let stdin = child.stdin.take().unwrap();
        let stdout = BufReader::new(child.stdout.take().unwrap());
        let mut e = Engine { child, stdin, stdout, name: exe.to_string() };
        e.send("uci");
        e.wait_for("uciok");
        e.send(&format!("setoption name Hash value {}", hash));
        for opt in options.split(';').map(|s| s.trim()).filter(|s| !s.is_empty()) {
            let (n, v) = opt.split_once('=').unwrap_or((opt, ""));
            e.send(&format!("setoption name {} value {}", n.trim(), v.trim()));
        }
        e.send("isready");
        e.wait_for("readyok");
        e
    }

    fn send(&mut self, line: &str) {
        writeln!(self.stdin, "{}", line).and_then(|_| self.stdin.flush()).unwrap_or_else(|e| panic!("{}: {}", self.name, e));
    }

    fn read_line(&mut self) -> String {
        let mut s = String::new();
        let n = self.stdout.read_line(&mut s).unwrap_or(0);
        if n == 0 {
            panic!("{} stopped unexpectedly", self.name);
        }
        s.trim_end().to_string()
    }

    fn wait_for(&mut self, word: &str) {
        loop {
            if self.read_line().starts_with(word) {
                return;
            }
        }
    }

    /// Asks for a move: (move text, last reported score for the mover, ms taken).
    fn go(&mut self, position: &str, go: &str) -> (String, Option<i32>, u64) {
        self.send(position);
        let t = Instant::now();
        self.send(go);
        let mut score = None;
        loop {
            let l = self.read_line();
            if let Some(rest) = l.strip_prefix("bestmove ") {
                return (rest.split_whitespace().next().unwrap_or("").to_string(), score, t.elapsed().as_millis() as u64);
            }
            if l.starts_with("info ") && l.contains(" multipv 1 ") || (l.starts_with("info depth") && !l.contains("multipv")) {
                let w: Vec<&str> = l.split_whitespace().collect();
                if let Some(i) = w.iter().position(|&x| x == "score") {
                    let v: i32 = w.get(i + 2).and_then(|v| v.parse().ok()).unwrap_or(0);
                    score = Some(match w.get(i + 1) {
                        Some(&"mate") => {
                            if v > 0 {
                                MATE - (2 * v - 1)
                            } else {
                                -MATE + 2 * -v
                            }
                        }
                        _ => v,
                    });
                }
            }
        }
    }
}

impl Drop for Engine {
    fn drop(&mut self) {
        let _ = writeln!(self.stdin, "quit");
        let _ = self.stdin.flush();
        let _ = self.child.wait();
    }
}

#[derive(Clone, Copy)]
enum Budget {
    Nodes(u64),
    MoveTime(u64),
    Clock(u64, u64),
}

/// One game. Returns A's score (1, 0.5, 0) and how it ended.
#[allow(clippy::too_many_arguments)]
fn play(cat: &Arc<Catalog>, w: &Army, b: &Army, opening: &[Move], a: &mut Engine, bb: &mut Engine, a_white: bool, budget: Budget, budget_b: Budget) -> (f32, String) {
    let mut g = army_game(cat, w, b, 8, 8);
    let r = g.rules.clone();
    let head = format!("position army {} {} moves", army_spec(cat, w), army_spec(cat, b));
    let mut texts: Vec<String> = Vec::new();
    for &m in opening {
        texts.push(move_text(&r, m));
        g.play(m);
    }
    a.send("ucinewgame");
    bb.send("ucinewgame");
    let mut clock = [0i64; 2];
    if let Budget::Clock(base, _) = budget {
        clock = [base as i64, base as i64];
    }
    let mut win_streak = 0i32;
    let mut draw_streak = 0;
    let white_score_of = |res: f32| if a_white { res } else { 1.0 - res };
    for ply in opening.len()..400 {
        let out = g.outcome();
        if out != Outcome::None {
            let res = if out == Outcome::Checkmate { if g.pos.side == WHITE { 0.0 } else { 1.0 } } else { 0.5 };
            return (white_score_of(res), outcome_name(out).to_string());
        }
        let side = g.pos.side;
        let a_to_move = (side == WHITE) == a_white;
        let eng = if a_to_move { &mut *a } else { &mut *bb };
        let go = match if a_to_move { budget } else { budget_b } {
            Budget::Nodes(n) => format!("go nodes {}", n),
            Budget::MoveTime(ms) => format!("go movetime {}", ms),
            Budget::Clock(_, inc) => format!("go wtime {} btime {} winc {} binc {}", clock[0].max(1), clock[1].max(1), inc, inc),
        };
        let pos_cmd = format!("{} {}", head, texts.join(" "));
        let (mv, score, ms) = eng.go(&pos_cmd, &go);
        if let Budget::Clock(_, inc) = budget {
            clock[side] -= ms as i64;
            if clock[side] < 0 {
                let res = if side == WHITE { 0.0 } else { 1.0 };
                return (white_score_of(res), "time".into());
            }
            clock[side] += inc as i64;
        }
        let m = match find_move(&g.pos, &r, &mv) {
            Some(m) => m,
            None => {
                eprintln!("illegal move {:?} from {} in {}", mv, eng.name, pos_cmd);
                let res = if side == WHITE { 0.0 } else { 1.0 };
                return (white_score_of(res), "illegal_move".into());
            }
        };
        if let Some(s) = score {
            let white_score = if side == WHITE { s } else { -s };
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
                return (white_score_of(if win_streak > 0 { 1.0 } else { 0.0 }), "adjudicated_win".into());
            }
            if ply >= 120 && white_score.abs() <= 15 {
                draw_streak += 1;
            } else {
                draw_streak = 0;
            }
            if draw_streak >= 24 {
                return (0.5, "adjudicated_draw".into());
            }
        }
        texts.push(move_text(&r, m));
        g.play(m);
    }
    (0.5, "max_plies".into())
}

/// An army the UCI "position army" command reads back exactly.
fn army_spec(cat: &Catalog, a: &Army) -> String {
    if !a.mirror && *a == standard(cat) {
        "standard".into()
    } else {
        assert!(a.mirror, "only mirrored text armies and the standard set can be sent");
        a.to_text(cat, 8)
    }
}

/// Pentanomial summary: (pairs, score, Elo, ±95%, LLR for elo0/elo1).
pub fn penta_stats(p: &[usize; 5], sprt: Option<(f64, f64)>) -> (usize, f64, f64, f64, f64) {
    let n: usize = p.iter().sum();
    if n == 0 {
        return (0, 0.5, 0.0, 0.0, 0.0);
    }
    let nf = n as f64;
    let vals = [0.0, 0.25, 0.5, 0.75, 1.0];
    let mean: f64 = (0..5).map(|i| vals[i] * p[i] as f64).sum::<f64>() / nf;
    let var: f64 = (0..5).map(|i| (vals[i] - mean).powi(2) * p[i] as f64).sum::<f64>() / nf;
    let elo = |s: f64| -> f64 {
        let s = s.clamp(1e-4, 1.0 - 1e-4);
        -400.0 * (1.0 / s - 1.0).log10()
    };
    let se = (var / nf).sqrt();
    let margin = (elo(mean + 1.96 * se) - elo(mean - 1.96 * se)) / 2.0;
    let mut llr = 0.0;
    if let Some((e0, e1)) = sprt {
        let s = |e: f64| 1.0 / (1.0 + 10f64.powf(-e / 400.0));
        let (s0, s1) = (s(e0), s(e1));
        let v = var.max(1e-6);
        // Generalised SPRT, normal approximation (as fishtest's).
        llr = nf * (s1 - s0) * (2.0 * mean - s0 - s1) / (2.0 * v);
    }
    (n, mean, elo(mean), margin, llr)
}

pub fn run(cat: &Arc<Catalog>, args: &Args, pieces: &str) {
    let ea = args.get("engine-a").unwrap_or_else(|| panic!("--engine-a <exe> needed")).to_string();
    let eb = args.get("engine-b").unwrap_or_else(|| panic!("--engine-b <exe> needed")).to_string();
    let budget = if let Some(tc) = args.get("tc") {
        let (b, i) = tc.split_once('+').unwrap_or((tc, "0"));
        Budget::Clock((b.parse::<f64>().expect("bad --tc") * 1000.0) as u64, (i.parse::<f64>().expect("bad --tc") * 1000.0) as u64)
    } else if let Some(ms) = args.get("movetime") {
        Budget::MoveTime(ms.parse().expect("bad --movetime"))
    } else {
        Budget::Nodes(args.num("nodes", 6000))
    };
    let budget_b = match (budget, args.get("nodes-b")) {
        (Budget::Nodes(_), Some(n)) => Budget::Nodes(n.parse().expect("bad --nodes-b")),
        _ => budget,
    };
    let pairs: usize = args.num("pairs", 1000);
    let sprt: Option<(f64, f64)> = args.get("sprt").map(|s| {
        let (a, b) = s.split_once(',').expect("--sprt E0,E1");
        (a.trim().parse().unwrap(), b.trim().parse().unwrap())
    });
    let conc: usize = args.num("concurrency", std::thread::available_parallelism().map(|n| n.get()).unwrap_or(4));
    let hash: usize = args.num("hash", 16);
    let ua = args.get("uci-a").unwrap_or("").to_string();
    let ub = args.get("uci-b").unwrap_or("").to_string();
    let rplies: usize = args.num("random-plies", 8);
    let seed: u64 = args.num("seed", 1);
    let standard_only = args.flag("standard");
    let pool: Vec<Army> = match args.get("pool") {
        None => Vec::new(),
        Some(path) => std::fs::read_to_string(path)
            .unwrap_or_else(|e| panic!("{}: {}", path, e))
            .lines()
            .map(|l| l.trim())
            .filter(|l| !l.is_empty() && !l.starts_with('#'))
            .map(|l| Army::from_text(cat, l.split('|').next().unwrap().trim()).unwrap_or_else(|e| panic!("{}: {}", l, e)))
            .collect(),
    };
    let pool_pairs: Vec<(usize, usize)> = (0..pool.len()).flat_map(|i| (0..pool.len()).filter(move |&j| j != i).map(move |j| (i, j))).collect();
    let (lo, hi) = ((0.05f64 / 0.95).ln(), (0.95f64 / 0.05).ln());
    let bdesc = match budget {
        Budget::Nodes(n) => format!("{} nodes/move", n),
        Budget::MoveTime(ms) => format!("{} ms/move", ms),
        Budget::Clock(b, i) => format!("{}+{} s", b as f64 / 1000.0, i as f64 / 1000.0),
    };
    println!("A: {}\nB: {}\n{}, up to {} pairs, {} at once{}", ea, eb, bdesc, pairs, conc, sprt.map(|(a, b)| format!(", SPRT [{}, {}]", a, b)).unwrap_or_default());
    let next = AtomicUsize::new(0);
    let stop = AtomicBool::new(false);
    struct Tally {
        penta: [usize; 5],
        wdl: [usize; 3],
        reasons: std::collections::BTreeMap<String, usize>,
        done_pairs: usize,
        /// When the SPRT decided: (games, Elo, margin, LLR). Games still being
        /// played then are counted too, but don't undo the decision.
        decision: Option<(usize, f64, f64, f64)>,
    }
    let tally = Mutex::new(Tally { penta: [0; 5], wdl: [0; 3], reasons: Default::default(), done_pairs: 0, decision: None });
    let t0 = Instant::now();
    std::thread::scope(|scope| {
        for _ in 0..conc.max(1) {
            scope.spawn(|| {
                let mut a = Engine::start(&ea, pieces, hash, &ua);
                let mut b = Engine::start(&eb, pieces, hash, &ub);
                let mut params = Params::defaults(cat);
                params.load_over(cat, BUILTIN_PARAMS);
                loop {
                    if stop.load(Ordering::SeqCst) {
                        break;
                    }
                    let i = next.fetch_add(1, Ordering::SeqCst);
                    if i >= pairs {
                        break;
                    }
                    let mut rng = Rng::new(seed.wrapping_mul(1_000_003).wrapping_add(i as u64));
                    let (w, bl) = if !pool_pairs.is_empty() {
                        let (a, b) = pool_pairs[i % pool_pairs.len()];
                        (pool[a].clone(), pool[b].clone())
                    } else if standard_only {
                        (standard(cat), standard(cat))
                    } else {
                        random_pair(cat, &mut rng, (BUDGET, BUDGET))
                    };
                    // The opening: a few plies picked at random among good moves.
                    let mut g = army_game(cat, &w, &bl, 8, 8);
                    let opening = {
                        let rules = g.rules.clone();
                        let et = EvalTables::new(&rules);
                        let mut s = Searcher::new(&rules, &et, &params, 4);
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
                    let (s1, r1) = play(cat, &w, &bl, &opening, &mut a, &mut b, true, budget, budget_b);
                    let (s2, r2) = play(cat, &w, &bl, &opening, &mut a, &mut b, false, budget, budget_b);
                    let mut t = tally.lock().unwrap();
                    let k = ((s1 + s2) * 2.0).round() as usize;
                    t.penta[k] += 1;
                    for s in [s1, s2] {
                        t.wdl[if s == 1.0 { 0 } else if s == 0.5 { 1 } else { 2 }] += 1;
                    }
                    *t.reasons.entry(r1).or_insert(0) += 1;
                    *t.reasons.entry(r2).or_insert(0) += 1;
                    t.done_pairs += 1;
                    let (n, _, elo, m, llr) = penta_stats(&t.penta, sprt);
                    // Not before 200 pairs: early on the variance is badly estimated.
                    let decided = sprt.is_some() && n >= 200 && (llr <= lo || llr >= hi);
                    if n % 25 == 0 || decided {
                        eprintln!(
                            "  {} games ({:.0}s): A +{} ={} -{}  Elo {:+.1} ±{:.1}{}",
                            n * 2,
                            t0.elapsed().as_secs_f64(),
                            t.wdl[0],
                            t.wdl[1],
                            t.wdl[2],
                            elo,
                            m,
                            if sprt.is_some() { format!("  LLR {:.2} [{:.2}, {:.2}]", llr, lo, hi) } else { String::new() }
                        );
                    }
                    if decided && t.decision.is_none() {
                        t.decision = Some((n * 2, elo, m, llr));
                        stop.store(true, Ordering::SeqCst);
                    }
                }
            });
        }
    });
    let t = tally.into_inner().unwrap();
    let (n, score, elo, m, llr) = penta_stats(&t.penta, sprt);
    println!(
        "\nResult: {} games, A +{} ={} -{}  score {:.1}%  => A is {:+.1} ±{:.1} Elo vs B (95%)",
        n * 2,
        t.wdl[0],
        t.wdl[1],
        t.wdl[2],
        score * 100.0,
        elo,
        m
    );
    println!("Pairs (A's score 0, 0.5, 1, 1.5, 2): {:?}", t.penta);
    if let Some((e0, e1)) = sprt {
        let llr = t.decision.map(|d| d.3).unwrap_or(llr);
        if let Some((g, e, mm, l)) = t.decision {
            println!("SPRT decided after {} games: Elo {:+.1} ±{:.1}, LLR {:.2}", g, e, mm, l);
        }
        let verdict = if llr >= hi {
            format!("H1 accepted (A gains at least ~{} Elo)", e1)
        } else if llr <= lo {
            format!("H0 accepted (A gains no more than ~{} Elo)", e0)
        } else {
            "no decision".into()
        };
        println!("SPRT [{}, {}]: LLR {:.2} [{:.2}, {:.2}]: {}", e0, e1, llr, lo, hi, verdict);
    }
    println!("Endings: {:?}", t.reasons);
    println!("Time: {:.0}s", t0.elapsed().as_secs_f64());
}
