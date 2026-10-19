//! Evolving a pool of varied, strong armies (`plusfish evolve`).
//!
//! Quality-diversity search (MAP-Elites): armies are sorted into niches by
//! two traits, and each niche keeps its best army. New armies are mutations of
//! the elites (or fresh random armies), so the search improves every niche at
//! once instead of collapsing onto one build.
//!
//! * Niches: extra royal (Queen / Wizard / none) x pawn count (0-3 / 4-6 / 7+),
//!   9 in all. Style (leapers / sliders / steppers, ability pieces) is
//!   reported but not a niche, to keep the number of niches small enough for
//!   each to get many tries.
//! * Fitness: an Elo rating on one shared scale with Standard = 0. Fixed
//!   reference armies (Standard, a strong Berserker build, random armies) get
//!   their ratings from a short round robin at the start; a candidate's rating
//!   is its performance against its opponents' ratings (reference armies and
//!   the current elites), allowing for White's first-move edge, with a weak
//!   prior (mean 0, sd `PRIOR_SD`) so a few lucky games don't make a champion.
//! * Racing: every candidate plays a short screen; only those close to the
//!   niche's elite play more games, and a challenger replaces the elite only
//!   after a full-length test that it wins on rating.
//! * The king-capture bug: pairings where a king starts attacked are never
//!   played, and candidates whose pairings with random armies break too often
//!   (`max_exposure`) are rejected before playing.
//!
//! State is checkpointed after every generation (`state.txt` + `games.txt` in
//! the run folder), and a run started again in the same folder carries on.

use crate::army::*;
use crate::defs::*;
use crate::eval::Params;
use crate::game::*;
use crate::position::*;
use crate::selfplay::*;
use crate::util::Rng;
use std::collections::{HashMap, HashSet};
use std::io::Write;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

pub const NICHES: usize = 9;
pub const STANDARD_KEY: &str = "standard";
/// The Berserker build from FINDINGS.md (+174 Elo against Standard): a strong
/// fixed opponent, so fitness isn't only about beating weak armies.
pub const BERSERKER_WALL: &str = "RNBQKBNR/1(BR)PPP(BR)2";
const PRIOR_SD: f64 = 200.0;
const ELO_K: f64 = std::f64::consts::LN_10 / 400.0;

#[derive(Clone)]
pub struct EvolveConfig {
    pub dir: PathBuf,
    pub seed: u64,
    pub threads: usize,
    pub nodes: u64,
    pub generations: usize,
    pub max_minutes: f64,
    /// Candidates per generation.
    pub batch: usize,
    /// Games (both colours, so even) in each racing stage: screen, second
    /// look, full test.
    pub stages: [usize; 3],
    /// How far below the elite (Elo) a candidate may be and still go on to
    /// the next stage.
    pub margins: [f64; 2],
    pub min_cost: f64,
    /// Most broken starts allowed against random armies (fraction).
    pub max_exposure: f64,
    pub random_refs: usize,
    pub calibration_games: usize,
    /// Stop when every niche is filled and no elite changed for this many
    /// generations.
    pub patience: usize,
    /// Share of candidates that are fresh random armies rather than mutants.
    pub fresh: f64,
}

impl Default for EvolveConfig {
    fn default() -> Self {
        EvolveConfig {
            dir: PathBuf::from("evolve_run"),
            seed: 1,
            threads: 6,
            nodes: 4000,
            generations: 60,
            max_minutes: 150.0,
            batch: 30,
            stages: [12, 12, 24],
            margins: [60.0, 25.0],
            min_cost: 36.0,
            max_exposure: 0.03,
            random_refs: 4,
            calibration_games: 20,
            patience: 12,
            fresh: 0.15,
        }
    }
}

// ---------- army traits ----------

