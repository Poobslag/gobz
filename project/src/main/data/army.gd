class_name Army

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var gobs: Array[Gob] = []

## Gold accrued during a battle by killing enemies.
var gold: Big = Big.ZERO

func reset() -> void:
	gobs.clear()
	gold = Big.ZERO


func duplicate() -> Army:
	var army: Army = Army.new()
	for gob: Gob in gobs:
		army.gobs.append(gob.duplicate())
	return army


func get_total_goblins() -> Big:
	var total: Big = Big.ZERO
	for gob: Gob in gobs:
		total = Big.add(total, gob.get_count())
	return total


func get_total_attack() -> Big:
	var total: Big = Big.ZERO
	for gob: Gob in gobs:
		total = Big.add(total, gob.get_total_attack())
	return total


func get_total_gold() -> Big:
	var total: Big = Big.ZERO
	for gob: Gob in gobs:
		total = Big.add(total, Big.mul(gob.gold, gob.get_count()))
	return total


func add_gob(gob: Gob) -> void:
	gobs.append(gob)


func remove_gob(gob: Gob) -> void:
	gobs.erase(gob)


func is_empty() -> bool:
	return gobs.is_empty()


func generate_random_recruit(data: Dictionary[String, Variant] = {}) -> Gob:
	var gob: Gob = Gob.new()
	gob.name = GoblinNames.random_name()
	var total_goblins: Big = get_total_goblins()
	
	# calculate type
	if data.has("type"):
		gob.type = data["type"]
	else:
		var types: Array[Gobs.Type] = \
				[Gobs.FIRE, Gobs.WATER, Gobs.GRASS, Gobs.ANGEL, Gobs.DEVIL]
		var weights: PackedFloat32Array
		if total_goblins.is_lt(20):
			weights = [1.0, 1.0, 1.0, 0.0, 0.0]
		elif total_goblins.is_lt(200):
			weights = [1.0, 1.0, 1.0, 0.4, 0.4]
		else:
			weights = [1.0, 1.0, 1.0, 1.0, 1.0]
		gob.type = types[rng.rand_weighted(weights)]
	
	# initialize attack/hp/cost
	gob.attack = [1, 2, 2, 3].pick_random()
	gob.hp_max = [3, 4, 4, 5].pick_random()
	if gob.type == Gobs.DEVIL:
		gob.attack += [1, 2, 2, 3].pick_random()
		gob.hp_max += [3, 4, 4, 5].pick_random()
	gob.front_hp = gob.hp_max
	var type_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if gob.type == Gobs.DEVIL:
		type_cost += [3, 4, 5, 5, 5, 6, 7].pick_random()
	gob.gold += type_cost
	
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
	while gob.level < target_level:
		gob.level_up()
		var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
		if gob.type == Gobs.DEVIL:
			level_cost *= 2
		gob.gold += level_cost
	
	gob.xp = randi_range(0, gob.get_exp_threshold() - 1)
	var fractional_level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if gob.type == Gobs.DEVIL:
		fractional_level_cost *= 2
	fractional_level_cost = roundi(fractional_level_cost * \
			gob.xp / float(gob.get_exp_threshold()))
	gob.gold += fractional_level_cost
	
	# adjust price
	if randf() < 0.2:
		gob.gold = ceili(float(gob.gold) * 1.5)
		if randf() < 0.2:
			gob.gold = ceili(float(gob.gold) * 1.5)
	elif randf() < 0.2:
		gob.gold = floori(float(gob.gold) / 1.5)
		if randf() < 0.2:
			gob.gold = floori(float(gob.gold) / 1.5)
	gob.gold = maxi(gob.gold, 1)
	if data.has("gold_factor"):
		var gold_float: float = gob.gold
		gob.gold = maxi(1, floor(gob.gold * data["gold_factor"]))
		if randf() < (gold_float - gob.gold):
			gob.gold += 1
	
	if data.has("count"):
		gob.back_count = Big.new((gob.back_count.to_float() + 1) * data["count"].to_float() - 1)
	
	return gob


func get_summary() -> ArmySummary:
	var result: ArmySummary = ArmySummary.new()
	
	for goblin_type: Gobs.Type in Gobs.Type.values():
		result.goblins_by_type[goblin_type] = Big.ZERO
		result.attack_by_type[goblin_type] = Big.ZERO
		result.wounded_by_type[goblin_type] = Big.ZERO
	
	for gob: Gob in gobs:
		result.goblins_by_type[gob.type] = \
				Big.add(result.goblins_by_type[gob.type], gob.get_count())
		result.total_goblins = \
				Big.add(result.total_goblins, gob.get_count())
		result.attack_by_type[gob.type] = \
				Big.add(result.attack_by_type[gob.type], gob.get_total_attack())
		result.wounded_by_type[gob.type] = \
				Big.add(result.wounded_by_type[gob.type], gob.get_wounded_count())
		result.total_attack = \
				Big.add(result.total_attack, gob.get_total_attack())
		result.total_gold = \
				Big.add(result.total_gold, \
				Big.mul(gob.gold, gob.get_count()))
	
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	gold = Big.new(json.get("gold", 0))
	gobs.clear()
	for gob_json: Dictionary in json.get("gobs", []):
		var typed_gob_json: Dictionary[String, Variant] = {}
		typed_gob_json.assign(gob_json)
		var gob: Gob = Gob.new()
		gob.from_json_dict(typed_gob_json)
		gobs.append(gob)


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	result["gobs"] = []
	for gob: Gob in gobs:
		result["gobs"].append(gob.to_json_dict())
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


static func json_dict_from_glob(glob: String) -> Dictionary[String, Variant]:
	var json: Dictionary[String, Variant] = {}
	var compressed_bytes: PackedByteArray = Marshalls.base64_to_raw(glob)
	var json_bytes: PackedByteArray = compressed_bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var json_str: String = json_bytes.get_string_from_utf8()
	var test_json_conv := JSON.new()
	var result: int = test_json_conv.parse(json_str)
	if result != OK:
		push_error("Error in glob: (%s) %s" % [test_json_conv.get_error_line(), test_json_conv.data])
	if not test_json_conv.data is Dictionary:
		push_error("Error in glob: Glob was not a json dictionary.")
	else:
		json.assign(test_json_conv.data)
	return json


static func glob_from_json_dict(json: Dictionary[String, Variant]) -> String:
	var json_str: String = JSON.stringify(json)
	var json_bytes: PackedByteArray = json_str.to_utf8_buffer()
	var compressed_bytes: PackedByteArray = json_bytes.compress(FileAccess.COMPRESSION_GZIP)
	return Marshalls.raw_to_base64(compressed_bytes)


class ArmySummary:
	var total_goblins: Big = Big.ZERO
	var total_attack: Big = Big.ZERO
	var goblins_by_type: Dictionary[Gobs.Type, Big] = {}
	var wounded_by_type: Dictionary[Gobs.Type, Big] = {}
	var attack_by_type: Dictionary[Gobs.Type, Big] = {}
	var total_gold: Big = Big.ZERO
	
	func _to_string() -> String:
		return str({
			"total_goblins": total_goblins,
			"total_attack": total_attack,
			"goblins_by_type": goblins_by_type,
			"wounded_by_type": wounded_by_type,
			"attack_by_type": attack_by_type,
			"total_gold": total_gold,
		})
