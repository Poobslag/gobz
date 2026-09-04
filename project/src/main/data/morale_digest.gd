class_name MoraleDigest

const CONDITIONS_BY_NAME: Dictionary[String, Script] = {
	"pct": PercentCondition,
	"type": TypeCondition,
}

static var NAMES_BY_CONDITION: Dictionary[Script, String] = {
}

var headlines: Array[Headline] = []

static func _static_init() -> void:
	for name: String in CONDITIONS_BY_NAME:
		NAMES_BY_CONDITION[CONDITIONS_BY_NAME[name]] = name


func reset() -> void:
	headlines.clear()


func add_headline(type: MoraleEvent.MoraleEventType) -> HeadlineBuilder:
	var headline: Headline = Headline.new()
	headline.type = type
	headlines.append(headline)
	return HeadlineBuilder.new(headline)


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	headlines.clear()
	for headline_dict: Dictionary in json.get("headlines", []):
		var headline: Headline = Headline.new()
		headline.from_json_dict(Utils.typed_json_dict(headline_dict))
		headlines.append(headline)


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	result["headlines"] = []
	for headline: Headline in headlines:
		result["headlines"].append(headline.to_json_dict())
	return result


class Headline:
	var type: MoraleEvent.MoraleEventType
	
	var conditions: Array[MoraleCondition] = []
	
	func evaluate(gob: Gob) -> float:
		var result: float = 1.0
		for condition: MoraleCondition in conditions:
			result *= condition.evaluate(gob)
		return result


	func from_json_dict(json: Dictionary[String, Variant]) -> void:
		type = MoraleEvent.MoraleEventType.get(json.get("type").to_upper())
		for condition_json: Dictionary in json.get("conditions", []):
			var condition_type: String = condition_json.get("condition_type")
			if CONDITIONS_BY_NAME.has(condition_type):
				var condition: MoraleCondition = CONDITIONS_BY_NAME[condition_type].new()
				condition.from_json_dict(condition_json)
				conditions.append(condition)
			else:
				push_warning("Unrecognized condition.type: '%s'" % [condition_type])


	func to_json_dict() -> Dictionary[String, Variant]:
		var result: Dictionary[String, Variant] = {}
		result["type"] = Utils.enum_to_snake_case(MoraleEvent.MoraleEventType, type)
		result["conditions"] = []
		for condition: MoraleCondition in conditions:
			var condition_dict: Dictionary[String, Variant] = condition.to_json_dict()
			condition_dict["condition_type"] = MoraleDigest.NAMES_BY_CONDITION[condition.get_script()]
			result["conditions"].append(condition_dict)
		return result


class MoraleCondition:
	## Subclasses should override this function to return a float [0.0, 1.0] for the percent of the specified Gob
	## which is affected by the headline.
	func evaluate(_gob: Gob) -> float:
		return 1.0
	
	
	func from_json_dict(_json: Dictionary[String, Variant]) -> void:
		push_warning("MoraleCondition does not implement from_json_dict")
	
	
	func to_json_dict() -> Dictionary[String, Variant]:
		push_warning("MoraleCondition does not implement from_json_dict")
		return {}


class PercentCondition extends MoraleCondition:
	var value: float = 1.0
	
	func evaluate(_gob: Gob) -> float:
		return value
	
	
	func from_json_dict(dict: Dictionary) -> void:
		value = dict.get("value", 1.0)
	
	
	func to_json_dict() -> Dictionary[String, Variant]:
		return {"value": value}


class TypeCondition extends MoraleCondition:
	var type: Gobs.Type
	
	func evaluate(gob: Gob) -> float:
		return 1.0 if gob.type == type else 0.0
	
	
	func from_json_dict(dict: Dictionary) -> void:
		type = Gobs.Type.get(dict.get("gob_type").to_upper())
	
	
	func to_json_dict() -> Dictionary[String, Variant]:
		return {"gob_type": Utils.enum_to_snake_case(Gobs.Type, type)}


class HeadlineBuilder:
	var headline: Headline
	
	func _init(init_headline: Headline) -> void:
		headline = init_headline
	
	
	func type(t: Gobs.Type) -> HeadlineBuilder:
		var condition: TypeCondition = TypeCondition.new()
		condition.type = t
		headline.conditions.append(condition)
		return self
	
	
	func pct(v: float) -> HeadlineBuilder:
		var condition: PercentCondition = PercentCondition.new()
		condition.value = v
		headline.conditions.append(condition)
		return self
