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

const DEVIL_COST_FACTOR: float = 2.0 * 1.35
const ANGEL_COST_FACTOR: float = 2.0 * 0.65

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

const MORALE_THRESHOLDS: Array[Array] = [
	[0, "😭", "WTF"],
	[4, "😭", "Traumitized"],
	[8, "😥", "Awful"],
	[16, "😥", "All messed up"],
	[24, "☹", "Pretty bad"],
	[30, "☹", "Bummed out"],
	[36, "😕", "Distracted"],
	[40, "😕", "Meh"],
	[45, "😐", "Whatever"],
	[50, "😐", "Fine"],
	[55, "🙂", "Alright"],
	[60, "🙂", "Pretty good"],
	[64, "🙂", "Good"],
	[70, "😀", "Pretty Great"],
	[76, "😀", "Great"],
	[84, "😄", "Amazing"],
	[92, "😄", "Awesome"],
	[96, "🤩", "Totally awesome"],
	[100, "🤩", "LFG"],
]

const ATTACK_THRESHOLDS: Array[Array] = [
	[3, ""],
	[6, "⭐"],
	[12, "⭐⭐"],
	[24, "⭐⭐⭐"],
	[48, "⭐⭐⭐⭐"],
]

static func attack_rating(attack: float) -> String:
	var attack_threshold_index: int = ATTACK_THRESHOLDS.size() - 1
	for i in ATTACK_THRESHOLDS.size() - 1:
		if attack <= ATTACK_THRESHOLDS[i][0]:
			attack_threshold_index = i
			break
	return ATTACK_THRESHOLDS[attack_threshold_index][1]


static func emoji_from_type(type: Type) -> String:
	return EMOJIS_BY_GOBLIN_TYPE[type]


static func army_bbcode(army: Army) -> String:
	var summary: Army.ArmySummary = army.get_summary()
	var result: String = ""
	var overall_attack_rating: String = attack_rating(
			summary.total_attack.to_float() / max(1, summary.total_goblins.to_float()))
	result += "[b]%s goblins %s[/b]\n" % [summary.total_goblins.to_aa(), overall_attack_rating]
	for goblin_type: Type in Type.values():
		if summary.goblins_by_type[goblin_type].is_gte(1):
			var type_attack_rating: String = attack_rating(
					summary.attack_by_type[goblin_type].to_float() / summary.goblins_by_type[goblin_type].to_float())
			var wounded_string: String = ""
			if summary.wounded_by_type[goblin_type].is_gte(1):
				var wounded_percent: float = 100 * summary.wounded_by_type[goblin_type].to_float() \
						/ summary.goblins_by_type[goblin_type].to_float()
				wounded_percent = max(wounded_percent, 1)
				wounded_string = "(%d%% 🩹) " % [wounded_percent]
			result += "%s: %s goblins %s%s\n" % [
					EMOJIS_BY_GOBLIN_TYPE[goblin_type],
					summary.goblins_by_type[goblin_type].to_aa(),
					wounded_string,
					type_attack_rating]
	
	return result.strip_edges()


static func morale_bbcode(morale: float, bold: bool = false) -> String:
	var threshold_index: int = MORALE_THRESHOLDS.size() - 1
	for i in MORALE_THRESHOLDS.size() - 1:
		if morale <= MORALE_THRESHOLDS[i][0]:
			threshold_index = i
			break
	var emoji: String = MORALE_THRESHOLDS[threshold_index][1]
	var text: String = MORALE_THRESHOLDS[threshold_index][2]
	
	var percent: String = "%s%%" % [roundi(clampf(morale, 0.0, 100.0))]
	var result: String
	if bold:
		result = "%s[b] %s (%s)[/b]" % [emoji, text, percent]
	else:
		result = "%s %s (%s)" % [emoji, text, percent]
	return result
