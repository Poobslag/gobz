class_name GobMorale

const MAX_CAPACITY: int = 8

var value: float = 0.0
var _events: Array[MoraleEvent] = []

func add_event(event: MoraleEvent) -> void:
	_events.append(event)
	value = clamp(value + event.delta, -25.0, 125.0)
	while _events.size() > MAX_CAPACITY:
		value -= _events.pop_front().delta


func size() -> int:
	return _events.size()


func get_event(index: int) -> MoraleEvent:
	return _events[index]


func get_last_event() -> MoraleEvent:
	return _events.back() if _events else null


func randomize_value() -> void:
	value = randf_range(0, 20) + randf_range(0, 30) + randf_range(0, 50)


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	value = json.get("value", 50.0)
	for event_json_dict: Dictionary in json.get("events", []):
		var event: MoraleEvent = MoraleEvent.new()
		event.from_json_dict(Utils.typed_json_dict(event_json_dict))
		_events.append(event)


func to_json_dict() -> Dictionary[String, Variant]:
	var events_json: Array[Dictionary] = []
	for event: MoraleEvent in _events:
		events_json.append(event.to_json_dict())
	return {
		"value": value,
		"events": events_json,
	}
