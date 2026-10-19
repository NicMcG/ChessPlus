//! The rules engine: positions, move generation, attack detection, making moves
//! and game outcomes. It is a straight port of the game's `core/` GDScript
//! (move_generator.gd, game_state.gd), driven entirely by the piece data, just
//! with precomputed tables and copy-make so it runs a few hundred times faster.

use crate::defs::*;
use std::sync::Arc;

pub const MAX_SQ: usize = 128;
pub const WHITE: usize = 0;
pub const BLACK: usize = 1;
pub const NO_SQ: u8 = 255;

// A square holds 0 (empty) or a piece code.
pub const PRESENT: u16 = 1 << 15;
pub const BLACK_BIT: u16 = 1 << 6;
pub const MOVED: u16 = 1 << 7;
pub const BROKEN: u16 = 1 << 8;
pub const USED: u16 = 1 << 9;

#[inline(always)]
pub fn kind_of(c: u16) -> usize {
    (c & 63) as usize
}
#[inline(always)]
pub fn team_of(c: u16) -> usize {
    ((c >> 6) & 1) as usize
}
#[inline(always)]
pub fn code(kind: usize, team: usize) -> u16 {
    PRESENT | kind as u16 | ((team as u16) << 6)
}

// Move flags.
pub const F_CAPTURE: u8 = 1;
pub const F_SHIELD: u8 = 2;
pub const F_EP: u8 = 4;
pub const F_CASTLE: u8 = 8;
pub const F_CRACK: u8 = 16;
pub const F_RAISE: u8 = 32;
pub const F_SKIP: u8 = 64;

pub const GEN_ALL: u8 = 0;
pub const GEN_CAPTURES: u8 = 1;
pub const GEN_TACTICAL: u8 = 2;

/// One move. `extra` depends on the kind of move: en passant -> the captured
/// piece's square; castling -> the partner's square; Raise Dead -> the kind
/// raised; a multi-step pawn move (F_SKIP) -> its leap count, with `steps` = how
/// many steps it took (for the squares it skipped).
#[derive(Clone, Copy, Debug, PartialEq, Eq, Default, Hash)]
pub struct Move {
    pub from: u8,
    pub to: u8,
    pub flags: u8,
    /// Promotion kind + 1, or 0.
    pub promo: u8,
    pub extra: u8,
    pub steps: u8,
}

impl Move {
    pub const NONE: Move = Move { from: 0, to: 0, flags: 0, promo: 0, extra: 0, steps: 0 };
    #[inline]
    pub fn is_capture(&self) -> bool {
        self.flags & (F_CAPTURE | F_SHIELD) != 0
    }
    #[inline]
    pub fn is_null(&self) -> bool {
        self.from == self.to && self.flags & F_RAISE == 0
    }
    #[inline]
    pub fn capture_square(&self) -> u8 {
        if self.flags & F_EP != 0 {
            self.extra
        } else {
            self.to
        }
    }
    /// Captures, shield breaks and promotions: the moves quiescence looks at.
    #[inline]
    pub fn is_tactical(&self) -> bool {
        self.is_capture() || self.promo != 0
    }
}

#[derive(Clone, Copy, Debug)]
pub struct KindInfo {
    pub is_king: bool,
    pub is_royal: bool,
    pub is_pawn: bool,
    pub can_promote: bool,
    pub castle: bool,
    pub shield: bool,
    pub dies: bool,
    pub ability: Ability,
    pub first_move: bool,
    pub can_capture: bool,
    pub cost: f64,
}

#[derive(Clone, Copy, Debug)]
pub struct Ray {
    pub start: u32,
    pub len: u8,
    pub lim_moved: u8,
    pub lim_unmoved: u8,
    pub mode: Mode,
    pub hop: bool,
    pub leap: u8,
    pub leap_own: bool,
    pub is_path: bool,
    pub dx: i8,
    pub dy: i8,
}

#[derive(Clone, Debug)]
struct Attacker {
    kind: u8,
    lim_moved: u8,
    lim_unmoved: u8,
    hop: bool,
}

#[derive(Clone, Debug)]
struct Line {
    attackers: Vec<Attacker>,
    plain_mask: u32,
    hop_mask: u32,
    has_hop: bool,
}

#[derive(Clone, Copy, Debug)]
struct RevRay {
    line: u16,
    start: u32,
    len: u8,
}

pub struct Zobrist {
    pub piece: Vec<u64>, // [sq][kind][team]
    pub broken: Vec<u64>,
    pub used: Vec<u64>,
    pub unmoved: Vec<u64>,
    pub side: u64,
    pub castle: [u64; 16],
    pub ep: Vec<u64>,
    pub lost: Vec<u64>, // [team][kind][count 0..16]
}

