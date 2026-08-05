class_name Army

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var items: Array[ArmyItem] = []
var gold: int

func reset() -> void:
	items.clear()


func duplicate() -> Army:
	var army: Army = Army.new()
	for item: ArmyItem in items:
		army.items.append(item.duplicate())
	return army


func get_total_goblins() -> int:
	var total: int = 0
	for item: ArmyItem in items:
		total += item.count
	return total


func get_total_attack() -> int:
	var total: int = 0
	for item: ArmyItem in items:
		total = Utils.big_add(total, Utils.big_mult(item.attack, item.count))
	return total


func get_total_gold() -> int:
	var total: int = 0
	for item: ArmyItem in items:
		total = Utils.big_add(total, Utils.big_mult(item.gold, item.count))
	return total


func add_item(item: ArmyItem) -> void:
	items.append(item)


func remove_item(item: ArmyItem) -> void:
	items.erase(item)


func is_empty() -> bool:
	return items.is_empty()


func generate_random_recruit(data: Dictionary[String, Variant] = {}) -> ArmyItem:
	var item: ArmyItem = ArmyItem.new()
	item.name = GoblinNames.random_name()
	var total_goblins: int = get_total_goblins()
	
	# calculate type
	if data.has("type"):
		item.type = data["type"]
	else:
		var types: Array[Goblins.GoblinType] = \
				[Goblins.FIRE, Goblins.WATER, Goblins.GRASS, Goblins.ANGEL, Goblins.DEVIL]
		var weights: PackedFloat32Array
		if total_goblins < 20:
			weights = [1.0, 1.0, 1.0, 0.0, 0.0]
		elif total_goblins < 200:
			weights = [1.0, 1.0, 1.0, 0.4, 0.4]
		else:
			weights = [1.0, 1.0, 1.0, 1.0, 1.0]
		item.type = types[rng.rand_weighted(weights)]
	
	var type_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if item.type == Goblins.DEVIL:
		type_cost *= 2
	item.gold += type_cost
	
	# calculate level
	var target_level: int
	if data.has("level"):
		target_level = data["level"]
	else:
		var max_level: int
		if total_goblins < 10:
			max_level = 4
		elif total_goblins < 100:
			max_level = 6
		else:
			max_level = 8
		target_level = randi_range(1, max_level)
	while item.level < target_level:
		item.level_up()
		var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
		if item.type == Goblins.DEVIL:
			level_cost *= 2
		item.gold += level_cost
	
	item.experience = int(randf_range(0, item.get_exp_threshold()))
	var fractional_level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if item.type == Goblins.DEVIL:
		fractional_level_cost *= 2
	fractional_level_cost = roundi(fractional_level_cost * float(item.experience) / item.get_exp_threshold())
	item.gold += fractional_level_cost
	
	# adjust price
	if randf() < 0.2:
		item.gold = ceili(float(item.gold) * 1.5)
		if randf() < 0.2:
			item.gold = ceili(float(item.gold) * 1.5)
	elif randf() < 0.2:
		item.gold = floori(float(item.gold) / 1.5)
		if randf() < 0.2:
			item.gold = floori(float(item.gold) / 1.5)
	item.gold = maxi(item.gold, 1)
	
	if data.has("count"):
		item.count *= data["count"]
		item.experience *= data["count"]
	
	return item


func get_summary() -> ArmySummary:
	var result: ArmySummary = ArmySummary.new()
	
	for goblin_type: Goblins.GoblinType in Goblins.GoblinType.values():
		result.goblins_by_type[goblin_type] = 0
		result.attack_by_type[goblin_type] = 0
	
	for army_item: Army.ArmyItem in items:
		result.goblins_by_type[army_item.type] = \
				Utils.big_add(result.goblins_by_type[army_item.type], army_item.count)
		result.total_goblins = \
				Utils.big_add(result.total_goblins, army_item.count)
		result.attack_by_type[army_item.type] = \
				Utils.big_add(result.attack_by_type[army_item.type],
				Utils.big_mult(army_item.attack, army_item.count))
		result.total_attack = \
				Utils.big_add(result.total_attack, \
				Utils.big_mult(army_item.attack, army_item.count))
	
	return result


class ArmyItem:
	var name: String = ""
	
	## Total goblins
	var count: int = 1
	
	## Gold for each goblin
	var gold: int = 0
	
	## Average goblin level
	var level: int = 1
	
	## Type of all goblins
	var type: Goblins.GoblinType = Goblins.GoblinType.FIRE
	
	## Max hp for each goblin
	var hp_max: int = 4
	
	## Hp missing from one goblin, if a goblin is wounded
	var hp: int = 4
	
	## Sum of all experience points toward the next level
	var experience: int = 0
	
	## Attack for each goblin
	var attack: int = 2
	
	func duplicate() -> ArmyItem:
		var copy: ArmyItem = ArmyItem.new()
		copy.name = name
		copy.count = count
		copy.gold = gold
		copy.level = level
		copy.type = type
		copy.hp_max = hp_max
		copy.hp = hp
		copy.experience = experience
		copy.attack = attack
		return copy
	
	
	func level_up() -> void:
		experience = maxi(0, experience - get_exp_threshold())
		var hp_gain: int = 0
		hp_gain += [1, 2, 2, 3].pick_random()
		attack += [1, 2, 2, 3].pick_random()
		if type == Goblins.DEVIL:
			hp_gain += [1, 2, 2, 3].pick_random()
			attack += [1, 2, 2, 3].pick_random()
		var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
		if type == Goblins.DEVIL:
			level_cost *= 2
		gold += level_cost
		hp_max += hp_gain
		hp += hp_gain
		level += 1
	
	
	func get_exp_threshold() -> int:
		var exp_factor: int = 4 if type == Goblins.DEVIL else 2
		if level % 10 == 0:
			exp_factor *= 10
		if level % 100 == 0:
			exp_factor *= 10
		return maxi(1, (level + 1) * exp_factor * count)
	
	
	func can_level_up() -> bool:
		return experience > get_exp_threshold()
	
	
	## Experience points for killing each goblin
	func get_kill_exp() -> int:
		return level + 1


class ArmySummary:
	var total_goblins: int
	var total_attack: int
	var goblins_by_type: Dictionary[Goblins.GoblinType, int] = {}
	var attack_by_type: Dictionary[Goblins.GoblinType, int] = {}
