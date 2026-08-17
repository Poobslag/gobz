class_name Gobs

enum Type {
	FIRE,
	WATER,
	GRASS,
	ANGEL,
	DEVIL,
}

const WOUNDED_ATTACK_FACTOR: float = 0.5
const WOUNDED_HP_THRESHOLD: float = 0.5

const FIRE: Type = Type.FIRE
const WATER: Type = Type.WATER
const GRASS: Type = Type.GRASS
const ANGEL: Type = Type.ANGEL
const DEVIL: Type = Type.DEVIL

const EMOJIS_BY_GOBLIN_TYPE: Dictionary[Type, String] = {
	FIRE: "🔥",
	WATER: "💧",
	GRASS: "🌳",
	ANGEL: "🕊️",
	DEVIL: "😈",
}

const GOBLIN_TYPES_BY_EMOJI: Dictionary[String, Type] = {
	"🔥": FIRE,
	"💧": WATER,
	"🌳": GRASS,
	"🕊️": ANGEL,
	"🕊": ANGEL, # without variation selector-16
	"😈": DEVIL,
}

static func emoji_from_type(type: Type) -> String:
	return EMOJIS_BY_GOBLIN_TYPE[type]


static func army_bbcode(army: Army) -> String:
	var summary: Army.ArmySummary = army.get_summary()
	var result: String = ""
	result += "[b]%s goblins, ⚔️%s[/b]\n" % \
			[summary.total_goblins.to_aa(), summary.total_attack.to_aa()]
	for goblin_type: Type in Type.values():
		if summary.goblins_by_type[goblin_type].is_gte(1):
			result += "%s: %s goblins, ⚔️%s\n" % [
					EMOJIS_BY_GOBLIN_TYPE[goblin_type],
					summary.goblins_by_type[goblin_type].to_aa(),
					summary.attack_by_type[goblin_type].to_aa()]
	
	return result.strip_edges()
