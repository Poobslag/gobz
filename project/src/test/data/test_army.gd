extends GutTest

func army_item(s: String) -> Army.ArmyItem:
	return ArmyTestUtils.army_item(s)

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
