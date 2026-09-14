class_name Items

enum Type {
	WEAK_MEDICINE,
	STRONG_MEDICINE,
	HERB_1,
	HERB_2,
	HERB_3,
	
	FOOD_BREAD,
	FOOD_CHICKEN, # a popular choice
	FOOD_PIZZA,
	FOOD_RAM, # everyone's favorite
	FOOD_UNKNOWN, # forbidden meat
}

const WEAK_MEDICINE: Type = Type.WEAK_MEDICINE
const STRONG_MEDICINE: Type = Type.STRONG_MEDICINE
const HERB_1: Type = Type.HERB_1
const HERB_2: Type = Type.HERB_2
const HERB_3: Type = Type.HERB_3

const FOOD_BREAD: Type = Type.FOOD_BREAD
const FOOD_CHICKEN: Type = Type.FOOD_CHICKEN
const FOOD_PIZZA: Type = Type.FOOD_PIZZA
const FOOD_RAM: Type = Type.FOOD_RAM
const FOOD_UNKNOWN: Type = Type.FOOD_UNKNOWN

const EMOJIS_BY_ITEM_TYPE: Dictionary[Type, String] = {
	WEAK_MEDICINE: "🍰",
	STRONG_MEDICINE: "🍺",
	HERB_1: "🌿",
	HERB_2: "🌽",
	HERB_3: "🌺",
	
	FOOD_BREAD: "🥐",
	FOOD_CHICKEN: "🍗",
	FOOD_PIZZA: "🍕",
	FOOD_RAM: "🍖",
	FOOD_UNKNOWN: "🥩",
}

static func emoji_from_type(type: Type) -> String:
	return EMOJIS_BY_ITEM_TYPE[type]
