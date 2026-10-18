class_name SystemFonts
extends RefCounted

## The game's own font only has Western letters. In the PC app, let it borrow
## the computer's fonts for anything else: emoji, symbols, Chinese, Japanese,
## Korean, Indian scripts... (The web version can't use the computer's fonts;
## there, typed text and chat are shown by the browser instead: see WebOverlay.)

## Each list is one fallback font: the first name the computer has is used.
const FALLBACKS := [
	["Segoe UI Emoji", "Apple Color Emoji", "Noto Color Emoji"],
	["Segoe UI Symbol", "Apple Symbols", "Noto Sans Symbols"],
	["Segoe UI", "Helvetica Neue", "Noto Sans", "Arial"],
	["Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC"],
	["Yu Gothic", "Hiragino Sans", "Noto Sans CJK JP"],
	["Malgun Gothic", "Apple SD Gothic Neo", "Noto Sans CJK KR"],
	["Nirmala UI", "Kohinoor Devanagari", "Noto Sans Devanagari"],
]

## Add the computer's fonts as fallbacks to the game's default font (once).
static func install() -> void:
	if OS.has_feature("web"):
		return
	var base := ThemeDB.fallback_font
	var fallbacks := base.fallbacks.duplicate()
	if fallbacks.any(func(f: Font) -> bool: return f is SystemFont):
		return
	for names: Array in FALLBACKS:
		var font := SystemFont.new()
		font.font_names = PackedStringArray(names)
		fallbacks.append(font)
	base.fallbacks = fallbacks
