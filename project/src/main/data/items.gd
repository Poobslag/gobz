class_name Items

enum Type {
	WEAK_MEDICINE,
	STRONG_MEDICINE,
	HERB_1,
	HERB_2,
	HERB_3,
}

const WEAK_MEDICINE: Type = Type.WEAK_MEDICINE
const STRONG_MEDICINE: Type = Type.STRONG_MEDICINE
const HERB_1: Type = Type.HERB_1
const HERB_2: Type = Type.HERB_2
const HERB_3: Type = Type.HERB_3

const EMOJIS_BY_ITEM_TYPE: Dictionary[Type, String] = {
	WEAK_MEDICINE: "🍰",
	STRONG_MEDICINE: "🍺",
	HERB_1: "🌿",
	HERB_2: "🌽",
	HERB_3: "🌺",
}

static func emoji_from_type(type: Type) -> String:
	return EMOJIS_BY_ITEM_TYPE[type]
