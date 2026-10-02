extends GutTest

func before_each() -> void:
	PlayerData.reset()


func gob(s: String) -> Gob:
	return ArmyTestUtils.gob(s)


func test_scale_up() -> void:
	PlayerData.army.add_gob(gob("🔥 3"))
	PlayerData.scale_army_units(10)
	assert_eq(PlayerData.army.gobs[0].get_count().to_int(), 10)


func test_scale_up_avoid_overflow() -> void:
	PlayerData.army.add_gob(gob("🔥 3"))
	PlayerData.army.gobs[0].back_count = Big.new(123_456_789_123_456_789)
	PlayerData.gold = Big.new(123_456_789_123_456_789)
	PlayerData.scale_army_units(123_456_789_123_456_789)
	assert_almost_eq(PlayerData.army.gobs[0].get_count().to_float(), 1.52e34, 1e32)
	assert_almost_eq(PlayerData.gold.to_float(), 1.52e34, 1e32)


func test_convert_to_json_and_back() -> void:
	PlayerData.day = 5
	PlayerData.army.add_gob(gob("🔥 3"))
	PlayerData.gold = Big.new(6700)
	PlayerData.inventory.add_item(Items.HERB_1, Big.new(123))
	PlayerData.dungeons.append(Dungeon.new())
	PlayerData.dungeons[0].army.add_gob(gob("💧 2"))
	PlayerData.dungeons[0].recon_army.add_gob(gob("💧 3"))
	PlayerData.food_record.food_today[Items.FOOD_BREAD] = Big.new(50)
	PlayerData.home_base_multiplier = Big.new(100)
	_convert_to_json_and_back()
	assert_eq(PlayerData.day, 5)
	assert_eq(PlayerData.army.get_total_goblins().to_int(), 1)
	assert_eq(PlayerData.inventory.get_count(Items.HERB_1).to_int(), 123)
	assert_eq(PlayerData.dungeons.size(), 1)
	assert_eq(PlayerData.food_record.food_today.get(Items.FOOD_BREAD, Big.ZERO).to_int(), 50)


func test_convert_to_json_and_back_heal_data() -> void:
	PlayerData.army.add_gob(gob("🔥 3"))
	PlayerData.army.add_gob(gob("🔥 4"))
	PlayerData.army.add_gob(gob("🔥 5"))
	for next_gob: Gob in PlayerData.army.gobs:
		next_gob.front_hp = 1
	PlayerData.home_base_data.heal_data.mark_groups_dirty()
	var old_chats_remaining: int = PlayerData.home_base_data.heal_data.get_groups()[0].chats_remaining
	var old_gobs_size: int = PlayerData.home_base_data.heal_data.get_groups()[0].gobs.size()
	var old_groups_size: int = PlayerData.home_base_data.heal_data.get_groups().size()
	_convert_to_json_and_back()
	assert_eq(PlayerData.home_base_data.heal_data.get_groups()[0].chats_remaining, old_chats_remaining)
	assert_eq(PlayerData.home_base_data.heal_data.get_groups()[0].gobs.size(), old_gobs_size)
	assert_eq(PlayerData.home_base_data.heal_data.get_groups().size(), old_groups_size)


func test_convert_to_json_and_back_party_data() -> void:
	PlayerData.home_base_data.party_data.cycle_parties()
	var old_party_name_0: String = PlayerData.home_base_data.party_data.get_parties()[0].name
	var old_party_name_1: String = PlayerData.home_base_data.party_data.get_parties()[1].name
	_convert_to_json_and_back()
	assert_eq(PlayerData.home_base_data.party_data.get_parties()[0].name, old_party_name_0)
	assert_eq(PlayerData.home_base_data.party_data.get_parties()[1].name, old_party_name_1)


func test_convert_to_json_and_back_market() -> void:
	var old_cost_herb_2: int = PlayerData.market.get_cost(Items.Type.HERB_2, Big.new(100)).to_int()
	var old_cost_pizza: int = PlayerData.market.get_cost(Items.Type.FOOD_PIZZA, Big.new(100)).to_int()
	_convert_to_json_and_back()
	assert_eq(PlayerData.market.get_cost(Items.Type.HERB_2, Big.new(100)).to_int(), old_cost_herb_2)
	assert_eq(PlayerData.market.get_cost(Items.Type.FOOD_PIZZA, Big.new(100)).to_int(), old_cost_pizza)


func _convert_to_json_and_back() -> void:
	var result: Dictionary[String, Variant] = PlayerData.to_json_dict()
	result = TestUtils.json_round_trip(result)
	PlayerData.reset()
	PlayerData.from_json_dict(result)


func test_can_spend() -> void:
	PlayerData.peak_gold = Big.new(876)
	PlayerData.gold = Big.new(123)
	
	assert_eq(PlayerData.can_spend(Big.new(100)), true)
	assert_eq(PlayerData.can_spend(Big.new(123)), true)
	assert_eq(PlayerData.can_spend(Big.new(124)), true)
	assert_eq(PlayerData.can_spend(Big.new(500)), false)


func test_can_spend_broke() -> void:
	PlayerData.peak_gold = Big.new(876)
	PlayerData.gold = Big.ZERO
	
	assert_eq(PlayerData.can_spend(Big.new(1)), false)
