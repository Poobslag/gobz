class_name PartyData

var partied: bool = false
var party_result: String

var _parties_cache: Array[Party] = []
var _parties_dirty: bool = true

func reset() -> void:
	partied = false
	party_result = ""
	_parties_cache = []
	_parties_dirty = true


func cycle_parties() -> void:
	reset()


func get_parties() -> Array[Party]:
	if _parties_dirty:
		_parties_dirty = false
		_parties_cache = _calculate_parties()
	return _parties_cache


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	result["partied"] = partied
	result["party_result"] = party_result
	var parties_json: Array[Dictionary] = []
	for party: Party in get_parties():
		parties_json.append(party.to_json_dict())
	result["parties"] = parties_json
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	reset()
	partied = json.get("partied", false)
	party_result = json.get("party_result", "")
	if json.has("parties"):
		for party_json: Dictionary in json["parties"]:
			var party: Party = PartyLibrary.initialize_party(party_json["name"])
			party.from_json_dict(Utils.typed_json_dict(party_json))
			_parties_cache.append(party)
		_parties_dirty = false


func _calculate_parties() -> Array[Party]:
	var result: Array[Party] = []
	result.append(PartyLibrary.get_random_party())
	result.append(PartyLibrary.get_random_party())
	return result
