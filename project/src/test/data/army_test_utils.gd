class_name ArmyTestUtils

## Example: "🔥 3" -> Level 3 fire goblin
static func gob(s: String) -> Gob:
	var s_split: PackedStringArray = s.split(" ")
	var type: Gobs.Type = Gobs.GOBLIN_TYPES_BY_EMOJI[s_split[0]]
	var level: int = int(s_split[1])
	
	var result: Gob = Gob.new()
	result.name = "%s%s" % [Utils.enum_to_snake_case(Gobs.Type, result.type, "none"), level]
	result.type = type
	var type_cost: int = 5
	if result.type == Gobs.DEVIL:
		type_cost *= 2
	result.gold += type_cost
	result.level = level
	var strength_factor: int = 2 if result.type == Gobs.DEVIL else 1
	result.hp_max += 4 * strength_factor * result.level
	result.attack += 2 * strength_factor * result.level
	result.front_hp = result.hp_max
	result.gold += 5 * strength_factor * result.level
	return result
