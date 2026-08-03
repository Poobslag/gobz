extends Node
## Stores the player's army.

var army: Army = Army.new()
var gold: int = 0

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
