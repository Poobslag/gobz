extends GutTest

const TEMP_SAVE_FOLDER := "user://test_sav_314"

func before_each() -> void:
	PlayerData.reset()
	PlayerSave.save_folder = TEMP_SAVE_FOLDER
	if not DirAccess.dir_exists_absolute(TEMP_SAVE_FOLDER):
		DirAccess.make_dir_absolute(TEMP_SAVE_FOLDER)


func after_each() -> void:
	Utils.remove_dir_recursive(TEMP_SAVE_FOLDER)


func load_player_data(filename: String) -> void:
	PlayerSave.save_slot = 0
	DirAccess.copy_absolute(
			"res://assets/test/data".path_join(filename),
			TEMP_SAVE_FOLDER.path_join("save0.json"))
	PlayerSave.load_data(0)


func test_012a() -> void:
	load_player_data("save_012a.json")
	
	assert_eq(PlayerData.army.get_total_goblins().to_int(), 4)
	assert_eq(PlayerData.army.get_total_attack().to_int(), 16)
	assert_eq(PlayerData.gold.to_int(), 46)
	assert_eq(PlayerData.dungeons[0].army.get_total_goblins().to_int(), 1)
	assert_eq(PlayerData.dungeons[0].army.get_total_attack().to_int(), 4)
	assert_eq(PlayerData.dungeons[0].recon_army.get_total_goblins().to_int(), 1)
	assert_eq(PlayerData.dungeons[0].recon_army.get_total_attack().to_int(), 4)
