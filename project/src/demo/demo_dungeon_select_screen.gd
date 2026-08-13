extends Control


func _ready() -> void:
	PlayerData.start_new_game()
	%DungeonSelect.refresh()
