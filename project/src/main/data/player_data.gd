extends Node
## Stores the player's army.

var army: Army = Army.new()
var gold: int = 0
var dungeons: Array[Dungeon] = []
var dungeon_index: int
var home_base_multiplier: int = 1

func reset() -> void:
	army.reset()


func has_current_dungeon() -> bool:
	return dungeon_index < dungeons.size()


func get_dungeon() -> Dungeon:
	return dungeons[dungeon_index]


func get_dungeon_army() -> Army:
	return get_dungeon().army


func initialize_starting_army() -> void:
	for i in range(3):
		var item: Army.ArmyItem = Army.ArmyItem.new()
		
		item.name = GoblinNames.random_name()
		item.type = [Goblins.FIRE, Goblins.WATER, Goblins.GRASS].pick_random()
		item.hp_max = randi_range(2, 4)
		item.hp = item.hp_max
		
		for _i in range(2):
			if randf() < 0.5:
				item.level_up()
		
		army.add_item(item)
	
	gold = 25


func add_dungeon(target_attack: int) -> void:
	dungeons.append(DungeonGenerator.generate_random_dungeon(target_attack))


func scale_army_units(factor: float) -> void:
	for item: Army.ArmyItem in PlayerData.army.items:
		item.count = min(item.count * float(factor), 999_999_999_999_999_999)
		item.experience = min(item.experience * float(factor), 999_999_999_999_999_999)
	for dungeon: Dungeon in PlayerData.dungeons:
		for item: Army.ArmyItem in dungeon.army.items:
			item.count = min(item.count * float(factor), 999_999_999_999_999_999)
			item.experience = min(item.experience * float(factor), 999_999_999_999_999_999)
	gold = min(gold * float(factor), 999_999_999_999_999_999)
