@tool
class_name DungeonSelectRow
extends HBoxContainer

signal pressed

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

var dungeon: Dungeon:
	set(value):
		dungeon = value
		if is_inside_tree():
			_refresh()

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)
	_refresh()


func _refresh() -> void:
	if dungeon == null:
		return
	
	var reward_icons: String = ""
	reward_icons += _get_gold_emojis()
	reward_icons += _get_loot_emojis()
	%Button.reward_icons = reward_icons
	%Button.boss = dungeon.boss
	
	%DungeonSummary.dungeon = dungeon


func _get_loot_emojis() -> String:
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


func _get_gold_emojis() -> String:
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
