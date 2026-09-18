extends Control

const DUNGEON_ROW_SCENE: PackedScene = preload("res://src/main/battle/dungeon_select_row.tscn")

func _ready() -> void:
	refresh()
	%TipLabel.text = "Tip: %s" % [PlayerData.get_next_tip()]


func refresh() -> void:
	for child: Node in %Dungeons.get_children():
		%Dungeons.remove_child(child)
		child.queue_free()
	
	_refresh_label()
	
	for dungeon: Dungeon in PlayerData.dungeons:
		_add_dungeon_row(dungeon)


func _add_dungeon_row(dungeon: Dungeon) -> void:
	var dungeon_row: DungeonSelectRow = DUNGEON_ROW_SCENE.instantiate()
	dungeon_row.dungeon = dungeon
	dungeon_row.pressed.connect(func() -> void:
		PlayerData.dungeon_index = PlayerData.dungeons.find(dungeon)
		get_tree().change_scene_to_file("res://src/main/battle/battle_screen.tscn"))
	%Dungeons.add_child(dungeon_row)


func _refresh_label() -> void:
	%RichTextLabel.text = ""
	%RichTextLabel.text += "Which dungeon will you enter?\n\n"
	%RichTextLabel.text += "Your army:\n"
	%RichTextLabel.text += Gobs.army_bbcode(PlayerData.army)
