extends GutTest

const TEMP_SAVE_FOLDER := "user://test_sav_863"

func before_each() -> void:
	PlayerData.reset()
	PlayerSave.save_folder = TEMP_SAVE_FOLDER


func after_each() -> void:
	Utils.remove_dir_recursive(TEMP_SAVE_FOLDER)


func test_save_and_load_data() -> void:
	PlayerData.day = 67
	PlayerSave.save_slot = 0
	PlayerSave.save_data()
	PlayerData.reset()
	PlayerSave.load_data(0)
	assert_eq(67, PlayerData.day)


func test_summarize() -> void:
	PlayerData.day = 67
	PlayerData.army.add_gob(ArmyTestUtils.gob("🔥 3"))
	PlayerData.army.add_gob(ArmyTestUtils.gob("🔥 3"))
	PlayerSave.save_slot = 0
	PlayerSave.save_data()
	PlayerData.reset()
	assert_eq(PlayerSave.peek_save_summary(0), {
		"error": OK,
		"desc": "Day 67: 2 goblins, 16⚔"})
