class_name DungeonDirector

static func cycle_dungeons() -> void:
	# remove all empty dungeons
	for i in range(PlayerData.dungeons.size() - 1, -1, -1):
		if PlayerData.dungeons[i].is_empty():
			PlayerData.dungeons.remove_at(i)
	
	# remove one non-boss dungeon
	if not PlayerData.dungeons.is_empty():
		var non_boss_dungeon_index: int = _find_non_boss_dungeon_index()
		if non_boss_dungeon_index != -1:
			PlayerData.dungeons.remove_at(non_boss_dungeon_index)
	
	# append a boss dungeon if none exists
	var boss_dungeon_index: int = _find_boss_dungeon_index()
	if boss_dungeon_index == -1:
		var dungeon: Dungeon = generate_boss_dungeon()
		PlayerData.dungeons.append(dungeon)
	
	# fill in non-boss dungeons
	while PlayerData.dungeons.size() < 6:
		var dungeon: Dungeon = generate_regular_dungeon()
		PlayerData.dungeons.append(dungeon)


static func generate_regular_dungeon() -> Dungeon:
	var boss_dungeon_index: int = _find_boss_dungeon_index()
	var blueprint: DungeonGenerator.DungeonBlueprint = DungeonGenerator.DungeonBlueprint.new()
	blueprint.attack = Big.new(PlayerData.army.get_total_attack().to_float() * randf_range(0.4, 1.4))
	blueprint.gold_factor = DungeonGenerator.RIPOFF_FACTOR
	if boss_dungeon_index != -1:
		var boss_dungeon: Dungeon = PlayerData.dungeons[boss_dungeon_index]
		var boss_growth_cap: Big = Big.new(boss_dungeon.army.get_total_attack().to_float() \
				* DungeonGenerator.BOSS_PROGRESS_CAP / DungeonGenerator.RIPOFF_FACTOR)
		if blueprint.attack.is_gt(boss_growth_cap):
			if PlayerData.should_log_gold_history:
				print("Capping dungeon size (%s > %s)" \
						% [blueprint.attack.to_aa(), boss_growth_cap.to_aa()])
			blueprint.attack = boss_growth_cap
	blueprint.allow_advanced_types = PlayerData.bosses_defeated >= 1
	var dungeon: Dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	return dungeon


static func generate_boss_dungeon() -> Dungeon:
	var blueprint: DungeonGenerator.DungeonBlueprint = DungeonGenerator.DungeonBlueprint.new()
	blueprint.attack = DungeonGenerator.calculate_boss_dungeon_attack(PlayerData.bosses_defeated)
	blueprint.gold_factor = DungeonGenerator.BOSS_REWARD_MULTIPLIER
	match PlayerData.bosses_defeated:
		0:
			blueprint.forced_types = [[Gobs.FIRE, Gobs.WATER, Gobs.GRASS].pick_random()]
		1:
			blueprint.forced_types = [Gobs.DEVIL, [Gobs.FIRE, Gobs.WATER, Gobs.GRASS].pick_random()]
	var dungeon: Dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	dungeon.name = "👑 %s" % [dungeon.name]
	dungeon.boss = true
	return dungeon


static func get_recruit_type_weights(day: int) -> Array[float]:
	# devils start showing up on day 6
	var devil_weight: float = clamp(remap(day, 5, 12, 0.0, 1.0), 0.0, 1.0)
	# angels start showing up on day 10
	var angel_weight: float = clamp(remap(day, 9, 16, 0.0, 1.0), 0.0, 1.0)
	return [1.0, 1.0, 1.0, angel_weight, devil_weight]


static func get_recruit_max_level(day: int) -> int:
	@warning_ignore("narrowing_conversion")
	return clampi(remap(day, 1, 20, 4, 8), 4, 8)


static func _find_boss_dungeon_index() -> int:
	return PlayerData.dungeons.find_custom(func(dungeon: Dungeon) -> bool:
		return dungeon.boss)


static func _find_non_boss_dungeon_index() -> int:
	return PlayerData.dungeons.find_custom(func(dungeon: Dungeon) -> bool:
		return not dungeon.boss)
