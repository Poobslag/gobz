class_name PlayerSaveUpgrader
extends SaveDataUpgrader

func _init() -> void:
	current_version = "0157"
	add_upgrade_method(_upgrade_012a, "012A", "0157")


func _upgrade_012a(json_dict: Dictionary[String, Variant], old_key: String) -> void:
	match old_key:
		"army":
			json_dict["army"] = _replace_army_glob_for_012a(json_dict["army"])
		"dungeons":
			for dungeon_json: Dictionary in json_dict["dungeons"]:
				dungeon_json["army"] = _replace_army_glob_for_012a(dungeon_json["army"])
				dungeon_json["recon_army"] = _replace_army_glob_for_012a(dungeon_json["recon_army"])


func _replace_army_glob_for_012a(army_glob: String) -> String:
	var army_json_dict: Dictionary[String, Variant] = Army.json_dict_from_glob(army_glob)
	army_json_dict["gobs"] = army_json_dict["hordes"]
	army_json_dict.erase("hordes")
	return Army.glob_from_json_dict(army_json_dict)
