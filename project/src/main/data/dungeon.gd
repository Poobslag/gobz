class_name Dungeon

var name: String
var army: Army

func get_vague_army() -> Army:
	var vague_army: Army = Army.new()
	var vague_count: int = mini(ceili(army.items.size() / 2.0), 15)
	var vague_scalar: float = army.items.size() / float(vague_count)
	for i in vague_count:
		var item: Army.ArmyItem = army.items[i]
		var vague_item: Army.ArmyItem = item.duplicate()
		var scalar: int = int(vague_scalar)
		if randf() < (vague_scalar - int(vague_scalar)):
			scalar += 1
		vague_item.count = Utils.big_mult(vague_item.count, scalar)
		vague_army.add_item(vague_item)
	
	return vague_army


func is_empty() -> bool:
	return army.is_empty()
