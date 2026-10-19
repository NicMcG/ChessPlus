//! `plusfish meta`: grows a pool of armies that look strong in the eval bar
//! at the start of the game (turn 0), against each other. Each round a new
//! army is hill-climbed from a random one against the whole pool, then:
//!   - it joins the pool if it differs enough from every member (and if that
//!     makes the pool too big, the member with the lowest average is dropped);
//!   - if it's close to a member, it replaces that member when it does better
//!     against the rest of the pool;
//!   - otherwise it's thrown away.
//! The run stops once the pool stays the same for a few rounds in a row.
//! Scores are Plusfish's own judgement, so re-run it whenever the engine gets
//! better; `start-check --pool` then shows how well those scores match games.

use plusfish_core::army::*;
use plusfish_core::defs::*;
use plusfish_core::eval::*;
use plusfish_core::search::*;
use plusfish_core::selfplay::start_is_broken;
use plusfish_core::util::{Args, Rng};
use std::collections::HashMap;
use std::io::Write;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::sync::{Arc, Mutex};

pub const HELP: &str = "\
meta: grow a pool of armies that look strong at the start (turn 0) in the eval
bar, against each other. Each round hill-climbs a new army against the pool:
it joins if its piece list differs from every member's by at least --min-diff
pieces (dropping the member with the lowest average once there are
more than --max), replaces a similar member if it does better against the rest,
or is thrown away. Stops after --stable rounds in a row without a change.
  --pool <file>      starting pool (pool.txt format); armies that break the
                     army rules are left out. Standard is always added.
  --out <file>       where the pool is written after every round (meta_pool.txt)
  --max N            pool size (default 10)       --rounds N (default 40)
  --stable N         rounds without a change before stopping (default 4)
  --min-diff N       pieces that must differ to count as new (default 3;
                     layout is ignored: same pieces, other squares = similar)
  --nodes N          nodes per start score, as the eval bar (default 20000)
  --climb-nodes N    nodes per score while climbing (default 8000)
  --patience N       climbing stops after N batches without a gain (default 5)
  --threads N        default 16   --seed N
  --name X           new armies are called X <round> (default Meta)
Scores are the advantage in centipawns, both colours averaged so White's
first move cancels; a pairing that starts with a king attacked counts as
unusable (the candidate is rejected).
";

struct Cfg {
    nodes: u64,
    climb_nodes: u64,
    threads: usize,
    min_diff: usize,
    patience: usize,
}

/// White's score of the starting position, from a node-limited search,
/// capped so a forced win doesn't swamp the averages. None = broken start.
struct Scorer<'a> {
    cat: &'a Arc<Catalog>,
    params: &'a Params,
    cache: Mutex<HashMap<(String, String, u64), Option<i32>>>,
}

impl<'a> Scorer<'a> {
    fn start_score(&self, w: &Army, b: &Army, nodes: u64) -> Option<i32> {
        let key = (w.to_text(self.cat, 8), b.to_text(self.cat, 8), nodes);
        if let Some(&v) = self.cache.lock().unwrap().get(&key) {
            return v;
        }
        let g = army_game(self.cat, w, b, 8, 8);
        let v = if start_is_broken(&g) {
            None
        } else {
            let et = EvalTables::new(&g.rules);
            let mut s = Searcher::new(&g.rules, &et, self.params, 4);
            let lim = Limits { nodes: Some(nodes), ..Default::default() };
            let rep = s.search(&g.pos, &g.keys[..g.keys.len() - 1], lim, 1, |_| {});
            Some(rep.lines.first().map(|l| l.score).unwrap_or(0).clamp(-1500, 1500))
        };
        self.cache.lock().unwrap().insert(key, v);
        v
    }

    /// a's advantage over b (centipawns), each playing White once.
    fn advantage(&self, a: &Army, b: &Army, nodes: u64) -> Option<f64> {
        let x = self.start_score(a, b, nodes)?;
        let y = self.start_score(b, a, nodes)?;
        Some((x - y) as f64 / 2.0)
    }

