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

const GOBLIN_TYPES_BY_EMOJI: Dictionary[String, GoblinType] = {
	"🔥": FIRE,
	"💧": WATER,
	"🌳": GRASS,
	"🕊️": ANGEL,
	"😈": DEVIL,
}

static func emoji_from_type(type: GoblinType) -> String:
	return EMOJIS_BY_GOBLIN_TYPE[type]


static func army_bbcode(army: Army) -> String:
	var summary: Army.ArmySummary = army.get_summary()
	var result: String = ""
	result += "[b]%s goblins, 🗡️%s[/b]\n" % [Utils.abbr_num(summary.total_goblins), Utils.abbr_num(summary.total_attack)]
	for goblin_type: GoblinType in GoblinType.values():
		if summary.goblins_by_type[goblin_type] >= 1:
			result += "%s: %s goblins, 🗡️%s\n" % [
					EMOJIS_BY_GOBLIN_TYPE[goblin_type],
					Utils.abbr_num(summary.goblins_by_type[goblin_type]),
					Utils.abbr_num(summary.attack_by_type[goblin_type])]
	
	return result.strip_edges()
