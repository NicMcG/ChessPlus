//! The search: iterative deepening alpha-beta (principal variation search) with
//! a transposition table, null-move pruning, late-move reductions, check
//! extensions, killer/history move ordering and a quiescence search over
//! captures, shield breaks, Crack Shots and promotions.

use crate::eval::*;
use crate::position::*;
use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::Arc;
use crate::util::now_ms;

pub const INF: i32 = 32000;
pub const MATE: i32 = 31000;
pub const MATE_BOUND: i32 = MATE - 1000;
const MAX_PLY: usize = 128;

#[derive(Clone, Copy, Default)]
struct TTEntry {
    key: u64,
    mv: Move,
    score: i16,
    eval: i16,
    depth: i8,
    bound: u8,
    age: u8,
}

/// The transposition table. Entries are three 64-bit words: the key XOR the
/// two data words, then the data. Threads can share it without locks: a
/// half-written entry fails the key check and is just a miss.
pub struct TT {
    words: Vec<AtomicU64>,
    mask: usize,
}

impl TT {
    pub fn new(mb: usize) -> TT {
        let entries = (mb.max(1) * 1024 * 1024 / 24).next_power_of_two() / 2;
        let entries = entries.max(1024);
        TT { words: (0..entries * 3).map(|_| AtomicU64::new(0)).collect(), mask: entries - 1 }
    }

    pub fn mb(&self) -> usize {
        self.words.len() * 8 / (1024 * 1024)
    }

    pub fn clear(&self) {
        for w in &self.words {
            w.store(0, Ordering::Relaxed);
        }
    }

    #[inline(always)]
    fn slot(&self, key: u64) -> usize {
        (key as usize) & self.mask
    }

    #[inline(always)]
    fn load(&self, slot: usize) -> TTEntry {
        let i = slot * 3;
        let k = self.words[i].load(Ordering::Relaxed);
        let a = self.words[i + 1].load(Ordering::Relaxed);
        let b = self.words[i + 2].load(Ordering::Relaxed);
        TTEntry {
            key: k ^ a ^ b,
            mv: Move { from: a as u8, to: (a >> 8) as u8, flags: (a >> 16) as u8, promo: (a >> 24) as u8, extra: (a >> 32) as u8, steps: (a >> 40) as u8 },
            score: (a >> 48) as u16 as i16,
            eval: b as u16 as i16,
            depth: (b >> 16) as u8 as i8,
            bound: (b >> 24) as u8,
            age: (b >> 32) as u8,
        }
    }

    #[inline(always)]
    fn store(&self, slot: usize, e: TTEntry) {
        let m = e.mv;
        let a = m.from as u64
            | (m.to as u64) << 8
            | (m.flags as u64) << 16
            | (m.promo as u64) << 24
            | (m.extra as u64) << 32
            | (m.steps as u64) << 40
            | (e.score as u16 as u64) << 48;
        let b = e.eval as u16 as u64 | (e.depth as u8 as u64) << 16 | (e.bound as u64) << 24 | (e.age as u64) << 32;
        let i = slot * 3;
        self.words[i].store(e.key ^ a ^ b, Ordering::Relaxed);
        self.words[i + 1].store(a, Ordering::Relaxed);
        self.words[i + 2].store(b, Ordering::Relaxed);
    }
}

const B_EXACT: u8 = 1;
const B_LOWER: u8 = 2;
const B_UPPER: u8 = 3;

#[derive(Clone, Copy, Debug, Default)]
pub struct Limits {
    pub depth: Option<i32>,
    pub nodes: Option<u64>,
    pub movetime_ms: Option<u64>,
}

#[derive(Clone, Debug)]
pub struct Line {
    pub score: i32,
    pub pv: Vec<Move>,
}

#[derive(Clone, Debug)]
pub struct Report {
    pub depth: i32,
    pub seldepth: usize,
    pub nodes: u64,
    pub ms: u64,
    pub lines: Vec<Line>,
}

