extends Control

func _ready() -> void:
	_refresh_label()
	
	for dungeon_select_row: DungeonSelectRow in [
			%DungeonSelectRow1,
			%DungeonSelectRow2,
			%DungeonSelectRow3,
			]:
		dungeon_select_row.pressed.connect(func() -> void:
				get_tree().change_scene_to_file("res://src/main/battle_screen.tscn"))


func _refresh_label() -> void:
	%RichTextLabel.text = ""
	%RichTextLabel.text += "Which dungeon will you enter?\n\n"
	%RichTextLabel.text += Goblins.army_bbcode(PlayerData.army)
