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
	var dungeon_select_info: Dictionary[String, String] = Dungeons.get_dungeon_select_info(dungeon)
	
	var dungeon_row: DungeonSelectRow = DUNGEON_ROW_SCENE.instantiate()
	
	var button_text: String = dungeon_select_info["reward_text"]
	if not dungeon.rewards.is_empty():
		button_text += "  "
		var reward_emoji: String = ""
		for i in dungeon.rewards.size():
			if i >= 3:
				break
			var reward: Dungeon.Reward = dungeon.rewards[i]
			reward_emoji += Items.emoji_from_type(reward.type)
		button_text += "%s" % [reward_emoji]
	dungeon_row.button_text = button_text
	
	var desc: String = "%s %s, %s" % [
		dungeon_select_info["emoji_string"], dungeon_select_info["name"], dungeon_select_info["attack_string"]
	]
	dungeon_row.desc = desc
	dungeon_row.pressed.connect(func() -> void:
		PlayerData.dungeon_index = PlayerData.dungeons.find(dungeon)
		get_tree().change_scene_to_file("res://src/main/battle/battle_screen.tscn"))
	%Dungeons.add_child(dungeon_row)


func _refresh_label() -> void:
	%RichTextLabel.text = ""
	%RichTextLabel.text += "Which dungeon will you enter?\n\n"
	%RichTextLabel.text += "Your army:\n"
	%RichTextLabel.text += Gobs.army_bbcode(PlayerData.army)