/// The tables a search learns from (hash table, history), kept between moves
/// of one game: `Searcher::into_tables` / `Searcher::with_tables`.
pub struct SearchTables {
    tt: Arc<TT>,
    age: u8,
    history: Vec<i32>,
}

pub struct Searcher<'a> {
    pub r: &'a Rules,
    pub et: &'a EvalTables,
    pub params: &'a Params,
    tt: Arc<TT>,
    age: u8,
    killers: [[Move; 2]; MAX_PLY + 2],
    /// The move played to reach each ply (NONE after a null move).
    played: [Move; MAX_PLY + 2],
    /// Static evaluation at each ply (-INF when in check), for "improving".
    evals: [i32; MAX_PLY + 2],
    /// Counter-moves: the quiet reply that last refuted a move, by side and
    /// that move's from/to squares.
    counter: Vec<Move>,
    history: Vec<i32>,
    pv: Vec<[Move; MAX_PLY + 1]>,
    pv_len: [usize; MAX_PLY + 1],
    buffers: Vec<Vec<Move>>,
    keys: Vec<u64>,
    values: Vec<i32>,
    pub nodes: u64,
    seldepth: usize,
    start: u64,
    limits: Limits,
    pub stop: Arc<AtomicBool>,
    stopped: bool,
    /// True while the first depth runs: limits don't apply until there's a move.
    must_finish: bool,
    root_excluded: Vec<Move>,
    /// Lazy SMP helpers search one ply deeper on odd thread numbers, so the
    /// threads don't all do the same work.
    depth_offset: i32,
}

fn is_mate(s: i32) -> bool {
    s.abs() >= MATE_BOUND
}

fn to_tt(s: i32, ply: usize) -> i32 {
    if s >= MATE_BOUND {
        s + ply as i32
    } else if s <= -MATE_BOUND {
        s - ply as i32
    } else {
        s
    }
}

fn from_tt(s: i32, ply: usize) -> i32 {
    if s >= MATE_BOUND {
        s - ply as i32
    } else if s <= -MATE_BOUND {
        s + ply as i32
    } else {
        s
    }
}

