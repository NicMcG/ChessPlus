//! `plusfish start-check`: how well engines' evaluations of the starting
//! position predict which army is better. Army pairs are played out many times
//! (both colours) to find the truth; each engine is then asked, over UCI, for
//! its score of both starting positions. Native-only, like enginematch.

use crate::ematch::{army_spec, Engine};
use plusfish_core::army::*;
use plusfish_core::defs::*;
use plusfish_core::eval::*;
use plusfish_core::selfplay::*;
use plusfish_core::util::{Args, Rng};
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};

pub const HELP: &str = "\
start-check: how well engines' starting-position scores predict which army
wins. Each army pair is played --games times with each colour (the built-in
engine, --nodes per move), then every engine scores both starting positions.
  --engines a.exe,b.exe   engines to compare
  --eval-nodes 1,20000,150000   node budgets they score with
  --pairs N        random army pairs (default 150)
  --pool <file>    also: every pool army against Standard and each other
  --games N        games per colour per pair (default 16)
  --nodes N        nodes per move in those games (default 6000)
  --seed N         --concurrency N
  --truth <file>   keep the game results there and reuse them next time
                   (they only depend on the matchups and the built-in engine)
An engine given as <exe>@<weights.txt> scores with other evaluation weights.
";

struct Matchup {
    x: Army,
    y: Army,
    label: String,
}

