class_name DungeonGenerator

static var _archetypes_by_slot_count: Dictionary[int, Array] = {
	1: [
		DungeonArchetype.new(2.0, ["1"])
	] as Array[DungeonArchetype],
	2: [
		DungeonArchetype.new(4.0, ["1", "1"]),
		# focused on 1
		DungeonArchetype.new(2.0, ["3", "1"]),
		DungeonArchetype.new(2.0, ["5", "1"]),
		# other
		DungeonArchetype.new(0.5, ["1 devil", "1 angel"]),
		DungeonArchetype.new(0.5, ["3 devil", "1 angel"]),
	] as Array[DungeonArchetype],
	3: [
		DungeonArchetype.new(4.0, ["1", "1", "1"]),
		# focused on 1
		DungeonArchetype.new(2.0, ["3", "1", "1"]),
		DungeonArchetype.new(2.0, ["5", "1", "1"]),
		# focused on 2
		DungeonArchetype.new(2.0, ["3", "3", "1"]),
		DungeonArchetype.new(2.0, ["5", "5", "1"]),
		# ramps
		DungeonArchetype.new(2.0, ["3", "2", "1"]),
		DungeonArchetype.new(2.0, ["5", "3", "1"]),
		# other
		DungeonArchetype.new(0.5, ["1 devil", "1 angel", "1"]),
		DungeonArchetype.new(0.5, ["1 fire", "1 water", "1 grass"]),
	] as Array[DungeonArchetype],
	4: [
		DungeonArchetype.new(8.0, ["1", "1", "1", "1"]),
		# focused on 1
		DungeonArchetype.new(3.0, ["3", "1", "1", "1"]),
		DungeonArchetype.new(3.0, ["5", "1", "1", "1"]),
		DungeonArchetype.new(3.0, ["8", "1", "1", "1"]),
		# focused on 2
		DungeonArchetype.new(4.0, ["3", "3", "1", "1"]),
		DungeonArchetype.new(4.0, ["5", "5", "1", "1"]),
		# focused on 3
		DungeonArchetype.new(4.0, ["3", "3", "3", "1"]),
		DungeonArchetype.new(4.0, ["5", "5", "5", "1"]),
		# ramps
		DungeonArchetype.new(3.0, ["6", "5", "4", "3"]),
		DungeonArchetype.new(3.0, ["4", "3", "2", "1"]),
		DungeonArchetype.new(3.0, ["8", "4", "2", "1"]),
		# other
		DungeonArchetype.new(0.5, ["2 devil", "2 angel", "1", "1"]),
	] as Array[DungeonArchetype],
	5: [
		DungeonArchetype.new(8.0, ["1", "1", "1", "1", "1"]),
		# focused on 1
		DungeonArchetype.new(3.0, ["3", "1", "1", "1", "1"]),
		DungeonArchetype.new(3.0, ["5", "1", "1", "1", "1"]),
		DungeonArchetype.new(3.0, ["8", "1", "1", "1", "1"]),
		# focused on 2
		DungeonArchetype.new(3.0, ["3", "3", "1", "1", "1"]),
		DungeonArchetype.new(3.0, ["5", "5", "1", "1", "1"]),
		DungeonArchetype.new(3.0, ["8", "8", "1", "1", "1"]),
		# focused on 3
		DungeonArchetype.new(3.0, ["3", "3", "3", "1", "1"]),
		DungeonArchetype.new(3.0, ["5", "5", "5", "1", "1"]),
		DungeonArchetype.new(3.0, ["8", "8", "8", "1", "1"]),
		# focused on 4
		DungeonArchetype.new(3.0, ["3", "3", "3", "3", "1"]),
		DungeonArchetype.new(3.0, ["5", "5", "5", "5", "1"]),
		DungeonArchetype.new(3.0, ["8", "8", "8", "8", "1"]),
		# ramps
		DungeonArchetype.new(2.0, ["8", "7", "6", "5", "4"]),
		DungeonArchetype.new(2.0, ["5", "4", "3", "2", "1"]),
		DungeonArchetype.new(2.0, ["8", "5", "3", "2", "1"]),
		DungeonArchetype.new(2.0, ["16", "8", "4", "2", "1"]),
		# other
		DungeonArchetype.new(0.5, ["3 devil", "3 angel", "1", "1", "1"]),
	] as Array[DungeonArchetype],
}

static var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

