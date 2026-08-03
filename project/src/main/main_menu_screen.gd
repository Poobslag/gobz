extends Control

func _ready() -> void:
	%PlayButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/main/home_base_screen.tscn"))
