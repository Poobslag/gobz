class_name Dungeon

var name: String
var army: Army = Army.new()
var recon_army: Army = Army.new()
var boss: bool = false

func perform_recon(force: bool = false) -> void:
	if not recon_army.is_empty() and not force:
		return
	
	recon_army.reset()
	var recon_count: int = mini(ceili(army.gobs.size() / 2.0), 15)
	var recon_scalar: float = army.gobs.size() / float(recon_count)
	for i in recon_count:
		var gob: Gob = army.gobs[i]
		var recon_gob: Gob = gob.duplicate()
		var scalar: int = Utils.stochastic_roundi(recon_scalar)
		recon_gob.back_count = Big.new((recon_gob.back_count.to_float() + 1) * scalar - 1)
		recon_army.add_gob(recon_gob)


func is_empty() -> bool:
	return army.is_empty()


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	result["name"] = name
	result["army"] = army.to_glob()
	result["recon_army"] = recon_army.to_glob()
	result["boss"] = boss
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	name = json.get("name", "")
	if json.has("army"):
		army.from_glob(json["army"])
	if json.has("recon_army"):
		recon_army.from_glob(json["recon_army"])
	boss = json.get("boss", false)