static func _generate_random_composition(allow_advanced_types: bool = true) -> Dictionary[String, Variant]:
	var slot_count: int
	if allow_advanced_types:
		slot_count = [1, 2, 3, 4, 5][_rng.rand_weighted([1, 2, 4, 4, 4])]
	else:
		slot_count = [1, 2, 3][_rng.rand_weighted([1, 2, 4])]
	
	var weights: Array[float] = []
	var archetypes: Array[DungeonArchetype] = _archetypes_by_slot_count[slot_count]
	for archetype: DungeonArchetype in archetypes:
		if archetype.has_advanced_types() and not allow_advanced_types:
			weights.append(0)
		else:
			weights.append(archetype.rarity)
	var archetype: DungeonArchetype = archetypes[_rng.rand_weighted(weights)]
	return archetype.roll_composition(allow_advanced_types)


static func _generate_dungeon_for_archetype(target_attack: Big, composition: Dictionary[String, Variant]) -> Dungeon:
	var min_count: Big = Big.ONE
	var max_count: Big = Big.ONE
	if target_attack.is_gte(500):
		min_count = Big.new(maxf(1, round(target_attack.to_float() * 0.0003)))
		max_count = Big.new(maxf(1, round(target_attack.to_float() * 0.0008)))
	
	var dungeon: Dungeon = Dungeon.new()
	dungeon.name = DungeonNames.random_name()
	var mercy: int = 0
	var total_attack: Big = Big.ZERO
	while total_attack.is_lt(target_attack) and mercy < 1000:
		var count: Big = Big.new(round(_rng.randf_range(min_count.to_float(), max_count.to_float())))
		var type: Gobs.Type = composition["types"][_rng.rand_weighted(composition["weights"])]
		var new_recruit: Gob = dungeon.army.generate_random_recruit({
			"count": count,
			"type": type,
			"gold_factor": PlayerData.get_ripoff_factor(),
		})
		dungeon.army.add_gob(new_recruit)
		total_attack = Big.add(total_attack, Big.mul(new_recruit.attack, new_recruit.count))
		mercy += 1
	
	return dungeon


static func generate_random_dungeon(target_attack: Big) -> Dungeon:
	var allow_advanced_types: bool = target_attack.is_gte(200)
	var composition: Dictionary[String, Variant] = _generate_random_composition(allow_advanced_types)
	var dungeon: Dungeon = _generate_dungeon_for_archetype(target_attack, composition)
	
	if Global.verbose_stdout_mode:
		print("----------")
		print("Generated new dungeon: %s" % [dungeon.name])
		var composition_json_dict: Dictionary[String, Variant] = {}
		for i: int in composition["types"].size():
			var type: Gobs.Type = composition["types"][i]
			var weight: float = composition["weights"][i]
			composition_json_dict[Utils.enum_to_snake_case(Gobs.Type, type)] = weight
		print("Composition: %s" % [composition_json_dict])
		print("Army (%s gobs): %s" % [dungeon.army.gobs.size(), dungeon.army.get_summary()])
	
	return dungeon


class DungeonArchetype:
	var rarity: float = 1.0
	var strings: Array[String]
	var _advanced_types: bool = false
	
	func _init(init_rarity:float, init_strings: Array[String]) -> void:
		rarity = init_rarity
		strings = init_strings
		
		# populate the 'advanced types' field
		if strings.size() >= 4:
			_advanced_types = true
		else:
			for s: String in strings:
				if s.contains("angel") || s.contains("devil"):
					_advanced_types = true
	
	func roll_composition(allow_advanced_types: bool = true) -> Dictionary[String, Variant]:
		var candidate_types: Array[Gobs.Type] = []
		if allow_advanced_types:
			candidate_types.assign(Gobs.Type.values())
		else:
			candidate_types.assign([Gobs.Type.FIRE, Gobs.Type.WATER, Gobs.Type.GRASS])
		candidate_types.shuffle()
		
		var types: Array[Gobs.Type] = []
		var weights: Array[float] = []
		
		for s: String in strings:
			var split: PackedStringArray = s.split(" ")
			var weight: float = float(split[0])
			var type: Gobs.Type
			if split.size() == 1:
				if candidate_types.is_empty():
					push_warning("No remaining types for '%s'" % [s])
					continue
				type = candidate_types.front()
			else:
				type = Gobs.Type[split[1].to_upper()]
			candidate_types.erase(type)
			weights.append(weight)
			types.append(type)
		
		return {
			"types": types,
			"weights": weights,
		}
	
	
	func has_advanced_types() -> bool:
		return _advanced_types
