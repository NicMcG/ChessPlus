//! The WebAssembly build's entry points (used by the game's web version through
//! `web/plusfish.js`): JavaScript copies a request into memory from pf_alloc,
//! calls pf_run, and reads pf_out_len() bytes of reply lines from the pointer it
//! returns.

use crate::api;
use crate::json::quote;
use std::alloc::{alloc, dealloc, Layout};
use std::sync::Mutex;

static OUT: Mutex<Vec<u8>> = Mutex::new(Vec::new());

#[no_mangle]
pub extern "C" fn pf_alloc(len: usize) -> *mut u8 {
    unsafe { alloc(Layout::from_size_align(len.max(1), 1).unwrap()) }
}

#[no_mangle]
pub extern "C" fn pf_free(ptr: *mut u8, len: usize) {
    unsafe { dealloc(ptr, Layout::from_size_align(len.max(1), 1).unwrap()) }
}

#[no_mangle]
pub extern "C" fn pf_run(ptr: *const u8, len: usize) -> *const u8 {
    let input = unsafe { std::slice::from_raw_parts(ptr, len) };
    let text = String::from_utf8_lossy(input);
    let mut out = String::new();
    if let Err(e) = api::eval_request(&text, &mut |line| {
        out.push_str(&line);
        out.push('\n');
    }) {
        out = format!("{{\"error\":{}}}\n", quote(&e));
    }
    let mut buf = OUT.lock().unwrap();
    *buf = out.into_bytes();
    buf.as_ptr()
}

#[no_mangle]
pub extern "C" fn pf_out_len() -> usize {
    OUT.lock().unwrap().len()
}
