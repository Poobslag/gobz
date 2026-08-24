extends GutTest

func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)


func before_each() -> void:
	PlayerData.reset()


func test_get_total_attack_overflow() -> void:
	PlayerData.army.add_gob(gob("🔥 4"))
	PlayerData.army.add_gob(gob("🔥 5"))
	PlayerData.army.gobs[0].back_count = Big.new(999_999_999_999_999_999)
	PlayerData.army.gobs[1].back_count = Big.new(999_999_999_999_999_999)
	assert_almost_eq(PlayerData.army.get_total_attack().to_float(), 2.2e19, 1.0e17)


func test_get_total_gold_overflow() -> void:
	PlayerData.army.add_gob(gob("🔥 4"))
	PlayerData.army.add_gob(gob("🔥 5"))
	PlayerData.army.gobs[0].back_count = Big.new(999_999_999_999_999_999)
	PlayerData.army.gobs[1].back_count = Big.new(999_999_999_999_999_999)
	assert_almost_eq(PlayerData.army.get_total_gold().to_float(), 5.5e19, 1.0e18)


func test_get_summary_overflow() -> void:
	PlayerData.army.add_gob(gob("🔥 4"))
	PlayerData.army.add_gob(gob("🔥 5"))
	PlayerData.army.gobs[0].back_count = Big.new(999_999_999_999_999_999)
	PlayerData.army.gobs[1].back_count = Big.new(999_999_999_999_999_999)
	var summary: Army.ArmySummary = PlayerData.army.get_summary()
	assert_almost_eq(summary.attack_by_type[Gobs.FIRE].to_float(), 2.2e19, 1.0e17)
	assert_almost_eq(summary.goblins_by_type[Gobs.FIRE].to_float(), 2.0e18, 1.0e16)
	assert_almost_eq(summary.total_attack.to_float(), 2.2e19, 1.0e17)
	assert_almost_eq(summary.total_goblins.to_float(), 2.0e18, 1.0e16)
	assert_almost_eq(summary.total_gold.to_float(), 5.5e19, 1.0e17)


func test_to_json_dict() -> void:
	PlayerData.army.add_gob(gob("🔥 4"))
	var json: Dictionary[String, Variant] = PlayerData.army.to_json_dict()
	assert_eq(json, {
			"gobs": [
				{"name": "fire4", "back_count": 0.0, "level": 4, "type": "fire",
					"hp": "20/20", "back_wounded": 0.0, "attack": 10, "gold": 25, "xp": 0},
			],
			"gold": 0.0,
		})


func test_from_json_dict() -> void:
	PlayerData.army.from_json_dict({
			"gobs": [
				{"name": "fire4", "back_count": 2, "level": 4, "type": "fire",
					"hp": "14/14", "attack": 12, "gold": 55, "xp": 3},
			],
			"gold": 123,
		})
	assert_eq(PlayerData.army.gobs.size(), 1)
	assert_eq(PlayerData.army.gobs[0].name, "fire4")
	assert_eq(PlayerData.army.gobs[0].get_count().to_int(), 3)
	assert_eq(PlayerData.army.gobs[0].level, 4)
	assert_eq(PlayerData.army.gobs[0].type, Gobs.Type.FIRE)
	assert_eq(PlayerData.army.gobs[0].front_hp, 14)
	assert_eq(PlayerData.army.gobs[0].hp_max, 14)
	assert_eq(PlayerData.army.gobs[0].attack, 12)
	assert_eq(PlayerData.army.gobs[0].gold, 55)
	assert_eq(PlayerData.army.gobs[0].xp, 3)
	
	assert_eq(123, PlayerData.army.gold.to_int())


func test_to_glob() -> void:
	PlayerData.army.from_json_dict({
			"gobs": [
				{"name": "fire4", "count": 2, "level": 4, "type": "fire",
					"hp": "14/14", "attack": 12, "gold": 55, "xp": 3},
				{"name": "fire5", "count": 3, "level": 5, "type": "fire",
					"hp": "16/16", "attack": 14, "gold": 65, "xp": 4},
				{"name": "water6", "count": 4, "level": 6, "type": "water",
					"hp": "18/18", "attack": 15, "gold": 75, "xp": 5},
			],
			"gold": 123,
		})
	var glob: String = PlayerData.army.to_glob()
	PlayerData.army.reset()
	PlayerData.army.from_glob(glob)
	assert_eq(PlayerData.army.gobs.size(), 3)
	assert_eq(PlayerData.army.gobs[0].name, "fire4")
	assert_eq(PlayerData.army.gobs[1].name, "fire5")
	assert_eq(PlayerData.army.gobs[2].name, "water6")
