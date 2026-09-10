class_name GobMorale

const MAX_CAPACITY: int = 8

## Morale happiness: Internally [-25, 125], shown as [0, 100].
var value: float = 0.0

var events: Array[MoraleEvent] = []

func add_event(event: MoraleEvent) -> void:
	events.append(event)
	value = clamp(value + event.delta, -25.0, 125.0)
	while events.size() > MAX_CAPACITY:
		events.pop_front()


func clear() -> void:
	randomize_value()
	events.clear()


func size() -> int:
	return events.size()


func get_event(index: int) -> MoraleEvent:
	return events[index]


func get_last_event() -> MoraleEvent:
	return events.back() if events else null


func pop_last_event() -> MoraleEvent:
	if not events:
		return null
	var event: MoraleEvent = events.pop_back()
	value -= event.delta
	return event


func randomize_value() -> void:
	value = randf_range(0, 20) + randf_range(0, 30) + randf_range(0, 50)


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	value = json.get("value", 50.0)
	for event_json_dict: Dictionary in json.get("events", []):
		var event: MoraleEvent = MoraleEvent.new()
		event.from_json_dict(Utils.typed_json_dict(event_json_dict))
		events.append(event)


func to_json_dict() -> Dictionary[String, Variant]:
	var events_json: Array[Dictionary] = []
	for event: MoraleEvent in events:
		events_json.append(event.to_json_dict())
	return {
		"value": value,
		"events": events_json,
	}
