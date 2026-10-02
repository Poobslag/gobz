extends ColorRect

signal finished

const VICTORY: Events.BattleResult = Events.BattleResult.VICTORY
const DEFEAT: Events.BattleResult = Events.BattleResult.DEFEAT
const SURRENDER: Events.BattleResult = Events.BattleResult.SURRENDER
const MUTUAL_DEFEAT: Events.BattleResult = Events.BattleResult.MUTUAL_DEFEAT
const RETREAT: Events.BattleResult = Events.BattleResult.RETREAT

const COLOR_BY_RESULT: Dictionary[Events.BattleResult, Color] = {
	VICTORY: Color("458a61"),
	DEFEAT: Color("8d8381"),
	SURRENDER: Color("8d8381"),
	MUTUAL_DEFEAT: Color("8d8381"),
	RETREAT: Color("8d8381"),
}

var _battle_result: Events.BattleResult

@onready var splash_showers: Array[Control] = [
	%VictoryShower, %DefeatShower, %RetreatShower
]

@onready var _splash_by_result: Dictionary[Events.BattleResult, Node] = {
	VICTORY: %VictoryShower,
	DEFEAT: %DefeatShower,
	SURRENDER: %DefeatShower,
	MUTUAL_DEFEAT: %DefeatShower,
	RETREAT: %RetreatShower,
}

func _ready() -> void:
	%DoneButton.pressed.connect(finished.emit)


func refresh() -> void:
	%YourGoblins.text = ""
	%YourGoblins.text += "You:\n"
	%YourGoblins.text += Gobs.army_bbcode(PlayerData.army)
	
	%EnemyGoblins.text = ""
	if PlayerData.has_current_dungeon():
		%EnemyGoblins.text += "Bad guys:\n"
		%EnemyGoblins.text += Gobs.army_bbcode(PlayerData.get_dungeon_army())


func show_result(new_battle_result: Events.BattleResult) -> void:
	_battle_result = new_battle_result
	refresh()
	_show_splash(_splash_by_result[_battle_result])
	color = COLOR_BY_RESULT[_battle_result]
	match _battle_result:
		VICTORY: _show_victory_result()
		DEFEAT: _show_defeat_result()
		SURRENDER: _show_surrender_result()
		MUTUAL_DEFEAT: _show_mutual_defeat_result()
		RETREAT: _show_retreat_result()
	_end_battle()


func _show_victory_result() -> void:
	# collect unknown food
	var looted_unknown_food: Big = %WatchPanel.gob_battle_status.enemies_killed
	PlayerData.inventory.add_item(Items.FOOD_UNKNOWN, looted_unknown_food)
	# collect rewards
	var dungeon_rewards: Array[Dungeon.Reward] = PlayerData.get_dungeon().rewards
	for reward: Dungeon.Reward in dungeon_rewards:
		PlayerData.inventory.add_item(reward.type, reward.count)
	var looted_gold: Big = Big.add(PlayerData.army.gold, PlayerData.get_dungeon_army().gold)
	PlayerData.gold = Big.add(PlayerData.gold, looted_gold)
	PlayerData.army.gold = Big.ZERO
	PlayerData.get_dungeon_army().gold = Big.ZERO
	
	%Message.text = ""
	if PlayerData.get_dungeon().boss:
		%Message.text += "[b]Boss dungeon #%s defeated![/b] Heck yeah!\n\n" \
				% [StringUtils.comma_sep(PlayerData.bosses_defeated + 1)]
	else:
		%Message.text += "Victory!\n\n"
	%Message.text += "You loot 💰%s from your fallen allies and enemies." % [looted_gold.to_aa()]
	if not dungeon_rewards.is_empty():
		var reward_loot_string: String = ""
		for i in dungeon_rewards.size():
			var reward: Dungeon.Reward = dungeon_rewards[i]
			if i == 0:
				pass
			elif i < dungeon_rewards.size() - 1:
				reward_loot_string += ", "
			else:
				reward_loot_string += " and "
			reward_loot_string += "%s%s" % [Items.emoji_from_type(reward.type), reward.count.to_aa()]
		%Message.text += " You also grab %s." % [reward_loot_string]


