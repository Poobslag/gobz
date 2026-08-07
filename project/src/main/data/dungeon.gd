class_name Dungeon

var name: String
var army: Army

var recon_army: Army

func perform_recon() -> void:
	recon_army = Army.new()
	var recon_count: int = mini(ceili(army.items.size() / 2.0), 15)
	var recon_scalar: float = army.items.size() / float(recon_count)
	for i in recon_count:
		var item: Army.ArmyItem = army.items[i]
		var recon_item: Army.ArmyItem = item.duplicate()
		var scalar: int = int(recon_scalar)
		if randf() < (recon_scalar - int(recon_scalar)):
			scalar += 1
		recon_item.count = Utils.big_mult(recon_item.count, scalar)
		recon_army.add_item(recon_item)


func is_empty() -> bool:
	return army.is_empty()