    /// Scores many pairings at once on `threads` threads.
    fn many(&self, pairs: &[(&Army, &Army)], nodes: u64, threads: usize) -> Vec<Option<f64>> {
        let out: Vec<Mutex<Option<f64>>> = pairs.iter().map(|_| Mutex::new(None)).collect();
        // Each pairing is two searches; spread the single searches.
        let jobs: Vec<(usize, bool)> = (0..pairs.len()).flat_map(|i| [(i, true), (i, false)]).collect();
        let next = AtomicUsize::new(0);
        std::thread::scope(|scope| {
            for _ in 0..threads.max(1) {
                scope.spawn(|| loop {
                    let j = next.fetch_add(1, Ordering::SeqCst);
                    if j >= jobs.len() {
                        break;
                    }
                    let (i, a_white) = jobs[j];
                    let (a, b) = pairs[i];
                    if a_white {
                        self.start_score(a, b, nodes);
                    } else {
                        self.start_score(b, a, nodes);
                    }
                });
            }
        });
        for (i, &(a, b)) in pairs.iter().enumerate() {
            *out[i].lock().unwrap() = self.advantage(a, b, nodes);
        }
        out.into_iter().map(|m| m.into_inner().unwrap()).collect()
    }

    /// Mean advantage of `a` over every army in `pool` (None if any pairing is broken).
    fn mean_vs(&self, a: &Army, pool: &[Army], nodes: u64, threads: usize) -> Option<f64> {
        if pool.is_empty() {
            return Some(0.0);
        }
        let pairs: Vec<(&Army, &Army)> = pool.iter().map(|p| (a, p)).collect();
        let v = self.many(&pairs, nodes, threads);
        let mut sum = 0.0;
        for x in v {
            sum += x?;
        }
        Some(sum / pool.len() as f64)
    }
}

fn buyable(cat: &Catalog) -> Vec<usize> {
    (0..cat.len()).filter(|&k| !cat.defs[k].is_king() && !cat.defs[k].is_form && cat.defs[k].value > 0.0).collect()
}

fn empty_squares(a: &Army) -> Vec<(i32, i32)> {
    let mut v = Vec::new();
    for row in 0..START_ROWS {
        for f in 0..8 {
            if a.at(f, row).is_none() {
                v.push((f, row));
            }
        }
    }
    v
}

/// One random change: swap a piece's type, move one, swap two squares, add,
/// remove, or trade one piece for one or two others (from plusfish-army-pool).
fn mutate_once(cat: &Catalog, a: &mut Army, rng: &mut Rng) {
    let kinds = buyable(cat);
    let non_king: Vec<usize> = (0..a.pieces.len()).filter(|&i| !cat.defs[a.pieces[i].0].is_king()).collect();
    let pick = |rng: &mut Rng, v: &Vec<usize>| -> Option<usize> { if v.is_empty() { None } else { Some(v[rng.below(v.len())]) } };
    match rng.below(7) {
        0 | 1 => {
            if let Some(i) = pick(rng, &non_king) {
                a.pieces[i].0 = kinds[rng.below(kinds.len())];
            }
        }
        2 => {
            let i = rng.below(a.pieces.len());
            let free = empty_squares(a);
            let kf = king_files(8);
            let free: Vec<(i32, i32)> = if cat.defs[a.pieces[i].0].is_king() { free.into_iter().filter(|s| s.1 == 0 && kf.contains(&s.0)).collect() } else { free };
            if !free.is_empty() {
                let s = free[rng.below(free.len())];
                a.pieces[i].1 = s.0;
                a.pieces[i].2 = s.1;
            }
        }
        3 => {
            if a.pieces.len() >= 2 {
                let i = rng.below(a.pieces.len());
                let j = rng.below(a.pieces.len());
                let (fi, ri) = (a.pieces[i].1, a.pieces[i].2);
                a.pieces[i].1 = a.pieces[j].1;
                a.pieces[i].2 = a.pieces[j].2;
                a.pieces[j].1 = fi;
                a.pieces[j].2 = ri;
            }
        }
        4 => {
            let free = empty_squares(a);
            if !free.is_empty() {
                let s = free[rng.below(free.len())];
                a.pieces.push((kinds[rng.below(kinds.len())], s.0, s.1));
            }
        }
        5 => {
            if let Some(i) = pick(rng, &non_king) {
                a.pieces.remove(i);
            }
        }
        _ => {
            if let Some(i) = pick(rng, &non_king) {
                let sq = (a.pieces[i].1, a.pieces[i].2);
                a.pieces.remove(i);
                a.pieces.push((kinds[rng.below(kinds.len())], sq.0, sq.1));
                if rng.below(2) == 0 {
                    let free = empty_squares(a);
                    if !free.is_empty() {
                        let s = free[rng.below(free.len())];
                        a.pieces.push((kinds[rng.below(kinds.len())], s.0, s.1));
                    }
                }
            }
        }
    }
}

