extends Control


func _ready() -> void:
	PlayerData.reset()
	PlayerData.initialize_starting_army()
	%DungeonSelect.refresh()
