class_name Goblins

enum GoblinType {
	FIRE,
	WATER,
	GRASS,
	ANGEL,
	DEVIL,
}

const FIRE: GoblinType = GoblinType.FIRE
const WATER: GoblinType = GoblinType.WATER
const GRASS: GoblinType = GoblinType.GRASS
const ANGEL: GoblinType = GoblinType.ANGEL
const DEVIL: GoblinType = GoblinType.DEVIL

const EMOJIS_BY_GOBLIN_TYPE: Dictionary[GoblinType, String] = {
	FIRE: "🔥",
	WATER: "💧",
	GRASS: "🌳",
	ANGEL: "🕊️",
	DEVIL: "😈",
}

static func army_bbcode(army: Army) -> String:
	var total_goblins: int = 0
	var total_attack: int = 0
	var goblins_by_type: Dictionary[Goblins.GoblinType, int] = {}
	var attack_by_type: Dictionary[Goblins.GoblinType, int] = {}
	
	for goblin_type: Goblins.GoblinType in Goblins.GoblinType.values():
		goblins_by_type[goblin_type] = 0
		attack_by_type[goblin_type] = 0
	
	for army_item: Army.ArmyItem in army.items:
		goblins_by_type[army_item.type] += army_item.count
		total_goblins += army_item.count
		attack_by_type[army_item.type] += army_item.attack * army_item.count
		total_attack += army_item.attack * army_item.count
	
	var result: String = ""
	result += "[b]%s goblins, 🗡️%s[/b]\n" % [total_goblins, total_attack]
	for goblin_type: GoblinType in GoblinType.values():
		if goblins_by_type[goblin_type] >= 1:
			result += "%s: %s goblins, 🗡️%s\n" % [
					EMOJIS_BY_GOBLIN_TYPE[goblin_type],
					goblins_by_type[goblin_type],
					attack_by_type[goblin_type]]
	
	return result.strip_edges()
