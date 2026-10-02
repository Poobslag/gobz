class_name Party

var name: String
var prompt: String
var likers: Array[Gobs.Type]
var dislikers: Array[Gobs.Type]

## Scales both the delta and pct of the party. This means a value of 0.5 will leave 25% of the original effect (half
## the magnitude, applied to half the goblins)
var nerf_factor: float = 1.0

## Expected reward for a non-nerfed party
var expected_reward: float = 10.0

var group_string: String

func _init(init_name: String) -> void:
	name = init_name
	group_string = "%s-%s" % [name.to_lower(), PlayerData.day]


func reset() -> void:
	name = ""
	prompt = ""
	likers = []
	dislikers = []
	nerf_factor = 1.0
	expected_reward = 10.0
	group_string = ""


func add_headline(type: MoraleEvent.MoraleEventType) -> MoraleDigest.HeadlineBuilder:
	return PlayerData.morale_digest.add_headline(type).group(group_string)


func execute() -> String:
	return ""


func finalize_morale() -> Array[Gob]:
	PartyLibrary.apply_preferences_to_group(group_string, likers, dislikers)
	return PartyLibrary.apply_group_headlines_to_army(group_string, nerf_factor)


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	result["name"] = name
	result["prompt"] = prompt
	var likers_json: Array[String] = []
	for liker: Gobs.Type in likers:
		likers_json.append(Utils.enum_to_snake_case(Gobs.Type, liker))
	result["likers"] = likers_json
	var dislikers_json: Array[String] = []
	for disliker: Gobs.Type in dislikers:
		dislikers_json.append(Utils.enum_to_snake_case(Gobs.Type, disliker))
	result["dislikers"] = dislikers_json
	result["nerf_factor"] = nerf_factor
	result["expected_reward"] = expected_reward
	result["group_string"] = group_string
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	reset()
	name = json.get("name", "")
	prompt = json.get("prompt", "")
	for liker_json: String in json.get("likers", []):
		likers.append(Gobs.Type.get(liker_json.to_upper()))
	for disliker_json: String in json.get("dislikers", []):
		dislikers.append(Gobs.Type.get(disliker_json.to_upper()))
	nerf_factor = json.get("nerf_factor", 1.0)
	expected_reward = json.get("expected_reward", 10.0)
	group_string = json.get("group_string", "")
