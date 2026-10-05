class_name Army

## When there are too many gobs in an army, we merge the smallest gobs, compressing the army in a lossy way.
const MAX_GOB_COUNT: int = 500
const MERGE_FACTOR: float = 0.7

## When there are too few gobs in an army, we split the smallest gobs, growing the army.
const MIN_GOB_COUNT: int = 50
const SPLIT_FACTOR: float = 0.3

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
	match gob.type:
		Gobs.DEVIL: type_cost = roundi(type_cost * Gobs.DEVIL_COST_FACTOR)
		Gobs.ANGEL: type_cost = roundi(type_cost * Gobs.ANGEL_COST_FACTOR)
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
	match gob.type:
		Gobs.DEVIL:
			fractional_level_cost = roundi(fractional_level_cost * 2.0 * 1.35)
		Gobs.ANGEL:
			fractional_level_cost = roundi(fractional_level_cost * 0.65)
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
	return ArmySummary.from_gobs(gobs)


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


func get_gobs_by_id() -> Dictionary[int, Gob]:
	var result: Dictionary[int, Gob] = {}
	for gob: Gob in gobs:
		result[gob.id] = gob
	return result


## Shrinks the army by merging the smallest gobs in pairs.[br]
## [br]
## Pairs are same-typed gobs of similar level and strength. The weaker gob of each pair is absorbed into the stronger
## one, so this is lossy. Gobs of different types are never merged.
func merge_small_gobs() -> void:
	var result: Array[Gob] = []
	var sorted_gobs: Array[Gob] = gobs.duplicate()
	
	# sort the gobs by size, and spit the largest gobs directly to result
	sorted_gobs.shuffle()
	sorted_gobs.sort_custom(func(a: Gob, b: Gob) -> bool:
		return a.back_count.to_float() < b.back_count.to_float())
	var paired_gob_count: int = floori(MERGE_FACTOR * sorted_gobs.size() * 0.5) * 2
	result.append_array(sorted_gobs.slice(paired_gob_count))
	sorted_gobs.resize(paired_gob_count)
	
	# sort the smallest gobs by type, level, attack, hp_max, xp
	sorted_gobs.shuffle()
	sorted_gobs.sort_custom(func(a: Gob, b: Gob) -> bool:
		if a.type != b.type:
			return a.type < b.type
		if a.level != b.level:
			return a.level < b.level
		if a.attack != b.attack:
			return a.attack < b.attack
		if a.hp_max != b.hp_max:
			return a.hp_max < b.hp_max
		return a.xp < b.xp)
	
	# pair up smallest neighboring gobs, excluding gobs of different types
	for i in range(0, sorted_gobs.size(), 2):
		var gob_a: Gob = sorted_gobs[i]
		var gob_b: Gob = sorted_gobs[i + 1]
		if gob_a.type != gob_b.type:
			result.append(gob_a)
			result.append(gob_b)
		else:
			result.append(Gobs.merge_gob(gob_a, gob_b))
	
	Global.print_verbose("Merged small gobs: %s->%s" % [gobs.size(), result.size()])
	gobs = result


func has_splittable_gobs() -> bool:
	var result: bool = false
	for gob: Gob in gobs:
		if gob.back_count.is_gt(0):
			result = true
			break
	return result


func merge_gob(gob_a: Gob, gob_b: Gob) -> Gob:
	var absorbed_gob: Gob
	var survivor_gob: Gob = Gobs.merge_gob(gob_a, gob_b)
	if survivor_gob == null:
		# attempting to merge a gob with itself
		pass
	else:
		absorbed_gob = gob_a if survivor_gob == gob_b else gob_b
		remove_gob(absorbed_gob)
	return survivor_gob


func split_gob(gob: Gob, requested_count: Big) -> Gob:
	var new_gob: Gob = Gobs.split_gob(gob, requested_count)
	if new_gob != null:
		add_gob(new_gob)
	return new_gob


## Grows the army by splitting oversized gobs into smaller ones.[br]
## [br]
## The target gob size is the army's total goblin count divided by MIN_GOB_COUNT. Any gob larger than the target size
## is split into gobs of the target size. Gobs which are not oversized are left alone.
func split_large_gobs() -> void:
	var result: Array[Gob] = gobs.duplicate()
	
	var target_gob_size: float = ceilf(get_total_goblins().to_float() / MIN_GOB_COUNT)
	for i in result.size():
		var gob: Gob = result[i]
		var split_count: float = ceilf(gob.get_count().to_float() / target_gob_size - 1)
		for _j in split_count:
			var new_gob: Gob = Gobs.split_gob(gob, Big.new(target_gob_size))
			if new_gob != null:
				result.append(new_gob)
	
	Global.print_verbose("Split large gobs: %s->%s" % [gobs.size(), result.size()])
	gobs = result


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