/// 0 = Queen, 1 = Wizard, 2 = no extra royal.
pub fn royal_class(cat: &Catalog, a: &Army) -> usize {
    for p in &a.pieces {
        let d = &cat.defs[p.0];
        if d.is_royal() && !d.is_king() {
            return if d.id == "wizard" { 1 } else { 0 };
        }
    }
    2
}

pub fn pawn_count(cat: &Catalog, a: &Army) -> usize {
    a.pieces.iter().filter(|p| cat.defs[p.0].is_pawn()).count()
}

pub fn niche(cat: &Catalog, a: &Army) -> usize {
    let pawns = match pawn_count(cat, a) {
        0..=3 => 0,
        4..=6 => 1,
        _ => 2,
    };
    royal_class(cat, a) * 3 + pawns
}

pub fn niche_name(n: usize) -> String {
    let royal = ["Queen", "Wizard", "no royal"][n / 3];
    let pawns = ["0-3 pawns", "4-6 pawns", "7+ pawns"][n % 3];
    format!("{}, {}", royal, pawns)
}

fn is_slider(d: &PieceDef) -> bool {
    d.rules.iter().any(|r| r.max_steps == 0 || r.max_steps >= 3)
}

/// "sliders" / "leapers" / "steppers" (whichever has the most points among
/// the non-pawn pieces), plus "+ability" if it has an ability piece.
pub fn style(cat: &Catalog, a: &Army) -> String {
    let mut pts = [0.0f64; 3];
    let mut ability = false;
    for p in &a.pieces {
        let d = &cat.defs[p.0];
        if d.is_king() || d.is_pawn() {
            continue;
        }
        if d.ability != Ability::None {
            ability = true;
        }
        let c = if d.keywords & KW_JUMP != 0 {
            1
        } else if is_slider(d) {
            0
        } else {
            2
        };
        pts[c] += d.value;
    }
    let best = (0..3).max_by(|&x, &y| pts[x].partial_cmp(&pts[y]).unwrap()).unwrap();
    format!("{}{}", ["sliders", "leapers", "steppers"][best], if ability { "+ability" } else { "" })
}

// ---------- the king-capture bug ----------

/// Checks starting positions for an attacked king, using one set of rules
/// with every piece type (much cheaper than setting up each game).
pub struct StartChecker {
    rules: Rules,
    /// Random armies to measure a candidate's exposure against.
    pub sample: Vec<Army>,
}

impl StartChecker {
    pub fn new(cat: &Arc<Catalog>, samples: usize, seed: u64) -> StartChecker {
        let rules = Rules::new(cat.clone(), 8, 8, vec![], true, kinds_mask(0..cat.len()));
        let mut rng = Rng::new(seed);
        let sample = (0..samples).map(|_| random_army(cat, &mut rng)).collect();
        StartChecker { rules, sample }
    }

    /// True if a king starts attacked when `w` plays `b` (`start_is_broken`).
    pub fn broken(&self, w: &Army, b: &Army) -> bool {
        let r = &self.rules;
        let mut p = Position::empty();
        for x in &w.pieces {
            p.put(r, (x.2 * 8 + x.1) as usize, code(x.0, WHITE));
        }
        for x in &b.pieces {
            let file = if b.mirror { 7 - x.1 } else { x.1 };
            p.put(r, ((7 - x.2) * 8 + file) as usize, code(x.0, BLACK));
        }
        p.in_check(r, WHITE) || p.in_check(r, BLACK)
    }

    /// Either colour.
    pub fn broken_pair(&self, a: &Army, b: &Army) -> bool {
        self.broken(a, b) || self.broken(b, a)
    }

    /// Share of starts against the random sample (both colours) with a king
    /// attacked.
    pub fn exposure(&self, a: &Army) -> f64 {
        let n = self.sample.iter().map(|s| self.broken(a, s) as usize + self.broken(s, a) as usize).sum::<usize>();
        n as f64 / (2 * self.sample.len()).max(1) as f64
    }
}

// ---------- mutation ----------

