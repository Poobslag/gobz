extends GutTest

func horde(s: String) -> Horde:
	return ArmyTestUtils.horde(s)


func after_each() -> void:
	PlayerData.army.reset()


func test_get_total_attack_overflow() -> void:
	PlayerData.army.add_horde(horde("🔥 4"))
	PlayerData.army.add_horde(horde("🔥 5"))
	PlayerData.army.hordes[0].count = Big.new(999_999_999_999_999_999)
	PlayerData.army.hordes[1].count = Big.new(999_999_999_999_999_999)
	assert_almost_eq(PlayerData.army.get_total_attack().to_float(), 2.2e19, 1.0e17)


func test_get_total_gold_overflow() -> void:
	PlayerData.army.add_horde(horde("🔥 4"))
	PlayerData.army.add_horde(horde("🔥 5"))
	PlayerData.army.hordes[0].count = Big.new(999_999_999_999_999_999)
	PlayerData.army.hordes[1].count = Big.new(999_999_999_999_999_999)
	assert_almost_eq(PlayerData.army.get_total_gold().to_float(), 5.5e19, 1.0e18)


func test_get_summary_overflow() -> void:
	PlayerData.army.add_horde(horde("🔥 4"))
	PlayerData.army.add_horde(horde("🔥 5"))
	PlayerData.army.hordes[0].count = Big.new(999_999_999_999_999_999)
	PlayerData.army.hordes[1].count = Big.new(999_999_999_999_999_999)
	var summary: Army.ArmySummary = PlayerData.army.get_summary()
	assert_almost_eq(summary.attack_by_type[Goblins.FIRE].to_float(), 2.2e19, 1.0e17)
	assert_almost_eq(summary.goblins_by_type[Goblins.FIRE].to_float(), 2.0e18, 1.0e16)
	assert_almost_eq(summary.total_attack.to_float(), 2.2e19, 1.0e17)
	assert_almost_eq(summary.total_goblins.to_float(), 2.0e18, 1.0e16)
	assert_almost_eq(summary.total_gold.to_float(), 5.5e19, 1.0e17)


func test_to_json_dict() -> void:
	PlayerData.army.add_horde(horde("🔥 4"))
	var json: Dictionary[String, Variant] = PlayerData.army.to_json_dict()
	assert_eq(json, {
			"hordes": [
				{"name": "fire4", "count": 1.0, "level": 4, "type": "fire",
					"hp": "20/20", "attack": 10, "gold": 25, "xp": 0},
			],
			"gold": 0.0,
		})


func test_from_json_dict() -> void:
	PlayerData.army.from_json_dict({
			"hordes": [
				{"name": "fire4", "count": 2, "level": 4, "type": "fire",
					"hp": "14/14", "attack": 12, "gold": 55, "xp": 3},
			],
			"gold": 123,
		})
	assert_eq(1, PlayerData.army.hordes.size())
	assert_eq("fire4", PlayerData.army.hordes[0].name)
	assert_eq(2, PlayerData.army.hordes[0].count.to_int())
	assert_eq(4, PlayerData.army.hordes[0].level)
	assert_eq(Goblins.GoblinType.FIRE, PlayerData.army.hordes[0].type)
	assert_eq(14, PlayerData.army.hordes[0].hp)
	assert_eq(14, PlayerData.army.hordes[0].hp_max)
	assert_eq(12, PlayerData.army.hordes[0].attack)
	assert_eq(55, PlayerData.army.hordes[0].gold)
	assert_eq(3, PlayerData.army.hordes[0].xp)
	
	assert_eq(123, PlayerData.army.gold.to_int())


func test_to_glob() -> void:
	PlayerData.army.from_json_dict({
			"hordes": [
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
	assert_eq(3, PlayerData.army.hordes.size())
	assert_eq("fire4", PlayerData.army.hordes[0].name)
	assert_eq("fire5", PlayerData.army.hordes[1].name)
	assert_eq("water6", PlayerData.army.hordes[2].name)
