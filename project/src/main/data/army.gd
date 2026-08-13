class_name Army

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var items: Array[ArmyItem] = []
var gold: Big = Big.ZERO

func reset() -> void:
	items.clear()
	gold = Big.ZERO


func duplicate() -> Army:
	var army: Army = Army.new()
	for item: ArmyItem in items:
		army.items.append(item.duplicate())
	return army


func get_total_goblins() -> Big:
	var total: Big = Big.ZERO
	for item: ArmyItem in items:
		total = Big.add(total, item.count)
	return total


func get_total_attack() -> Big:
	var total: Big = Big.ZERO
	for item: ArmyItem in items:
		total = Big.add(total, Big.mul(item.attack, item.count))
	return total


func get_total_gold() -> Big:
	var total: Big = Big.ZERO
	for item: ArmyItem in items:
		total = Big.add(total, Big.mul(item.gold, item.count))
	return total


func add_item(item: ArmyItem) -> void:
	items.append(item)


func remove_item(item: ArmyItem) -> void:
	items.erase(item)


func is_empty() -> bool:
	return items.is_empty()


func generate_random_recruit(data: Dictionary[String, Variant] = {}) -> ArmyItem:
	var item: ArmyItem = ArmyItem.new()
	item.name = GoblinNames.random_name()
	var total_goblins: Big = get_total_goblins()
	
	# calculate type
	if data.has("type"):
		item.type = data["type"]
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
		item.type = types[rng.rand_weighted(weights)]
	
	# initialize attack/hp/cost
	item.attack = [1, 2, 2, 3].pick_random()
	item.hp_max = [3, 4, 4, 5].pick_random()
	if item.type == Goblins.DEVIL:
		item.attack += [1, 2, 2, 3].pick_random()
		item.hp_max += [3, 4, 4, 5].pick_random()
	item.hp = item.hp_max
	var type_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if item.type == Goblins.DEVIL:
		type_cost += [3, 4, 5, 5, 5, 6, 7].pick_random()
	item.gold += type_cost
	
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
	while item.level < target_level:
		item.level_up()
		var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
		if item.type == Goblins.DEVIL:
			level_cost *= 2
		item.gold += level_cost
	
	item.xp = randi_range(0, item.get_exp_threshold() - 1)
	var fractional_level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
	if item.type == Goblins.DEVIL:
		fractional_level_cost *= 2
	fractional_level_cost = roundi(fractional_level_cost * \
			item.xp / float(item.get_exp_threshold()))
	item.gold += fractional_level_cost
	
	# adjust price
	if randf() < 0.2:
		item.gold = ceili(float(item.gold) * 1.5)
		if randf() < 0.2:
			item.gold = ceili(float(item.gold) * 1.5)
	elif randf() < 0.2:
		item.gold = floori(float(item.gold) / 1.5)
		if randf() < 0.2:
			item.gold = floori(float(item.gold) / 1.5)
	item.gold = maxi(item.gold, 1)
	if data.has("gold_factor"):
		var gold_float: float = item.gold
		item.gold = maxi(1, floor(item.gold * data["gold_factor"]))
		if randf() < (gold_float - item.gold):
			item.gold += 1
	
	if data.has("count"):
		item.count = Big.mul(item.count, data["count"])
	
	return item


func get_summary() -> ArmySummary:
	var result: ArmySummary = ArmySummary.new()
	
	for goblin_type: Goblins.GoblinType in Goblins.GoblinType.values():
		result.goblins_by_type[goblin_type] = Big.ZERO
		result.attack_by_type[goblin_type] = Big.ZERO
	
	for army_item: Army.ArmyItem in items:
		result.goblins_by_type[army_item.type] = \
				Big.add(result.goblins_by_type[army_item.type], army_item.count)
		result.total_goblins = \
				Big.add(result.total_goblins, army_item.count)
		result.attack_by_type[army_item.type] = \
				Big.add(result.attack_by_type[army_item.type],
				Big.mul(army_item.attack, army_item.count))
		result.total_attack = \
				Big.add(result.total_attack, \
				Big.mul(army_item.attack, army_item.count))
	
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	gold = Big.new(json.get("gold", 0))
	items.clear()
	for item_json: Dictionary in json.get("items", []):
		var typed_item_json: Dictionary[String, Variant] = {}
		typed_item_json.assign(item_json)
		var item: ArmyItem = ArmyItem.new()
		item.from_json_dict(typed_item_json)
		items.append(item)


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {
	}
	result["items"] = []
	for item: ArmyItem in items:
		result["items"].append(item.to_json_dict())
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


class ArmyItem:
	var name: String = ""
	
	## Total goblins
	var count: Big = Big.ONE:
		set(value):
			if value.to_float() - floor(value.to_float()) != 0.0:
				push_error("Error: count was set to a non integer value")
			count = value
	
	## Level for each goblin
	var level: int = 1
	
	## Type of all goblins
	var type: Goblins.GoblinType = Goblins.GoblinType.FIRE
	
	## Max hp for each goblin
	var hp_max: int = 4
	
	## Hp missing from one goblin, if a goblin is wounded
	var hp: int = 4
	
	## Attack for each goblin
	var attack: int = 2
	
	## Gold for each goblin
	var gold: int = 0
	
	## Experience for each goblin
	var xp: int = 0
	
	func duplicate() -> ArmyItem:
		var copy: ArmyItem = ArmyItem.new()
		copy.name = name
		copy.count = count
		copy.gold = gold
		copy.level = level
		copy.type = type
		copy.hp_max = hp_max
		copy.hp = hp
		copy.xp = xp
		copy.attack = attack
		return copy
	
	
	func level_up() -> void:
		xp = max(0, xp - get_exp_threshold())
		var hp_gain: int = 0
		hp_gain += [2, 4, 4, 6].pick_random()
		attack += [1, 2, 2, 3].pick_random()
		if type == Goblins.DEVIL:
			hp_gain += [2, 4, 4, 6].pick_random()
			attack += [1, 2, 2, 3].pick_random()
		var level_cost: int = [3, 4, 5, 5, 5, 6, 7].pick_random()
		if type == Goblins.DEVIL:
			level_cost *= 2
		gold += level_cost
		hp_max += hp_gain
		hp += hp_gain
		level += 1
	
	
	func get_exp_threshold() -> int:
		var exp_factor: int = 4 if type == Goblins.DEVIL else 2
		var level_tmp: int = level
		while level_tmp > 0 and level_tmp % 10 == 0:
			level_tmp /= 10
			exp_factor *= 10
		return maxi(1, (level + 1) * exp_factor)
	
	
	func can_level_up() -> bool:
		return xp >= get_exp_threshold()
	
	
	## Experience points for killing each goblin
	func get_kill_exp() -> int:
		return level + 1
	
	
	func from_json_dict(json: Dictionary[String, Variant]) -> void:
		name = json.get("name", "")
		count = Big.new(json.get("count", 1))
		level = json.get("level", 1)
		type = Goblins.GoblinType.get(json.get("type", "fire").to_upper())
		
		var hp_split: PackedStringArray = json.get("hp", "4/4").split("/")
		hp = int(hp_split[0])
		hp_max = int(hp_split[1])
		
		attack = json.get("attack", 2)
		gold = json.get("gold", 0)
		xp = json.get("xp", 0)
	
	
	func to_json_dict() -> Dictionary[String, Variant]:
		return {
			"name": name,
			"count": count.to_float(),
			"level": level,
			"type": Utils.enum_to_snake_case(Goblins.GoblinType, type),
			"hp": "%s/%s" % [hp, hp_max],
			"attack": attack,
			"gold": gold,
			"xp": xp,
		}


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
