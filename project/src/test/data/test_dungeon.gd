extends GutTest

var dungeon: Dungeon = Dungeon.new()

func test_convert_to_json_and_back() -> void:
	var reward: Dungeon.Reward = Dungeon.Reward.new()
	reward.type = Items.Type.FOOD_PIZZA
	reward.count = Big.new(123)
	dungeon.rewards.append(reward)
	var result: Dictionary[String, Variant] = dungeon.to_json_dict()
	
	dungeon = Dungeon.new()
	dungeon.from_json_dict(result)
	assert_eq(dungeon.rewards.size(), 1)
	assert_eq(dungeon.rewards[0].type, Items.Type.FOOD_PIZZA)
	assert_eq(dungeon.rewards[0].count.to_int(), 123)