pub fn run(cat: &Arc<Catalog>, args: &Args, pieces: &str) {
    let engines: Vec<String> = args.get("engines").expect("--engines a.exe,b.exe").split(',').map(|s| s.to_string()).collect();
    let budgets: Vec<u64> = args.get("eval-nodes").unwrap_or("1,20000,150000").split(',').map(|s| s.parse().expect("bad --eval-nodes")).collect();
    let npairs: usize = args.num("pairs", 150);
    let games: usize = args.num("games", 16);
    let nodes: u64 = args.num("nodes", 6000);
    let seed: u64 = args.num("seed", 7);
    let conc: usize = args.num("concurrency", std::thread::available_parallelism().map(|n| n.get()).unwrap_or(4));

    let mut ms: Vec<Matchup> = Vec::new();
    let mut rng = Rng::new(seed);
    for i in 0..npairs {
        let (x, y) = random_pair(cat, &mut rng, (BUDGET, BUDGET));
        // Both orders must make sense as starts.
        if start_is_broken(&army_game(cat, &y, &x, 8, 8)) {
            continue;
        }
        ms.push(Matchup { x, y, label: format!("random {}", i) });
    }
    let nrandom = ms.len();
    if let Some(path) = args.get("pool") {
        let pool: Vec<(Army, String)> = std::fs::read_to_string(path)
            .unwrap_or_else(|e| panic!("{}: {}", path, e))
            .lines()
            .map(|l| l.trim())
            .filter(|l| !l.is_empty() && !l.starts_with('#'))
            .map(|l| {
                let mut f = l.split('|');
                let a = Army::from_text(cat, f.next().unwrap().trim()).unwrap();
                (a, f.next().unwrap_or("?").trim().to_string())
            })
            .collect();
        let ok = |w: &Army, b: &Army| !start_is_broken(&army_game(cat, w, b, 8, 8)) && !start_is_broken(&army_game(cat, b, w, 8, 8));
        for (a, n) in &pool {
            if !ok(a, &standard(cat)) {
                println!("skipped {} v Standard: a broken start", n);
                continue;
            }
            ms.push(Matchup { x: a.clone(), y: standard(cat), label: format!("{} v Standard", n) });
        }
        for i in 0..pool.len() {
            for j in i + 1..pool.len() {
                if !ok(&pool[i].0, &pool[j].0) {
                    println!("skipped {} v {}: a broken start", pool[i].1, pool[j].1);
                    continue;
                }
                ms.push(Matchup { x: pool[i].0.clone(), y: pool[j].0.clone(), label: format!("{} v {}", pool[i].1, pool[j].1) });
            }
        }
    }
    println!("{} matchups ({} random), {} games each colour at {} nodes/move", ms.len(), nrandom, games, nodes);

    // Per matchup: X's score as White, as Black, and split halves (even/odd games).
    let truth_file = args.get("truth");
    let specs: Vec<String> = ms.iter().map(|m| format!("{}\t{}\t{}", m.label, army_spec(cat, &m.x), army_spec(cat, &m.y))).collect();
    let cached = truth_file.and_then(|f| std::fs::read_to_string(f).ok()).and_then(|text| {
        let rows: Vec<Truth> = text
            .lines()
            .zip(&specs)
            .filter_map(|(l, spec)| {
                let (head, nums) = l.rsplit_once("\t#\t")?;
                if head != spec {
                    return None;
                }
                let v: Vec<f64> = nums.split('\t').filter_map(|x| x.parse().ok()).collect();
                (v.len() == 4).then(|| Truth { xw: v[0], xb: v[1], half: [v[2], v[3]] })
            })
            .collect();
        (rows.len() == ms.len() && text.lines().count() == ms.len()).then_some(rows)
    });
    let truth: Vec<Truth> = match cached {
        Some(t) => {
            println!("game results from {}", truth_file.unwrap());
            t
        }
        None => {
            let t = play_truth(cat, &ms, games, nodes, seed, conc);
            if let Some(f) = truth_file {
                let text: String = specs.iter().zip(&t).map(|(s, r)| format!("{}\t#\t{}\t{}\t{}\t{}\n", s, r.xw, r.xb, r.half[0], r.half[1])).collect();
                std::fs::write(f, text).unwrap_or_else(|e| panic!("{}: {}", f, e));
            }
            t
        }
    };

    // Engine scores of both starts (White's view = side to move).
    let nm = ms.len();
    let jobs: Vec<(usize, usize, usize, bool)> = (0..engines.len())
        .flat_map(|e| (0..budgets.len()).flat_map(move |b| (0..nm).flat_map(move |m| [(e, b, m, true), (e, b, m, false)])))
        .collect();
    let scores: Mutex<std::collections::HashMap<(usize, usize, usize, bool), i32>> = Mutex::new(Default::default());
    let next = AtomicUsize::new(0);
    std::thread::scope(|scope| {
        for _ in 0..conc.max(1) {
            scope.spawn(|| {
                let mut eng: Vec<Engine> = engines.iter().map(|e| Engine::start(e, pieces, 32, "")).collect();
                loop {
                    let i = next.fetch_add(1, Ordering::SeqCst);
                    if i >= jobs.len() {
                        break;
                    }
                    let (e, b, m, x_white) = jobs[i];
                    let (w, bl) = if x_white { (&ms[m].x, &ms[m].y) } else { (&ms[m].y, &ms[m].x) };
                    eng[e].send("ucinewgame");
                    let pos = format!("position army {} {}", army_spec(cat, w), army_spec(cat, bl));
                    let (_, sc, _) = eng[e].go(&pos, &format!("go nodes {}", budgets[b]));
                    // Capped, so a start that loses at once doesn't swamp the correlation.
                    let sc = sc.unwrap_or(0).clamp(-1500, 1500);
                    scores.lock().unwrap().insert((e, b, m, x_white), sc);
                }
            });
        }
    });
    let scores = scores.into_inner().unwrap();

    let elo = |s: f64| -400.0 * (1.0 / s.clamp(0.01, 0.99) - 1.0).log10();
    let sets: Vec<(&str, Vec<usize>)> = {
        let mut v = vec![("random pairs", (0..nrandom).collect::<Vec<_>>())];
        if ms.len() > nrandom {
            v.push(("pool + Standard", (nrandom..ms.len()).collect()));
            v.push(("all", (0..ms.len()).collect()));
        }
        v
    };
    for (name, idx) in &sets {
        let army_truth: Vec<f64> = idx.iter().map(|&k| (truth[k].xw + truth[k].xb) / 2.0).collect();
        let h0: Vec<f64> = idx.iter().map(|&k| truth[k].half[0]).collect();
        let h1: Vec<f64> = idx.iter().map(|&k| truth[k].half[1]).collect();
        let rel = pearson(&h0, &h1);
        // Spearman-Brown: reliability of the full average from the split halves.
        let ceiling = (2.0 * rel / (1.0 + rel)).max(0.0).sqrt();
        let white_edge: f64 = idx.iter().map(|&k| (truth[k].xw + 1.0 - truth[k].xb) / 2.0).sum::<f64>() / idx.len() as f64;
        let clear: Vec<usize> = (0..idx.len()).filter(|&j| (army_truth[j] - 0.5).abs() >= 0.15).collect();
        let sd_truth = sd(&army_truth.iter().map(|&s| elo(s)).collect::<Vec<_>>());
        println!("\n== {}: {} matchups. White scores {:.1}% ({:+.0} Elo). Spread of army strength: sd {:.0} Elo.", name, idx.len(), 100.0 * white_edge, elo(white_edge), sd_truth);
        println!("   Best possible correlation with this many games (noise ceiling): {:.2}. {} matchups clearly one-sided (score >= 65%).", ceiling, clear.len());
        println!("   {:<28} {:>7} {:>10} {:>9} {:>13} {:>15}", "engine @ nodes", "corr", "rank corr", "right side", "right (clear)", "White's edge (cp)");
        for (e, ename) in engines.iter().enumerate() {
            for (b, bn) in budgets.iter().enumerate() {
                // X's advantage averaged over colours, so White's tempo cancels.
                let adv: Vec<f64> = idx.iter().map(|&k| (scores[&(e, b, k, true)] - scores[&(e, b, k, false)]) as f64 / 2.0).collect();
                let tempo: f64 = idx.iter().map(|&k| (scores[&(e, b, k, true)] + scores[&(e, b, k, false)]) as f64 / 2.0).sum::<f64>() / idx.len() as f64;
                let tl: Vec<f64> = army_truth.iter().map(|&s| elo(s)).collect();
                let right = (0..idx.len()).filter(|&j| (adv[j] > 0.0) == (army_truth[j] > 0.5) && army_truth[j] != 0.5).count();
                let decided = (0..idx.len()).filter(|&j| army_truth[j] != 0.5).count();
                let rc = clear.iter().filter(|&&j| (adv[j] > 0.0) == (army_truth[j] > 0.5)).count();
                let stem = |p: &str| std::path::Path::new(p).file_stem().map(|s| s.to_string_lossy().to_string()).unwrap_or(p.to_string());
                let short = match ename.rsplit_once('@') {
                    Some((e, p)) => format!("{}@{}", stem(e), stem(p)),
                    None => stem(ename),
                };
                println!(
                    "   {:<28} {:>7.2} {:>10.2} {:>8.0}% {:>12.0}% {:>15.0}",
                    format!("{} @ {}", short, bn),
                    pearson(&adv, &tl),
                    pearson(&ranks(&adv), &ranks(&tl)),
                    100.0 * right as f64 / decided.max(1) as f64,
                    100.0 * rc as f64 / clear.len().max(1) as f64,
                    tempo
                );
            }
        }
    }
    if ms.len() > nrandom {
        println!("\nPool armies against Standard (X = pool army): X's score over both colours, and each engine's advantage for X in pawns at the largest budget.");
        let b = budgets.len() - 1;
        for k in nrandom..ms.len() {
            if !ms[k].label.ends_with("v Standard") {
                continue;
            }
            let s = (truth[k].xw + truth[k].xb) / 2.0;
            let advs: Vec<String> = (0..engines.len()).map(|e| format!("{:+.2}", (scores[&(e, b, k, true)] - scores[&(e, b, k, false)]) as f64 / 200.0)).collect();
            println!("   {:<36} {:>5.1}% ({:+5.0} Elo)   {}", ms[k].label, 100.0 * s, elo(s), advs.join("  "));
        }
    }
}