/// Everything fixed for one game: board size, piece types, promotion choices,
/// and the precomputed move/attack tables.
pub struct Rules {
    pub cat: Arc<Catalog>,
    pub w: i32,
    pub h: i32,
    pub nsq: usize,
    pub info: Vec<KindInfo>,
    /// Promotion choices (kinds), most valuable first.
    pub promo: Vec<u8>,
    pub castle_corner: bool,
    ray_sq: Vec<u8>,
    rays: Vec<Ray>,
    ray_index: Vec<(u32, u32)>,
    unusual: [u32; 2],
    lines: [Vec<Line>; 2],
    rev_sq: Vec<u8>,
    rev: Vec<RevRay>,
    rev_index: [Vec<(u32, u32)>; 2],
    pub z: Zobrist,
}

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

impl Rules {
    /// `kinds_present`: bit mask of piece kinds that can ever be on the board in
    /// this game (on it at the start, promotion choices, lost pieces). The attack
    /// tables cover just those, like `GameState.attack_table`.
    pub fn new(cat: Arc<Catalog>, w: i32, h: i32, promo: Vec<u8>, castle_corner: bool, kinds_present: u32) -> Rules {
        assert!(w >= 1 && h >= 1 && (w * h) as usize <= MAX_SQ && w <= 26, "board too big");
        let nsq = (w * h) as usize;
        let nk = cat.len();
        let maxwh = w.max(h);
        let info: Vec<KindInfo> = cat
            .defs
            .iter()
            .map(|d| KindInfo {
                is_king: d.is_king(),
                is_royal: d.is_royal(),
                is_pawn: d.is_pawn(),
                can_promote: d.can_promote(),
                castle: d.has_castle(),
                shield: d.has_shield(),
                dies: d.dies_on_capture,
                ability: d.ability,
                first_move: d.has_first_move_rule(),
                can_capture: d.can_capture(),
                cost: d.value,
            })
            .collect();
        let lim = |steps: i32| -> u8 { (if steps == 0 { maxwh } else { steps }).clamp(0, 255) as u8 };

        // Forward rays: for each kind, team and square.
        let mut ray_sq = Vec::new();
        let mut rays = Vec::new();
        let mut ray_index = vec![(0u32, 0u32); nk * 2 * nsq];
        let mut unusual = [0u32; 2];
        for k in 0..nk {
            let def = &cat.defs[k];
            for t in 0..2 {
                let flip = if t == WHITE { 1 } else { -1 };
                for s in 0..nsq {
                    let (fx, fy) = ((s as i32) % w, (s as i32) / w);
                    let begin = rays.len() as u32;
                    for rule in &def.rules {
                        if !rule.path.is_empty() {
                            if rule.mode != Mode::MoveOnly {
                                unusual[t] |= 1 << k;
                            }
                            for variant in rule.path_variants() {
                                let (mut x, mut y) = (fx, fy);
                                let start = ray_sq.len() as u32;
                                let mut ok = !variant.is_empty();
                                for &(dx, dy) in &variant {
                                    x += dx;
                                    y += dy * flip;
                                    if x < 0 || y < 0 || x >= w || y >= h {
                                        ok = false;
                                        break;
                                    }
                                    ray_sq.push((y * w + x) as u8);
                                }
                                if !ok {
                                    ray_sq.truncate(start as usize);
                                    continue;
                                }
                                rays.push(Ray {
                                    start,
                                    len: variant.len() as u8,
                                    lim_moved: 0,
                                    lim_unmoved: 0,
                                    mode: rule.mode,
                                    hop: false,
                                    leap: 0,
                                    leap_own: false,
                                    is_path: true,
                                    dx: 0,
                                    dy: 0,
                                });
                            }
                            continue;
                        }
                        if rule.leap_steps > 0 && rule.mode != Mode::MoveOnly {
                            unusual[t] |= 1 << k;
                        }
                        let lm = lim(rule.max_steps);
                        let lu = if rule.first_move_max_steps > 0 { lim(rule.first_move_max_steps) } else { lm };
                        let reach = lm.max(lu) as i32;
                        for &(dx, dy) in &rule.directions {
                            if dx == 0 && dy == 0 {
                                continue;
                            }
                            let (sx, sy) = (dx, dy * flip);
                            let start = ray_sq.len() as u32;
                            let (mut x, mut y) = (fx, fy);
                            let mut n = 0;
                            while n < reach {
                                x += sx;
                                y += sy;
                                if x < 0 || y < 0 || x >= w || y >= h {
                                    break;
                                }
                                ray_sq.push((y * w + x) as u8);
                                n += 1;
                            }
                            if n == 0 {
                                continue;
                            }
                            rays.push(Ray {
                                start,
                                len: n as u8,
                                lim_moved: lm,
                                lim_unmoved: lu,
                                mode: rule.mode,
                                hop: rule.captures_by_hopping,
                                leap: rule.leap_steps.clamp(0, 255) as u8,
                                leap_own: rule.leap_over_own,
                                is_path: false,
                                dx: sx as i8,
                                dy: sy as i8,
                            });
                        }
                    }
                    ray_index[(k * 2 + t) * nsq + s] = (begin, rays.len() as u32);
                }
            }
        }

        // Attack lines (MoveGenerator.attack_table), walked back from a target.
        let mut lines: [Vec<Line>; 2] = [Vec::new(), Vec::new()];
        let mut line_steps: [Vec<(i32, i32, i32)>; 2] = [Vec::new(), Vec::new()];
        for t in 0..2 {
            let flip = if t == WHITE { 1 } else { -1 };
            for k in 0..nk {
                if kinds_present & (1 << k) == 0 {
                    continue;
                }
                for rule in &cat.defs[k].rules {
                    if rule.mode == Mode::MoveOnly || rule.is_unusual() {
                        continue;
                    }
                    let lm = lim(rule.max_steps);
                    let lu = if rule.first_move_max_steps > 0 { lim(rule.first_move_max_steps) } else { lm };
                    let reach = lm.max(lu) as i32;
                    for &(dx, dy) in &rule.directions {
                        if dx == 0 && dy == 0 {
                            continue;
                        }
                        let step = (dx, dy * flip);
                        let idx = match line_steps[t].iter().position(|&(a, b, _)| (a, b) == step) {
                            Some(i) => i,
                            None => {
                                line_steps[t].push((step.0, step.1, 0));
                                lines[t].push(Line { attackers: Vec::new(), plain_mask: 0, hop_mask: 0, has_hop: false });
                                lines[t].len() - 1
                            }
                        };
                        line_steps[t][idx].2 = line_steps[t][idx].2.max(reach);
                        let line = &mut lines[t][idx];
                        line.attackers.push(Attacker { kind: k as u8, lim_moved: lm, lim_unmoved: lu, hop: rule.captures_by_hopping });
                        if rule.captures_by_hopping {
                            line.hop_mask |= 1 << k;
                            line.has_hop = true;
                        } else {
                            line.plain_mask |= 1 << k;
                        }
                    }
                }
            }
        }
        let mut rev_sq = Vec::new();
        let mut rev = Vec::new();
        let mut rev_index: [Vec<(u32, u32)>; 2] = [vec![(0, 0); nsq], vec![(0, 0); nsq]];
        for t in 0..2 {
            for s in 0..nsq {
                let (tx, ty) = ((s as i32) % w, (s as i32) / w);
                let begin = rev.len() as u32;
                for (li, &(sx, sy, reach)) in line_steps[t].iter().enumerate() {
                    let start = rev_sq.len() as u32;
                    let (mut x, mut y) = (tx, ty);
                    let mut n = 0;
                    while n < reach {
                        x -= sx;
                        y -= sy;
                        if x < 0 || y < 0 || x >= w || y >= h {
                            break;
                        }
                        rev_sq.push((y * w + x) as u8);
                        n += 1;
                    }
                    if n > 0 {
                        rev.push(RevRay { line: li as u16, start, len: n as u8 });
                    }
                }
                rev_index[t][s] = (begin, rev.len() as u32);
            }
        }
        for t in 0..2 {
            unusual[t] &= kinds_present;
        }

        let mut seed = 0x5EED_C0DE_1234_5678u64;
        let mut gen = |n: usize| -> Vec<u64> { (0..n).map(|_| splitmix(&mut seed)).collect() };
        let piece = gen(nsq * MAX_KINDS * 2);
        let broken = gen(nsq);
        let used = gen(nsq);
        let unmoved = gen(nsq);
        let side = gen(1)[0];
        let castle_v = gen(16);
        let mut castle = [0u64; 16];
        castle.copy_from_slice(&castle_v);
        castle[0] = 0;
        let ep = gen(nsq);
        let mut lost = gen(2 * MAX_KINDS * 17);
        for t in 0..2 {
            for k in 0..MAX_KINDS {
                lost[(t * MAX_KINDS + k) * 17] = 0;
            }
        }
        Rules {
            cat,
            w,
            h,
            nsq,
            info,
            promo,
            castle_corner,
            ray_sq,
            rays,
            ray_index,
            unusual,
            lines,
            rev_sq,
            rev,
            rev_index,
            z: Zobrist { piece, broken, used, unmoved, side, castle, ep, lost },
        }
    }

