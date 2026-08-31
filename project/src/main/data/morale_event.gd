class_name MoraleEvent

enum MoraleEventType {
	NONE,
	DAY_OFF,
}

const NONE: MoraleEventType = MoraleEventType.NONE
const DAY_OFF: MoraleEventType = MoraleEventType.DAY_OFF

var type: MoraleEventType = MoraleEventType.NONE
var delta: float = 0.0
var params: Array[Variant] = []

func get_desc(gob: Gob) -> String:
	var result: String
	match type:
		NONE:
			pass
		DAY_OFF:
			if delta > 0.0:
				result = "%s enjoyed their day off." % [gob.name]
			else:
				result = "%s grew restless during their day off." % [gob.name]
	return result

func from_json_dict(json: Dictionary[String, Variant]) -> void:
	type = MoraleEventType.get(json.get("type", "none").to_upper())
	delta = json.get("delta", 0.0)
	params = json.get("params", [])


func to_json_dict() -> Dictionary[String, Variant]:
	return {
		"type": Utils.enum_to_snake_case(MoraleEventType, type),
		"delta": delta,
		"param": params
	}