struct Truth {
    xw: f64,
    xb: f64,
    half: [f64; 2],
}

/// Plays every matchup `games` times with each colour (built-in engine).
/// Game i is matchup i / (2 * games); X plays White in the first half.
fn play_truth(cat: &Arc<Catalog>, ms: &[Matchup], games: usize, nodes: u64, seed: u64, conc: usize) -> Vec<Truth> {
    let mut params = Params::defaults(cat);
    params.load_over(cat, BUILTIN_PARAMS);
    let cfg = PlayConfig { nodes, random_plies: 6, max_plies: 400, tt_mb: 8, sample_every: 0 };
    let per = 2 * games;
    let total = ms.len() * per;
    let recs = run_games(
        cat,
        total,
        conc,
        &params,
        &params,
        &cfg,
        seed,
        &|i, _| {
            let m = &ms[i / per];
            if i % per < games {
                (m.x.clone(), m.y.clone(), true)
            } else {
                (m.y.clone(), m.x.clone(), true)
            }
        },
        &|_, n| {
            if n % 500 == 0 {
                eprintln!("{} / {} games", n, total);
            }
        },
    );
    (0..ms.len())
        .map(|k| {
            let r = &recs[k * per..(k + 1) * per];
            let xw = r[..games].iter().map(|g| g.result as f64).sum::<f64>() / games as f64;
            let xb = r[games..].iter().map(|g| 1.0 - g.result as f64).sum::<f64>() / games as f64;
            let mut half = [0.0; 2];
            for (j, g) in r.iter().enumerate() {
                let s = if j < games { g.result as f64 } else { 1.0 - g.result as f64 };
                half[j % 2] += s / games as f64;
            }
            Truth { xw, xb, half }
        })
        .collect()
}

fn pearson(a: &[f64], b: &[f64]) -> f64 {
    let n = a.len() as f64;
    let (ma, mb) = (a.iter().sum::<f64>() / n, b.iter().sum::<f64>() / n);
    let cov: f64 = a.iter().zip(b).map(|(x, y)| (x - ma) * (y - mb)).sum();
    let va: f64 = a.iter().map(|x| (x - ma).powi(2)).sum();
    let vb: f64 = b.iter().map(|y| (y - mb).powi(2)).sum();
    if va == 0.0 || vb == 0.0 {
        0.0
    } else {
        cov / (va * vb).sqrt()
    }
}

fn sd(a: &[f64]) -> f64 {
    let n = a.len() as f64;
    let m = a.iter().sum::<f64>() / n;
    (a.iter().map(|x| (x - m).powi(2)).sum::<f64>() / n).sqrt()
}

/// Ranks (ties averaged), for a rank correlation.
fn ranks(a: &[f64]) -> Vec<f64> {
    let mut idx: Vec<usize> = (0..a.len()).collect();
    idx.sort_by(|&i, &j| a[i].partial_cmp(&a[j]).unwrap());
    let mut r = vec![0.0; a.len()];
    let mut i = 0;
    while i < idx.len() {
        let mut j = i;
        while j + 1 < idx.len() && a[idx[j + 1]] == a[idx[i]] {
            j += 1;
        }
        for k in i..=j {
            r[idx[k]] = (i + j) as f64 / 2.0;
        }
        i = j + 1;
    }
    r
}
