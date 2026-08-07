extends GutTest

func before_each() -> void:
	PlayerData.reset()


func army_item(s: String) -> Army.ArmyItem:
	return ArmyTestUtils.army_item(s)


func test_scale_up() -> void:
	PlayerData.army.add_item(army_item("🔥 3"))
	PlayerData.scale_army_units(10)
	assert_eq(PlayerData.army.items[0].count, 10)


func test_scale_up_avoid_overflow() -> void:
	PlayerData.army.add_item(army_item("🔥 3"))
	PlayerData.army.items[0].count = 123_456_789_123_456_789
	PlayerData.gold = 123_456_789_123_456_789
	PlayerData.scale_army_units(123_456_789_123_456_789)
	assert_eq(999_999_999_999_999_999, PlayerData.army.items[0].count)
	assert_eq(999_999_999_999_999_999, PlayerData.gold)
