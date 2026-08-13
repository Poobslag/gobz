class_name Dungeon

var name: String
var army: Army

var recon_army: Army

func perform_recon() -> void:
	recon_army = Army.new()
	var recon_count: int = mini(ceili(army.hordes.size() / 2.0), 15)
	var recon_scalar: float = army.hordes.size() / float(recon_count)
	for i in recon_count:
		var horde: Horde = army.hordes[i]
		var recon_horde: Horde = horde.duplicate()
		var scalar: int = int(recon_scalar)
		if randf() < (recon_scalar - int(recon_scalar)):
			scalar += 1
		recon_horde.count = Big.mul(recon_horde.count, scalar)
		recon_army.add_horde(recon_horde)


func is_empty() -> bool:
	return army.is_empty()
