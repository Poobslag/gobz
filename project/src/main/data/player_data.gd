extends Node
## Stores the player's army.

var army: Army = Army.new()
var gold: int = 0
var dungeons: Array[Dungeon] = []
var current_dungeon: int

func reset() -> void:
	army.reset()


func initialize_starting_army() -> void:
	for i in range(3):
		var item: Army.ArmyItem = Army.ArmyItem.new()
		
		item.type = [Goblins.FIRE, Goblins.WATER, Goblins.GRASS].pick_random()
		item.hp_max = randi_range(2, 4)
		item.hp = item.hp_max
		
		for _i in range(2):
			if randf() < 0.5:
				army.level_up(item)
		
		army.add_item(item)
	
	gold = 25
	
	_add_dungeon(5)
	_add_dungeon(20)
	_add_dungeon(50)
	_add_dungeon(120)
	_add_dungeon(200)


func _add_dungeon(target_attack: int) -> void:
	var dungeon: Dungeon = Dungeon.new()
	dungeon.army = Army.new()
	dungeon.name = DungeonNames.random_name()
	while dungeon.army.get_total_attack() < target_attack:
		dungeon.army.add_item(dungeon.army.generate_random_recruit())
	dungeons.append(dungeon)
