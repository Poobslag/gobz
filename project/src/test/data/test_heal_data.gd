extends GutTest


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