fn buyable(cat: &Catalog) -> Vec<usize> {
    (0..cat.len()).filter(|&k| !cat.defs[k].is_king() && cat.defs[k].value > 0.0).collect()
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

fn mutate_once(cat: &Catalog, a: &mut Army, rng: &mut Rng) {
    let kinds = buyable(cat);
    let non_king: Vec<usize> = (0..a.pieces.len()).filter(|&i| !cat.defs[a.pieces[i].0].is_king()).collect();
    let pick = |rng: &mut Rng, v: &Vec<usize>| -> Option<usize> { if v.is_empty() { None } else { Some(v[rng.below(v.len())]) } };
    match rng.below(7) {
        // Swap a piece for another type.
        0 | 1 => {
            if let Some(i) = pick(rng, &non_king) {
                a.pieces[i].0 = kinds[rng.below(kinds.len())];
            }
        }
        // Move a piece (the king only to the other king square).
        2 => {
            let i = rng.below(a.pieces.len());
            let free = empty_squares(a);
            let free: Vec<(i32, i32)> = if cat.defs[a.pieces[i].0].is_king() { free.into_iter().filter(|s| s.1 == 0 && (s.0 == 3 || s.0 == 4)).collect() } else { free };
            if !free.is_empty() {
                let s = free[rng.below(free.len())];
                a.pieces[i].1 = s.0;
                a.pieces[i].2 = s.1;
            }
        }
        // Swap two pieces' squares.
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
        // Add a piece.
        4 => {
            let free = empty_squares(a);
            if !free.is_empty() {
                let s = free[rng.below(free.len())];
                a.pieces.push((kinds[rng.below(kinds.len())], s.0, s.1));
            }
        }
        // Remove a piece.
        5 => {
            if let Some(i) = pick(rng, &non_king) {
                a.pieces.remove(i);
            }
        }
        // Trade: remove one, add one or two (re-spend the points).
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

/// A legal mutant of `parent` (1 to 3 changes) costing at least `min_cost`.
pub fn mutate(cat: &Catalog, parent: &Army, min_cost: f64, rng: &mut Rng) -> Option<Army> {
    for _ in 0..500 {
        let mut a = parent.clone();
        let changes = 1 + rng.below(3);
        for _ in 0..changes {
            mutate_once(cat, &mut a, rng);
        }
        a.pieces.sort_by_key(|p| (p.2, p.1));
        a.mirror = true;
        if a.pieces == parent.pieces || a.cost(cat) < min_cost - 1e-9 || !a.problems(cat, 8).is_empty() {
            continue;
        }
        a.name = a.to_text(cat, 8);
        return Some(a);
    }
    None
}

// ---------- ratings ----------

/// One game from an army's point of view.
#[derive(Clone, Copy)]
struct Result1 {
    opp: usize,
    white: bool,
    score: f32,
}

/// Performance rating (Elo) and its standard error, given the opponents'
/// ratings and White's edge, with a normal prior N(0, PRIOR_SD).
fn performance(games: &[(f64, bool, f64)], edge: f64) -> (f64, f64) {
    let mut r = 0.0f64;
    let prior = 1.0 / (PRIOR_SD * ELO_K).powi(2);
    let mut info = prior;
    for _ in 0..30 {
        let z0 = r * ELO_K;
        let mut grad = -prior * z0;
        info = prior;
        for &(ro, white, s) in games {
            let z = z0 - ro * ELO_K + if white { edge } else { -edge } * ELO_K;
            let mu = 1.0 / (1.0 + (-z).exp());
            grad += s - mu;
            info += mu * (1.0 - mu);
        }
        let step = grad / info;
        r += step / ELO_K;
        if step.abs() < 1e-7 {
            break;
        }
    }
    (r, 1.0 / info.sqrt() / ELO_K)
}

// ---------- state ----------

pub struct Entry {
    pub army: Army,
    pub key: String,
    pub is_ref: bool,
    pub rating: f64,
    pub se: f64,
    games: Vec<Result1>,
}

pub struct State {
    pub gen: usize,
    pub edge: f64,
    pub entries: Vec<Entry>,
    index: HashMap<String, usize>,
    pub archive: [Option<usize>; NICHES],
    /// Candidates rejected before playing (illegal mutants are never made;
    /// these are the too-exposed ones), so they aren't retried.
    rejected: HashSet<String>,
    pub stale: usize,
    pub games_played: usize,
    pub minutes: f64,
}

impl State {
    fn new() -> State {
        State { gen: 0, edge: 0.0, entries: Vec::new(), index: HashMap::new(), archive: [None; NICHES], rejected: HashSet::new(), stale: 0, games_played: 0, minutes: 0.0 }
    }

    fn add(&mut self, army: Army, key: String, is_ref: bool, rating: f64) -> usize {
        if let Some(&i) = self.index.get(&key) {
            return i;
        }
        let i = self.entries.len();
        self.entries.push(Entry { army, key: key.clone(), is_ref, rating, se: PRIOR_SD, games: Vec::new() });
        self.index.insert(key, i);
        i
    }

    fn record(&mut self, w: usize, b: usize, result: f32) {
        self.entries[w].games.push(Result1 { opp: b, white: true, score: result });
        self.entries[b].games.push(Result1 { opp: w, white: false, score: 1.0 - result });
        self.games_played += 1;
    }

    /// Re-estimates a non-reference army's rating from all its games.
    fn rate(&mut self, i: usize) {
        if self.entries[i].is_ref {
            return;
        }
        let g: Vec<(f64, bool, f64)> = self.entries[i].games.iter().map(|x| (self.entries[x.opp].rating, x.white, x.score as f64)).collect();
        let (r, se) = performance(&g, self.edge);
        self.entries[i].rating = r;
        self.entries[i].se = se;
    }

    fn elites(&self) -> Vec<usize> {
        self.archive.iter().flatten().copied().collect()
    }

    fn save(&self, dir: &Path, cat: &Catalog) {
        let mut s = String::new();
        s += &format!("gen {}\nedge {}\nstale {}\nminutes {}\n", self.gen, self.edge, self.stale, self.minutes);
        for e in self.entries.iter().filter(|e| e.is_ref) {
            s += &format!("ref {} {} {}\n", e.key, e.rating, e.army.to_text(cat, 8));
        }
        for (n, a) in self.archive.iter().enumerate() {
            if let Some(i) = a {
                s += &format!("elite {} {}\n", n, self.entries[*i].key);
            }
        }
        for k in &self.rejected {
            s += &format!("rejected {}\n", k);
        }
        let tmp = dir.join("state.tmp");
        std::fs::write(&tmp, s).expect("can't write state");
        std::fs::rename(&tmp, dir.join("state.txt")).expect("can't write state");
    }
}

fn army_from_key(cat: &Catalog, key: &str) -> Army {
    if key == STANDARD_KEY {
        return standard(cat);
    }
    let mut a = Army::from_text(cat, key).expect("bad army in state");
    a.name = key.to_string();
    a
}

fn load_state(dir: &Path, cat: &Catalog) -> Option<State> {
    let text = std::fs::read_to_string(dir.join("state.txt")).ok()?;
    let mut st = State::new();
    let mut elites = Vec::new();
    for line in text.lines() {
        let parts: Vec<&str> = line.split_whitespace().collect();
        match parts.as_slice() {
            ["gen", v] => st.gen = v.parse().unwrap(),
            ["edge", v] => st.edge = v.parse().unwrap(),
            ["stale", v] => st.stale = v.parse().unwrap(),
            ["minutes", v] => st.minutes = v.parse().unwrap(),
            ["ref", key, rating, _text] => {
                let a = army_from_key(cat, key);
                st.add(a, key.to_string(), true, rating.parse().unwrap());
            }
            ["elite", n, key] => elites.push((n.parse::<usize>().unwrap(), key.to_string())),
            ["rejected", key] => {
                st.rejected.insert(key.to_string());
            }
            _ => {}
        }
    }
    if let Ok(games) = std::fs::read_to_string(dir.join("games.txt")) {
        for line in games.lines() {
            let p: Vec<&str> = line.split_whitespace().collect();
            if p.len() != 3 {
                continue;
            }
            let w = st.add(army_from_key(cat, p[0]), p[0].to_string(), false, 0.0);
            let b = st.add(army_from_key(cat, p[1]), p[1].to_string(), false, 0.0);
            st.record(w, b, p[2].parse().unwrap());
        }
    }
    for (n, key) in elites {
        st.archive[n] = st.index.get(&key).copied();
    }
    // Ratings settle after a few passes (elites play each other).
    for _ in 0..4 {
        for i in 0..st.entries.len() {
            st.rate(i);
        }
    }
    Some(st)
}

// ---------- playing ----------

/// Plays the games (white entry, black entry) and records them.
fn play(st: &mut State, cat: &Arc<Catalog>, params: &Params, cfg: &EvolveConfig, jobs: &[(usize, usize)], salt: u64) {
    if jobs.is_empty() {
        return;
    }
    let pcfg = PlayConfig { nodes: cfg.nodes, random_plies: 6, tt_mb: 4, ..Default::default() };
    let armies: Vec<(Army, Army)> = jobs.iter().map(|&(w, b)| (st.entries[w].army.clone(), st.entries[b].army.clone())).collect();
    let pair = |i: usize, _r: &mut Rng| -> (Army, Army, bool) { (armies[i].0.clone(), armies[i].1.clone(), true) };
    let log = Mutex::new(std::fs::OpenOptions::new().create(true).append(true).open(cfg.dir.join("games.txt")).expect("can't open games.txt"));
    let keys: Vec<(String, String)> = jobs.iter().map(|&(w, b)| (st.entries[w].key.clone(), st.entries[b].key.clone())).collect();
    let progress = |_r: &GameRecord, _n: usize| {};
    let seed = cfg.seed.wrapping_mul(0x9E37_79B9).wrapping_add(salt);
    let recs = run_games(cat, jobs.len(), cfg.threads, params, params, &pcfg, seed, &pair, &progress);
    let mut f = log.lock().unwrap();
    for (i, rec) in recs.iter().enumerate() {
        writeln!(f, "{} {} {}", keys[i].0, keys[i].1, rec.result).ok();
        st.record(jobs[i].0, jobs[i].1, rec.result);
    }
}

/// `n` more games (both colours) for entry `c`, against the reference armies
/// and current elites in turn, skipping pairings with an attacked king.
fn schedule(st: &State, checker: &StartChecker, c: usize, n: usize, rng: &mut Rng) -> Vec<(usize, usize)> {
    let mut opps: Vec<usize> = st.entries.iter().enumerate().filter(|(_, e)| e.is_ref).map(|(i, _)| i).collect();
    opps.extend(st.elites().into_iter().filter(|&e| e != c));
    let mut order = opps.clone();
    rng.shuffle(&mut order);
    // Standard and the Berserker build first, so every test includes them.
    for key in [BERSERKER_WALL, STANDARD_KEY] {
        let i = st.index[key];
        order.retain(|&x| x != i);
        order.insert(0, i);
    }
    let mut jobs = Vec::new();
    let mut k = 0;
    let ca = &st.entries[c].army;
    let mut tries = 0;
    while jobs.len() + 2 <= n && tries < 4 * order.len() + 4 {
        let o = order[k % order.len()];
        k += 1;
        tries += 1;
        if checker.broken_pair(ca, &st.entries[o].army) {
            continue;
        }
        jobs.push((c, o));
        jobs.push((o, c));
    }
    jobs
}

fn calibrate(st: &mut State, cat: &Arc<Catalog>, params: &Params, cfg: &EvolveConfig) {
    let refs: Vec<usize> = (0..st.entries.len()).collect();
    let mut jobs = Vec::new();
    for &a in &refs {
        for &b in &refs {
            if a != b {
                for _ in 0..(cfg.calibration_games / 2).max(1) {
                    jobs.push((a, b));
                }
            }
        }
    }
    eprintln!("calibrating {} reference armies: {} games", refs.len(), jobs.len());
    let before = st.games_played;
    play(st, cat, params, cfg, &jobs, 0xCA1);
    // Fit ratings (Standard = 0) and White's edge.
    let na = refs.len();
    let mut x = Vec::new();
    let mut y = Vec::new();
    for e in 0..na {
        for g in &st.entries[e].games {
            if g.white {
                let mut row = vec![0.0; na];
                row[e] += 1.0;
                row[g.opp] -= 1.0;
                row.remove(0);
                row.push(1.0);
                x.push(row);
                y.push(g.score as f64);
            }
        }
    }
    let (beta, _, _) = crate::tune::logistic_cov(&x, &y, 0.01);
    for e in 1..na {
        st.entries[e].rating = beta[e - 1] / ELO_K;
    }
    st.edge = beta[na - 1] / ELO_K;
    eprintln!("  {} games; White's edge {:+.0} Elo", st.games_played - before, st.edge);
    for e in &st.entries {
        eprintln!("  {:+6.0}  {}", e.rating, e.key);
    }
}

fn print_archive(st: &State, cat: &Catalog) {
    for n in 0..NICHES {
        match st.archive[n] {
            Some(i) => {
                let e = &st.entries[i];
                eprintln!("  {:<22} {:+5.0} ±{:<3.0} {:>3}g  {:>4} pts  {:<18} {}", niche_name(n), e.rating, 1.96 * e.se, e.games.len(), e.army.cost(cat), style(cat, &e.army), e.key);
            }
            None => eprintln!("  {:<22} (empty)", niche_name(n)),
        }
    }
}

/// Writes `archive.txt`: the elites with their niche, style, cost, rating.
fn write_archive(st: &State, cat: &Catalog, checker: &StartChecker, dir: &Path) {
    let mut s = String::from("# army | niche | style | cost | rating vs Standard (evolution estimate) | games | exposure\n");
    let mut order: Vec<(usize, usize)> = st.archive.iter().enumerate().filter_map(|(n, a)| a.map(|i| (n, i))).collect();
    order.sort_by(|a, b| st.entries[b.1].rating.partial_cmp(&st.entries[a.1].rating).unwrap());
    for (n, i) in order {
        let e = &st.entries[i];
        s += &format!(
            "{} | {} | {} | {} | {:+.0} ±{:.0} | {} | {:.1}%\n",
            e.key,
            niche_name(n),
            style(cat, &e.army),
            e.army.cost(cat),
            e.rating,
            1.96 * e.se,
            e.games.len(),
            100.0 * checker.exposure(&e.army)
        );
    }
    std::fs::write(dir.join("archive.txt"), s).expect("can't write archive");
}

pub fn evolve(cat: &Arc<Catalog>, params: &Params, cfg: &EvolveConfig) {
    std::fs::create_dir_all(&cfg.dir).expect("can't make run folder");
    let checker = StartChecker::new(cat, 300, 99);
    let start = std::time::Instant::now();
    let mut st = match load_state(&cfg.dir, cat) {
        Some(s) => {
            eprintln!("resuming {} at generation {} ({} games so far)", cfg.dir.display(), s.gen, s.games_played);
            s
        }
        None => {
            let mut s = State::new();
            s.add(standard(cat), STANDARD_KEY.into(), true, 0.0);
            let bw = Army::from_text(cat, BERSERKER_WALL).unwrap();
            s.add(bw, BERSERKER_WALL.into(), true, 0.0);
            let mut rng = Rng::new(cfg.seed ^ 0x5EED);
            while s.entries.len() < 2 + cfg.random_refs {
                let a = random_army(cat, &mut rng);
                let ok = a.cost(cat) >= 37.0 && s.entries.iter().all(|e| !checker.broken_pair(&a, &e.army));
                if ok {
                    let key = a.to_text(cat, 8);
                    s.add(a, key, true, 0.0);
                }
            }
            // Ref games are logged too; reload them only as ref games.
            let _ = std::fs::remove_file(cfg.dir.join("games.txt"));
            calibrate(&mut s, cat, params, cfg);
            s.save(&cfg.dir, cat);
            s
        }
    };
    let base_minutes = st.minutes;
    loop {
        let minutes = base_minutes + start.elapsed().as_secs_f64() / 60.0;
        let full = st.archive.iter().all(|a| a.is_some());
        if st.gen >= cfg.generations {
            eprintln!("stopping: {} generations", st.gen);
            break;
        }
        if minutes >= cfg.max_minutes {
            eprintln!("stopping: time limit ({:.0} minutes)", minutes);
            break;
        }
        if full && st.stale >= cfg.patience {
            eprintln!("stopping: no elite changed for {} generations", st.stale);
            break;
        }
        let mut rng = Rng::new(cfg.seed.wrapping_mul(7919).wrapping_add(st.gen as u64 * 104_729));
        // 1. Candidates.
        let mut cands: Vec<usize> = Vec::new();
        let mut tries = 0;
        let mut exposed = 0;
        while cands.len() < cfg.batch && tries < cfg.batch * 50 {
            tries += 1;
            let elites = st.elites();
            let a = if elites.len() < 3 || rng.float() < cfg.fresh {
                let mut a = random_army(cat, &mut rng);
                a.pieces.sort_by_key(|p| (p.2, p.1));
                if a.cost(cat) < cfg.min_cost {
                    continue;
                }
                a
            } else {
                let p = elites[rng.below(elites.len())];
                match mutate(cat, &st.entries[p].army, cfg.min_cost, &mut rng) {
                    Some(a) => a,
                    None => continue,
                }
            };
            let key = a.to_text(cat, 8);
            if st.index.contains_key(&key) || st.rejected.contains(&key) {
                continue;
            }
            if checker.exposure(&a) > cfg.max_exposure {
                st.rejected.insert(key);
                exposed += 1;
                continue;
            }
            cands.push(st.add(a, key, false, 0.0));
        }
        // 2. Racing.
        let mut alive = cands.clone();
        let mut changed = 0;
        for stage in 0..3 {
            let mut jobs = Vec::new();
            for &c in &alive {
                jobs.extend(schedule(&st, &checker, c, cfg.stages[stage], &mut rng));
            }
            if stage == 2 {
                // Elites being challenged get at least as many games.
                let target: usize = cfg.stages.iter().sum();
                let mut seen = HashSet::new();
                for &c in &alive {
                    if let Some(e) = st.archive[niche(cat, &st.entries[c].army)] {
                        let have = st.entries[e].games.len();
                        if have < target && seen.insert(e) {
                            jobs.extend(schedule(&st, &checker, e, (target - have + 1) & !1, &mut rng));
                        }
                    }
                }
            }
            let salt = (st.gen * 3 + stage) as u64 + 1;
            play(&mut st, cat, params, cfg, &jobs, salt);
            for i in 0..st.entries.len() {
                if !st.entries[i].is_ref && !st.entries[i].games.is_empty() {
                    st.rate(i);
                }
            }
            let mut next = Vec::new();
            for &c in &alive {
                let n = niche(cat, &st.entries[c].army);
                let r = st.entries[c].rating;
                match st.archive[n] {
                    None => {
                        st.archive[n] = Some(c);
                        changed += 1;
                    }
                    Some(e) if e == c => {}
                    Some(e) => {
                        let er = st.entries[e].rating;
                        if stage < 2 {
                            if r > er - cfg.margins[stage] {
                                next.push(c);
                            }
                        } else if r > er {
                            st.archive[n] = Some(c);
                            changed += 1;
                        }
                    }
                }
            }
            alive = next;
            if alive.is_empty() {
                break;
            }
        }
        st.gen += 1;
        st.stale = if changed > 0 { 0 } else { st.stale + 1 };
        st.minutes = base_minutes + start.elapsed().as_secs_f64() / 60.0;
        st.save(&cfg.dir, cat);
        write_archive(&st, cat, &checker, &cfg.dir);
        eprintln!(
            "generation {}: {} candidates ({} rejected as exposed), {} new elites, {} games so far, {:.1} min",
            st.gen,
            cands.len(),
            exposed,
            changed,
            st.games_played,
            st.minutes
        );
        print_archive(&st, cat);
    }
    write_archive(&st, cat, &checker, &cfg.dir);
    eprintln!("final archive in {}", cfg.dir.join("archive.txt").display());
    print_archive(&st, cat);
}

#[cfg(test)]
mod tests {
    use super::*;

    fn cat() -> Arc<Catalog> {
        let dir = find_pieces_dir(None).expect("pieces");
        Arc::new(Catalog::load_dir(&dir).unwrap())
    }

    #[test]
    fn mutants_stay_legal() {
        let cat = cat();
        let mut rng = Rng::new(3);
        let mut a = standard(&cat);
        a.mirror = true;
        for _ in 0..2000 {
            let m = mutate(&cat, &a, 36.0, &mut rng).expect("no mutant");
            assert!(m.problems(&cat, 8).is_empty(), "{}", m.to_text(&cat, 8));
            assert!(m.cost(&cat) >= 36.0);
            a = m;
        }
    }

    #[test]
    fn checker_matches_game_setup() {
        let cat = cat();
        let ch = StartChecker::new(&cat, 0, 1);
        let mut rng = Rng::new(11);
        for _ in 0..500 {
            let w = random_army(&cat, &mut rng);
            let b = random_army(&cat, &mut rng);
            assert_eq!(ch.broken(&w, &b), start_is_broken(&army_game(&cat, &w, &b, 8, 8)));
        }
    }

    #[test]
    fn performance_is_sane() {
        let even: Vec<(f64, bool, f64)> = (0..100).map(|i| (100.0, i % 2 == 0, 0.5)).collect();
        let (r, _) = performance(&even, 0.0);
        // Pulled a little towards the prior's 0.
        assert!(r > 70.0 && r < 100.0, "{}", r);
        let wins: Vec<(f64, bool, f64)> = (0..100).map(|i| (0.0, i % 2 == 0, if i % 4 == 0 { 0.0 } else { 1.0 })).collect();
        let (r, se) = performance(&wins, 0.0);
        assert!(r > 150.0 && r < 200.0 && se > 20.0 && se < 50.0, "{} {}", r, se);
    }
}

#[cfg(test)]
mod tres_tests {
    use super::*;

    #[test]
    fn tres_round_trips() {
        let dir = find_pieces_dir(None).expect("pieces");
        let cat = Arc::new(Catalog::load_dir(&dir).unwrap());
        let mut rng = Rng::new(5);
        let mut armies = vec![standard(&cat)];
        for _ in 0..50 {
            armies.push(random_army(&cat, &mut rng));
        }
        for mut a in armies {
            a.name = format!("Test \"{}\"", a.to_text(&cat, 8));
            let back = Army::from_tres(&cat, &a.to_tres(&cat)).unwrap();
            let (mut x, mut y) = (a.pieces.clone(), back.pieces.clone());
            x.sort();
            y.sort();
            assert_eq!(x, y);
            assert_eq!(a.mirror, back.mirror);
            assert_eq!(a.name, back.name);
        }
    }
}
