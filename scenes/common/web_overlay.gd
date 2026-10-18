class_name WebOverlay
extends RefCounted

## In the web version, puts real web-page elements on top of the game: text
## boxes (so tapping one opens the phone's keyboard straight away, and any
## language or emoji can be typed) and message lists (so the browser draws every
## character, including emoji, which the game's own font doesn't have).
##
## Godot tells this where to put each element in its own pixels; the JavaScript
## below turns that into page coordinates. Events from the page (typing, Enter)
## come back through one callback and are passed to the handler registered for
## that element. Outside a browser, available() is false and nothing is used.

const JS := """
(function () {
	if (window.cpOverlay) return;
	const o = window.cpOverlay = { els: {}, spots: {}, handler: null, next: 1 };
	o.canvas = function () { return document.getElementById('canvas') || document.querySelector('canvas'); };
	// Game pixels -> page coordinates (the canvas may be scaled for the screen).
	// Measured from the top of the page, not the screen, and the elements are
	// attached to the page (position: absolute): when the phone's keyboard opens
	// and Safari slides the page up, they slide with the game.
	o.toPage = function (x, y) {
		const c = o.canvas(); const r = c.getBoundingClientRect(); const s = r.width / c.width;
		return [r.left + window.scrollX + x * s, r.top + window.scrollY + y * s, s];
	};
	o.base = function (el) {
		Object.assign(el.style, { position: 'absolute', zIndex: 10, display: 'none', margin: '0', boxSizing: 'border-box',
			fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif' });
		document.body.appendChild(el);
		const id = 'e' + (o.next++);
		o.els[id] = el;
		return id;
	};
	o.input = function () {
		const el = document.createElement('input');
		el.type = 'text'; el.autocomplete = 'off'; el.spellcheck = false;
		el.setAttribute('autocapitalize', 'off'); el.setAttribute('autocorrect', 'off');
		Object.assign(el.style, { background: 'transparent', border: 'none', outline: 'none', color: '#e6e6e6', padding: '0 10px' });
		const id = o.base(el);
		el.addEventListener('input', function () { if (o.handler) o.handler(id, 'input', el.value); });
		el.addEventListener('keydown', function (e) {
			if (e.key === 'Enter') { e.preventDefault(); if (o.handler) o.handler(id, 'submit', el.value); el.blur(); }
		});
		// Keep the game from also reacting to keys typed into the box.
		['keydown', 'keyup', 'keypress'].forEach(function (t) { el.addEventListener(t, function (e) { e.stopPropagation(); }); });
		return id;
	};
	o.list = function () {
		const el = document.createElement('div');
		Object.assign(el.style, { overflowY: 'auto', color: '#ffffff', webkitOverflowScrolling: 'touch', wordWrap: 'break-word' });
		return o.base(el);
	};
	// Show the element over the game rectangle (x, y, w, h), or hide it.
	o.place = function (id, x, y, w, h, fontPx, show, minFont) {
		const el = o.els[id]; if (!el) return;
		o.spots[id] = [x, y, w, h, fontPx, show, minFont];
		if (!show) { el.style.display = 'none'; return; }
		const p = o.toPage(x, y); const s = p[2];
		Object.assign(el.style, { display: 'block', left: p[0] + 'px', top: p[1] + 'px',
			width: (w * s) + 'px', height: (h * s) + 'px', fontSize: Math.max(minFont, fontPx * s) + 'px' });
	};
	o.setValue = function (id, v) { const el = o.els[id]; if (el && el.value !== v) el.value = v; };
	o.setAttr = function (id, name, v) { const el = o.els[id]; if (el) el[name] = v; };
	// Fill a list with messages: JSON [{text, color}], and scroll to the newest.
	o.setItems = function (id, json) {
		const el = o.els[id]; if (!el) return;
		el.textContent = '';
		JSON.parse(json).forEach(function (m) {
			const line = document.createElement('div');
			line.textContent = m.text;
			line.style.color = m.color;
			line.style.margin = '0 0 0.5em 0';
			el.appendChild(line);
		});
		el.scrollTop = el.scrollHeight;
	};
	o.remove = function (id) { const el = o.els[id]; if (el) { el.remove(); delete o.els[id]; delete o.spots[id]; } };
	// If the page or screen changes (keyboard opening, rotating), put everything
	// back over its spot.
	o.replaceAll = function () {
		Object.keys(o.spots).forEach(function (id) { o.place.apply(null, [id].concat(o.spots[id])); });
	};
	window.addEventListener('resize', o.replaceAll);
	window.addEventListener('scroll', o.replaceAll);
	if (window.visualViewport) {
		window.visualViewport.addEventListener('resize', o.replaceAll);
		window.visualViewport.addEventListener('scroll', o.replaceAll);
	}
})();
"""

## Element id -> Callable(kind: String, value: String) for its events.
static var _handlers := {}
static var _callback: JavaScriptObject
static var _overlay: JavaScriptObject

## True in the web version.
static func available() -> bool:
	return OS.has_feature("web")

## A new text box; `handler` gets ("input", text) as the player types and
## ("submit", text) when they press Enter/Go. Returns its id.
static func create_input(handler: Callable) -> String:
	var id := str(_js().input())
	_handlers[id] = handler
	return id

## A new scrolling message list. Returns its id.
static func create_list() -> String:
	return str(_js().list())

## Put element `id` over `rect` (in the game's canvas pixels, see canvas_rect),
## with text `font_px` canvas pixels tall (at least `min_font` page pixels:
## iPhones zoom into text boxes smaller than 16), or hide it.
static func place(id: String, rect: Rect2, font_px: float, show: bool, min_font := 16) -> void:
	_js().place(id, rect.position.x, rect.position.y, rect.size.x, rect.size.y, font_px, show, min_font)

static func set_value(id: String, text: String) -> void:
	_js().setValue(id, text)

static func set_attribute(id: String, attribute: String, value: Variant) -> void:
	_js().setAttr(id, attribute, value)

## Show `items` ([{"text": ..., "color": "#rrggbb"}]) in list `id`.
static func set_items(id: String, items: Array) -> void:
	_js().setItems(id, JSON.stringify(items))

static func remove(id: String) -> void:
	_handlers.erase(id)
	_js().remove(id)

## Where `control` is on the canvas, in canvas pixels (what place() expects),
## and how big its text is there.
static func canvas_rect(control: Control) -> Rect2:
	var to_canvas := control.get_viewport().get_final_transform() * control.get_global_transform_with_canvas()
	return Rect2(to_canvas.origin, control.size * to_canvas.get_scale())

static func canvas_scale(control: Control) -> float:
	var to_canvas := control.get_viewport().get_final_transform() * control.get_global_transform_with_canvas()
	return to_canvas.get_scale().y

## The page's helper, set up the first time it's needed.
static func _js() -> JavaScriptObject:
	if _overlay == null:
		JavaScriptBridge.eval(JS, true)
		_overlay = JavaScriptBridge.get_interface("cpOverlay")
		# Kept in a static var: if it were freed, the page couldn't call back.
		_callback = JavaScriptBridge.create_callback(_on_event)
		_overlay.handler = _callback
	return _overlay

## From the page: [element id, kind, value].
static func _on_event(args: Array) -> void:
	var id := str(args[0])
	if _handlers.has(id):
		(_handlers[id] as Callable).call(str(args[1]), str(args[2]))
