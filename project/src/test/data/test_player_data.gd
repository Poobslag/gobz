extends GutTest

func before_each() -> void:
	PlayerData.reset()


func army_item(s: String) -> Army.ArmyItem:
	return ArmyTestUtils.army_item(s)


func test_scale_up() -> void:
	PlayerData.army.add_item(army_item("🔥 3"))
	PlayerData.scale_army_units(10)
	assert_eq(PlayerData.army.items[0].count.to_int(), 10,)


func test_scale_up_avoid_overflow() -> void:
	PlayerData.army.add_item(army_item("🔥 3"))
	PlayerData.army.items[0].count = Big.new(123_456_789_123_456_789)
	PlayerData.gold = Big.new(123_456_789_123_456_789)
	PlayerData.scale_army_units(123_456_789_123_456_789)
	assert_almost_eq(PlayerData.army.items[0].count.to_float(), 1.52e34, 1e32)
	assert_almost_eq(PlayerData.gold.to_float(), 1.52e34, 1e32)
