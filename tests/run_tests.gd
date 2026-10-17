extends Node

## Runs every test in every *_test.gd file in this folder, then prints a summary.
## In the editor: open run_tests.tscn and press F6.
## Command line: see "Running tests" in CLAUDE.md. Words after "--" only run
## files whose names contain them, e.g. "-- movegen".

const TEST_DIR := "res://tests/"

func _ready() -> void:
	var filters := OS.get_cmdline_user_args()
	var passed := 0
	var failed := 0
	for file in DirAccess.get_files_at(TEST_DIR):
		if not file.ends_with("_test.gd") or not _matches(file, filters):
			continue
		var script: GDScript = load(TEST_DIR + file)
		for test_name in _test_names(script):
			# A fresh copy per test, so one test's leftovers can't affect another.
			var suite: TestSuite = script.new()
			var start := Time.get_ticks_msec()
			suite.call(test_name)
			var ms := Time.get_ticks_msec() - start
			var label := "%s.%s (%d ms)" % [file.get_basename(), test_name, ms]
			if suite.failures.is_empty():
				passed += 1
				print("  PASS  ", label)
			else:
				failed += 1
				print("  FAIL  ", label)
				for failure in suite.failures:
					print("        ", failure)
	print("\n%d passed, %d failed" % [passed, failed])
	get_tree().quit(1 if failed > 0 else 0)

func _matches(file: String, filters: PackedStringArray) -> bool:
	if filters.is_empty():
		return true
	for filter in filters:
		if file.contains(filter):
			return true
	return false

## The script's functions whose names start with "test_", in the order written.
func _test_names(script: GDScript) -> PackedStringArray:
	var names: PackedStringArray = []
	for method in script.get_script_method_list():
		var method_name: String = method.name
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	return names