    #[inline(always)]
    pub fn rays_of(&self, kind: usize, team: usize, sq: usize) -> &[Ray] {
        let (a, b) = self.ray_index[(kind * 2 + team) * self.nsq + sq];
        &self.rays[a as usize..b as usize]
    }
    #[inline(always)]
    pub fn ray_squares(&self, r: &Ray) -> &[u8] {
        &self.ray_sq[r.start as usize..r.start as usize + r.len as usize]
    }
    #[inline(always)]
    pub fn file(&self, sq: usize) -> i32 {
        sq as i32 % self.w
    }
    #[inline(always)]
    pub fn rank(&self, sq: usize) -> i32 {
        sq as i32 / self.w
    }
    #[inline(always)]
    pub fn far_rank(&self, team: usize) -> i32 {
        if team == WHITE {
            self.h - 1
        } else {
            0
        }
    }
    #[inline(always)]
    pub fn back_rank(&self, team: usize) -> i32 {
        if team == WHITE {
            0
        } else {
            self.h - 1
        }
    }
    #[inline]
    pub fn def(&self, kind: usize) -> &PieceDef {
        &self.cat.defs[kind]
    }

    #[inline(always)]
    fn piece_key(&self, sq: usize, c: u16) -> u64 {
        let k = kind_of(c);
        let mut h = self.z.piece[(sq * MAX_KINDS + k) * 2 + team_of(c)];
        if c & BROKEN != 0 {
            h ^= self.z.broken[sq];
        }
        if c & USED != 0 {
            h ^= self.z.used[sq];
        }
        if c & MOVED == 0 && self.info[k].first_move {
            h ^= self.z.unmoved[sq];
        }
        h
    }
    #[inline(always)]
    fn lost_key(&self, team: usize, kind: usize, count: u8) -> u64 {
        self.z.lost[(team * MAX_KINDS + kind) * 17 + (count.min(16) as usize)]
    }
}

