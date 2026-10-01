extends Collectible

@export var target_goblin_count: float

func refresh_collectible() -> void:
	if PlayerData.army.get_total_goblins().to_float() >= target_goblin_count:
		unlock_collectible()


func get_instructions() -> String:
	var current_goblin_count: float = PlayerData.army.get_total_goblins().to_float()
	var base_instructions: String = "Build an army of %s goblins." % [Big.float_to_aa(target_goblin_count)]
	return with_progress(base_instructions, current_goblin_count, target_goblin_count)
