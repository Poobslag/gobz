class_name Dungeon

var name: String
var army: Army = Army.new()
var recon_army: Army = Army.new()

func perform_recon() -> void:
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


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	result["name"] = name
	result["army"] = army.to_glob()
	result["recon_army"] = recon_army.to_glob()
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	name = json.get("name", "")
	if json.has("army"):
		army.from_glob(json["army"])
	if json.has("recon_army"):
		recon_army.from_glob(json["recon_army"])