#[derive(Clone)]
pub struct Position {
    pub sq: [u16; MAX_SQ],
    pub occ: [u128; 2],
    pub kings: [u128; 2],
    pub side: usize,
    /// Squares the last move's pawn-type piece skipped (en passant targets).
    pub ep: u128,
    pub ep_victim: u8,
    pub halfmove: u32,
    pub fullmove: u32,
    /// Lost pieces per team, as counts per kind.
    pub lost: [[u8; MAX_KINDS]; 2],
    /// Pieces + lost + side, kept up to date move by move.
    pub hash: u64,
    /// `hash` plus castling rights and usable en passant: same key = same
    /// position for repetition (`GameState._position_key`).
    pub key: u64,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Outcome {
    None,
    Checkmate,
    Stalemate,
    FiftyMoves,
    Repetition,
    Insufficient,
}

#[inline(always)]
fn bits(mut b: u128) -> impl Iterator<Item = usize> {
    std::iter::from_fn(move || {
        if b == 0 {
            None
        } else {
            let s = b.trailing_zeros() as usize;
            b &= b - 1;
            Some(s)
        }
    })
}

impl Position {
    pub fn empty() -> Position {
        Position {
            sq: [0; MAX_SQ],
            occ: [0; 2],
            kings: [0; 2],
            side: WHITE,
            ep: 0,
            ep_victim: NO_SQ,
            halfmove: 0,
            fullmove: 1,
            lost: [[0; MAX_KINDS]; 2],
            hash: 0,
            key: 0,
        }
    }

    #[inline(always)]
    pub fn put(&mut self, r: &Rules, s: usize, c: u16) {
        debug_assert!(self.sq[s] == 0);
        self.sq[s] = c;
        let t = team_of(c);
        self.occ[t] |= 1u128 << s;
        if r.info[kind_of(c)].is_king {
            self.kings[t] |= 1u128 << s;
        }
        self.hash ^= r.piece_key(s, c);
    }

    #[inline(always)]
    pub fn remove(&mut self, r: &Rules, s: usize) -> u16 {
        let c = self.sq[s];
        if c == 0 {
            return 0;
        }
        self.sq[s] = 0;
        let t = team_of(c);
        self.occ[t] &= !(1u128 << s);
        self.kings[t] &= !(1u128 << s);
        self.hash ^= r.piece_key(s, c);
        c
    }

    #[inline(always)]
    fn add_lost(&mut self, r: &Rules, team: usize, kind: usize, delta: i32) {
        let old = self.lost[team][kind];
        let new = (old as i32 + delta).clamp(0, 255) as u8;
        self.hash ^= r.lost_key(team, kind, old) ^ r.lost_key(team, kind, new);
        self.lost[team][kind] = new;
    }

    pub fn set_side(&mut self, r: &Rules, side: usize) {
        if self.side != side {
            self.hash ^= r.z.side;
            self.side = side;
        }
    }

    pub fn set_lost(&mut self, r: &Rules, team: usize, kind: usize, count: u8) {
        let d = count as i32 - self.lost[team][kind] as i32;
        self.add_lost(r, team, kind, d);
    }

    #[inline]
    pub fn occupied(&self) -> u128 {
        self.occ[0] | self.occ[1]
    }

