extends Control

func _ready() -> void:
	%FightButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/main/dungeon_select_screen.tscn"))
