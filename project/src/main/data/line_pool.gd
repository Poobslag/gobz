class_name LinePool

static var _cache: Dictionary[String, Array] = {}

static func get_random_line(path: String) -> String:
	# initialize the cache
	if not _cache.has(path):
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		var lines: Array[String] = []
		lines.assign(Utils.get_lines_from_file(file))
		for i in range(lines.size() - 1, -1, -1):
			if lines[i].is_empty():
				lines.pop_at(i)
		_cache[path] = lines
	
	# return a random line from the cache
	var cached_lines: Array[String] = _cache[path]
	if cached_lines.is_empty():
		push_error("No lines loaded from %s" % [path])
		return ""
	@warning_ignore("integer_division")
	var cached_line: String = cached_lines.pop_at(randi_range(0, cached_lines.size() / 2))
	cached_lines.push_back(cached_line)
	return cached_line