    /// True if a piece of `by` could capture on `s` (`MoveGenerator.attacked_with`).
    pub fn attacked(&self, r: &Rules, s: usize, by: usize) -> bool {
        let (a, b) = r.rev_index[by][s];
        for rr in &r.rev[a as usize..b as usize] {
            let line = &r.lines[by][rr.line as usize];
            let mut screens = 0;
            let sqs = &r.rev_sq[rr.start as usize..rr.start as usize + rr.len as usize];
            for (i, &p) in sqs.iter().enumerate() {
                let c = self.sq[p as usize];
                if c == 0 {
                    continue;
                }
                if team_of(c) == by {
                    let k = kind_of(c);
                    let mask = if screens == 0 { line.plain_mask } else { line.hop_mask };
                    if mask & (1 << k) != 0 {
                        let dist = (i + 1) as u8;
                        let hop = screens == 1;
                        for at in &line.attackers {
                            if at.kind as usize == k && at.hop == hop {
                                let limit = if c & MOVED != 0 { at.lim_moved } else { at.lim_unmoved };
                                if dist <= limit {
                                    return true;
                                }
                            }
                        }
                    }
                }
                screens += 1;
                if screens > 1 || !line.has_hop {
                    break;
                }
            }
        }
        let um = r.unusual[by];
        if um != 0 {
            for from in bits(self.occ[by]) {
                let c = self.sq[from];
                let k = kind_of(c);
                if um & (1 << k) == 0 {
                    continue;
                }
                for ray in r.rays_of(k, by, from) {
                    if ray.mode == Mode::MoveOnly {
                        continue;
                    }
                    if ray.is_path {
                        let sqs = r.ray_squares(ray);
                        if sqs[sqs.len() - 1] as usize == s && sqs[..sqs.len() - 1].iter().all(|&p| self.sq[p as usize] == 0) {
                            return true;
                        }
                    } else if ray.leap > 0 {
                        if self.ray_reaches(r, ray, c, by, s) {
                            return true;
                        }
                    }
                }
            }
        }
        false
    }

    /// `_rule_reaches` for a leaping rule.
    fn ray_reaches(&self, r: &Rules, ray: &Ray, c: u16, team: usize, s: usize) -> bool {
        let sqs = r.ray_squares(ray);
        let idx = match sqs.iter().position(|&p| p as usize == s) {
            Some(i) => i,
            None => return false,
        };
        let limit = if c & MOVED != 0 { ray.lim_moved } else { ray.lim_unmoved } as usize;
        if idx < ray.leap as usize || idx + 1 > limit {
            return false;
        }
        for j in 0..idx {
            let p = self.sq[sqs[j] as usize];
            if j < ray.leap as usize {
                if ray.leap_own && (p == 0 || team_of(p) != team) {
                    return false;
                }
            } else if p != 0 {
                return false;
            }
        }
        true
    }

    pub fn in_check(&self, r: &Rules, team: usize) -> bool {
        for k in bits(self.kings[team]) {
            if self.attacked(r, k, 1 - team) {
                return true;
            }
        }
        false
    }

    #[inline(always)]
    fn push(&self, r: &Rules, kind: usize, us: usize, m: Move, out: &mut Vec<Move>) {
        if r.info[kind].can_promote && m.flags & F_SHIELD == 0 && !r.promo.is_empty() && r.rank(m.to as usize) == r.far_rank(us) {
            for &p in &r.promo {
                let mut pm = m;
                pm.promo = p + 1;
                out.push(pm);
            }
        } else {
            out.push(m);
        }
    }

    #[inline(always)]
    fn hit(&self, r: &Rules, from: usize, to: usize, target: u16) -> Move {
        let flags = if r.info[kind_of(target)].shield && target & BROKEN == 0 { F_SHIELD } else { F_CAPTURE };
        Move { from: from as u8, to: to as u8, flags, promo: 0, extra: 0, steps: 0 }
    }

