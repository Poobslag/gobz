extends GutTest

func before_each() -> void:
	PlayerData.reset()


func horde(s: String) -> Horde:
	return ArmyTestUtils.horde(s)


func test_scale_up() -> void:
	PlayerData.army.add_horde(horde("🔥 3"))
	PlayerData.scale_army_units(10)
	assert_eq(PlayerData.army.hordes[0].count.to_int(), 10,)


func test_scale_up_avoid_overflow() -> void:
	PlayerData.army.add_horde(horde("🔥 3"))
	PlayerData.army.hordes[0].count = Big.new(123_456_789_123_456_789)
	PlayerData.gold = Big.new(123_456_789_123_456_789)
	PlayerData.scale_army_units(123_456_789_123_456_789)
	assert_almost_eq(PlayerData.army.hordes[0].count.to_float(), 1.52e34, 1e32)
	assert_almost_eq(PlayerData.gold.to_float(), 1.52e34, 1e32)


func test_calc_ripoff_factor() -> void:
	PlayerData.gold = Big.new(5_000)
	assert_eq(PlayerData.get_ripoff_factor(), 0.5)
	PlayerData.gold = Big.new(27_500)
	assert_eq(PlayerData.get_ripoff_factor(), 0.45)
	PlayerData.gold = Big.new(50_000)
	assert_eq(PlayerData.get_ripoff_factor(), 0.4)
	PlayerData.gold = Big.new(500_000)
	assert_eq(PlayerData.get_ripoff_factor(), 0.3)
	PlayerData.gold = Big.new(5e50)
	assert_eq(PlayerData.get_ripoff_factor(), 0.01)
