extends Control

const DUNGEON_ROW_SCENE: PackedScene = preload("res://src/main/dungeon_select_row.tscn")

func _ready() -> void:
	refresh()


func refresh() -> void:
	for child: Node in %Dungeons.get_children():
		%Dungeons.remove_child(child)
		child.queue_free()
	
	_refresh_label()
	
	for dungeon: Dungeon in PlayerData.dungeons:
		_add_dungeon_row(dungeon)


func _add_dungeon_row(dungeon: Dungeon) -> void:
	var vague_army: Army = dungeon.get_vague_army()
	var dungeon_row: DungeonSelectRow = DUNGEON_ROW_SCENE.instantiate()
	dungeon_row.button_text = "+💰%s" % [StringUtils.comma_sep(vague_army.get_total_gold())]
	
	var attack_by_type: Dictionary[Goblins.GoblinType, int]
	for type: Goblins.GoblinType in Goblins.GoblinType.values():
		attack_by_type[type] = 0
	for item: Army.ArmyItem in vague_army.items:
		attack_by_type[item.type] += item.attack * item.count
	var type_summaries: Array[Dictionary] = []
	for type: Goblins.GoblinType in Goblins.GoblinType.values():
		type_summaries.append({
			"emoji": Goblins.EMOJIS_BY_GOBLIN_TYPE[type],
			"attack": attack_by_type[type],
		} as Dictionary[String, Variant])
	type_summaries.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
		return a["attack"] > b["attack"]
		)
	
	var emoji_string: String = ""
	if type_summaries.size() == 0:
		emoji_string = "-"
	if type_summaries.size() >= 1:
		emoji_string = type_summaries[0]["emoji"]
	if type_summaries.size() >= 2:
		if type_summaries[1]["attack"] > type_summaries[0]["attack"] * 0.2:
			emoji_string += type_summaries[1]["emoji"]
		else:
			emoji_string = type_summaries[0]["emoji"] + emoji_string
	if type_summaries.size() >= 3:
		if type_summaries[2]["attack"] > type_summaries[0]["attack"] * 0.2:
			emoji_string +=  type_summaries[2]["emoji"]
		else:
			emoji_string = type_summaries[0]["emoji"] + emoji_string
	
	dungeon_row.desc = "%s %s, %s⚔" % [
		emoji_string, dungeon.name, vague_army.get_total_attack()
	]
	dungeon_row.pressed.connect(func() -> void:
		PlayerData.current_dungeon = PlayerData.dungeons.find(dungeon)
		get_tree().change_scene_to_file("res://src/main/battle_screen.tscn"))
	%Dungeons.add_child(dungeon_row)


func _refresh_label() -> void:
	%RichTextLabel.text = ""
	%RichTextLabel.text += "Which dungeon will you enter?\n\n"
	%RichTextLabel.text += "Your forces:\n\n"
	%RichTextLabel.text += Goblins.army_bbcode(PlayerData.army)