    /// Every move by the movement rules, not checking whether it leaves the king
    /// in check (`MoveGenerator.pseudo_legal_moves`). `mode`: GEN_ALL, or
    /// GEN_CAPTURES (captures, shield breaks, Crack Shots), or GEN_TACTICAL
    /// (those plus quiet promotions).
    pub fn gen_pseudo(&self, r: &Rules, out: &mut Vec<Move>, mode: u8) {
        let us = self.side;
        let tactical_only = mode != GEN_ALL;
        let far = r.far_rank(us);
        for from in bits(self.occ[us]) {
            let c = self.sq[from];
            let k = kind_of(c);
            let info = r.info[k];
            let promo_quiet = mode == GEN_TACTICAL && info.can_promote && !r.promo.is_empty();
            let first_new = out.len();
            let moved = c & MOVED != 0;
            for ray in r.rays_of(k, us, from) {
                let sqs = r.ray_squares(ray);
                if ray.is_path {
                    let n = sqs.len();
                    if !sqs[..n - 1].iter().all(|&p| self.sq[p as usize] == 0) {
                        continue;
                    }
                    let to = sqs[n - 1] as usize;
                    let t = self.sq[to];
                    if t == 0 {
                        if ray.mode != Mode::CaptureOnly && (!tactical_only || (promo_quiet && r.rank(to) == far)) {
                            self.push(r, k, us, Move { from: from as u8, to: to as u8, ..Move::NONE }, out);
                        }
                    } else if team_of(t) != us && ray.mode != Mode::MoveOnly {
                        self.push(r, k, us, self.hit(r, from, to, t), out);
                    }
                    continue;
                }
                let limit = (if moved { ray.lim_moved } else { ray.lim_unmoved }).min(ray.len) as usize;
                let leap = ray.leap as usize;
                let can_ep = info.is_pawn && ray.mode != Mode::MoveOnly && self.ep != 0;
                let quiet_ok = ray.mode != Mode::CaptureOnly && !tactical_only;
                let quiet_promo = ray.mode != Mode::CaptureOnly && promo_quiet;
                for i in 0..limit {
                    let to = sqs[i] as usize;
                    if i < leap {
                        if ray.leap_own {
                            let o = self.sq[to];
                            if o == 0 || team_of(o) != us {
                                break;
                            }
                        }
                        continue;
                    }
                    let t = self.sq[to];
                    if t == 0 {
                        if can_ep && self.ep & (1u128 << to) != 0 && self.ep_victim != NO_SQ {
                            let v = self.sq[self.ep_victim as usize];
                            if v != 0 && team_of(v) != us && r.info[kind_of(v)].is_pawn {
                                let m = Move { from: from as u8, to: to as u8, flags: F_CAPTURE | F_EP, promo: 0, extra: self.ep_victim, steps: 0 };
                                self.push(r, k, us, m, out);
                                continue;
                            }
                        }
                        if quiet_ok || (quiet_promo && r.rank(to) == far) {
                            let mut m = Move { from: from as u8, to: to as u8, ..Move::NONE };
                            if info.is_pawn && i > leap {
                                m.flags = F_SKIP;
                                m.steps = (i + 1) as u8;
                                m.extra = leap as u8;
                            }
                            self.push(r, k, us, m, out);
                        }
                        continue;
                    }
                    if ray.hop {
                        if ray.mode != Mode::MoveOnly {
                            for j in i + 1..limit {
                                let s2 = sqs[j] as usize;
                                let t2 = self.sq[s2];
                                if t2 == 0 {
                                    continue;
                                }
                                if team_of(t2) != us {
                                    self.push(r, k, us, self.hit(r, from, s2, t2), out);
                                }
                                break;
                            }
                        }
                    } else if team_of(t) != us && ray.mode != Mode::MoveOnly {
                        self.push(r, k, us, self.hit(r, from, to, t), out);
                    }
                    break;
                }
            }
            if !tactical_only && info.is_king && !moved {
                self.gen_castling(r, from, out);
            }
            if c & USED == 0 {
                match info.ability {
                    Ability::CrackShot => {
                        let end = out.len();
                        for i in first_new..end {
                            let m = out[i];
                            if m.is_capture() && m.promo == 0 {
                                let mut shot = m;
                                shot.flags |= F_CRACK;
                                shot.flags &= !F_SKIP;
                                out.push(shot);
                            }
                        }
                    }
                    Ability::RaiseDead if !tactical_only => {
                        for kk in 0..r.info.len() {
                            if self.lost[us][kk] > 0 && !r.info[kk].is_pawn && r.info[kk].ability != Ability::RaiseDead {
                                out.push(Move { from: from as u8, to: from as u8, flags: F_RAISE, promo: 0, extra: kk as u8, steps: 0 });
                            }
                        }
                    }
                    _ => {}
                }
            }
        }
    }

    fn gen_castling(&self, r: &Rules, king: usize, out: &mut Vec<Move>) {
        let us = self.side;
        let them = 1 - us;
        let (kx, ky) = (r.file(king), r.rank(king));
        let mut checked = false;
        for dir in [-1i32, 1] {
            let mut x = kx + dir;
            let mut partner = None;
            while x >= 0 && x < r.w {
                let s = (ky * r.w + x) as usize;
                if self.sq[s] != 0 {
                    partner = Some(s);
                    break;
                }
                x += dir;
            }
            let p = match partner {
                Some(p) => p,
                None => continue,
            };
            if (r.file(p) - kx).abs() < 3 {
                continue;
            }
            let pc = self.sq[p];
            if team_of(pc) != us || !r.info[kind_of(pc)].castle || pc & MOVED != 0 {
                continue;
            }
            if r.castle_corner {
                let px = r.file(p);
                if r.rank(p) != r.back_rank(us) || (px != 0 && px != r.w - 1) {
                    continue;
                }
            }
            if !checked {
                if self.attacked(r, king, them) {
                    return;
                }
                checked = true;
            }
            let crossed = (king as i32 + dir) as usize;
            if self.attacked(r, crossed, them) {
                continue;
            }
            out.push(Move { from: king as u8, to: (king as i32 + 2 * dir) as u8, flags: F_CASTLE, promo: 0, extra: p as u8, steps: 0 });
        }
    }

