extends GutTest

func army_item(s: String) -> Army.ArmyItem:
	return ArmyTestUtils.army_item(s)


func after_each() -> void:
	PlayerData.army.reset()


func test_get_total_attack_overflow() -> void:
	PlayerData.army.add_item(army_item("🔥 4"))
	PlayerData.army.add_item(army_item("🔥 5"))
	PlayerData.army.items[0].count = 999_999_999_999_999_999
	PlayerData.army.items[1].count = 999_999_999_999_999_999
	assert_eq(PlayerData.army.get_total_attack(), 999_999_999_999_999_999)


func test_get_total_gold_overflow() -> void:
	PlayerData.army.add_item(army_item("🔥 4"))
	PlayerData.army.add_item(army_item("🔥 5"))
	PlayerData.army.items[0].count = 999_999_999_999_999_999
	PlayerData.army.items[1].count = 999_999_999_999_999_999
	assert_eq(PlayerData.army.get_total_gold(), 999_999_999_999_999_999)


func test_get_summary_overflow() -> void:
	PlayerData.army.add_item(army_item("🔥 4"))
	PlayerData.army.add_item(army_item("🔥 5"))
	PlayerData.army.items[0].count = 999_999_999_999_999_999
	PlayerData.army.items[1].count = 999_999_999_999_999_999
	var summary: Army.ArmySummary = PlayerData.army.get_summary()
	assert_eq(999_999_999_999_999_999, summary.attack_by_type[Goblins.FIRE])
	assert_eq(999_999_999_999_999_999, summary.goblins_by_type[Goblins.FIRE])
	assert_eq(999_999_999_999_999_999, summary.total_attack)
	assert_eq(999_999_999_999_999_999, summary.total_goblins)
#
	#var name: String = ""
	#var count: int = 1
	#var gold: int = 0
	#var level: int = 1
	#var type: Goblins.GoblinType = Goblins.GoblinType.FIRE
	#var hp_max: int = 4
	#var hp: int = 4
	#var experience: int = 0
	#var attack: int = 2

func test_to_json_dict() -> void:
	PlayerData.army.add_item(army_item("🔥 4"))
	var json: Dictionary[String, Variant] = PlayerData.army.to_json_dict()
	assert_eq(json, {
			"items": [
				{"name": "fire4", "count": 1, "level": 4, "type": "fire",
					"hp": "14/14", "attack": 12, "gold": 55, "exp": 0},
			],
			"gold": 0,
		})


func test_from_json_dict() -> void:
	PlayerData.army.from_json_dict({
			"items": [
				{"name": "fire4", "count": 2, "level": 4, "type": "fire",
					"hp": "14/14", "attack": 12, "gold": 55, "exp": 3},
			],
			"gold": 123,
		})
	assert_eq(1, PlayerData.army.items.size())
	assert_eq("fire4", PlayerData.army.items[0].name)
	assert_eq(2, PlayerData.army.items[0].count)
	assert_eq(4, PlayerData.army.items[0].level)
	assert_eq(Goblins.GoblinType.FIRE, PlayerData.army.items[0].type)
	assert_eq(14, PlayerData.army.items[0].hp)
	assert_eq(14, PlayerData.army.items[0].hp_max)
	assert_eq(12, PlayerData.army.items[0].attack)
	assert_eq(55, PlayerData.army.items[0].gold)
	assert_eq(3, PlayerData.army.items[0].experience)
	
	assert_eq(123, PlayerData.army.gold)


func test_to_glob() -> void:
	PlayerData.army.from_json_dict({
			"items": [
				{"name": "fire4", "count": 2, "level": 4, "type": "fire",
					"hp": "14/14", "attack": 12, "gold": 55, "exp": 3},
				{"name": "fire5", "count": 3, "level": 5, "type": "fire",
					"hp": "16/16", "attack": 14, "gold": 65, "exp": 4},
				{"name": "water6", "count": 4, "level": 6, "type": "water",
					"hp": "18/18", "attack": 15, "gold": 75, "exp": 5},
			],
			"gold": 123,
		})
	var glob: String = PlayerData.army.to_glob()
	PlayerData.army.reset()
	PlayerData.army.from_glob(glob)
	assert_eq(3, PlayerData.army.items.size())
	assert_eq("fire4", PlayerData.army.items[0].name)
	assert_eq("fire5", PlayerData.army.items[1].name)
	assert_eq("water6", PlayerData.army.items[2].name)
