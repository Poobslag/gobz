class_name ArmyTestUtils

## Example: "🔥 3" -> Level 3 fire goblin
static func horde(s: String) -> Horde:
	var s_split: PackedStringArray = s.split(" ")
	var type: Goblins.GoblinType = Goblins.GOBLIN_TYPES_BY_EMOJI[s_split[0]]
	var level: int = int(s_split[1])
	
	var result: Horde = Horde.new()
	result.name = "%s%s" % [Utils.enum_to_snake_case(Goblins.GoblinType, result.type, "none"), level]
	result.type = type
	var type_cost: int = 5
	if result.type == Goblins.DEVIL:
		type_cost *= 2
	result.gold += type_cost
	result.level = level
	var strength_factor: int = 2 if result.type == Goblins.DEVIL else 1
	result.hp_max += 4 * strength_factor * result.level
	result.attack += 2 * strength_factor * result.level
	result.hp = result.hp_max
	result.gold += 5 * strength_factor * result.level
	return result
