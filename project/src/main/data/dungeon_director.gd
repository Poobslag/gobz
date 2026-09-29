class_name DungeonDirector

const DUNGEON_ATTACK_MIN: float = 0.4
const DUNGEON_ATTACK_MAX: float = 1.4
const RAID_DUNGEON_ATTACK_MIN: float = 1.2
const RAID_DUNGEON_ATTACK_MAX: float = 1.8
const RAID_DAYS_START: int = 3

static func cycle_dungeons() -> void:
	remove_empty_dungeons()
	
	# remove one non-boss dungeon
	if not PlayerData.dungeons.is_empty():
		var non_boss_dungeon_index: int = _find_regular_dungeon_index()
		if non_boss_dungeon_index != -1:
			PlayerData.dungeons.remove_at(non_boss_dungeon_index)
	
	# decrement raid_days
	var raid_dungeon_index: int = find_raid_dungeon_index()
	if raid_dungeon_index >= 0:
		var raid_dungeon: Dungeon = PlayerData.dungeons[raid_dungeon_index]
		raid_dungeon.raid_days -= 1
	
	# insert a raid dungeon if we generate a random number smaller than raid_chance
	PlayerData.raid_chance += 0.12
	if raid_dungeon_index == -1 and randf() < PlayerData.raid_chance:
		PlayerData.raid_chance -= 1.0
		var dungeon: Dungeon = generate_raid_dungeon()
		PlayerData.dungeons.append(dungeon)
	
	# insert a boss dungeon if none exists
	var boss_dungeon_index: int = _find_boss_dungeon_index()
	if boss_dungeon_index == -1:
		var dungeon: Dungeon = generate_boss_dungeon()
		PlayerData.dungeons.insert(0, dungeon)
	
	# fill in non-boss dungeons
	fill_missing_dungeons()


static func remove_empty_dungeons() -> void:
	for i in range(PlayerData.dungeons.size() - 1, -1, -1):
		if PlayerData.dungeons[i].is_empty():
			PlayerData.dungeons.remove_at(i)


static func fill_missing_dungeons() -> void:
	while PlayerData.dungeons.size() < 6:
		var dungeon: Dungeon = generate_regular_dungeon()
		PlayerData.dungeons.append(dungeon)


static func generate_regular_dungeon() -> Dungeon:
	var blueprint: DungeonGenerator.DungeonBlueprint = regular_dungeon_blueprint()
	var dungeon: Dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	return dungeon


static func regular_dungeon_blueprint() -> DungeonGenerator.DungeonBlueprint:
	var blueprint: DungeonGenerator.DungeonBlueprint = DungeonGenerator.DungeonBlueprint.new()
	blueprint.attack = Big.new(PlayerData.army.get_total_attack().to_float() \
			* randf_range(DUNGEON_ATTACK_MIN, DUNGEON_ATTACK_MAX))
	blueprint.gold_factor = DungeonGenerator.RIPOFF_FACTOR
	var boss_dungeon_index: int = _find_boss_dungeon_index()
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
	return blueprint


static func generate_raid_dungeon() -> Dungeon:
	var blueprint: DungeonGenerator.DungeonBlueprint = regular_dungeon_blueprint()
	blueprint.attack = Big.new(PlayerData.army.get_total_attack().to_float() \
			* randf_range(RAID_DUNGEON_ATTACK_MIN, RAID_DUNGEON_ATTACK_MAX))
	var dungeon: Dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	dungeon.raid_days = RAID_DAYS_START
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


static func find_raid_dungeon_index() -> int:
	return PlayerData.dungeons.find_custom(func(dungeon: Dungeon) -> bool:
		return dungeon.raid_days >= 0)


static func _find_boss_dungeon_index() -> int:
	return PlayerData.dungeons.find_custom(func(dungeon: Dungeon) -> bool:
		return dungeon.boss)


static func _find_regular_dungeon_index() -> int:
	return PlayerData.dungeons.find_custom(func(dungeon: Dungeon) -> bool:
		return not dungeon.boss and dungeon.raid_days == -1)
