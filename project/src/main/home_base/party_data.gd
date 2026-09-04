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


func _calculate_parties() -> Array[Party]:
	var result: Array[Party] = []
	result.append(PartyLibrary.get_random_party())
	return result
