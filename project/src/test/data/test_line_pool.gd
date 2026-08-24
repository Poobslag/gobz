extends GutTest

func test_empty() -> void:
	# empty lines should be filtered
	var lines: Array[String] = LinePool.get_cached_lines("res://assets/test/data/blank_lines.csv")
	assert_eq(["quicksand faded"], lines)
