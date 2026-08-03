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


func generate_random_recruit() -> Dictionary[String, Variant]:
	var item: ArmyItem = ArmyItem.new()
	item.name = GoblinNames.random_name()
	var cost: int = 0
	var total_goblins: int = get_total_goblins()
	var types: Array[Goblins.GoblinType] = [Goblins.FIRE, Goblins.WATER, Goblins.GRASS, Goblins.ANGEL, Goblins.DEVIL]
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
	cost += type_cost
	
	var max_level_up_count: int
	if total_goblins < 10:
		max_level_up_count = 4
	elif total_goblins < 100:
		max_level_up_count = 6
	else:
		max_level_up_count = 8
	var level_up_count: int = randi_range(0, max_level_up_count)
	for _i in level_up_count:
		level_up(item)
		var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
		if item.type == Goblins.DEVIL:
			cost += level_cost * 2
	
	if randf() < 0.2:
		cost = ceili(float(cost) * 1.5)
		if randf() < 0.2:
			cost = ceili(float(cost) * 1.5)
	elif randf() < 0.2:
		cost = floori(float(cost) / 1.5)
		if randf() < 0.2:
			cost = floori(float(cost) / 1.5)
	cost = maxi(cost, 1)
	
	return {
		"item": item,
		"cost": cost,
	} as Dictionary[String, Variant]


class ArmyItem:
	var name: String = ""
	
	## Total goblins
	var count: int = 1
	
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
