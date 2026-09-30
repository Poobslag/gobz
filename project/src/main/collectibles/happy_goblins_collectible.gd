extends Collectible

@export var target_goblin_count: float
@export var target_morale: float

func refresh_collectible() -> void:
	if PlayerData.army.get_total_goblins().to_float() >= target_goblin_count \
			and PlayerData.army.get_average_morale() >= target_morale:
		unlock_collectible()


func get_instructions() -> String:
	return "Have {goblins} goblins with {morale}+ average morale.".format([
			["goblins", Big.float_to_aa(target_goblin_count)],
			["morale", Big.float_to_aa(target_morale)],
		])
