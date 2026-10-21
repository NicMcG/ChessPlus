//! Game files and the balance report.
//!
//! A game file has one JSON object per line: both armies (text form), the
//! moves (move text), the result (1 = White won, 0.5, 0) and why it ended.
//! Features are worked out again from the moves when needed, so the same games
//! can be re-analysed after the evaluation changes.

use crate::army::*;
use crate::defs::*;
use crate::eval::*;
use crate::game::*;
use crate::json::{quote, Json};

use crate::selfplay::{GameRecord, Sample};
use crate::tune::logistic;
use std::sync::Arc;

pub fn game_line(cat: &Catalog, g: &GameRecord, rules_moves: &[String]) -> String {
    format!(
        "{{\"white\":{},\"black\":{},\"black_mirror\":{},\"result\":{},\"reason\":{},\"plies\":{},\"moves\":{}}}",
        quote(&g.white.to_text(cat, 8)),
        quote(&g.black.to_text(cat, 8)),
        g.black.mirror,
        g.result,
        quote(&g.reason),
        g.plies,
        quote(&rules_moves.join(" "))
    )
}

pub struct StoredGame {
    pub white: Army,
    pub black: Army,
    pub result: f64,
    pub reason: String,
    pub moves: Vec<String>,
}

pub fn read_games(cat: &Catalog, text: &str) -> Vec<StoredGame> {
    let mut out = Vec::new();
    for line in text.lines() {
        let line = line.trim();
        if line.is_empty() {
            continue;
        }
        let j = match Json::parse(line) {
            Ok(j) => j,
            Err(_) => continue,
        };
        let get = |k: &str| j.get(k).and_then(|v| v.as_str()).unwrap_or("").to_string();
        let (w, mut b) = match (Army::from_text(cat, &get("white")), Army::from_text(cat, &get("black"))) {
            (Ok(w), Ok(b)) => (w, b),
            _ => continue,
        };
        // Files written before Black armies were mirrored (Oct 2026) have no flag.
        b.mirror = j.get("black_mirror").and_then(|v| v.as_bool()).unwrap_or(false);
        out.push(StoredGame {
            white: w,
            black: b,
            result: j.get("result").and_then(|v| v.as_f64()).unwrap_or(0.5),
            reason: get("reason"),
            moves: get("moves").split_whitespace().map(|s| s.to_string()).collect(),
        });
    }
    out
}

/// Quiet positions from the games, with features, for tuning and the in-game
/// regression. Skips the randomised opening (`skip` plies).
pub fn samples_from_games(cat: &Arc<Catalog>, games: &[StoredGame], skip: usize, every: usize, threads: usize) -> Vec<Sample> {
    let chunk = (games.len() + threads - 1) / threads.max(1);
    let mut all = Vec::new();
    std::thread::scope(|scope| {
        let handles: Vec<_> = games
            .chunks(chunk.max(1))
            .map(|part| {
                scope.spawn(move || {
                    let mut out = Vec::new();
                    for sg in part {
                        let mut g = army_game(cat, &sg.white, &sg.black, 8, 8);
                        let r = g.rules.clone();
                        let et = EvalTables::new(&r);
                        for (ply, mt) in sg.moves.iter().enumerate() {
                            let m = match find_move(&g.pos, &r, mt) {
                                Some(m) => m,
                                None => break,
                            };
                            if ply >= skip && ply % every == 0 && !m.is_tactical() && !g.pos.in_check(&r, g.pos.side) {
                                let mut acc = Sparse(Default::default());
                                features(&g.pos, &r, &et, &mut acc);
                                let mut f: Vec<(u16, f32)> = acc.0.into_iter().filter(|(_, v)| *v != 0.0).map(|(k, v)| (k as u16, v)).collect();
                                f.sort_by_key(|x| x.0);
                                out.push(Sample { feats: f, phase: phase(&g.pos, &et), result: sg.result as f32 });
                            }
                            g.play(m);
                        }
                    }
                    out
                })
            })
            .collect();
        for h in handles {
            all.extend(h.join().unwrap());
        }
    });
    all
}

pub struct ValueRow {
    pub kind: usize,
    pub cost: f64,
    pub games_with: usize,
    pub army_value: f64,
    pub army_se: f64,
    pub elo_per_piece: f64,
    pub ingame_value: Option<(f64, f64)>,
    pub verdict: String,
}

pub struct ValueReport {
    pub rows: Vec<ValueRow>,
    pub games: usize,
    pub white_score: f64,
    pub white_elo: f64,
    pub extras: Vec<(String, f64, f64)>,
    pub draw_rate: f64,
    pub reasons: Vec<(String, usize)>,
    pub avg_plies: f64,
}

