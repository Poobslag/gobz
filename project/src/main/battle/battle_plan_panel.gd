extends ColorRect

signal tutorial_pressed
signal retreat_pressed
signal fight_pressed

var orders: Array[Gobs.Type] = []
var consecutive_retreat_presses: int = 0

var _battle_state: BattleState

@onready var button_by_type: Dictionary[Gobs.Type, Button] = {
		Gobs.FIRE: %Fire,
		Gobs.WATER: %Water,
		Gobs.GRASS: %Grass,
		Gobs.ANGEL: %Angel,
		Gobs.DEVIL: %Devil,
}

func _ready() -> void:
	for type: Gobs.Type in Gobs.Type.values():
		var button: Button = button_by_type[type]
		button.pressed.connect(_append_order.bind(type))
	%Fight.pressed.connect(_on_fight_pressed)
	%Retreat.pressed.connect(_on_retreat_pressed)
	%TutorialButton.pressed.connect(_on_tutorial_pressed)
	%Undo.pressed.connect(_on_undo_pressed)


func show_plan(new_battle_state: BattleState) -> void:
	consecutive_retreat_presses = 0
	_battle_state = new_battle_state
	orders.assign(_battle_state.player_side.get_reserve_types())
	refresh()


func clear_orders() -> void:
	orders.clear()


func refresh() -> void:
	%YourGoblins.text = ""
	%YourGoblins.text += "You:\n"
	%YourGoblins.text += _roster_bbcode(_battle_state.player_side)
	
	%EnemyGoblins.text = ""
	%EnemyGoblins.text += "Bad guys:\n"
	%EnemyGoblins.text += _roster_bbcode(_battle_state.enemy_side)
	
	var all_orders_given: bool = true
	
	# enable/disable type buttons
	var available_gob_types: Array[Gobs.Type] = _battle_state.player_side.get_available_types()
	for type: Gobs.Type in Gobs.Type.values():
		var button: Button = button_by_type[type]
		button.disabled = not available_gob_types.has(type) or orders.has(type)
		if not button.disabled:
			all_orders_given = false
	
	# update retreat button
	%Retreat.text = "Retreat"
	%Retreat.disabled = false
	if PlayerData.army.is_empty():
		%Retreat.text = "Defeat"
	elif PlayerData.has_current_dungeon() and PlayerData.get_dungeon().is_raiding():
		%Retreat.text = "No escape!"
		%Retreat.disabled = true
	
	# enable/disable undo button
	%Undo.disabled = orders.is_empty()
	
	# enable/disable fight button
	%Fight.disabled = orders.is_empty() and _battle_state.player_side.active_gobs.is_empty()
	
	var order_string: String = ""
	if not orders.is_empty():
		var order_emojis: Array[String] = []
		for order: Gobs.Type in orders:
			order_emojis.append(Gobs.EMOJIS_BY_GOBLIN_TYPE[order])
		order_string = "(Current orders: %s)" % [", ".join(order_emojis)]
	var query: String = ""
	if consecutive_retreat_presses >= 1:
		query = "Really retreat?"
	elif all_orders_given:
		query = "Your goblins are ready!"
	elif orders.is_empty():
		query = "Who should attack first?"
	else:
		query = "Who should attack next?"
	%QueryLabel.text = "%s %s" % [query, order_string]
	
	var player_disadvantage: bool = PlayerData.has_current_dungeon() \
			and PlayerData.get_dungeon_army().get_total_attack().is_gte(PlayerData.army.get_total_attack())
	%SplashArt.flip_h = player_disadvantage


func _roster_bbcode(battle_side: BattleState.BattleSide) -> String:
	var result: String = Gobs.army_bbcode(battle_side.army)
	if not battle_side.active_gobs.is_empty():
		result += "\n"
		result += "Already fighting: %s" % [_active_gobs_label(battle_side)]
	return result


func _active_gobs_label(battle_side: BattleState.BattleSide) -> String:
	return Gobs.count_label(battle_side.active_gobs, func(gob: Gob, tally: Gobs.TypeTally) -> void:
			tally.add(gob.type, gob.get_count()))


func _append_order(type: Gobs.Type) -> void:
	consecutive_retreat_presses = 0
	if not orders.has(type):
		orders.push_back(type)
	refresh()


func _on_fight_pressed() -> void:
	consecutive_retreat_presses = 0
	fight_pressed.emit()


func _on_retreat_pressed() -> void:
	consecutive_retreat_presses += 1
	if consecutive_retreat_presses >= 2 or PlayerData.army.is_empty():
		retreat_pressed.emit()
	refresh()


func _on_tutorial_pressed() -> void:
	consecutive_retreat_presses = 0
	tutorial_pressed.emit()


func _on_undo_pressed() -> void:
	consecutive_retreat_presses = 0
	if not orders.is_empty():
		var popped_order: Gobs.Type = orders.pop_back()
		_battle_state.player_side.remove_reserve_type(popped_order)
	refresh()
