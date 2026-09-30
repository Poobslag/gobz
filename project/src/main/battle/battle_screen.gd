extends Control

@onready var _panels: Array[Control] = [
	%BribePanel,
	%PickPanel,
	%WatchPanel,
	%ResultsPanel,
]

func _ready() -> void:
	%BribePanel.surrender_pressed.connect(_on_bribe_panel_surrender_pressed)
	%BribePanel.fight_pressed.connect(_on_bribe_panel_fight_pressed)
	%PickPanel.finished.connect(_on_pick_panel_finished)
	%WatchPanel.finished.connect(_on_watch_panel_finished)
	%ResultsPanel.finished.connect(_on_results_panel_finished)
	%PickPanel.tutorial_pressed.connect(%TutorialPanel.open)
	%WatchPanel.tutorial_pressed.connect(%TutorialPanel.open)
	%BribePanel.tutorial_pressed.connect(%TutorialPanel.open)
	
	if PlayerData.has_current_dungeon() and PlayerData.get_dungeon().is_raiding():
		show_bribe_panel()
	else:
		show_pick_panel()
	
	if not PlayerData.finished_tutorials.has(PlayerData.BATTLE_TUTORIAL):
		%TutorialPanel.open()
		PlayerData.finished_tutorials[PlayerData.BATTLE_TUTORIAL] = true


func hide_tutorial_panel() -> void:
	%TutorialPanel.hide()


func show_bribe_panel() -> void:
	_show_panel(%BribePanel)


func show_pick_panel() -> void:
	_show_panel(%PickPanel)
	%PickPanel.clear_orders()
	%PickPanel.refresh()


func show_results_panel(battle_result: Events.BattleResult) -> void:
	_show_panel(%ResultsPanel)
	%ResultsPanel.show_result(battle_result)
	
	HomeBaseData.heal_data.reroll_wound_severity(%WatchPanel.gob_battle_status)
	MoraleBattleResolver.update_gob_battle_morale(%WatchPanel.gob_battle_status)
	
	var dead_gob_ids: Dictionary[int, bool] = {}
	for gob: Gob in %WatchPanel.gob_battle_status.get_gobs():
		if %WatchPanel.gob_battle_status.has_action(gob, GobBattleStatus.KILLED):
			dead_gob_ids[gob.id] = true
	MoraleRelationshipResolver.apply_death_morale(dead_gob_ids)
	MoraleRelationshipResolver.create_random_relationships(0.08, 0.04)


func _show_panel(panel: Control) -> void:
	for other_panel: Control in _panels:
		other_panel.hide()
	panel.show()


func _on_pick_panel_finished() -> void:
	var player_orders: Array[Gobs.Type] = %PickPanel.orders
	# calculate enemy orders
	var enemy_orders: Array[Gobs.Type] = []
	if PlayerData.has_current_dungeon():
		enemy_orders = []
		var army_summary: Army.ArmySummary = PlayerData.get_dungeon_army().get_summary()
		for type: Gobs.Type in Gobs.Type.values():
			if army_summary.goblins_by_type[type].is_gt(0):
				enemy_orders.append(type)
		enemy_orders.shuffle()
	
	if player_orders.is_empty():
		show_results_panel(Events.BattleResult.RETREAT)
	else:
		_show_panel(%WatchPanel)
		%WatchPanel.play(player_orders, enemy_orders)


func _on_watch_panel_finished() -> void:
	if PlayerData.army.is_empty() \
			or not PlayerData.has_current_dungeon() \
			or PlayerData.get_dungeon_army().is_empty():
		var battle_result: Events.BattleResult
		if PlayerData.army.is_empty() and PlayerData.get_dungeon_army().is_empty():
			battle_result = Events.BattleResult.MUTUAL_DEFEAT
		elif PlayerData.army.is_empty():
			battle_result = Events.BattleResult.DEFEAT
		else:
			battle_result = Events.BattleResult.VICTORY
		show_results_panel(battle_result)
	else:
		show_pick_panel()


func _on_results_panel_finished() -> void:
	PlayerSave.save_data()
	
	# determine if any dungeons are raiding (raid_days == 0)
	var raiding_dungeon_index: int = -1
	for dungeon_index: int in PlayerData.dungeons.size():
		var dungeon: Dungeon = PlayerData.dungeons[dungeon_index]
		if dungeon.is_raiding():
			raiding_dungeon_index = dungeon_index
			break
	
	if raiding_dungeon_index >= 0:
		PlayerData.dungeon_index = raiding_dungeon_index
		get_tree().change_scene_to_file("res://src/main/battle/battle_screen.tscn")
	else:
		get_tree().change_scene_to_file("res://src/main/home_base/home_base_screen.tscn")


func _on_bribe_panel_surrender_pressed() -> void:
	show_results_panel(Events.BattleResult.SURRENDER)


func _on_bribe_panel_fight_pressed() -> void:
	show_pick_panel()