/// A legal army 1 to 3 changes away from `parent`, costing at least 36.
fn mutate(cat: &Catalog, parent: &Army, rng: &mut Rng) -> Option<Army> {
    for _ in 0..500 {
        let mut a = parent.clone();
        for _ in 0..1 + rng.below(3) {
            mutate_once(cat, &mut a, rng);
        }
        a.pieces.sort_by_key(|p| (p.2, p.1));
        a.mirror = true;
        if a.pieces == parent.pieces || a.cost(cat) < 36.0 - 1e-9 || !a.problems(cat, 8).is_empty() {
            continue;
        }
        a.name = a.to_text(cat, 8);
        return Some(a);
    }
    None
}

/// How many pieces would have to change to turn one army's piece list into
/// the other's (layout ignored): half the summed differences in counts, rounded up.
pub fn pieces_apart(a: &Army, b: &Army) -> usize {
    let mut kinds: Vec<usize> = a.pieces.iter().chain(&b.pieces).map(|p| p.0).collect();
    kinds.sort();
    kinds.dedup();
    let total: usize = kinds.iter().map(|&k| (a.count(k) as i64 - b.count(k) as i64).unsigned_abs() as usize).sum();
    (total + 1) / 2
}

/// On how many of the 16 starting squares two armies differ (the closer of
/// the army as built and its mirror image, which plays the same).
pub fn squares_apart(a: &Army, b: &Army) -> usize {
    let diff = |flip: bool| {
        let mut n = 0;
        for row in 0..START_ROWS {
            for f in 0..8 {
                let fb = if flip { 7 - f } else { f };
                if a.at(f, row) != b.at(fb, row) {
                    n += 1;
                }
            }
        }
        n
    };
    diff(false).min(diff(true))
}

fn pieces_text(cat: &Catalog, a: &Army) -> String {
    let mut counts: Vec<(usize, usize)> = Vec::new();
    for p in &a.pieces {
        if cat.defs[p.0].is_king() {
            continue;
        }
        match counts.iter_mut().find(|c| c.0 == p.0) {
            Some(c) => c.1 += 1,
            None => counts.push((p.0, 1)),
        }
    }
    counts.sort_by(|x, y| cat.defs[y.0].value.partial_cmp(&cat.defs[x.0].value).unwrap().then(x.0.cmp(&y.0)));
    counts.iter().map(|&(k, n)| if n > 1 { format!("{} {}", n, cat.defs[k].name) } else { cat.defs[k].name.clone() }).collect::<Vec<_>>().join(", ")
}

struct Member {
    army: Army,
    name: String,
    born: usize,
}

/// Each member's mean advantage over the others, at the eval-bar budget.
fn standings(sc: &Scorer, pool: &[Member], cfg: &Cfg) -> Vec<f64> {
    let n = pool.len();
    let mut pairs = Vec::new();
    for i in 0..n {
        for j in i + 1..n {
            pairs.push((&pool[i].army, &pool[j].army));
        }
    }
    let v = sc.many(&pairs, cfg.nodes, cfg.threads);
    let mut sum = vec![0.0; n];
    let mut k = 0;
    for i in 0..n {
        for j in i + 1..n {
            let x = v[k].unwrap_or(0.0);
            sum[i] += x;
            sum[j] -= x;
            k += 1;
        }
    }
    sum.iter().map(|s| s / (n.max(2) - 1) as f64).collect()
}

/// Hill-climbs from `start` against `pool`: each batch tries one mutant per
/// thread and keeps the best if it beats the current army.
fn climb(cat: &Arc<Catalog>, sc: &Scorer, start: Army, pool: &[Army], cfg: &Cfg, rng: &mut Rng, log: &mut dyn FnMut(String)) -> (Army, f64) {
    let mut cur = start;
    let mut cur_score = sc.mean_vs(&cur, pool, cfg.climb_nodes, cfg.threads).unwrap_or(-1e9);
    let mut fails = 0;
    let mut batch = 0;
    while fails < cfg.patience && batch < 200 {
        batch += 1;
        let mutants: Vec<Army> = (0..cfg.threads.max(4)).filter_map(|_| mutate(cat, &cur, rng)).collect();
        // Score all mutants against the pool in one go.
        let mut pairs = Vec::new();
        for m in &mutants {
            for p in pool {
                pairs.push((m, p));
            }
        }
        let v = sc.many(&pairs, cfg.climb_nodes, cfg.threads);
        let mut best: Option<(usize, f64)> = None;
        for (i, _) in mutants.iter().enumerate() {
            let part = &v[i * pool.len()..(i + 1) * pool.len()];
            if part.iter().any(|x| x.is_none()) {
                continue;
            }
            let s = part.iter().map(|x| x.unwrap()).sum::<f64>() / pool.len().max(1) as f64;
            if best.map(|b| s > b.1).unwrap_or(true) {
                best = Some((i, s));
            }
        }
        match best {
            Some((i, s)) if s > cur_score + 0.5 => {
                cur = mutants[i].clone();
                cur_score = s;
                fails = 0;
            }
            _ => fails += 1,
        }
    }
    log(format!("  climbed {} batches to {:+.0} cp (at {} nodes): {}", batch, cur_score, cfg.climb_nodes, cur.to_text(cat, 8)));
    (cur, cur_score)
}

