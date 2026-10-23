// Runs Plusfish (web/plusfish.wasm, the same engine as the game's eval bar)
// the way web/plusfish.js does: copy the request in, call pf_run, read the
// reply lines back.

import type { PlusfishRunner } from "./referee.ts";

interface PlusfishExports {
  memory: WebAssembly.Memory;
  pf_alloc(len: number): number;
  pf_free(ptr: number, len: number): void;
  pf_run(ptr: number, len: number): number;
  pf_out_len(): number;
}

export async function loadPlusfish(wasm: Uint8Array<ArrayBuffer>): Promise<PlusfishRunner> {
  const instance = await WebAssembly.instantiate(await WebAssembly.compile(wasm), {});
  const ex = instance.exports as unknown as PlusfishExports;
  return (request) => {
    const bytes = new TextEncoder().encode(JSON.stringify(request));
    const ptr = ex.pf_alloc(bytes.length);
    new Uint8Array(ex.memory.buffer, ptr, bytes.length).set(bytes);
    const out = ex.pf_run(ptr, bytes.length);
    const len = ex.pf_out_len();
    // Read the reply before freeing (the memory may move as it grows).
    const text = new TextDecoder().decode(new Uint8Array(ex.memory.buffer, out, len));
    ex.pf_free(ptr, bytes.length);
    return text.split("\n").filter((line) => line.trim() !== "");
  };
}
