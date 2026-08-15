extends GutTest

func before_each() -> void:
	PlayerData.reset()


func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)


func test_scale_up() -> void:
	PlayerData.army.add_gob(gob("🔥 3"))
	PlayerData.scale_army_units(10)
	assert_eq(PlayerData.army.gobs[0].count.to_int(), 10,)


func test_scale_up_avoid_overflow() -> void:
	PlayerData.army.add_gob(gob("🔥 3"))
	PlayerData.army.gobs[0].count = Big.new(123_456_789_123_456_789)
	PlayerData.gold = Big.new(123_456_789_123_456_789)
	PlayerData.scale_army_units(123_456_789_123_456_789)
	assert_almost_eq(PlayerData.army.gobs[0].count.to_float(), 1.52e34, 1e32)
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


func test_convert_to_json_and_back() -> void:
	PlayerData.day = 5
	PlayerData.army.add_gob(gob("🔥 3"))
	PlayerData.gold = Big.new(6700)
	PlayerData.dungeons.append(Dungeon.new())
	PlayerData.dungeons[0].army.add_gob(gob("💧 2"))
	PlayerData.dungeons[0].recon_army.add_gob(gob("💧 3"))
	PlayerData.home_base_multiplier = Big.new(100)
	var result: Dictionary[String, Variant] = PlayerData.to_json_dict()
	PlayerData.reset()
	PlayerData.from_json_dict(result)
	assert_eq(PlayerData.day, 5)
	assert_eq(PlayerData.army.get_total_goblins().to_int(), 1)
	assert_eq(PlayerData.dungeons.size(), 1)
