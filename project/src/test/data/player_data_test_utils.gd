class_name PlayerDataTestUtils

static func load_player_data(filename: String) -> Error:
	PlayerData.reset()
	if not FileAccess.file_exists(filename):
		return ERR_FILE_NOT_FOUND
	
	var s: String = FileAccess.get_file_as_string(filename)
	var test_json_conv := JSON.new()
	var result: int = test_json_conv.parse(s)
	if result != OK:
		push_error("Error in %s: (%s) %s" %
				[filename, test_json_conv.get_error_line(), test_json_conv.get_error_message()])
		return ERR_FILE_CORRUPT
	var save_json: Dictionary[String, Variant] = {}
	save_json.assign(test_json_conv.data)
	
	var upgrader := PlayerSaveUpgrader.new()
	if upgrader.needs_upgrade(save_json):
		upgrader.upgrade(save_json)
	
	var typed_data_dict: Dictionary[String, Variant] = {}
	typed_data_dict.assign(save_json)
	PlayerData.from_json_dict(typed_data_dict)
	return OK
