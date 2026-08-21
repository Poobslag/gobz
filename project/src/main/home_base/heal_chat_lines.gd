class_name HealChatLines

const HEAL_PROMPTS_PATH: String = "res://assets/main/home_base/heal_prompts.csv"

static var _cached_lines: Array[HealChatLine] = []

static func get_random_lines(count: int, min_value: int = 0) -> Array[HealChatLine]:
	if _cached_lines.is_empty():
		_load_cached_lines()
		if _cached_lines.is_empty():
			push_error("")
			return []
	
	var result: Array[HealChatLine] = []
	while result.size() < count:
		@warning_ignore("integer_division")
		var line: HealChatLine = _cached_lines.pop_at(randi_range(0, _cached_lines.size() / 2))
		_cached_lines.append(line)
		if line.value >= min_value:
			result.append(line)
	
	return result

static func _load_cached_lines() -> void:
	var file: FileAccess = FileAccess.open(HEAL_PROMPTS_PATH, FileAccess.READ)
	
	# ignore the header
	file.get_csv_line(",")
	
	while not file.eof_reached():
		var csv_line: PackedStringArray = file.get_csv_line(",")
		if csv_line.size() < 6:
			continue
		var heal_chat_line: HealChatLine = HealChatLine.new()
		heal_chat_line.value = int(csv_line[0])
		heal_chat_line.prompt_abbr_1 = csv_line[1]
		heal_chat_line.prompt_abbr_2 = csv_line[2]
		heal_chat_line.prompt = csv_line[3]
		heal_chat_line.response_good = csv_line[4]
		heal_chat_line.response_bad = csv_line[5]
		_cached_lines.append(heal_chat_line)
	_cached_lines.shuffle()


class HealChatLine:
	var value: int
	var prompt_abbr_1: String
	var prompt_abbr_2: String
	var prompt: String
	var response_good: String
	var response_bad: String
