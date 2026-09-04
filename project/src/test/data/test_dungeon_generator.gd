extends GutTest

var blueprint: DungeonGenerator.DungeonBlueprint

func before_each() -> void:
	blueprint = DungeonGenerator.DungeonBlueprint.new()


func test_has_advanced_types() -> void:
	var archetype: DungeonGenerator.DungeonArchetype
	
	archetype = DungeonGenerator.DungeonArchetype.new(1.0, ["3 devil", "2 angel", "1"])
	assert_eq(true, archetype.has_advanced_types())
	
	archetype = DungeonGenerator.DungeonArchetype.new(1.0, ["3 fire", "2 water", "1"])
	assert_eq(false, archetype.has_advanced_types())
	
	archetype = DungeonGenerator.DungeonArchetype.new(1.0, ["3", "2", "1", "1"])
	assert_eq(true, archetype.has_advanced_types())


func test_generate() -> void:
	var archetype: DungeonGenerator.DungeonArchetype
	
	archetype = DungeonGenerator.DungeonArchetype.new(1.0, ["3 devil", "2 angel", "1"])
	var composition: Dictionary[String, Variant] = archetype.roll_composition(blueprint)
	assert_eq(composition["types"][0], Gobs.Type.DEVIL)
	assert_eq(composition["types"][1], Gobs.Type.ANGEL)
	assert_false(composition["types"][2] in [Gobs.Type.DEVIL, Gobs.Type.ANGEL])
	assert_eq(composition["weights"], [3.0, 2.0, 1.0])


func test_roll_composition_basic() -> void:
	var archetype: DungeonGenerator.DungeonArchetype
	
	archetype = DungeonGenerator.DungeonArchetype.new(1.0, ["3", "2", "1"])
	blueprint.allow_advanced_types = false
	var composition: Dictionary[String, Variant] = archetype.roll_composition(blueprint)
	assert_false(composition["types"][0] in [Gobs.Type.DEVIL, Gobs.Type.ANGEL])
	assert_false(composition["types"][1] in [Gobs.Type.DEVIL, Gobs.Type.ANGEL])
	assert_false(composition["types"][2] in [Gobs.Type.DEVIL, Gobs.Type.ANGEL])


func test_generate_exact_types() -> void:
	blueprint.forced_types = [Gobs.Type.DEVIL, Gobs.Type.GRASS]
	blueprint.attack = Big.new(50)
	var dungeon: Dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	assert_between(dungeon.army.gobs.size(), 2, 40)
	for gob: Gob in dungeon.army.gobs:
		assert_true(gob.type in [Gobs.Type.DEVIL, Gobs.Type.GRASS])


func test_generate_random_dungeon_gobs_size() -> void:
	var dungeon: Dungeon
	
	blueprint.attack = Big.new(500)
	dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	assert_between(dungeon.army.gobs.size(), 20, 500)
	
	blueprint.attack = Big.new(5_000)
	dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	assert_between(dungeon.army.gobs.size(), 20, 500)
	
	blueprint.attack = Big.new(5_000_000)
	dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	assert_between(dungeon.army.gobs.size(), 20, 500)
	
	blueprint.attack = Big.new(5_000_000_000)
	dungeon = DungeonGenerator.generate_random_dungeon(blueprint)
	assert_between(dungeon.army.gobs.size(), 20, 500)


func test_calculate_boss_dungeon_attack() -> void:
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(0).to_aa(), "800")
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(1).to_aa(), "48.0k")
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(2).to_aa(), "2.8m")
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(3).to_aa(), "172m")
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(10).to_aa(), "483z")
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(100).to_aa(), "5.2dw")
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(1000).to_aa(), "6.9gg")
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(10000).to_aa(), "6.9gg")
	assert_eq(DungeonGenerator.calculate_boss_dungeon_attack(100000).to_aa(), "6.9gg")
