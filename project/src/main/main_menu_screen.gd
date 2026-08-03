extends Control

func _ready() -> void:
	PlayerData.reset()
	PlayerData.initialize_starting_army()
	
	%PlayButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/main/home_base_screen.tscn"))
