extends Node

signal before_save
signal after_save
signal after_load

## In LibreOffice Calc: =LOWER(DEC2HEX(INT((NOW()-DATE(2026,8,1))*24),4))
const PLAYER_DATA_VERSION: String = "01a3"

var save_folder: String = "user://"

var save_slot: int = 0

var player_data_scene: GDScript = PlayerData.get_script()

## Provides backwards compatibility with old settings files.
var _upgrader := PlayerSaveUpgrader.new()

## The currently active thread which is saving the player's data.[br]
## [br]
## This thread is assigned when saving begins, and reset to null when saving completes.
var _save_thread: Thread = null

func peek_save_summary(other_save_slot: int) -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = _load_json_internal(other_save_slot)
	var desc: String = "Day %s: %s goblins" % [
			StringUtils.comma_sep(result["json"].get("day", 1)),
			Big.float_to_aa(result["json"]["total_goblins"]) if result["json"].has("total_goblins") else "??",
		]
	return {
		"error": result.get("error", ""),
		"desc": desc
	}


func has_data(loaded_save_slot: int) -> bool:
	return FileAccess.file_exists(_get_save_slot_filename(loaded_save_slot))


func load_data(loaded_save_slot: int) -> void:
	save_slot = loaded_save_slot
	_load_player_data_internal(PlayerData, loaded_save_slot)
	after_load.emit()


## Writes the player's in-memory data to a save file.[br]
## [br]
## Threading is enabled for performance, but can be disabled with the [param threaded] parameter.
func save_data(saved_save_slot: int = save_slot, threaded: bool = true) -> void:
	if _save_thread:
		# A save thread is already active; don't start another until it's finished.
		return
	
	var use_threaded: bool = threaded and not OS.has_feature("web")
	if use_threaded:
		before_save.emit()
		_save_thread = Thread.new()
		_save_thread.start(_threaded_write_file.bind(saved_save_slot))
		# the after_save signal is emitted from within the thread.
	else:
		before_save.emit()
		_save_player_data_internal(PlayerData, saved_save_slot)
		after_save.emit()


func delete_data(saved_save_slot: int = save_slot) -> void:
	DirAccess.remove_absolute(_get_save_slot_filename(saved_save_slot))


func _get_save_slot_filename(filename_save_slot: int) -> String:
	return save_folder.path_join("save%s.json" % [filename_save_slot])


func _load_json_internal(loaded_save_slot: int) -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {
		"error": OK,
		"json": {} as Dictionary[String, Variant],
	}
	var filename: String = _get_save_slot_filename(loaded_save_slot)
	if not FileAccess.file_exists(filename):
		result["error"] = ERR_FILE_NOT_FOUND
		return result
	var s: String = FileAccess.get_file_as_string(filename)
	var test_json_conv := JSON.new()
	var parse_result: int = test_json_conv.parse(s)
	if parse_result != OK:
		push_error("Error in %s: (%s) %s" %
				[filename, test_json_conv.get_error_line(), test_json_conv.get_error_message()])
		result["error"] = ERR_FILE_CORRUPT
		return result
	result["json"] = Utils.typed_json_dict(test_json_conv.data)
	if _upgrader.needs_upgrade(result["json"]):
		_upgrader.upgrade(result["json"])
	return result


func _load_player_data_internal(player_data: PlayerData, loaded_save_slot: int) -> Error:
	player_data.reset()
	var result: Dictionary[String, Variant] = _load_json_internal(loaded_save_slot)
	if result.get("error") != OK:
		return result.get("error")
	player_data.from_json_dict(result["json"])
	return OK


func _save_player_data_internal(player_data: PlayerData, saved_save_slot: int) -> void:
	if not DirAccess.dir_exists_absolute(save_folder):
		DirAccess.make_dir_absolute(save_folder)
	
	var filename: String = _get_save_slot_filename(saved_save_slot)
	var data_json: Dictionary[String, Variant] = player_data.to_json_dict()
	data_json["version"] = PLAYER_DATA_VERSION
	FileAccess.open(filename, FileAccess.WRITE).store_string(JSON.stringify(data_json, "  "))


## Saves the player data.[br]
## [br]
## This code is meant to be invoked from within a secondary thread.
func _threaded_write_file(saved_save_slot: int) -> void:
	# Warning: A race condition exists where PlayerData could be modified while being converted to JSON. The JSON
	# conversion takes about 50 ms so threading it avoids dropped frames.
	_save_player_data_internal(PlayerData, saved_save_slot)
	_after_threaded_write_file.call_deferred()


## Performs cleanup steps after a threaded save operation.[br]
## [br]
## This code is meant to be invoked on the main thread, after a threaded save operation completes on a secondary
## thread.
func _after_threaded_write_file() -> void:
	_save_thread.wait_to_finish()
	_save_thread = null
	after_save.emit()
