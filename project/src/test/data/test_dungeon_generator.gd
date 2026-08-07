extends GutTest

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
	var composition: Dictionary[String, Variant] = archetype.roll_composition()
	assert_eq(composition["types"][0], Goblins.GoblinType.DEVIL)
	assert_eq(composition["types"][1], Goblins.GoblinType.ANGEL)
	assert_false(composition["types"][2] in [Goblins.GoblinType.DEVIL, Goblins.GoblinType.ANGEL])
	assert_eq(composition["weights"], [3.0, 2.0, 1.0])


func test_generate_basic() -> void:
	var archetype: DungeonGenerator.DungeonArchetype
	
	archetype = DungeonGenerator.DungeonArchetype.new(1.0, ["3", "2", "1"])
	var composition: Dictionary[String, Variant] = archetype.roll_composition(false)
	assert_false(composition["types"][0] in [Goblins.GoblinType.DEVIL, Goblins.GoblinType.ANGEL])
	assert_false(composition["types"][1] in [Goblins.GoblinType.DEVIL, Goblins.GoblinType.ANGEL])
	assert_false(composition["types"][2] in [Goblins.GoblinType.DEVIL, Goblins.GoblinType.ANGEL])
