class_name FoodRecord

var food_yesterday: Dictionary[Items.Type, Big] = {}
var food_today: Dictionary[Items.Type, Big] = {}
var morale_yesterday: float = 0.0
var morale_today: float = 0.0
var shown: bool = false
var starved: bool = false

func reset() -> void:
	food_yesterday.clear()
	food_today.clear()
	morale_yesterday = 0.0
	morale_today = 0.0
	shown = false
	starved = false


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	if json.has("food_yesterday"):
		for key_string: String in json["food_yesterday"].keys():
			food_yesterday[Items.Type.get(key_string.to_upper())] = Big.new(json["food_yesterday"][key_string])
	if json.has("food_today"):
		for key_string: String in json["food_today"].keys():
			food_today[Items.Type.get(key_string.to_upper())] = Big.new(json["food_today"][key_string])
	morale_yesterday = json.get("morale_yesterday", 0.0)
	morale_today = json.get("morale_today", 0.0)
	shown = json.get("shown", false)
	starved = json.get("starved", false)


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	result["food_yesterday"] = {}
	for type: Items.Type in food_yesterday:
		result["food_yesterday"][Utils.enum_to_snake_case(Items.Type, type)] = food_yesterday[type].to_float()
	result["food_today"] = {}
	for type: Items.Type in food_today:
		result["food_today"][Utils.enum_to_snake_case(Items.Type, type)] = food_today[type].to_float()
	result["morale_yesterday"] = morale_yesterday
	result["morale_today"] = morale_today
	result["shown"] = shown
	result["starved"] = starved
	return result
