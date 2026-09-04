class_name MoraleEvent

enum MoraleEventType {
	NONE,
	DAY_OFF,
	MADE_FRIEND,
	MURDERBALL_WON,
	MURDERBALL_LOST,
	MURDERBALL_PLAY,
}

const NONE: MoraleEventType = MoraleEventType.NONE
const DAY_OFF: MoraleEventType = MoraleEventType.DAY_OFF
const MADE_FRIEND: MoraleEventType = MoraleEventType.MADE_FRIEND
const MURDERBALL_WON: MoraleEventType = MoraleEventType.MURDERBALL_WON
const MURDERBALL_LOST: MoraleEventType = MoraleEventType.MURDERBALL_LOST
const MURDERBALL_PLAY: MoraleEventType = MoraleEventType.MURDERBALL_PLAY

var type: MoraleEventType = MoraleEventType.NONE
var delta: float = 0.0
var params: Array[Variant] = []
var day: int = 1

func get_desc(_gob: Gob) -> String:
	var result: String
	match type:
		NONE:
			pass
		DAY_OFF:
			if delta > 0.0:
				result = "Relaxing day off"
			else:
				result = "Boring day off"
		MADE_FRIEND:
			var gob_ref: GobRef = gob_ref_from_param(0)
			result = "Befriended %s" % [gob_ref.name]
		MURDERBALL_WON:
			if delta > 0.0:
				result = "Won a game of murderball"
			else:
				result = "Boring game of murderball"
		MURDERBALL_LOST:
			if delta > 0.0:
				result = "Close game of murderball"
			else:
				result = "Lost a game of murderball"
		MURDERBALL_PLAY:
			if delta > 0.0:
				result = "Played murderball"
			else:
				result = "Suffered through murderball"
	return result


func gob_ref_from_param(i: int) -> GobRef:
	var gob_ref: GobRef = GobRef.new()
	gob_ref.from_json_dict(Utils.typed_json_dict(params[i]))
	return gob_ref


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	type = MoraleEventType.get(json.get("type", "none").to_upper())
	delta = json.get("delta", 0.0)
	params = json.get("params", [])
	day = json.get("day", 1)


func to_json_dict() -> Dictionary[String, Variant]:
	return {
		"type": Utils.enum_to_snake_case(MoraleEventType, type),
		"delta": delta,
		"params": params,
		"day": day
	}


class GobRef:
	var id: int = -1
	var name: String
	
	func from_json_dict(json: Dictionary[String, Variant]) -> void:
		id = json.get("id", -1)
		name = json.get("name", "")
