class_name Army

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var hordes: Array[Horde] = []
var gold: Big = Big.ZERO

func reset() -> void:
	hordes.clear()
	gold = Big.ZERO


func duplicate() -> Army:
	var army: Army = Army.new()
	for horde: Horde in hordes:
		army.hordes.append(horde.duplicate())
	return army


func get_total_goblins() -> Big:
	var total: Big = Big.ZERO
	for horde: Horde in hordes:
		total = Big.add(total, horde.count)
	return total


func get_total_attack() -> Big:
	var total: Big = Big.ZERO
	for horde: Horde in hordes:
		total = Big.add(total, Big.mul(horde.attack, horde.count))
	return total


func get_total_gold() -> Big:
	var total: Big = Big.ZERO
	for horde: Horde in hordes:
		total = Big.add(total, Big.mul(horde.gold, horde.count))
	return total


func add_horde(horde: Horde) -> void:
	hordes.append(horde)


func remove_horde(horde: Horde) -> void:
	hordes.erase(horde)


func is_empty() -> bool:
	return hordes.is_empty()


func generate_random_recruit(data: Dictionary[String, Variant] = {}) -> Horde:
	var horde: Horde = Horde.new()
	horde.name = GoblinNames.random_name()
	var total_goblins: Big = get_total_goblins()
	
	# calculate type
	if data.has("type"):
		horde.type = data["type"]
	else:
		var types: Array[Goblins.GoblinType] = \
				[Goblins.FIRE, Goblins.WATER, Goblins.GRASS, Goblins.ANGEL, Goblins.DEVIL]
		var weights: PackedFloat32Array
		if total_goblins.is_lt(20):
			weights = [1.0, 1.0, 1.0, 0.0, 0.0]
		elif total_goblins.is_lt(200):
			weights = [1.0, 1.0, 1.0, 0.4, 0.4]
		else:
			weights = [1.0, 1.0, 1.0, 1.0, 1.0]
		horde.type = types[rng.rand_weighted(weights)]
	
	# initialize attack/hp/cost
	horde.attack = [1, 2, 2, 3].pick_random()
	horde.hp_max = [3, 4, 4, 5].pick_random()
	if horde.type == Goblins.DEVIL:
		horde.attack += [1, 2, 2, 3].pick_random()
		horde.hp_max += [3, 4, 4, 5].pick_random()
	horde.hp = horde.hp_max
	var type_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if horde.type == Goblins.DEVIL:
		type_cost += [3, 4, 5, 5, 5, 6, 7].pick_random()
	horde.gold += type_cost
	
	# calculate level
	var target_level: int
	if data.has("level"):
		target_level = data["level"]
	else:
		var max_level: int
		if total_goblins.is_lt(10):
			max_level = 4
		elif total_goblins.is_lt(100):
			max_level = 6
		else:
			max_level = 8
		target_level = randi_range(1, max_level)
	while horde.level < target_level:
		horde.level_up()
		var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
		if horde.type == Goblins.DEVIL:
			level_cost *= 2
		horde.gold += level_cost
	
	horde.xp = randi_range(0, horde.get_exp_threshold() - 1)
	var fractional_level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if horde.type == Goblins.DEVIL:
		fractional_level_cost *= 2
	fractional_level_cost = roundi(fractional_level_cost * \
			horde.xp / float(horde.get_exp_threshold()))
	horde.gold += fractional_level_cost
	
	# adjust price
	if randf() < 0.2:
		horde.gold = ceili(float(horde.gold) * 1.5)
		if randf() < 0.2:
			horde.gold = ceili(float(horde.gold) * 1.5)
	elif randf() < 0.2:
		horde.gold = floori(float(horde.gold) / 1.5)
		if randf() < 0.2:
			horde.gold = floori(float(horde.gold) / 1.5)
	horde.gold = maxi(horde.gold, 1)
	if data.has("gold_factor"):
		var gold_float: float = horde.gold
		horde.gold = maxi(1, floor(horde.gold * data["gold_factor"]))
		if randf() < (gold_float - horde.gold):
			horde.gold += 1
	
	if data.has("count"):
		horde.count = Big.mul(horde.count, data["count"])
	
	return horde


func get_summary() -> ArmySummary:
	var result: ArmySummary = ArmySummary.new()
	
	for goblin_type: Goblins.GoblinType in Goblins.GoblinType.values():
		result.goblins_by_type[goblin_type] = Big.ZERO
		result.attack_by_type[goblin_type] = Big.ZERO
	
	for horde: Horde in hordes:
		result.goblins_by_type[horde.type] = \
				Big.add(result.goblins_by_type[horde.type], horde.count)
		result.total_goblins = \
				Big.add(result.total_goblins, horde.count)
		result.attack_by_type[horde.type] = \
				Big.add(result.attack_by_type[horde.type],
				Big.mul(horde.attack, horde.count))
		result.total_attack = \
				Big.add(result.total_attack, \
				Big.mul(horde.attack, horde.count))
	
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	gold = Big.new(json.get("gold", 0))
	hordes.clear()
	for horde_json: Dictionary in json.get("hordes", []):
		var typed_horde_json: Dictionary[String, Variant] = {}
		typed_horde_json.assign(horde_json)
		var horde: Horde = Horde.new()
		horde.from_json_dict(typed_horde_json)
		hordes.append(horde)


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {
	}
	result["hordes"] = []
	for horde: Horde in hordes:
		result["hordes"].append(horde.to_json_dict())
	result["gold"] = gold.to_float()
	return result


func to_glob() -> String:
	var json_str: String = JSON.stringify(to_json_dict())
	var json_bytes: PackedByteArray = json_str.to_utf8_buffer()
	var compressed_bytes: PackedByteArray = json_bytes.compress(FileAccess.COMPRESSION_GZIP)
	return Marshalls.raw_to_base64(compressed_bytes)


func from_glob(glob: String) -> void:
	var compressed_bytes: PackedByteArray = Marshalls.base64_to_raw(glob)
	var json_bytes: PackedByteArray = compressed_bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var json_str: String = json_bytes.get_string_from_utf8()
	var test_json_conv := JSON.new()
	var result: int = test_json_conv.parse(json_str)
	if result != OK:
		push_error("Error in glob: (%s) %s" % [test_json_conv.get_error_line(), test_json_conv.data])
	if test_json_conv.data is Dictionary:
		var json: Dictionary[String, Variant] = {}
		json.assign(test_json_conv.data)
		from_json_dict(json)


class ArmySummary:
	var total_goblins: Big = Big.ZERO
	var total_attack: Big = Big.ZERO
	var goblins_by_type: Dictionary[Goblins.GoblinType, Big] = {}
	var attack_by_type: Dictionary[Goblins.GoblinType, Big] = {}
	
	func _to_string() -> String:
		return str({
			"total_goblins": total_goblins,
			"total_attack": total_attack,
			"goblins_by_type": goblins_by_type,
			"attack_by_type": attack_by_type,
		})