const LOGIT_TO_ELO: f64 = 400.0 / std::f64::consts::LN_10;

/// Fits both regressions and turns them into points on the army-cost scale.
pub fn value_report(cat: &Arc<Catalog>, games: &[StoredGame], samples: &[Sample]) -> ValueReport {
    let nk = cat.len();
    // Kinds that appear at all, kings excluded (every army has exactly one).
    let mut used: Vec<usize> = Vec::new();
    let mut games_with = vec![0usize; nk];
    for g in games {
        let mut seen = vec![false; nk];
        for p in g.white.pieces.iter().chain(g.black.pieces.iter()) {
            seen[p.0] = true;
        }
        for k in 0..nk {
            if seen[k] {
                games_with[k] += 1;
            }
        }
    }
    for k in 0..nk {
        if games_with[k] > 0 && !cat.defs[k].is_king() {
            used.push(k);
        }
    }
    // 1. Army regression: result ~ extra pieces of each type at the start.
    let x: Vec<Vec<f64>> = games
        .iter()
        .map(|g| {
            let mut row: Vec<f64> = used.iter().map(|&k| g.white.count(k) as f64 - g.black.count(k) as f64).collect();
            row.push(1.0);
            row
        })
        .collect();
    let y: Vec<f64> = games.iter().map(|g| g.result).collect();
    let (beta, se) = logistic(&x, &y, 0.5);
    // Scale: logit per point, from a weighted fit of beta against cost.
    let mut num = 0.0;
    let mut den = 0.0;
    for (i, &k) in used.iter().enumerate() {
        let c = cat.defs[k].value;
        let wgt = 1.0 / (se[i] * se[i]).max(1e-6);
        num += wgt * beta[i] * c;
        den += wgt * c * c;
    }
    let per_point = if den > 0.0 { num / den } else { 1.0 };
    let white_logit = beta[used.len()];

    // 2. In-game regression: result ~ material on the board (+ shields,
    // unused abilities) in quiet positions.
    let mut ingame: Vec<Option<(f64, f64)>> = vec![None; nk];
    let mut extras = Vec::new();
    if !samples.is_empty() {
        let mut cols: Vec<usize> = Vec::new();
        for &k in &used {
            cols.push(k * PER_KIND + FE_MAT);
        }
        for &k in &used {
            let d = &cat.defs[k];
            if d.has_shield() {
                cols.push(k * PER_KIND + FE_SHIELD);
            }
            // A Necromancer leaves the board when it uses Raise Dead, and a
            // Werewolf becomes its wolf form (another kind) with Full Moon, so
            // "on the board" already means "ability unused": no separate column.
            if d.ability != Ability::None && d.ability != Ability::RaiseDead && d.transforms_into.is_none() {
                cols.push(k * PER_KIND + FE_ABIL);
            }
        }
        // Forms (the wolf) never start a game but are on the board after a
        // transformation: their own material column, shown with the extras.
        for &k in &used {
            if let Some(form) = cat.defs[k].transforms_into.as_deref().and_then(|f| cat.kind_by_id(f)) {
                cols.push(form * PER_KIND + FE_MAT);
            }
        }
        cols.push(G_RAISE);
        cols.push(G_TEMPO);
        let index: std::collections::HashMap<usize, usize> = cols.iter().enumerate().map(|(i, &c)| (c, i)).collect();
        // Subsample to keep Newton's method quick.
        let step = (samples.len() / 200_000).max(1);
        let xs: Vec<Vec<f64>> = samples
            .iter()
            .step_by(step)
            .map(|s| {
                let mut row = vec![0.0; cols.len()];
                for &(f, v) in &s.feats {
                    if let Some(&i) = index.get(&(f as usize)) {
                        row[i] = v as f64;
                    }
                }
                row
            })
            .collect();
        let ys: Vec<f64> = samples.iter().step_by(step).map(|s| s.result as f64).collect();
        let (b2, se2) = logistic(&xs, &ys, 0.5);
        // Scale by the same weighted fit against cost, material columns only.
        let mut num = 0.0;
        let mut den = 0.0;
        for (i, &k) in used.iter().enumerate() {
            let c = cat.defs[k].value;
            let wgt = 1.0 / (se2[i] * se2[i]).max(1e-6);
            num += wgt * b2[i] * c;
            den += wgt * c * c;
        }
        let pp = if den > 0.0 { num / den } else { 1.0 };
        // A fresh piece: on the board, shield intact, ability unused.
        for (i, &k) in used.iter().enumerate() {
            let mut v = b2[i];
            let mut var = se2[i] * se2[i];
            for extra in [k * PER_KIND + FE_SHIELD, k * PER_KIND + FE_ABIL] {
                if let Some(&j) = index.get(&extra) {
                    v += b2[j];
                    var += se2[j] * se2[j];
                }
            }
            ingame[k] = Some((v / pp, var.sqrt() / pp));
        }
        for (i, &c) in cols.iter().enumerate().skip(used.len()) {
            extras.push((feature_name(cat, c), b2[i] / pp, se2[i] / pp));
        }
    }

    let mut rows = Vec::new();
    for (i, &k) in used.iter().enumerate() {
        let cost = cat.defs[k].value;
        let v = beta[i] / per_point;
        let s = se[i] / per_point.abs();
        let diff = v - cost;
        let verdict = if games_with[k] < 200 {
            "too few games".to_string()
        } else if diff.abs() > 1.96 * s && diff.abs() >= 0.5 {
            if diff > 0.0 {
                format!("UNDERPRICED by ~{:.1}", diff)
            } else {
                format!("OVERPRICED by ~{:.1}", -diff)
            }
        } else if diff.abs() > 1.96 * s {
            format!("slightly {} ({:+.1})", if diff > 0.0 { "underpriced" } else { "overpriced" }, diff)
        } else {
            "about right".to_string()
        };
        rows.push(ValueRow {
            kind: k,
            cost,
            games_with: games_with[k],
            army_value: v,
            army_se: s,
            elo_per_piece: beta[i] * LOGIT_TO_ELO,
            ingame_value: ingame[k],
            verdict,
        });
    }
    rows.sort_by(|a, b| b.cost.partial_cmp(&a.cost).unwrap().then(a.kind.cmp(&b.kind)));
    let white_score = games.iter().map(|g| g.result).sum::<f64>() / games.len().max(1) as f64;
    let draw_rate = games.iter().filter(|g| g.result == 0.5).count() as f64 / games.len().max(1) as f64;
    let mut reasons: std::collections::BTreeMap<String, usize> = Default::default();
    for g in games {
        *reasons.entry(g.reason.clone()).or_insert(0) += 1;
    }
    let mut reasons: Vec<(String, usize)> = reasons.into_iter().collect();
    reasons.sort_by(|a, b| b.1.cmp(&a.1));
    let avg_plies = games.iter().map(|g| g.moves.len()).sum::<usize>() as f64 / games.len().max(1) as f64;
    ValueReport { rows, games: games.len(), white_score, white_elo: white_logit * LOGIT_TO_ELO, extras, draw_rate, reasons, avg_plies }
}

