extends Node

## In LibreOffice Calc: =LOWER(DEC2HEX(INT((NOW()-DATE(2026,8,1))*24),4))
const PLAYER_DATA_VERSION: String = "0157"

var save_folder: String = "user://"

var save_slot: int = 0

var player_data_scene: GDScript = PlayerData.get_script()

## Provides backwards compatibility with old settings files.
var _upgrader := PlayerSaveUpgrader.new()

func peek_save_summary(other_save_slot: int) -> Dictionary[String, Variant]:
	var player_data: PlayerData = player_data_scene.new()
	var error: int = _load_player_data_internal(player_data, other_save_slot)
	var summary: Dictionary[String, Variant] = {
		"error": error,
		"desc": "Day %s: %s goblins, %s⚔" % \
				[player_data.day, player_data.army.get_total_goblins().to_aa(),
				player_data.army.get_total_attack().to_aa()]
	}
	player_data.free()
	return summary


func has_data(loaded_save_slot: int) -> bool:
	return FileAccess.file_exists(_get_save_slot_filename(loaded_save_slot))


func load_data(loaded_save_slot: int) -> void:
	save_slot = loaded_save_slot
	_load_player_data_internal(PlayerData, loaded_save_slot)


func save_data(saved_save_slot: int = save_slot) -> void:
	_save_player_data_internal(PlayerData, saved_save_slot)


func delete_data(saved_save_slot: int = save_slot) -> void:
	DirAccess.remove_absolute(_get_save_slot_filename(saved_save_slot))


func _get_save_slot_filename(filename_save_slot: int) -> String:
	return save_folder.path_join("save%s.json" % [filename_save_slot])


func _load_player_data_internal(player_data: PlayerData, loaded_save_slot: int) -> Error:
	player_data.reset()
	var filename: String = _get_save_slot_filename(loaded_save_slot)
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
	
	if _upgrader.needs_upgrade(save_json):
		_upgrader.upgrade(save_json)
	
	player_data.from_json_dict(Utils.typed_json_dict(save_json))
	return OK


func _save_player_data_internal(player_data: PlayerData, saved_save_slot: int) -> void:
	if not DirAccess.dir_exists_absolute(save_folder):
		DirAccess.make_dir_absolute(save_folder)
	
	var filename: String = _get_save_slot_filename(saved_save_slot)
	var data_json: Dictionary[String, Variant] = player_data.to_json_dict()
	data_json["version"] = PLAYER_DATA_VERSION
	FileAccess.open(filename, FileAccess.WRITE).store_string(JSON.stringify(data_json, "  "))