    /// Plays a move (`GameState.make_move`). The position must be a copy if you
    /// want the old one back: there's no undo (copying is cheap).
    pub fn make(&mut self, r: &Rules, m: Move) {
        let us = self.side;
        let them = 1 - us;
        let from = m.from as usize;
        let to = m.to as usize;
        let mut c = self.sq[from];
        let k = kind_of(c);
        if m.is_capture() || r.info[k].is_pawn {
            self.halfmove = 0;
        } else {
            self.halfmove += 1;
        }
        if m.flags & (F_CRACK | F_RAISE) != 0 {
            self.remove(r, from);
            c |= USED;
            self.put(r, from, c);
        }
        self.ep = 0;
        self.ep_victim = NO_SQ;
        if m.flags & F_RAISE != 0 {
            let raised = m.extra as usize;
            self.add_lost(r, us, raised, -1);
            self.remove(r, from);
            self.put(r, from, code(raised, us) | MOVED);
            self.next_turn(r);
            return;
        }
        if m.flags & F_SHIELD != 0 {
            let t = self.remove(r, to);
            self.put(r, to, t | BROKEN);
            if r.info[k].dies {
                self.remove(r, from);
                self.add_lost(r, us, k, 1);
            }
            self.next_turn(r);
            return;
        }
        let cs = m.capture_square() as usize;
        if m.flags & F_CRACK != 0 {
            let t = self.remove(r, cs);
            self.add_lost(r, them, kind_of(t), 1);
            self.next_turn(r);
            return;
        }
        self.remove(r, from);
        if m.flags & F_CAPTURE != 0 {
            let t = self.remove(r, cs);
            self.add_lost(r, them, kind_of(t), 1);
        }
        if m.promo != 0 {
            self.put(r, to, code(m.promo as usize - 1, us) | MOVED);
        } else {
            self.put(r, to, c | MOVED);
        }
        if m.flags & F_CASTLE != 0 {
            let pf = m.extra as usize;
            let pc = self.remove(r, pf);
            let dir = if to > from { 1 } else { -1 };
            self.put(r, (from as i32 + dir) as usize, pc | MOVED);
        }
        if m.flags & F_CAPTURE != 0 && r.info[k].dies {
            self.remove(r, to);
            self.add_lost(r, us, k, 1);
        }
        if m.flags & F_SKIP != 0 {
            let n = m.steps as i32;
            let (dx, dy) = ((r.file(to) - r.file(from)) / n, (r.rank(to) - r.rank(from)) / n);
            for j in m.extra as i32..n - 1 {
                let x = r.file(from) + dx * (j + 1);
                let y = r.rank(from) + dy * (j + 1);
                self.ep |= 1u128 << (y * r.w + x);
            }
            if self.ep != 0 {
                self.ep_victim = to as u8;
            }
        }
        self.next_turn(r);
    }

    fn next_turn(&mut self, r: &Rules) {
        if self.side == BLACK {
            self.fullmove += 1;
        }
        self.side = 1 - self.side;
        self.hash ^= r.z.side;
        self.update_key(r);
    }

    /// Recomputes `key`: the running hash plus castling rights (as FEN writes
    /// them) and en passant, if a legal en passant capture exists.
    pub fn update_key(&mut self, r: &Rules) {
        let mut key = self.hash ^ r.z.castle[self.castling_bits(r) as usize];
        if self.ep != 0 {
            let mut moves = Vec::with_capacity(32);
            self.gen_pseudo(r, &mut moves, GEN_CAPTURES);
            for m in moves {
                // Same test as the game: a legal move whose capture square isn't
                // where it lands (en passant). Making it clears en passant, so
                // this never recurses more than once.
                if m.capture_square() != m.to && self.is_legal(r, m) {
                    key = key.wrapping_add(r.z.ep[m.to as usize]);
                }
            }
        }
        self.key = key;
    }

    /// Castling rights as 4 bits (white K, white Q, black K, black Q), worked out
    /// like `Fen._castling_text`.
    pub fn castling_bits(&self, r: &Rules) -> u8 {
        let mut b = 0u8;
        for team in 0..2 {
            let ks = self.kings[team];
            if ks == 0 {
                continue;
            }
            let king = ks.trailing_zeros() as usize;
            if self.sq[king] & MOVED != 0 {
                continue;
            }
            for (bit, dir) in [(0u8, 1i32), (1u8, -1i32)] {
                let mut x = r.file(king) + dir;
                let y = r.rank(king);
                while x >= 0 && x < r.w {
                    let p = self.sq[(y * r.w + x) as usize];
                    if p != 0 && team_of(p) == team && r.info[kind_of(p)].castle && p & MOVED == 0 {
                        b |= 1 << (team as u8 * 2 + bit);
                        break;
                    }
                    x += dir;
                }
            }
        }
        b
    }

    pub fn legal_moves(&self, r: &Rules) -> Vec<Move> {
        let mut pseudo = Vec::with_capacity(64);
        self.gen_pseudo(r, &mut pseudo, GEN_ALL);
        pseudo.retain(|&m| self.is_legal(r, m));
        pseudo
    }

