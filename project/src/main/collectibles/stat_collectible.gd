extends Collectible

@export var tracked_stat: String
@export var target_value: float = 0
@export var instructions_template: String = "Get a value of {target}."

func connect_signals() -> void:
	super.connect_signals()
	PlayerData.stat_changed.connect(_on_player_data_stat_changed)


func refresh_collectible() -> void:
	if PlayerData.get_stat(tracked_stat) >= target_value:
		unlock_collectible()


func get_instructions() -> String:
	var result: String = instructions_template.format([["target", Big.float_to_aa(target_value)]])
	return with_progress(result, PlayerData.get_stat(tracked_stat), target_value)


func _on_player_data_stat_changed(changed_stat: String) -> void:
	if changed_stat != tracked_stat:
		return
	refresh_collectible()