func _show_defeat_result() -> void:
	PlayerData.army.gold = Big.ZERO
	PlayerData.gold = Big.add(PlayerData.gold, Big.new(PlayerData.get_dungeon_army().gold.to_float() * 0.1))
	PlayerData.initialize_starting_army()
	
	%Message.text = ""
	%Message.text += "Defeat...\n\n"
	var goblin: Gob = PlayerData.army.gobs.back()
	%Message.text += "%s %s is inspired by the bravery of the fallen goblins!\n" % [
		Gobs.emoji_from_type(goblin.type), goblin.name
	]
	%Message.text += "They give what gold they have and prepare for battle."


## When the player surrenders to raiders, we take away half their stuff (rounding up)
func _show_surrender_result() -> void:
	PlayerData.gold = Big.div(PlayerData.gold, 2)
	for item_type: Items.Type in PlayerData.inventory.items:
		PlayerData.inventory.set_count(item_type, Big.div(PlayerData.inventory.get_count(item_type), 2))
	# empty all the goblins so that the dungeon cycles
	PlayerData.get_dungeon().army.reset()
	
	%Message.text = ""
	%Message.text += "Surrender...\n\n"


func _show_mutual_defeat_result() -> void:
	var looted_gold: Big = Big.new(
			Big.add(PlayerData.army.gold, PlayerData.get_dungeon_army().gold).to_float() * 0.5)
	PlayerData.gold = Big.add(PlayerData.gold, looted_gold)
	PlayerData.initialize_starting_army()
	PlayerData.get_dungeon_army().gold = Big.ZERO
	
	%Message.text = ""
	if PlayerData.get_dungeon().boss:
		%Message.text += "[b]Boss dungeon #%s defeated...?[/b] Umm, kind of!\n\n" \
				% [StringUtils.comma_sep(PlayerData.bosses_defeated + 1)]
	else:
		%Message.text += "Mutual defeat...\n\n"
	var goblin: Gob = PlayerData.army.gobs.back()
	%Message.text += "%s %s is inspired by the bravery of the fallen goblins!\n" % [
		Gobs.emoji_from_type(goblin.type), goblin.name
	]
	%Message.text += "They loot 💰%s from the battlefield and prepare for battle."


func _show_retreat_result() -> void:
	var looted_gold: Big = PlayerData.army.gold
	PlayerData.gold = Big.add(PlayerData.gold, looted_gold)
	PlayerData.army.gold = Big.ZERO
	# force recon; the player knows the exact unit comp, plus it may have changed during battle
	PlayerData.get_dungeon().recon_army = PlayerData.get_dungeon().army.duplicate()
	PlayerData.get_dungeon_army().gold = Big.ZERO
	
	%Message.text = ""
	%Message.text += "Retreat!\n\n"
	if looted_gold.is_gt(0):
		%Message.text += "You scurry home with 💰%s in your pockets." % [looted_gold.to_aa()]
	else:
		%Message.text += "You scurry home empty-handed."


func _end_battle() -> void:
	if PlayerData.get_dungeon_army().is_empty() and PlayerData.get_dungeon().boss:
		PlayerData.bosses_defeated += 1
	PlayerData.prev_dungeon = PlayerData.get_dungeon()
	
	Events.battle_finished.emit(PlayerData.get_dungeon(), _battle_result)
	
	var raided: bool = PlayerData.get_dungeon().is_raiding()
	if raided:
		# being raided doesn't increment the day counter or cycle dungeons, but we replace the raiders
		DungeonDirector.remove_empty_dungeons()
		DungeonDirector.fill_missing_dungeons()
	else:
		DungeonDirector.cycle_dungeons()
		FoodSystem.feed_goblins()
		PlayerData.day += 1
	
	PlayerData.home_base_data.heal_data.mark_groups_dirty()
	PlayerData.home_base_data.party_data.cycle_parties()
	PlayerData.market.mark_costs_dirty()
	if raided:
		# being raided results in the ui reflecting that you're at half your previous gold level
		PlayerData.raise_peaks()
	else:
		PlayerData.reset_peaks()
	PlayerData.print_gold_history()


func _show_splash(shower: Node) -> void:
	for next_shower: Node in splash_showers:
		next_shower.hide()
	shower.visible = true
