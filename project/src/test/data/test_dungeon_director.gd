extends GutTest

func before_each() -> void:
	PlayerData.reset()


func test_cycle_dungeons_boss_cap() -> void:
	# player strength is about 1,200, but they haven't beaten the first boss
	PlayerData.bosses_defeated = 0
	PlayerData.army.add_gob(gob("🔥 5"))
	PlayerData.army.gobs[0].back_count = Big.new(99)
	DungeonDirector.cycle_dungeons()
	
	# dungeon strength is capped to about 200-500
	assert_true(PlayerData.dungeons[0].boss)
	assert_between(PlayerData.dungeons[0].army.get_total_attack().to_float(), 500.0, 1_500.0)
	assert_between(PlayerData.dungeons[1].army.get_total_attack().to_float(), 200.0, 500.0)
	assert_between(PlayerData.dungeons[2].army.get_total_attack().to_float(), 200.0, 500.0)
	assert_between(PlayerData.dungeons[3].army.get_total_attack().to_float(), 200.0, 500.0)


func test_cycle_dungeons_no_boss_cap() -> void:
	# player strength is about 1,200, but they've beaten a few bosses
	PlayerData.bosses_defeated = 5
	PlayerData.army.add_gob(gob("🔥 5"))
	PlayerData.army.gobs[0].back_count = Big.new(99)
	DungeonDirector.cycle_dungeons()
	
	# dungeon strength is uncapped
	assert_true(PlayerData.dungeons[0].boss)
	assert_between(PlayerData.dungeons[1].army.get_total_attack().to_float(), 500.0, 2_000.0)
	assert_between(PlayerData.dungeons[2].army.get_total_attack().to_float(), 500.0, 2_000.0)
	assert_between(PlayerData.dungeons[3].army.get_total_attack().to_float(), 500.0, 2_000.0)


func test_recruit_type_weights() -> void:
	assert_eq(DungeonDirector.get_recruit_type_weights(0), [1.0, 1.0, 1.0, 0.0, 0.0])
	
	# devils start showing up on day 6
	assert_almost_eq(DungeonDirector.get_recruit_type_weights(5)[4], 0.000, 0.001)
	assert_almost_eq(DungeonDirector.get_recruit_type_weights(6)[4], 0.143, 0.001)
	
	# angels start showing up on day 10
	assert_almost_eq(DungeonDirector.get_recruit_type_weights(9)[3], 0.000, 0.001)
	assert_almost_eq(DungeonDirector.get_recruit_type_weights(10)[3], 0.143, 0.001)
	
	assert_eq(DungeonDirector.get_recruit_type_weights(999), [1.0, 1.0, 1.0, 1.0, 1.0])


func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)