impl<'a> Searcher<'a> {
    pub fn new(r: &'a Rules, et: &'a EvalTables, params: &'a Params, tt_mb: usize) -> Searcher<'a> {
        let values = (0..r.info.len()).map(|k| piece_value(params, k)).collect();
        Searcher {
            r,
            et,
            params,
            tt: Arc::new(TT::new(tt_mb)),
            age: 0,
            killers: [[Move::NONE; 2]; MAX_PLY + 2],
            played: [Move::NONE; MAX_PLY + 2],
            evals: [-INF; MAX_PLY + 2],
            counter: vec![Move::NONE; 2 * MAX_SQ * MAX_SQ],
            history: vec![0; 2 * MAX_SQ * MAX_SQ],
            pv: vec![[Move::NONE; MAX_PLY + 1]; MAX_PLY + 1],
            pv_len: [0; MAX_PLY + 1],
            buffers: (0..MAX_PLY + 2).map(|_| Vec::with_capacity(128)).collect(),
            keys: Vec::with_capacity(512),
            values,
            nodes: 0,
            seldepth: 0,
            start: now_ms(),
            limits: Limits::default(),
            stop: Arc::new(AtomicBool::new(false)),
            stopped: false,
            must_finish: false,
            root_excluded: Vec::new(),
            depth_offset: 0,
        }
    }

    /// A searcher that carries on with tables from an earlier one.
    pub fn with_tables(r: &'a Rules, et: &'a EvalTables, params: &'a Params, t: SearchTables) -> Searcher<'a> {
        let mut s = Searcher::new(r, et, params, 1);
        s.tt = t.tt;
        s.age = t.age;
        s.history = t.history;
        s
    }

    pub fn into_tables(self) -> SearchTables {
        SearchTables { tt: self.tt, age: self.age, history: self.history }
    }

    pub fn tt_mb(t: &SearchTables) -> usize {
        t.tt.mb()
    }

    pub fn clear(&mut self) {
        self.tt.clear();
        for h in self.history.iter_mut() {
            *h = 0;
        }
    }

    #[inline]
    fn eval(&self, p: &Position) -> i32 {
        evaluate(p, self.r, self.et, self.params)
    }

    fn time_up(&mut self) -> bool {
        if self.stopped {
            return true;
        }
        if self.must_finish {
            // An outside "stop" still counts.
            if self.nodes & 1023 == 0 && self.stop.load(Ordering::Relaxed) {
                self.stopped = true;
            }
            return self.stopped;
        }
        if self.nodes & 1023 == 0 {
            if self.stop.load(Ordering::Relaxed) {
                self.stopped = true;
            }
            if let Some(ms) = self.limits.movetime_ms {
                if (now_ms() - self.start) >= ms {
                    self.stopped = true;
                }
            }
        }
        if let Some(n) = self.limits.nodes {
            if self.nodes >= n {
                self.stopped = true;
            }
        }
        self.stopped
    }

    /// Searches `pos`. `history_keys`: repetition keys of the game's earlier
    /// positions (oldest first, not including `pos`), so repetitions count.
    /// `report` is called after each finished depth.
    pub fn search(&mut self, pos: &Position, history_keys: &[u64], limits: Limits, multipv: usize, mut report: impl FnMut(&Report)) -> Report {
        self.start = now_ms();
        self.limits = limits;
        self.nodes = 0;
        self.stopped = false;
        self.age = self.age.wrapping_add(1);
        self.killers = [[Move::NONE; 2]; MAX_PLY + 2];
        for h in self.history.iter_mut() {
            *h /= 8;
        }
        let max_depth = limits.depth.unwrap_or(MAX_PLY as i32 - 8).min(MAX_PLY as i32 - 8);
        let root_moves = pos.legal_moves(self.r);
        let mut best = Report { depth: 0, seldepth: 0, nodes: 0, ms: 0, lines: Vec::new() };
        if root_moves.is_empty() {
            let score = if pos.in_check(self.r, pos.side) { -MATE } else { 0 };
            best.lines.push(Line { score, pv: Vec::new() });
            return best;
        }
        let multipv = multipv.max(1).min(root_moves.len());
        let mut prev_scores: Vec<i32> = vec![0; multipv];
        for depth in 1..=max_depth {
            self.seldepth = 0;
            self.must_finish = depth == 1;
            let mut lines: Vec<Line> = Vec::new();
            self.root_excluded.clear();
            for idx in 0..multipv {
                let mut delta = 30;
                let mut alpha = -INF;
                let mut beta = INF;
                if depth >= 4 && !is_mate(prev_scores[idx]) {
                    alpha = prev_scores[idx] - delta;
                    beta = prev_scores[idx] + delta;
                }
                let score = loop {
                    self.keys.clear();
                    self.keys.extend_from_slice(history_keys);
                    let s = self.negamax(pos, depth + self.depth_offset, alpha, beta, 0, true, false);
                    if self.stopped {
                        break s;
                    }
                    if s <= alpha {
                        alpha = (alpha - delta).max(-INF);
                        beta = (alpha + beta) / 2;
                    } else if s >= beta {
                        beta = (beta + delta).min(INF);
                    } else {
                        break s;
                    }
                    delta += delta;
                    if delta > 1000 {
                        alpha = -INF;
                        beta = INF;
                    }
                };
                if self.stopped && (depth > 1 || idx > 0) {
                    break;
                }
                let pv: Vec<Move> = self.pv[0][..self.pv_len[0]].to_vec();
                if pv.is_empty() {
                    break;
                }
                self.root_excluded.push(pv[0]);
                lines.push(Line { score, pv });
            }
            if self.stopped && (depth > 1) && lines.len() < multipv {
                // Keep the previous depth's complete result, but take a better
                // first line if one finished.
                if let Some(l) = lines.first() {
                    if !best.lines.is_empty() && l.pv.first() == best.lines[0].pv.first() {
                        best.lines[0] = l.clone();
                    }
                }
                break;
            }
            lines.sort_by(|a, b| b.score.cmp(&a.score));
            for (i, l) in lines.iter().enumerate() {
                prev_scores[i] = l.score;
            }
            best = Report { depth, seldepth: self.seldepth, nodes: self.nodes, ms: (now_ms() - self.start), lines };
            report(&best);
            if self.stopped {
                break;
            }
            if multipv == 1 && is_mate(best.lines[0].score) && depth > 8 && (MATE - best.lines[0].score.abs()) < depth {
                break;
            }
            if let Some(ms) = limits.movetime_ms {
                // Don't start a depth we're unlikely to finish.
                if (now_ms() - self.start) * 2 > ms && limits.depth.is_none() {
                    break;
                }
            }
        }
        self.must_finish = false;
        if best.lines.is_empty() {
            // Only possible after an outside "stop" during depth 1.
            best.lines.push(Line { score: 0, pv: vec![root_moves[0]] });
        }
        best.nodes = self.nodes;
        best.ms = now_ms() - self.start;
        best
    }

    /// `search` on `threads` threads (Lazy SMP): helper threads search the
    /// same position with their own move-ordering tables, sharing the hash
    /// table, and stop when this (the main) thread finishes. Only the main
    /// thread's limits and results count; the node total includes helpers.
    /// Native only: the WebAssembly build has no threads.
    #[cfg(not(target_arch = "wasm32"))]
    pub fn search_threads(&mut self, pos: &Position, history_keys: &[u64], limits: Limits, multipv: usize, threads: usize, report: impl FnMut(&Report)) -> Report {
        if threads <= 1 {
            return self.search(pos, history_keys, limits, multipv, report);
        }
        let helper_stop = Arc::new(AtomicBool::new(false));
        let (r, et, params) = (self.r, self.et, self.params);
        let age = self.age;
        std::thread::scope(|sc| {
            let mut handles = Vec::new();
            for i in 1..threads {
                let tt = self.tt.clone();
                let hs = helper_stop.clone();
                handles.push(sc.spawn(move || {
                    let mut h = Searcher::new(r, et, params, 1);
                    h.tt = tt;
                    h.age = age;
                    h.stop = hs;
                    h.depth_offset = (i % 2) as i32;
                    let lim = Limits { depth: limits.depth, nodes: None, movetime_ms: None };
                    h.search(pos, history_keys, lim, 1, |_| {});
                    h.nodes
                }));
            }
            let mut rep = self.search(pos, history_keys, limits, multipv, report);
            helper_stop.store(true, Ordering::SeqCst);
            for h in handles {
                rep.nodes += h.join().unwrap_or(0);
            }
            rep
        })
    }

    /// Without threads (WebAssembly): an ordinary search.
    #[cfg(target_arch = "wasm32")]
    pub fn search_threads(&mut self, pos: &Position, history_keys: &[u64], limits: Limits, multipv: usize, _threads: usize, report: impl FnMut(&Report)) -> Report {
        self.search(pos, history_keys, limits, multipv, report)
    }

    fn is_repetition(&self, p: &Position) -> bool {
        let n = self.keys.len();
        let window = (p.halfmove as usize).min(n);
        for i in 1..=window {
            if self.keys[n - i] == p.key {
                return true;
            }
        }
        false
    }

    fn order(&self, p: &Position, moves: &mut [Move], tt_move: Move, ply: usize) -> Vec<i32> {
        let us = p.side;
        moves
            .iter()
            .map(|m| {
                if *m == tt_move {
                    return 10_000_000;
                }
                let attacker = self.values[kind_of(p.sq[m.from as usize])];
                if m.flags & F_CAPTURE != 0 {
                    let victim = self.values[kind_of(p.sq[m.capture_square() as usize])];
                    let crack = if m.flags & F_CRACK != 0 { 50 } else { 0 };
                    if self.capture_gain(p, *m) < -50 {
                        // Probably loses material: after the killers.
                        return 650_000 + victim * 16 - attacker / 8;
                    }
                    return 1_000_000 + victim * 16 - attacker / 8 + crack;
                }
                if m.promo != 0 {
                    return 900_000 + self.values[m.promo as usize - 1];
                }
                if m.flags & F_SHIELD != 0 {
                    return 800_000 + self.values[kind_of(p.sq[m.to as usize])] * 4 - attacker / 8;
                }
                if *m == self.killers[ply][0] {
                    return 700_000;
                }
                if *m == self.killers[ply][1] {
                    return 690_000;
                }
                if ply > 0 && *m == self.counter_of(p.side, self.played[ply - 1]) {
                    return 680_000;
                }
                if m.flags & F_RAISE != 0 {
                    return 600_000 + self.values[m.extra as usize];
                }
                self.history[(us * MAX_SQ + m.from as usize) * MAX_SQ + m.to as usize]
            })
            .collect()
    }

    /// A rough exchange estimate for a capture: what it wins, minus the
    /// capturing piece if it is then lost (a Ram always is; other pieces when
    /// the square is defended). Not a full exchange evaluation, but cheap and
    /// it works for any piece type.
    fn capture_gain(&self, p: &Position, m: Move) -> i32 {
        let victim = self.values[kind_of(p.sq[m.capture_square() as usize])];
        if m.flags & F_CRACK != 0 {
            return victim;
        }
        let k = kind_of(p.sq[m.from as usize]);
        let mut attacker = self.values[k];
        let mut gain = victim;
        if m.promo != 0 {
            attacker = self.values[m.promo as usize - 1];
            gain += attacker - self.values[k];
        }
        if self.r.info[k].dies {
            return gain - self.values[k];
        }
        if attacker > victim && p.attacked(self.r, m.to as usize, 1 - p.side) {
            return gain - attacker;
        }
        gain
    }

    #[inline]
    fn counter_of(&self, side: usize, prev: Move) -> Move {
        if prev == Move::NONE {
            return Move::NONE;
        }
        self.counter[(side * MAX_SQ + prev.from as usize) * MAX_SQ + prev.to as usize]
    }

    fn negamax(&mut self, p: &Position, mut depth: i32, mut alpha: i32, mut beta: i32, ply: usize, is_pv: bool, was_null: bool) -> i32 {
        self.pv_len[ply] = 0;
        if self.time_up() {
            return 0;
        }
        let r = self.r;
        let root = ply == 0;
        if !root {
            if self.is_repetition(p) || p.halfmove >= 100 {
                return 0;
            }
            if (p.occupied().count_ones() as usize) <= 5 && p.checkmate_impossible(r) {
                return 0;
            }
            // Mate distance pruning.
            alpha = alpha.max(-MATE + ply as i32);
            beta = beta.min(MATE - ply as i32 - 1);
            if alpha >= beta {
                return alpha;
            }
            if ply >= MAX_PLY {
                return self.eval(p);
            }
        }
        let in_check = p.in_check(r, p.side);
        if in_check && depth < 1 {
            depth = 1;
        }
        if depth <= 0 {
            return self.quiesce(p, alpha, beta, ply);
        }
        self.nodes += 1;
        // Transposition table.
        let slot = self.tt.slot(p.key);
        let e = self.tt.load(slot);
        let mut tt_move = Move::NONE;
        if e.key == p.key && e.bound != 0 {
            tt_move = e.mv;
            let s = from_tt(e.score as i32, ply);
            if !is_pv && e.depth as i32 >= depth && !root {
                if e.bound == B_EXACT || (e.bound == B_LOWER && s >= beta) || (e.bound == B_UPPER && s <= alpha) {
                    return s;
                }
            }
        }
        let static_eval = if in_check { -INF } else if e.key == p.key && e.bound != 0 { e.eval as i32 } else { self.eval(p) };
        let us = p.side;
        self.evals[ply] = static_eval;
        // Is our position better than two plies ago? If not, prune harder.
        let improving = !in_check && (ply < 2 || self.evals[ply - 2] == -INF || static_eval > self.evals[ply - 2]);

        if !is_pv && !in_check && !root {
            // Reverse futility pruning.
            if depth <= 6 && static_eval - 90 * depth + if improving { 45 } else { 0 } >= beta && !is_mate(beta) {
                return static_eval;
            }
            // Null move: if passing still beats beta, a real move surely will.
            if !was_null && depth >= 3 && static_eval >= beta && self.has_pieces(p, us) {
                let mut child = p.clone();
                child.ep = 0;
                child.ep_victim = NO_SQ;
                child.halfmove += 1;
                child.set_side(r, 1 - us);
                child.update_key(r);
                let rd = 3 + depth / 4;
                self.keys.push(p.key);
                self.played[ply] = Move::NONE;
                let s = -self.negamax(&child, depth - rd, -beta, -beta + 1, ply + 1, false, true);
                self.keys.pop();
                if self.stopped {
                    return 0;
                }
                if s >= beta {
                    return if is_mate(s) { beta } else { s };
                }
            }
        }

        let mut moves = std::mem::take(&mut self.buffers[ply]);
        moves.clear();
        p.gen_pseudo(r, &mut moves, GEN_ALL);
        if root && !self.root_excluded.is_empty() {
            let ex = self.root_excluded.clone();
            moves.retain(|m| !ex.contains(m));
        }
        let mut scores = self.order(p, &mut moves, tt_move, ply);
        let mut best = -INF;
        let mut best_move = Move::NONE;
        let mut legal = 0;
        let orig_alpha = alpha;
        let mut quiets_tried = [Move::NONE; 32];
        let mut n_quiets = 0;
        self.keys.push(p.key);
        for i in 0..moves.len() {
            // Selection sort: the next best-ordered move.
            let mut bi = i;
            for j in i + 1..moves.len() {
                if scores[j] > scores[bi] {
                    bi = j;
                }
            }
            moves.swap(i, bi);
            scores.swap(i, bi);
            let m = moves[i];
            let mut child = p.clone();
            child.make(r, m);
            if child.leaves_king_attacked(p, r, m) {
                continue;
            }
            legal += 1;
            let gives_check = child.in_check(r, child.side);
            let quiet = !m.is_tactical() && m.flags & (F_RAISE | F_CASTLE) == 0;
            // Late move pruning for quiet moves near the leaves.
            let lmp_limit = if improving { 4 + depth * depth * 3 } else { 3 + depth * depth * 2 };
            if !is_pv && !in_check && quiet && !gives_check && depth <= 3 && legal > lmp_limit && best > -MATE_BOUND {
                continue;
            }
            self.played[ply] = m;
            // Futility pruning: near the leaves, a quiet move can't lift a
            // position this far below alpha.
            if !is_pv && !in_check && quiet && !gives_check && depth <= 3 && legal > 1 && static_eval + 100 + 120 * depth <= alpha && !is_mate(alpha) {
                continue;
            }
            let ext = if gives_check && ply < 64 { 1 } else { 0 };
            let new_depth = depth - 1 + ext;
            let score;
            if legal == 1 {
                score = -self.negamax(&child, new_depth, -beta, -alpha, ply + 1, is_pv, false);
            } else {
                let mut red = 0;
                if depth >= 3 && quiet && !in_check && !gives_check && legal > if is_pv { 4 } else { 2 } {
                    red = (0.75 + (depth as f32).ln() * (legal as f32).ln() / 2.2) as i32;
                    if is_pv {
                        red -= 1;
                    }
                    red -= self.history[(us * MAX_SQ + m.from as usize) * MAX_SQ + m.to as usize] / 6000;
                    red = red.clamp(0, new_depth - 1);
                }
                let mut s = -self.negamax(&child, new_depth - red, -alpha - 1, -alpha, ply + 1, false, false);
                if s > alpha && red > 0 {
                    s = -self.negamax(&child, new_depth, -alpha - 1, -alpha, ply + 1, false, false);
                }
                if s > alpha && s < beta && is_pv {
                    s = -self.negamax(&child, new_depth, -beta, -alpha, ply + 1, true, false);
                }
                score = s;
            }
            if self.stopped {
                break;
            }
            if quiet && n_quiets < quiets_tried.len() {
                quiets_tried[n_quiets] = m;
                n_quiets += 1;
            }
            if score > best {
                best = score;
                best_move = m;
                if score > alpha {
                    alpha = score;
                    self.pv[ply][0] = m;
                    let n = self.pv_len[ply + 1].min(MAX_PLY - 1);
                    for k in 0..n {
                        self.pv[ply][k + 1] = self.pv[ply + 1][k];
                    }
                    self.pv_len[ply] = n + 1;
                    if score >= beta {
                        if quiet {
                            if self.killers[ply][0] != m {
                                self.killers[ply][1] = self.killers[ply][0];
                                self.killers[ply][0] = m;
                            }
                            if ply > 0 {
                                let prev = self.played[ply - 1];
                                if prev != Move::NONE {
                                    self.counter[(us * MAX_SQ + prev.from as usize) * MAX_SQ + prev.to as usize] = m;
                                }
                            }
                            // The move that cut off gains; the quiet moves tried
                            // before it lose (bounded "gravity" updates).
                            let bonus = (depth * depth * 16).min(1600);
                            for (j, q) in quiets_tried[..n_quiets].iter().enumerate() {
                                let b = if j + 1 == n_quiets { bonus } else { -bonus };
                                let h = &mut self.history[(us * MAX_SQ + q.from as usize) * MAX_SQ + q.to as usize];
                                *h += b - *h * b.abs() / 16384;
                            }
                        }
                        break;
                    }
                }
            }
        }
        self.keys.pop();
        self.buffers[ply] = moves;
        if self.stopped {
            return 0;
        }
        if legal == 0 {
            if root && !self.root_excluded.is_empty() {
                return -INF;
            }
            return if in_check { -MATE + ply as i32 } else { 0 };
        }
        let bound = if best >= beta {
            B_LOWER
        } else if best > orig_alpha {
            B_EXACT
        } else {
            B_UPPER
        };
        let e = self.tt.load(slot);
        if e.key != p.key || depth as i8 >= e.depth - 2 || e.age != self.age || bound == B_EXACT {
            self.tt.store(
                slot,
                TTEntry {
                    key: p.key,
                    mv: best_move,
                    score: to_tt(best, ply).clamp(-INF, INF) as i16,
                    eval: static_eval.clamp(-INF, INF) as i16,
                    depth: depth.min(127) as i8,
                    bound,
                    age: self.age,
                },
            );
        }
        best
    }

    fn has_pieces(&self, p: &Position, team: usize) -> bool {
        p.squares(team).any(|s| {
            let i = &self.r.info[kind_of(p.sq[s])];
            !i.is_pawn && !i.is_king
        })
    }

    fn quiesce(&mut self, p: &Position, mut alpha: i32, beta: i32, ply: usize) -> i32 {
        self.pv_len[ply] = 0;
        self.nodes += 1;
        if ply > self.seldepth {
            self.seldepth = ply;
        }
        if self.time_up() {
            return 0;
        }
        let r = self.r;
        if ply >= MAX_PLY {
            return self.eval(p);
        }
        // Transposition table: any stored result is deep enough here.
        let slot = self.tt.slot(p.key);
        let e = self.tt.load(slot);
        let hit = e.key == p.key && e.bound != 0;
        let mut tt_move = Move::NONE;
        if hit {
            let s = from_tt(e.score as i32, ply);
            if e.bound == B_EXACT || (e.bound == B_LOWER && s >= beta) || (e.bound == B_UPPER && s <= alpha) {
                return s;
            }
            tt_move = e.mv;
        }
        let orig_alpha = alpha;
        let in_check = p.in_check(r, p.side);
        let raw_eval = if in_check { -INF } else if hit { e.eval as i32 } else { self.eval(p) };
        let stand = if in_check { -MATE + ply as i32 } else { raw_eval };
        if !in_check {
            if stand >= beta {
                return stand;
            }
            alpha = alpha.max(stand);
        }
        let mut moves = std::mem::take(&mut self.buffers[ply]);
        moves.clear();
        p.gen_pseudo(r, &mut moves, if in_check { GEN_ALL } else { GEN_TACTICAL });
        let mut scores = self.order(p, &mut moves, tt_move, ply.min(MAX_PLY));
        let mut best = stand;
        let mut best_move = Move::NONE;
        let mut legal = 0;
        for i in 0..moves.len() {
            let mut bi = i;
            for j in i + 1..moves.len() {
                if scores[j] > scores[bi] {
                    bi = j;
                }
            }
            moves.swap(i, bi);
            scores.swap(i, bi);
            let m = moves[i];
            // Captures that probably lose material.
            if !in_check && m.flags & F_CAPTURE != 0 && self.capture_gain(p, m) < -50 {
                continue;
            }
            // Delta pruning: even winning this piece can't lift us to alpha.
            if !in_check && m.promo == 0 {
                let gain = if m.flags & F_CAPTURE != 0 {
                    self.values[kind_of(p.sq[m.capture_square() as usize])]
                } else {
                    self.values[kind_of(p.sq[m.to as usize])] / 2
                };
                if stand + gain + 150 < alpha {
                    continue;
                }
            }
            let mut child = p.clone();
            child.make(r, m);
            if child.leaves_king_attacked(p, r, m) {
                continue;
            }
            legal += 1;
            let s = -self.quiesce(&child, -beta, -alpha, ply + 1);
            if self.stopped {
                break;
            }
            if s > best {
                best = s;
                best_move = m;
                if s > alpha {
                    alpha = s;
                    self.pv[ply][0] = m;
                    let n = self.pv_len[ply + 1].min(MAX_PLY - 1);
                    for k in 0..n {
                        self.pv[ply][k + 1] = self.pv[ply + 1][k];
                    }
                    self.pv_len[ply] = n + 1;
                    if s >= beta {
                        break;
                    }
                }
            }
        }
        self.buffers[ply] = moves;
        if self.stopped {
            return 0;
        }
        if in_check && legal == 0 {
            return -MATE + ply as i32;
        }
        let e = self.tt.load(slot);
        if e.key != p.key || e.depth <= 0 || e.age != self.age {
            let bound = if best >= beta {
                B_LOWER
            } else if best > orig_alpha {
                B_EXACT
            } else {
                B_UPPER
            };
            self.tt.store(
                slot,
                TTEntry { key: p.key, mv: best_move, score: to_tt(best, ply).clamp(-INF, INF) as i16, eval: raw_eval.clamp(-INF, INF) as i16, depth: 0, bound, age: self.age },
            );
        }
        best
    }
}

/// "+1.25", "-0.40" or "#3" / "#-2" (mate in N moves), for people.
pub fn score_text(s: i32) -> String {
    if s >= MATE_BOUND {
        format!("#{}", (MATE - s + 1) / 2)
    } else if s <= -MATE_BOUND {
        format!("#-{}", (MATE + s) / 2)
    } else {
        format!("{:+.2}", s as f64 / 100.0)
    }
}

/// UCI style: "cp 125" or "mate 3".
pub fn score_uci(s: i32) -> String {
    if s >= MATE_BOUND {
        format!("mate {}", (MATE - s + 1) / 2)
    } else if s <= -MATE_BOUND {
        format!("mate -{}", (MATE + s) / 2)
    } else {
        format!("cp {}", s)
    }
}
