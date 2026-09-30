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
	var save_json: Dictionary[String, Variant] = Utils.typed_json_dict(test_json_conv.data)
	
	var upgrader := PlayerSaveUpgrader.new()
	if upgrader.needs_upgrade(save_json):
		upgrader.upgrade(save_json)
	
	var typed_data_dict: Dictionary[String, Variant] = {}
	typed_data_dict.assign(save_json)
	PlayerData.from_json_dict(typed_data_dict)
	return OK


static func prepare_demo() -> void:
	PlayerData.start_new_game()
	PlayerSave.save_folder = "user://demo_sav_183"
	PlayerData.finished_tutorials = {
		PlayerData.BATTLE_TUTORIAL: true,
		PlayerData.HOME_BASE_TUTORIAL: true,
	}
	populate_default_food_record()


static func set_gold(gold: Big) -> void:
	PlayerData.gold = gold
	PlayerData.reset_peaks()


static func populate_default_food_record() -> void:
	PlayerData.food_record.morale_today = randf_range(0, 100)
	PlayerData.food_record.morale_yesterday = randf_range(0, 100)
	for type: Items.Type in [
			Items.FOOD_BREAD, Items.FOOD_CHICKEN,
			Items.FOOD_PIZZA, Items.FOOD_RAM, Items.FOOD_UNKNOWN]:
		PlayerData.food_record.food_today[type] = Big.new(randf_range(10, 100))
		PlayerData.food_record.food_yesterday[type] = Big.new(randf_range(10, 100))
