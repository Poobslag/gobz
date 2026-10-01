extends Collectible

@export var target_beer_count: float = 0

func connect_signals() -> void:
	super.connect_signals()
	disconnect_save_signal()
	disconnect_load_signal()
	
	Events.party_finished.connect(_on_events_party_finished)


func get_instructions() -> String:
	return "Spend {target} beer at a single party.".format([["target", Big.float_to_aa(target_beer_count)]])


func _on_events_party_finished(_party: Party, beer_count: Big) -> void:
	if beer_count.is_gte(target_beer_count):
		unlock_collectible()
