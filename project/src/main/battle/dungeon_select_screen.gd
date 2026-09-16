extends Control

const DUNGEON_ROW_SCENE: PackedScene = preload("res://src/main/battle/dungeon_select_row.tscn")

const GOLD_EMOJI_THRESHOLDS: Array[Array] = [
	[0.005, "🔔", 1],
	[0.01, "🔔", 2],
	[0.03, "🔔", 3],
	[0.05, "🔔", 5],
	[0.10, "💰", 1],
	[0.30, "💰", 2],
	[0.50, "💰", 3],
	[1.00, "💰", 5],
	[3.00, "💰", 8],
	[5.00, "💰", 16],
	[10.00, "💰", 24],
	[30.00, "💰", 40],
]

const LOOT_EMOJI_THRESHOLDS: Array[Array] = [
	[0.30, 1],
	[0.50, 2],
	[1.00, 3],
	[3.00, 5],
	[5.00, 8],
]

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
	
	var reward_icons: String = ""
	reward_icons += _get_gold_emojis(dungeon)
	reward_icons += _get_loot_emojis(dungeon)
	dungeon_row.reward_icons += reward_icons
	
	dungeon_row.boss = dungeon.boss
	
	var desc: String = "%s %s, %s" % [
		dungeon_select_info["emoji_string"], dungeon_select_info["name"], dungeon_select_info["attack_string"]
	]
	dungeon_row.desc = desc
	dungeon_row.pressed.connect(func() -> void:
		PlayerData.dungeon_index = PlayerData.dungeons.find(dungeon)
		get_tree().change_scene_to_file("res://src/main/battle/battle_screen.tscn"))
	%Dungeons.add_child(dungeon_row)


func _get_loot_emojis(dungeon: Dungeon) -> String:
	var result: String = ""
	for reward: Dungeon.Reward in dungeon.rewards:
		# if we consider an "average goblin" $20, about how many goblins worth of net worth is the player?
		var net_worth_as_goblins: float = max(1, PlayerData.peak_net_worth.to_float() / 20.0)
		var reward_ratio: float = reward.count.to_float() / net_worth_as_goblins
		var loot_emoji_threshold_index: int = LOOT_EMOJI_THRESHOLDS.size() - 1
		for i in LOOT_EMOJI_THRESHOLDS.size() - 1:
			if reward_ratio <= LOOT_EMOJI_THRESHOLDS[i][0]:
				loot_emoji_threshold_index = i
				break
		var loot_emoji_count: int = LOOT_EMOJI_THRESHOLDS[loot_emoji_threshold_index][1]
		var loot_emoji: String = Items.emoji_from_type(reward.type)
		result += loot_emoji.repeat(loot_emoji_count)
	return result


func _get_gold_emojis(dungeon: Dungeon) -> String:
	var gold_ratio: float = \
			dungeon.recon_army.get_total_gold().to_float() / PlayerData.peak_net_worth.to_float()
	var gold_emoji_threshold_index: int = GOLD_EMOJI_THRESHOLDS.size() - 1
	for i in GOLD_EMOJI_THRESHOLDS.size() - 1:
		if gold_ratio <= GOLD_EMOJI_THRESHOLDS[i][0]:
			gold_emoji_threshold_index = i
			break
	var gold_emoji: String = GOLD_EMOJI_THRESHOLDS[gold_emoji_threshold_index][1]
	var gold_emoji_count: int = GOLD_EMOJI_THRESHOLDS[gold_emoji_threshold_index][2]
	return gold_emoji.repeat(gold_emoji_count)


func _refresh_label() -> void:
	%RichTextLabel.text = ""
	%RichTextLabel.text += "Which dungeon will you enter?\n\n"
	%RichTextLabel.text += "Your army:\n"
	%RichTextLabel.text += Gobs.army_bbcode(PlayerData.army)
