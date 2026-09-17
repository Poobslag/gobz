extends GutTest


func test_subsample_string() -> void:
	assert_eq(DungeonRewardsButton.subsample_string("abcdefg", 10), "abbcddeffg")
	assert_eq(DungeonRewardsButton.subsample_string("abcdefg", 7), "abcdefg")
	assert_eq(DungeonRewardsButton.subsample_string("abcdefg", 4), "aceg")
	assert_eq(DungeonRewardsButton.subsample_string("abcdefg", 1), "d")
	assert_eq(DungeonRewardsButton.subsample_string("abcdefg", 0), "")
	
	assert_eq(DungeonRewardsButton.subsample_string("abcdefghij", 8), "abdefgij")