pub fn print_report(cat: &Catalog, rep: &ValueReport) -> String {
    let mut s = String::new();
    s += &format!("Balance report from {} self-play games\n", rep.games);
    s += &format!(
        "White scores {:.1}% overall (first-move edge with equal armies: {:+.0} Elo); {:.0}% draws; {:.0} plies per game on average\n",
        rep.white_score * 100.0,
        rep.white_elo,
        rep.draw_rate * 100.0,
        rep.avg_plies
    );
    s += &format!(
        "Endings: {}\n\n",
        rep.reasons.iter().map(|(r, n)| format!("{} {}", r, n)).collect::<Vec<_>>().join(", ")
    );
    s += "Values are on the army-cost scale (the fit is scaled so that, on average, value = cost).\n";
    s += "  worth (army): what one extra piece of the type at the start is worth, from game results\n";
    s += "  worth (board): what a fresh one (shield intact, ability unused) is worth while on the\n";
    s += "                 board mid-game; more precise, but blind to promotion and one-shot pieces\n\n";
    s += &format!("{:<12} {:>5} {:>7} {:>14} {:>10} {:>14}  {}\n", "piece", "cost", "games", "worth (army)", "Elo/piece", "worth (board)", "verdict");
    for row in &rep.rows {
        let d = &cat.defs[row.kind];
        let ig = row.ingame_value.map(|(v, e)| format!("{:.2} ±{:.2}", v, 1.96 * e)).unwrap_or("-".into());
        s += &format!(
            "{:<12} {:>5} {:>7} {:>14} {:>+10.0} {:>14}  {}\n",
            d.name,
            d.value,
            row.games_with,
            format!("{:.2} ±{:.2}", row.army_value, 1.96 * row.army_se),
            row.elo_per_piece,
            ig,
            row.verdict
        );
    }
    if !rep.extras.is_empty() {
        s += "\nOther terms (board regression, in points):\n";
        for (n, v, e) in &rep.extras {
            s += &format!("  {:<22} {:+.2} ±{:.2}\n", n, v, 1.96 * e);
        }
    }
    s
}

