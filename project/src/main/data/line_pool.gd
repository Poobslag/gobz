class_name LinePool

static var _cache: Dictionary[String, Array] = {}

static func get_longest_line(path: String) -> String:
	var lines: Array[String] = get_cached_lines(path)
	var longest_line_index: int = 0
	var max_length: int = 0
	for i in lines.size():
		var line_length: int = lines[i].length()
		if line_length > max_length:
			longest_line_index = i
			max_length = line_length
	var line: String = lines.pop_at(longest_line_index)
	lines.push_back(line)
	return line


static func get_cached_lines(path: String) -> Array[String]:
	if not _cache.has(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var lines: Array[String] = []
		while not file.eof_reached():
			var csv_line: PackedStringArray = file.get_csv_line()
			if csv_line.size() >= 1 and not csv_line[0].is_empty():
				lines.append(csv_line[0])
		if lines.is_empty():
			push_error("No lines loaded from %s" % [path])
		lines.shuffle()
		_cache[path] = lines
	return _cache[path]


static func get_random_line(path: String) -> String:
	var lines: Array[String] = get_cached_lines(path)
	@warning_ignore("integer_division")
	var line: String = lines.pop_at(randi_range(0, lines.size() / 2))
	lines.push_back(line)
	return line
