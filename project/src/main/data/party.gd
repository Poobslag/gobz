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


func add_headline(type: MoraleEvent.MoraleEventType) -> MoraleDigest.HeadlineBuilder:
	return PlayerData.morale_digest.add_headline(type).group(group_string)


func execute() -> String:
	return ""


func finalize_morale() -> Array[Gob]:
	PartyLibrary.apply_preferences_to_group(group_string, likers, dislikers)
	return PartyLibrary.apply_group_headlines_to_army(group_string, nerf_factor)
