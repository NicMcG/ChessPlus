//! A minimal JSON reader/writer (enough for trace files and reports).

#[derive(Clone, Debug, PartialEq)]
pub enum Json {
    Null,
    Bool(bool),
    Num(f64),
    Str(String),
    Arr(Vec<Json>),
    Obj(Vec<(String, Json)>),
}

impl Json {
    pub fn get(&self, key: &str) -> Option<&Json> {
        match self {
            Json::Obj(v) => v.iter().find(|(k, _)| k == key).map(|(_, v)| v),
            _ => None,
        }
    }
    pub fn as_str(&self) -> Option<&str> {
        match self {
            Json::Str(s) => Some(s),
            _ => None,
        }
    }
    pub fn as_f64(&self) -> Option<f64> {
        match self {
            Json::Num(n) => Some(*n),
            _ => None,
        }
    }
    pub fn as_bool(&self) -> Option<bool> {
        match self {
            Json::Bool(b) => Some(*b),
            _ => None,
        }
    }
    pub fn as_arr(&self) -> Option<&Vec<Json>> {
        match self {
            Json::Arr(a) => Some(a),
            _ => None,
        }
    }

    pub fn parse(text: &str) -> Result<Json, String> {
        let b: Vec<char> = text.chars().collect();
        let mut i = 0;
        let v = value(&b, &mut i)?;
        Ok(v)
    }

    pub fn write(&self) -> String {
        match self {
            Json::Null => "null".into(),
            Json::Bool(b) => b.to_string(),
            Json::Num(n) => {
                if n.fract() == 0.0 && n.abs() < 1e15 {
                    format!("{}", *n as i64)
                } else {
                    format!("{}", n)
                }
            }
            Json::Str(s) => quote(s),
            Json::Arr(a) => format!("[{}]", a.iter().map(|v| v.write()).collect::<Vec<_>>().join(",")),
            Json::Obj(o) => format!("{{{}}}", o.iter().map(|(k, v)| format!("{}:{}", quote(k), v.write())).collect::<Vec<_>>().join(",")),
        }
    }
}

pub fn quote(s: &str) -> String {
    let mut out = String::from("\"");
    for c in s.chars() {
        match c {
            '"' => out += "\\\"",
            '\\' => out += "\\\\",
            '\n' => out += "\\n",
            '\r' => out += "\\r",
            '\t' => out += "\\t",
            c if (c as u32) < 0x20 => out += &format!("\\u{:04x}", c as u32),
            c => out.push(c),
        }
    }
    out.push('"');
    out
}

fn ws(b: &[char], i: &mut usize) {
    while *i < b.len() && b[*i].is_whitespace() {
        *i += 1;
    }
}

fn value(b: &[char], i: &mut usize) -> Result<Json, String> {
    ws(b, i);
    if *i >= b.len() {
        return Err("unexpected end of JSON".into());
    }
    match b[*i] {
        '{' => {
            *i += 1;
            let mut o = Vec::new();
            loop {
                ws(b, i);
                if *i < b.len() && b[*i] == '}' {
                    *i += 1;
                    break;
                }
                let k = match value(b, i)? {
                    Json::Str(s) => s,
                    _ => return Err("object key must be a string".into()),
                };
                ws(b, i);
                if *i >= b.len() || b[*i] != ':' {
                    return Err("expected ':'".into());
                }
                *i += 1;
                let v = value(b, i)?;
                o.push((k, v));
                ws(b, i);
                if *i < b.len() && b[*i] == ',' {
                    *i += 1;
                }
            }
            Ok(Json::Obj(o))
        }
        '[' => {
            *i += 1;
            let mut a = Vec::new();
            loop {
                ws(b, i);
                if *i < b.len() && b[*i] == ']' {
                    *i += 1;
                    break;
                }
                a.push(value(b, i)?);
                ws(b, i);
                if *i < b.len() && b[*i] == ',' {
                    *i += 1;
                }
            }
            Ok(Json::Arr(a))
        }
        '"' => {
            *i += 1;
            let mut s = String::new();
            while *i < b.len() && b[*i] != '"' {
                if b[*i] == '\\' && *i + 1 < b.len() {
                    *i += 1;
                    match b[*i] {
                        'n' => s.push('\n'),
                        't' => s.push('\t'),
                        'r' => s.push('\r'),
                        'u' => {
                            let hex: String = b[*i + 1..(*i + 5).min(b.len())].iter().collect();
                            if let Some(c) = u32::from_str_radix(&hex, 16).ok().and_then(char::from_u32) {
                                s.push(c);
                            }
                            *i += 4;
                        }
                        c => s.push(c),
                    }
                } else {
                    s.push(b[*i]);
                }
                *i += 1;
            }
            *i += 1;
            Ok(Json::Str(s))
        }
        't' => {
            *i += 4;
            Ok(Json::Bool(true))
        }
        'f' => {
            *i += 5;
            Ok(Json::Bool(false))
        }
        'n' => {
            *i += 4;
            Ok(Json::Null)
        }
        _ => {
            let st = *i;
            while *i < b.len() && (b[*i].is_ascii_digit() || "+-.eE".contains(b[*i])) {
                *i += 1;
            }
            let t: String = b[st..*i].iter().collect();
            t.parse().map(Json::Num).map_err(|_| format!("bad JSON number '{}'", t))
        }
    }
}