fn read_pool(cat: &Catalog, path: &str, log: &mut dyn FnMut(String)) -> Vec<(Army, String)> {
    let text = std::fs::read_to_string(path).unwrap_or_else(|e| panic!("{}: {}", path, e));
    let mut out = Vec::new();
    for l in text.lines().map(|l| l.trim()).filter(|l| !l.is_empty() && !l.starts_with('#')) {
        let mut f = l.split('|');
        let spec = f.next().unwrap().trim();
        let name = f.next().unwrap_or(spec).trim().to_string();
        match Army::from_text(cat, spec) {
            Ok(a) => {
                let p = a.problems(cat, 8);
                if p.is_empty() {
                    out.push((a, name));
                } else {
                    log(format!("left out {} ({}): {}", name, spec, p.join(" ")));
                }
            }
            Err(e) => log(format!("left out {}: {}", spec, e)),
        }
    }
    out
}

fn write_pool(cat: &Catalog, path: &str, pool: &[Member], score: &[f64], round: usize, cfg: &Cfg) {
    let mut s = String::new();
    s += "# Chess Plus army pool grown by `plusfish meta` (armies that look strongest at turn 0 in Plusfish's eval bar, against each other).\n";
    s += &format!("# After round {}. Score = mean advantage over the rest of the pool at the start, {} nodes, both colours averaged (centipawns).\n", round, cfg.nodes);
    s += "# army | name | cost | score | pieces\n";
    let mut order: Vec<usize> = (0..pool.len()).collect();
    order.sort_by(|&a, &b| score[b].partial_cmp(&score[a]).unwrap());
    for i in order {
        let m = &pool[i];
        s += &format!("{} | {} | {} | {:+.0} | {}\n", m.army.to_text(cat, 8), m.name, m.army.cost(cat), score[i], pieces_text(cat, &m.army));
    }
    std::fs::write(path, s).unwrap_or_else(|e| panic!("{}: {}", path, e));
}

