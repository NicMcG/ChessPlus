// Plusfish in the web version of Chess Plus: loads plusfish.wasm (the engine
// compiled to WebAssembly, from engine/plusfish) and offers
//   window.plusfish.ready      true once it's loaded
//   window.plusfish.run(json)  evaluate positions; returns reply lines (JSON)
// The game calls it through JavaScriptBridge (scenes/game/plusfish_link.gd).
// Loaded by the page: export_presets.cfg's head include; copied next to
// index.html by tools/deploy_web.sh.
(function () {
	var pf = { ready: false, error: "" };
	window.plusfish = pf;
	fetch("plusfish.wasm")
		.then(function (r) {
			if (!r.ok) throw new Error("plusfish.wasm: " + r.status);
			return r.arrayBuffer();
		})
		.then(function (bytes) { return WebAssembly.instantiate(bytes, {}); })
		.then(function (result) {
			pf.exports = result.instance.exports;
			pf.ready = true;
		})
		.catch(function (e) { pf.error = String(e); });

	pf.run = function (input) {
		var ex = pf.exports;
		if (!ex) return '{"error":"Plusfish is not loaded"}';
		try {
			var bytes = new TextEncoder().encode(input);
			var ptr = ex.pf_alloc(bytes.length);
			new Uint8Array(ex.memory.buffer, ptr, bytes.length).set(bytes);
			var out = ex.pf_run(ptr, bytes.length);
			var len = ex.pf_out_len();
			// Read the reply before freeing (the memory may move as it grows).
			var text = new TextDecoder().decode(new Uint8Array(ex.memory.buffer, out, len));
			ex.pf_free(ptr, bytes.length);
			return text;
		} catch (e) {
			return JSON.stringify({ error: String(e) });
		}
	};
})();
