extends GutTest

func before_each() -> void:
	PlayerData.reset()
	HomeBaseData.reset()
	HomeBaseData.heal_data.forced_heal_threshold = HealData.HealThreshold.new(2.0, 3, 2, 3)


func test_get_heal_threshold_1() -> void:
	var threshold: HealData.HealThreshold = HealData.get_heal_threshold(Big.new(1))
	assert_eq(threshold.groups, 2)
	assert_eq(threshold.chats, 1)
	assert_eq(threshold.options, 2)


func test_get_heal_threshold_123() -> void:
	var threshold: HealData.HealThreshold = HealData.get_heal_threshold(Big.new(123))
	assert_eq(threshold.groups, 3)
	assert_between(threshold.chats, 2, 3)
	assert_eq(threshold.options, 3)


func test_get_heal_threshold_10e5() -> void:
	var threshold: HealData.HealThreshold = HealData.get_heal_threshold(Big.new(1.23e5))
	assert_between(threshold.groups, 3, 4)
	assert_eq(threshold.chats, 3)
	assert_between(threshold.options, 3, 4)


func test_get_heal_threshold_10e16() -> void:
	var threshold: HealData.HealThreshold = HealData.get_heal_threshold(Big.new(1.23e16))
	assert_eq(threshold.groups, 5)
	assert_between(threshold.chats, 4, 5)
	assert_eq(threshold.options, 5)


func test_get_heal_threshold_10e300() -> void:
	var threshold: HealData.HealThreshold = HealData.get_heal_threshold(Big.new(1.23e300))
	assert_eq(threshold.groups, 12)
	assert_eq(threshold.chats, 6)
	assert_eq(threshold.options, 6)


func test_remove_group_at_preserves_index() -> void:
	for _i in 10:
		var gob: Gob = ArmyTestUtils.gob("🔥 3")
		gob.back_count = Big.new(10)
		gob.back_wounded = Big.new(5)
		PlayerData.army.add_gob(gob)
	HomeBaseData.heal_data.mark_groups_dirty()
	
	assert_eq(HomeBaseData.heal_data.groups.size(), 3)
	HomeBaseData.heal_data.group_index = 1
	HomeBaseData.heal_data.remove_group_at(2)
	assert_eq(HomeBaseData.heal_data.group_index, 1)


func test_remove_group_at_shifts_index() -> void:
	for _i in 10:
		var gob: Gob = ArmyTestUtils.gob("🔥 3")
		gob.back_count = Big.new(10)
		gob.back_wounded = Big.new(5)
		PlayerData.army.add_gob(gob)
	HomeBaseData.heal_data.mark_groups_dirty()
	
	assert_eq(HomeBaseData.heal_data.groups.size(), 3)
	HomeBaseData.heal_data.group_index = 1
	HomeBaseData.heal_data.remove_group_at(1)
	assert_eq(HomeBaseData.heal_data.group_index, 0)


func test_remove_group_at_group_index_0() -> void:
	for _i in 10:
		var gob: Gob = ArmyTestUtils.gob("🔥 3")
		gob.back_count = Big.new(10)
		gob.back_wounded = Big.new(5)
		PlayerData.army.add_gob(gob)
	HomeBaseData.heal_data.mark_groups_dirty()
	
	assert_eq(HomeBaseData.heal_data.groups.size(), 3)
	HomeBaseData.heal_data.group_index = 0
	HomeBaseData.heal_data.remove_group_at(0)
	assert_eq(HomeBaseData.heal_data.group_index, 0)
