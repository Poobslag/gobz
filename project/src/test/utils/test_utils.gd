@tool
class_name TestUtils
## Contains test utilities.

static func json_round_trip(json: Dictionary[String, Variant]) -> Dictionary[String, Variant]:
	return Utils.typed_json_dict(JSON.parse_string(JSON.stringify(json)))
