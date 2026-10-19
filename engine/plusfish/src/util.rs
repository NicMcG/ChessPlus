//! Small helpers: a random number generator and command-line options.

use std::collections::HashMap;

/// Milliseconds since the program started (0 on WebAssembly, which has no
/// clock here: searches there are limited by nodes instead).
#[cfg(not(target_arch = "wasm32"))]
pub fn now_ms() -> u64 {
    static START: std::sync::OnceLock<std::time::Instant> = std::sync::OnceLock::new();
    START.get_or_init(std::time::Instant::now).elapsed().as_millis() as u64
}

#[cfg(target_arch = "wasm32")]
pub fn now_ms() -> u64 {
    0
}

#[derive(Clone)]
pub struct Rng(u64);

impl Rng {
    pub fn new(seed: u64) -> Rng {
        Rng(seed ^ 0x2545F4914F6CDD1D)
    }
    pub fn from_time() -> Rng {
        let t = std::time::SystemTime::now().duration_since(std::time::UNIX_EPOCH).unwrap().as_nanos() as u64;
        Rng::new(t)
    }
    pub fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    /// 0..n
    pub fn below(&mut self, n: usize) -> usize {
        if n == 0 {
            0
        } else {
            (self.next() % n as u64) as usize
        }
    }
    /// lo..hi (hi excluded)
    pub fn range(&mut self, lo: i64, hi: i64) -> i64 {
        lo + self.below((hi - lo).max(1) as usize) as i64
    }
    pub fn float(&mut self) -> f64 {
        (self.next() >> 11) as f64 / (1u64 << 53) as f64
    }
    pub fn shuffle<T>(&mut self, v: &mut [T]) {
        for i in (1..v.len()).rev() {
            let j = self.below(i + 1);
            v.swap(i, j);
        }
    }
}

/// `--name value` / `--flag` options plus the plain words in between.
pub struct Args {
    pub words: Vec<String>,
    pub opts: HashMap<String, String>,
}

impl Args {
    pub fn parse(raw: &[String]) -> Args {
        let mut words = Vec::new();
        let mut opts = HashMap::new();
        let mut i = 0;
        while i < raw.len() {
            let a = &raw[i];
            if let Some(name) = a.strip_prefix("--") {
                if let Some((k, v)) = name.split_once('=') {
                    opts.insert(k.to_string(), v.to_string());
                } else if i + 1 < raw.len() && !raw[i + 1].starts_with("--") {
                    opts.insert(name.to_string(), raw[i + 1].clone());
                    i += 1;
                } else {
                    opts.insert(name.to_string(), "true".to_string());
                }
            } else {
                words.push(a.clone());
            }
            i += 1;
        }
        Args { words, opts }
    }
    pub fn get(&self, k: &str) -> Option<&str> {
        self.opts.get(k).map(|s| s.as_str())
    }
    pub fn num<T: std::str::FromStr>(&self, k: &str, default: T) -> T {
        self.get(k).and_then(|v| v.parse().ok()).unwrap_or(default)
    }
    pub fn flag(&self, k: &str) -> bool {
        self.get(k).map(|v| v != "false").unwrap_or(false)
    }
}
