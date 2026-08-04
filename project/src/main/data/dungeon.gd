class_name Dungeon

var name: String
var army: Army

func get_vague_army() -> Army:
	var vague_army: Army = Army.new()
	for i in range(0, army.items.size(), 2):
		var item: Army.ArmyItem = army.items[i]
		var vague_item: Army.ArmyItem = item.duplicate()
		if i != army.items.size() - 1:
			vague_item.count *= 2
		vague_army.add_item(vague_item)
	return vague_army


func is_empty() -> bool:
	return army.is_empty()
