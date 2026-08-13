class_name ArmyTestUtils

## Example: "🔥 3" -> Level 3 fire goblin
static func army_item(s: String) -> Army.ArmyItem:
	var s_split: PackedStringArray = s.split(" ")
	var type: Goblins.GoblinType = Goblins.GOBLIN_TYPES_BY_EMOJI[s_split[0]]
	var level: int = int(s_split[1])
	
	var item: Army.ArmyItem = Army.ArmyItem.new()
	item.name = "%s%s" % [Utils.enum_to_snake_case(Goblins.GoblinType, item.type, "none"), level]
	item.type = type
	var type_cost: int = 5
	if item.type == Goblins.DEVIL:
		type_cost *= 2
	item.gold += type_cost
	item.level = level
	var strength_factor: int = 2 if item.type == Goblins.DEVIL else 1
	item.hp_max += 4 * strength_factor * item.level
	item.attack += 2 * strength_factor * item.level
	item.hp = item.hp_max
	item.gold += 5 * strength_factor * item.level
	return item
