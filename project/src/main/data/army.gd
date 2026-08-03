class_name Army
extends Node

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var items: Array[ArmyItem] = []

func reset() -> void:
	items.clear()


func get_total_goblins() -> int:
	var total: int = 0
	for item: ArmyItem in items:
		total += item.count
	return total


func get_total_attack() -> int:
	var total: int = 0
	for item: ArmyItem in items:
		total += item.attack * item.count
	return total


func get_total_gold() -> int:
	var total: int = 0
	for item: ArmyItem in items:
		total += item.gold * item.count
	return total


func add_item(item: ArmyItem) -> void:
	items.append(item)


func level_up(item: ArmyItem) -> void:
	item.hp_max += [1, 2, 2, 3].pick_random()
	item.attack += [1, 2, 2, 3].pick_random()
	if item.type == Goblins.DEVIL:
		item.hp_max += [1, 2, 2, 3].pick_random()
		item.attack += [1, 2, 2, 3].pick_random()
	item.level += 1
	item.experience = 0


func should_level_up(item: ArmyItem) -> bool:
	var exp_factor: int = 4 if item.type == Goblins.DEVIL else 2
	return item.experience > exp_factor * item.level


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
		level_up(item)
		var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
		if item.type == Goblins.DEVIL:
			level_cost *= 2
		item.gold += level_cost
	
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
	
	return item


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
