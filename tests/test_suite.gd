class_name TestSuite
extends RefCounted

## The base for every test file. A test file extends this and adds functions
## whose names start with "test_". run_tests.gd calls each one on a fresh copy
## and reports anything recorded in `failures`.

var failures: PackedStringArray = []

func check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func check_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, expected, actual])
