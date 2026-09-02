class_name MoraleEvent

enum MoraleEventType {
	NONE,
	DAY_OFF,
	MADE_FRIEND,
}

const NONE: MoraleEventType = MoraleEventType.NONE
const DAY_OFF: MoraleEventType = MoraleEventType.DAY_OFF
const MADE_FRIEND: MoraleEventType = MoraleEventType.MADE_FRIEND

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
		MADE_FRIEND:
			var gob_ref: GobRef = gob_ref_from_param(0)
			result = "%s became friends with %s." % [gob.name, gob_ref.name]
	return result


func gob_ref_from_param(i: int) -> GobRef:
	var gob_ref: GobRef = GobRef.new()
	gob_ref.from_json_dict(Utils.typed_json_dict(params[i]))
	return gob_ref


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	type = MoraleEventType.get(json.get("type", "none").to_upper())
	delta = json.get("delta", 0.0)
	params = json.get("params", [])


func to_json_dict() -> Dictionary[String, Variant]:
	return {
		"type": Utils.enum_to_snake_case(MoraleEventType, type),
		"delta": delta,
		"params": params
	}


class GobRef:
	var id: int = -1
	var name: String
	
	func from_json_dict(json: Dictionary[String, Variant]) -> void:
		id = json.get("id", -1)
		name = json.get("name", "")
