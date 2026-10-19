//! The balance report as a self-contained web page: a dot plot of each piece's
//! measured worth against its cost, then the full table.

use crate::defs::Catalog;
use crate::report::{ValueReport, ValueRow};

fn esc(t: &str) -> String {
    t.replace('&', "&amp;").replace('<', "&lt;").replace('>', "&gt;").replace('"', "&quot;")
}

const STYLE: &str = r#"
.viz-root { color-scheme: light; --surface-1:#fcfcfb; --surface-2:#f0efec; --text-primary:#0b0b0b; --text-secondary:#52514e; --text-muted:#8a8984; --grid:#e4e3df; --under:#2a78d6; --over:#e34948; --fair:#8a8984; }
@media (prefers-color-scheme: dark) { :root:where(:not([data-theme="light"])) .viz-root { color-scheme: dark; --surface-1:#1a1a19; --surface-2:#262624; --text-primary:#f0efec; --text-secondary:#c3c2b7; --text-muted:#8f8e86; --grid:#33332f; --under:#3987e5; --over:#e66767; --fair:#8f8e86; } }
:root[data-theme="dark"] .viz-root { color-scheme: dark; --surface-1:#1a1a19; --surface-2:#262624; --text-primary:#f0efec; --text-secondary:#c3c2b7; --text-muted:#8f8e86; --grid:#33332f; --under:#3987e5; --over:#e66767; --fair:#8f8e86; }
body { margin:0; }
.viz-root { background:var(--surface-1); color:var(--text-primary); font:14px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif; padding:24px; min-height:100vh; box-sizing:border-box; }
.wrap { max-width:800px; margin:0 auto; }
h1 { font-size:22px; margin:0 0 4px; } h2 { font-size:16px; margin:28px 0 8px; }
.sub { color:var(--text-secondary); margin:0 0 14px; }
.legend { display:flex; gap:18px; flex-wrap:wrap; color:var(--text-secondary); font-size:13px; margin:8px 0 4px; }
.legend span { display:inline-flex; align-items:center; gap:6px; }
svg { display:block; }
.chart { width:100%; height:auto; }
.grid { stroke:var(--grid); stroke-width:1; }
.tick { fill:var(--text-muted); font-size:12px; }
.name { fill:var(--text-primary); font-size:13px; }
.hit { fill:transparent; } .row:hover .hit { fill:var(--surface-2); }
.link { stroke:var(--text-muted); stroke-width:2; stroke-dasharray:2 3; }
.ci { stroke-width:2; stroke-linecap:round; }
.cost { fill:var(--surface-1); stroke:var(--text-secondary); stroke-width:2; }
.worth { stroke:var(--surface-1); stroke-width:2; }
.under .worth { fill:var(--under); } .under .ci { stroke:var(--under); }
.over .worth { fill:var(--over); } .over .ci { stroke:var(--over); }
.fair .worth { fill:var(--fair); } .fair .ci { stroke:var(--fair); }
table { border-collapse:collapse; width:100%; font-size:13px; }
th,td { text-align:left; padding:6px 8px; border-bottom:1px solid var(--grid); }
th { color:var(--text-secondary); font-weight:600; } td.num { font-variant-numeric:tabular-nums; }
#tip { position:fixed; pointer-events:none; background:var(--surface-2); color:var(--text-primary); border:1px solid var(--grid); border-radius:6px; padding:6px 9px; font-size:12px; max-width:340px; display:none; box-shadow:0 2px 8px rgba(0,0,0,.15); }
.note { color:var(--text-secondary); font-size:13px; }
"#;

const SCRIPT: &str = r#"
const tip = document.getElementById('tip');
document.querySelectorAll('g.row').forEach(g => {
  g.addEventListener('mousemove', e => {
    tip.textContent = g.dataset.tip; tip.style.display = 'block';
    tip.style.left = Math.min(e.clientX + 14, innerWidth - 360) + 'px';
    tip.style.top = (e.clientY + 14) + 'px';
  });
  g.addEventListener('mouseleave', () => tip.style.display = 'none');
});
"#;

pub fn html_report(cat: &Catalog, rep: &ValueReport) -> String {
    let rows: Vec<&ValueRow> = rep.rows.iter().collect();
    let max_x = rows.iter().map(|r| (r.army_value + 1.96 * r.army_se).max(r.cost)).fold(1.0f64, f64::max).ceil() + 0.5;
    let min_x = rows.iter().map(|r| r.army_value - 1.96 * r.army_se).fold(0.0f64, f64::min).floor();
    let (left, right, top, row_h) = (120.0, 24.0, 20.0, 30.0);
    let width = 760.0;
    let plot_w = width - left - right;
    let height = top + row_h * rows.len() as f64 + 40.0;
    let x = |v: f64| left + (v - min_x) / (max_x - min_x) * plot_w;
    let mut svg = String::new();
    let mut tick = min_x;
    while tick <= max_x + 1e-9 {
        let tx = x(tick);
        svg += &format!(
            "<line class=\"grid\" x1=\"{tx:.1}\" x2=\"{tx:.1}\" y1=\"{:.1}\" y2=\"{:.1}\"/><text class=\"tick\" x=\"{tx:.1}\" y=\"{:.1}\" text-anchor=\"middle\">{}</text>",
            top - 6.0,
            height - 34.0,
            height - 18.0,
            tick
        );
        tick += 1.0;
    }
    svg += &format!("<text class=\"tick\" x=\"{:.0}\" y=\"{:.0}\" text-anchor=\"middle\">points</text>", left + plot_w / 2.0, height - 2.0);
    for (i, r) in rows.iter().enumerate() {
        let d = &cat.defs[r.kind];
        let cy = top + row_h * i as f64 + row_h / 2.0;
        let class = if r.verdict.starts_with("UNDER") {
            "under"
        } else if r.verdict.starts_with("OVER") {
            "over"
        } else {
            "fair"
        };
        let lo_v = r.army_value - 1.96 * r.army_se;
        let hi_v = r.army_value + 1.96 * r.army_se;
        let tip = format!(
            "{}: costs {} · measured worth {:.2} (95% range {:.2} to {:.2}) · {:+.0} Elo per extra piece · in {} games · {}",
            d.name, r.cost, r.army_value, lo_v, hi_v, r.elo_per_piece, r.games_with, r.verdict
        );
        svg += &format!(
            concat!(
                "<g class=\"row {}\" data-tip=\"{}\"><rect class=\"hit\" x=\"0\" y=\"{:.1}\" width=\"{}\" height=\"{}\"/>",
                "<text class=\"name\" x=\"{:.1}\" y=\"{:.1}\" text-anchor=\"end\">{}</text>",
                "<line class=\"link\" x1=\"{:.1}\" x2=\"{:.1}\" y1=\"{:.1}\" y2=\"{:.1}\"/>",
                "<line class=\"ci\" x1=\"{:.1}\" x2=\"{:.1}\" y1=\"{:.1}\" y2=\"{:.1}\"/>",
                "<circle class=\"cost\" cx=\"{:.1}\" cy=\"{:.1}\" r=\"5\"/>",
                "<circle class=\"worth\" cx=\"{:.1}\" cy=\"{:.1}\" r=\"6\"/></g>"
            ),
            class,
            esc(&tip),
            cy - row_h / 2.0,
            width,
            row_h,
            left - 12.0,
            cy + 4.0,
            esc(&d.name),
            x(r.cost),
            x(r.army_value),
            cy,
            cy,
            x(lo_v),
            x(hi_v),
            cy,
            cy,
            x(r.cost),
            cy,
            x(r.army_value),
            cy
        );
    }
    let mut table = String::from(
        "<table><thead><tr><th>Piece</th><th>Cost</th><th>Games</th><th>Worth (army)</th><th>Elo per piece</th><th>Worth (on board)</th><th>Verdict</th></tr></thead><tbody>",
    );
    for r in &rows {
        let d = &cat.defs[r.kind];
        let ig = r.ingame_value.map(|(v, e)| format!("{:.2} ± {:.2}", v, 1.96 * e)).unwrap_or("–".into());
        table += &format!(
            "<tr><td>{}</td><td class=\"num\">{}</td><td class=\"num\">{}</td><td class=\"num\">{:.2} ± {:.2}</td><td class=\"num\">{:+.0}</td><td class=\"num\">{}</td><td>{}</td></tr>",
            esc(&d.name),
            r.cost,
            r.games_with,
            r.army_value,
            1.96 * r.army_se,
            r.elo_per_piece,
            ig,
            esc(&r.verdict)
        );
    }
    table += "</tbody></table>";
    let mut extras = String::new();
    if !rep.extras.is_empty() {
        extras += "<h2>Other terms (worth on board, in points)</h2><table><tbody>";
        for (n, v, e) in &rep.extras {
            extras += &format!("<tr><td>{}</td><td class=\"num\">{:+.2} ± {:.2}</td></tr>", esc(n), v, 1.96 * e);
        }
        extras += "</tbody></table>";
    }
    let endings = rep.reasons.iter().map(|(r, n)| format!("{} {}", esc(&r.replace('_', " ")), n)).collect::<Vec<_>>().join(" · ");
    let legend = concat!(
        "<div class=\"legend\">",
        "<span><svg width=\"14\" height=\"14\"><circle cx=\"7\" cy=\"7\" r=\"5\" fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\"/></svg>Current cost</span>",
        "<span><svg width=\"14\" height=\"14\"><circle cx=\"7\" cy=\"7\" r=\"6\" fill=\"var(--under)\"/></svg>Worth more than it costs (underpriced)</span>",
        "<span><svg width=\"14\" height=\"14\"><circle cx=\"7\" cy=\"7\" r=\"6\" fill=\"var(--over)\"/></svg>Worth less (overpriced)</span>",
        "<span><svg width=\"14\" height=\"14\"><circle cx=\"7\" cy=\"7\" r=\"6\" fill=\"var(--fair)\"/></svg>About right</span>",
        "<span>Bar = 95% range</span></div>"
    );
    let mut out = String::new();
    out += "<!doctype html><html><head><meta charset=\"utf-8\"><title>Chess Plus balance report</title><style>";
    out += STYLE;
    out += "</style></head><body><div class=\"viz-root\"><div class=\"wrap\">";
    out += "<h1>What each Chess Plus piece is worth, measured against its cost</h1>";
    out += &format!(
        "<p class=\"sub\">From {} Plusfish self-play games between random armies. White scored {:.1}% ({:+.0} Elo first-move edge); {:.0}% draws; {:.0} plies per game on average.</p>",
        rep.games,
        rep.white_score * 100.0,
        rep.white_elo,
        rep.draw_rate * 100.0,
        rep.avg_plies
    );
    out += legend;
    out += &format!(
        "<svg class=\"chart\" viewBox=\"0 0 {} {:.0}\" role=\"img\" aria-label=\"Dot plot of measured worth versus cost for each piece\">{}</svg>",
        width, height, svg
    );
    out += &format!(
        "<p class=\"note\">Worth is on the army-cost scale: the fit is scaled so that, across all pieces, worth equals cost on average. A piece is flagged when its worth is at least half a point off its cost and the gap is outside the 95% range. Endings: {}.</p>",
        endings
    );
    out += "<h2>Table</h2>";
    out += &table;
    out += &extras;
    out += "<p class=\"note\">Worth (army) comes from a logistic regression of each game's result on the difference in each piece type between the two starting armies (budgets were varied so worth can be measured on its own). Worth (on board) regresses results on the material on the board in quiet mid-game positions, for a fresh piece (shield intact, ability unused). It is more precise, but it only sees a piece while it's on the board: a Lance's promotion or a Ram's one capture don't show up there.</p>";
    out += "</div><div id=\"tip\"></div></div><script>";
    out += SCRIPT;
    out += "</script></body></html>";
    out
}
