extends GutTest

func before_each() -> void:
	PlayerData.reset()


func test_cycle_dungeons_boss_cap() -> void:
	# player strength is about 12,000, but they haven't beaten the first boss
	PlayerData.bosses_defeated = 0
	PlayerData.army.add_gob(gob("🔥 5"))
	PlayerData.army.gobs[0].back_count = Big.new(999)
	DungeonDirector.cycle_dungeons()
	
	# dungeon strength is capped to about 200-500
	assert_between(PlayerData.dungeons[1].army.get_total_attack().to_float(), 100.0, 1_000.0)
	
	# player strength is about 12,000, but they've beaten a few bosses
	PlayerData.bosses_defeated = 5
	PlayerData.dungeons.clear()
	DungeonDirector.cycle_dungeons()
	
	# dungeon strength is uncapped
	assert_between(PlayerData.dungeons[1].army.get_total_attack().to_float(), 5_000.0, 20_000.0)


func test_recruit_type_weights() -> void:
	assert_eq(DungeonDirector.get_recruit_type_weights(0), [1.0, 1.0, 1.0, 0.0, 0.0])
	
	# devils start showing up on day 6
	assert_almost_eq(DungeonDirector.get_recruit_type_weights(5)[4], 0.000, 0.001)
	assert_almost_eq(DungeonDirector.get_recruit_type_weights(6)[4], 0.143, 0.001)
	
	# angels start showing up on day 10
	assert_almost_eq(DungeonDirector.get_recruit_type_weights(9)[3], 0.000, 0.001)
	assert_almost_eq(DungeonDirector.get_recruit_type_weights(10)[3], 0.143, 0.001)
	
	assert_eq(DungeonDirector.get_recruit_type_weights(999), [1.0, 1.0, 1.0, 1.0, 1.0])


func test_max_level() -> void:
	assert_eq(DungeonDirector.get_recruit_max_level(1), 4)
	assert_eq(DungeonDirector.get_recruit_max_level(11), 6)
	assert_eq(DungeonDirector.get_recruit_max_level(21), 8)
	assert_eq(DungeonDirector.get_recruit_max_level(2000), 8)


func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)