pub fn run(cat: &Arc<Catalog>, params: &Params, args: &Args) {
    let cfg = Cfg {
        nodes: args.num("nodes", 20_000),
        climb_nodes: args.num("climb-nodes", 8_000),
        threads: args.num("threads", 16),
        min_diff: args.num("min-diff", 3),
        patience: args.num("patience", 5),
    };
    let max: usize = args.num("max", 10);
    let rounds: usize = args.num("rounds", 40);
    let stable: usize = args.num("stable", 4);
    let out = args.get("out").unwrap_or("meta_pool.txt").to_string();
    let prefix = args.get("name").unwrap_or("Meta").to_string();
    let mut rng = Rng::new(args.num("seed", 1u64));
    let logf = Mutex::new(std::fs::File::create(format!("{}.log", out.trim_end_matches(".txt"))).ok());
    let mut log = |s: String| {
        println!("{}", s);
        if let Some(f) = logf.lock().unwrap().as_mut() {
            writeln!(f, "{}", s).ok();
        }
    };
    let sc = Scorer { cat, params, cache: Mutex::new(HashMap::new()) };

    let mut pool: Vec<Member> = vec![Member { army: standard(cat), name: "Standard".into(), born: 0 }];
    if let Some(p) = args.get("pool") {
        for (a, n) in read_pool(cat, p, &mut log) {
            pool.push(Member { army: a, name: n, born: 0 });
        }
    }
    // Members that start with a king attacked against another can't share a pool.
    let mut i = 1;
    while i < pool.len() {
        if (0..i).any(|j| start_is_broken(&army_game(cat, &pool[i].army, &pool[j].army, 8, 8)) || start_is_broken(&army_game(cat, &pool[j].army, &pool[i].army, 8, 8))) {
            log(format!("left out {}: a king is attacked at the start against another member", pool[i].name));
            pool.remove(i);
        } else {
            i += 1;
        }
    }
    let mut score = standings(&sc, &pool, &cfg);
    while pool.len() > max {
        let worst = (0..pool.len()).min_by(|&a, &b| score[a].partial_cmp(&score[b]).unwrap()).unwrap();
        log(format!("starting pool over {}: drops {} ({:+.0})", max, pool[worst].name, score[worst]));
        pool.remove(worst);
        score = standings(&sc, &pool, &cfg);
    }
    log(format!("starting pool: {}", pool.iter().zip(&score).map(|(m, s)| format!("{} {:+.0}", m.name, s)).collect::<Vec<_>>().join(", ")));
    write_pool(cat, &out, &pool, &score, 0, &cfg);

    let mut quiet = 0;
    for round in 1..=rounds {
        let t0 = std::time::Instant::now();
        // Even rounds refine a member against the others (the result usually
        // stays close to it and competes to replace it); odd rounds explore
        // from a random army.
        let refine = round % 2 == 0 && pool.len() >= 2;
        let pick = rng.below(pool.len());
        let others: Vec<Army> = (0..pool.len()).filter(|&i| !(refine && i == pick)).map(|i| pool[i].army.clone()).collect();
        let start = if refine {
            let m = &pool[pick];
            log(format!("round {}: refining {}: {}", round, m.name, m.army.to_text(cat, 8)));
            m.army.clone()
        } else {
            let a = loop {
                let a = random_army(cat, &mut rng);
                if a.cost(cat) >= 36.0 && sc.mean_vs(&a, &others, cfg.climb_nodes, cfg.threads).is_some() {
                    break a;
                }
            };
            log(format!("round {}: climbing from {}", round, a.to_text(cat, 8)));
            a
        };
        let (cand, _) = climb(cat, &sc, start, &others, &cfg, &mut rng, &mut log);
        let cand_score = match sc.mean_vs(&cand, &others, cfg.nodes, cfg.threads) {
            Some(s) => s,
            None => {
                log("  a king is attacked at the start against a member at the eval-bar budget: thrown away".into());
                quiet += 1;
                continue;
            }
        };
        // Nearest member by piece list, then by layout.
        let (near, apart) = (0..pool.len()).map(|i| (i, pieces_apart(&cand, &pool[i].army))).min_by_key(|&(i, d)| (d, squares_apart(&cand, &pool[i].army))).unwrap();
        let name = format!("{} {}", prefix, round);
        let mut changed = false;
        if apart >= cfg.min_diff {
            pool.push(Member { army: cand.clone(), name: name.clone(), born: round });
            score = standings(&sc, &pool, &cfg);
            log(format!("  {:+.0} cp vs the pool at {} nodes, {} pieces from the nearest ({}): joins as {}", cand_score, cfg.nodes, apart, pool[near].name, name));
            changed = true;
            while pool.len() > max {
                let worst = (0..pool.len()).min_by(|&a, &b| score[a].partial_cmp(&score[b]).unwrap()).unwrap();
                log(format!("  pool over {}: drops {} ({:+.0})", max, pool[worst].name, score[worst]));
                if pool[worst].born == round {
                    changed = false;
                }
                pool.remove(worst);
                score = standings(&sc, &pool, &cfg);
            }
        } else {
            // Close to a member: compare the two against the rest of the pool.
            let rest: Vec<Army> = (0..pool.len()).filter(|&i| i != near).map(|i| pool[i].army.clone()).collect();
            let c = sc.mean_vs(&cand, &rest, cfg.nodes, cfg.threads);
            let m = sc.mean_vs(&pool[near].army, &rest, cfg.nodes, cfg.threads).unwrap_or(-1e9);
            match c {
                Some(c) if c > m + 1.0 => {
                    log(format!("  only {} pieces from {}, and better against the rest ({:+.0} vs {:+.0}): replaces it as {}", apart, pool[near].name, c, m, name));
                    pool[near] = Member { army: cand.clone(), name: name.clone(), born: round };
                    score = standings(&sc, &pool, &cfg);
                    changed = true;
                }
                _ => log(format!("  only {} pieces from {}, and not better against the rest ({:+.0} vs {:+.0}): thrown away", apart, pool[near].name, c.unwrap_or(f64::NAN), m)),
            }
        }
        quiet = if changed { 0 } else { quiet + 1 };
        write_pool(cat, &out, &pool, &score, round, &cfg);
        log(format!(
            "  pool after round {} ({:.0}s): {}",
            round,
            t0.elapsed().as_secs_f64(),
            pool.iter().zip(&score).map(|(m, s)| format!("{} {:+.0}", m.name, s)).collect::<Vec<_>>().join(", ")
        ));
        if quiet >= stable && pool.len() >= max.min(3) {
            log(format!("stable: no change for {} rounds", quiet));
            break;
        }
    }
    log(format!("wrote {}", out));
}
