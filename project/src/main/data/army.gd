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
	var total: float = 0.0
	for gob: Gob in gobs:
		total += gob.get_count().to_float()
	return Big.new(total)


func get_total_attack() -> Big:
	var total: float = 0.0
	for gob: Gob in gobs:
		total += gob.get_total_attack().to_float()
	return Big.new(total)


func get_total_gold() -> Big:
	var total: float = 0.0
	for gob: Gob in gobs:
		total += gob.gold * gob.get_count().to_float()
	return Big.new(total)


func add_gob(gob: Gob) -> void:
	gobs.append(gob)


func remove_gob(gob: Gob) -> void:
	gobs.erase(gob)


func is_empty() -> bool:
	return gobs.is_empty()


## The following dictionary keys are supported:
## 	'type' (Gobs.Type): Goblin type to assign[br]
## 	'type_weights' (Array[float]): Array of five weights for fire/water/grass/angel/devil goblins[br]
## 	'level' (int): Goblin level
## 	'gold_factor' (float): Multiply the goblin's gold
## 	'count' (Big): Total goblins
func generate_random_recruit(data: Dictionary[String, Variant] = {}) -> Gob:
	var gob: Gob = PlayerData.create_gob()
	gob.name = GoblinNames.random_name()
	
	# calculate type
	if data.has("type"):
		gob.type = data["type"]
	else:
		var types: Array[Gobs.Type] = \
				[Gobs.FIRE, Gobs.WATER, Gobs.GRASS, Gobs.ANGEL, Gobs.DEVIL]
		var weights: PackedFloat32Array = [1.0, 1.0, 1.0, 1.0, 1.0]
		if data.has("type_weights"):
			weights = data["type_weights"]
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
		target_level = randi_range(1, data.get("max_level", 8))
	while gob.level < target_level:
		gob.level_up()
	
	gob.xp = randi_range(0, gob.get_exp_threshold() - 1)
	var fractional_level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if gob.type == Gobs.DEVIL:
		fractional_level_cost *= 2
	fractional_level_cost = roundi(fractional_level_cost * \
			gob.xp / float(gob.get_exp_threshold()))
	gob.gold += fractional_level_cost
	
	# adjust price
	gob.gold = roundi(Utils.apply_market_whim(gob.gold))
	gob.gold = maxi(gob.gold, 1)
	if data.has("gold_factor"):
		var gold_float: float = gob.gold
		gob.gold = maxi(1, Utils.stochastic_roundi(gold_float * data["gold_factor"]))
	
	if data.has("count"):
		gob.back_count = Big.new((gob.back_count.to_float() + 1) * data["count"].to_float() - 1)
	
	gob.morale.randomize_value()
	
	return gob


func get_summary() -> ArmySummary:
	var result: ArmySummary = ArmySummary.new()
	
	var total_goblins: float = 0.0
	var total_attack: float = 0.0
	var goblins_by_type: Dictionary[Gobs.Type, float] = {}
	var wounded_by_type: Dictionary[Gobs.Type, float] = {}
	var attack_by_type: Dictionary[Gobs.Type, float] = {}
	var total_gold: float = 0.0
	
	for goblin_type: Gobs.Type in Gobs.Type.values():
		goblins_by_type[goblin_type] = 0.0
		attack_by_type[goblin_type] = 0.0
		wounded_by_type[goblin_type] = 0.0
	
	for gob: Gob in gobs:
		goblins_by_type[gob.type] += gob.get_count().to_float()
		total_goblins += gob.get_count().to_float()
		attack_by_type[gob.type] += gob.get_total_attack().to_float()
		wounded_by_type[gob.type] += gob.get_wounded_count().to_float()
		total_attack += gob.get_total_attack().to_float()
		total_gold += gob.gold * gob.get_count().to_float()
	
	result.total_goblins = Big.new(total_goblins)
	result.total_attack = Big.new(total_attack)
	for type: Gobs.Type in Gobs.Type.values():
		result.goblins_by_type[type] = Big.new(goblins_by_type[type])
		result.wounded_by_type[type] = Big.new(wounded_by_type[type])
		result.attack_by_type[type] = Big.new(attack_by_type[type])
	result.total_gold = Big.new(total_gold)
	
	return result


func get_average_morale() -> float:
	var count: float = PlayerData.army.get_total_goblins().to_float()
	if count == 0.0:
		return 0.0
	var morale_sum: float = 0
	for gob: Gob in PlayerData.army.gobs:
		morale_sum += gob.get_count().to_float() * gob.morale.value
	return morale_sum / count


func get_average_morale_by_type() -> Dictionary[Gobs.Type, float]:
	var morale_sum_by_type: Dictionary[Gobs.Type, float] = {}
	var count_by_type: Dictionary[Gobs.Type, float] = {}
	for type: Gobs.Type in Gobs.Type.values():
		morale_sum_by_type[type] = 0.0
		count_by_type[type] = 0.0
	var result: Dictionary[Gobs.Type, float] = {}
	for gob: Gob in PlayerData.army.gobs:
		morale_sum_by_type[gob.type] += gob.get_count().to_float() * gob.morale.value
		count_by_type[gob.type] += gob.get_count().to_float()
	for type: Gobs.Type in Gobs.Type.values():
		var morale_sum: float = morale_sum_by_type.get(type, 0.0)
		var count: float = count_by_type.get(type, 0.0)
		result[type] = 0.0 if count == 0 else morale_sum / count
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	gold = Big.new(json.get("gold", 0))
	gobs.clear()
	for gob_json: Dictionary in json.get("gobs", []):
		var gob: Gob = PlayerData.create_gob()
		gob.from_json_dict(Utils.typed_json_dict(gob_json))
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
		from_json_dict(Utils.typed_json_dict(test_json_conv.data))


static func json_dict_from_glob(glob: String) -> Dictionary[String, Variant]:
	var compressed_bytes: PackedByteArray = Marshalls.base64_to_raw(glob)
	var json_bytes: PackedByteArray = compressed_bytes.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	var json_str: String = json_bytes.get_string_from_utf8()
	var test_json_conv := JSON.new()
	var result: int = test_json_conv.parse(json_str)
	if result != OK:
		push_error("Error in glob: (%s) %s" % [test_json_conv.get_error_line(), test_json_conv.data])
		return {}
	if not test_json_conv.data is Dictionary:
		push_error("Error in glob: Glob was not a json dictionary.")
		return {}
	return Utils.typed_json_dict(test_json_conv.data)


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