    #[inline]
    pub fn is_legal(&self, r: &Rules, m: Move) -> bool {
        let mut child = self.clone();
        child.make(r, m);
        !child.leaves_king_attacked(self, r, m)
    }

    /// After `m` was played from `before`: is one of the mover's kings attacked?
    /// Like `MoveGenerator.legal_moves`, it checks the squares the kings stood
    /// on before the move (moved along if the king itself moved), so a king
    /// brought back by Raise Dead doesn't count yet.
    #[inline]
    pub fn leaves_king_attacked(&self, before: &Position, r: &Rules, m: Move) -> bool {
        let us = before.side;
        let mut ks = before.kings[us];
        let from_bit = 1u128 << m.from;
        if ks & from_bit != 0 {
            ks &= !from_bit;
            let lands = if m.flags & (F_SHIELD | F_CRACK) != 0 { m.from } else { m.to };
            ks |= 1u128 << lands;
        }
        for k in bits(ks) {
            if self.attacked(r, k, 1 - us) {
                return true;
            }
        }
        false
    }

    pub fn has_legal_move(&self, r: &Rules) -> bool {
        let mut pseudo = Vec::with_capacity(64);
        self.gen_pseudo(r, &mut pseudo, GEN_ALL);
        pseudo.into_iter().any(|m| self.is_legal(r, m))
    }

    /// Kinds of lost pieces Raise Dead could bring back for `team`.
    pub fn raisable(&self, r: &Rules, team: usize) -> bool {
        (0..r.info.len()).any(|k| self.lost[team][k] > 0 && !r.info[k].is_pawn && r.info[k].ability != Ability::RaiseDead)
    }

    /// `GameState._checkmate_impossible`.
    pub fn checkmate_impossible(&self, r: &Rules) -> bool {
        for team in 0..2 {
            if self.raisable(r, team) {
                for s in bits(self.occ[team]) {
                    let c = self.sq[s];
                    if c & USED == 0 && r.info[kind_of(c)].ability == Ability::RaiseDead {
                        return false;
                    }
                }
            }
        }
        let mut others: Vec<usize> = Vec::new();
        let mut colors = [false; 2];
        let mut non_capturers = 0;
        for s in bits(self.occupied()) {
            let k = kind_of(self.sq[s]);
            let info = &r.info[k];
            if info.is_king {
                continue;
            }
            if info.is_pawn {
                return false;
            }
            if !info.can_capture {
                non_capturers += 1;
                continue;
            }
            others.push(k);
            colors[((r.file(s) + r.rank(s)) % 2) as usize] = true;
        }
        if others.is_empty() {
            return true;
        }
        if non_capturers > 0 {
            return false;
        }
        if others.len() == 1 && r.def(others[0]).is_distant_leaper() {
            return true;
        }
        for &k in &others {
            if !r.def(k).stays_on_one_color() {
                return false;
            }
        }
        colors[0] != colors[1]
    }

    /// How the game stands (`GameState.outcome`). `keys`: the repetition key of
    /// every position so far, oldest first, ending with this one.
    pub fn outcome(&self, r: &Rules, keys: &[u64]) -> Outcome {
        if !self.has_legal_move(r) {
            return if self.in_check(r, self.side) { Outcome::Checkmate } else { Outcome::Stalemate };
        }
        if self.checkmate_impossible(r) {
            return Outcome::Insufficient;
        }
        if self.halfmove >= 100 {
            return Outcome::FiftyMoves;
        }
        if repetitions(keys, self.halfmove as usize) >= 3 {
            return Outcome::Repetition;
        }
        Outcome::None
    }

    pub fn count(&self, team: usize, kind: usize) -> u32 {
        bits(self.occ[team]).filter(|&s| kind_of(self.sq[s]) == kind).count() as u32
    }

    pub fn squares(&self, team: usize) -> impl Iterator<Item = usize> {
        bits(self.occ[team])
    }
}

/// How many times the last key occurs among the last `window` + 1 keys.
pub fn repetitions(keys: &[u64], window: usize) -> usize {
    let n = keys.len();
    if n == 0 {
        return 0;
    }
    let cur = keys[n - 1];
    let mut count = 1;
    for i in 1..=window.min(n - 1) {
        if keys[n - 1 - i] == cur {
            count += 1;
        }
    }
    count
}

pub fn perft(pos: &Position, r: &Rules, depth: u32) -> u64 {
    let mut moves = Vec::with_capacity(64);
    pos.gen_pseudo(r, &mut moves, GEN_ALL);
    let mut total = 0;
    for m in moves {
        let mut child = pos.clone();
        child.make(r, m);
        if child.leaves_king_attacked(pos, r, m) {
            continue;
        }
        total += if depth <= 1 { 1 } else { perft(&child, r, depth - 1) };
    }
    total
}
