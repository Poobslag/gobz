extends Control

@onready var _panels: Array[Control] = [
	%BribePanel,
	%PickPanel,
	%WatchPanel,
	%ResultsPanel,
]

var _battle_state: BattleState

func _ready() -> void:
	%BribePanel.surrender_pressed.connect(show_results_panel.bind(Events.BattleResult.SURRENDER))
	%BribePanel.fight_pressed.connect(show_pick_panel)
	%PickPanel.fight_pressed.connect(_on_pick_panel_fight_pressed)
	%PickPanel.retreat_pressed.connect(_show_retreat)
	%WatchPanel.finished.connect(_on_watch_panel_finished)
	%WatchPanel.plan_pressed.connect(show_pick_panel)
	%WatchPanel.retreat_pressed.connect(_show_retreat)
	%ResultsPanel.finished.connect(_on_results_panel_finished)
	%PickPanel.tutorial_pressed.connect(%TutorialPanel.open)
	%WatchPanel.tutorial_pressed.connect(%TutorialPanel.open)
	%BribePanel.tutorial_pressed.connect(%TutorialPanel.open)
	
	if PlayerData.has_current_dungeon():
		if PlayerData.get_dungeon().is_raiding():
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
		
	if Global.verbose_stdout_mode and PlayerData.has_current_dungeon():
		print('----------')
		var datetime: Dictionary = Time.get_datetime_dict_from_system(true)
		var datetime_str: String = "%04d-%02d-%02d %02d:%02d:%02d" % [
				datetime["year"], datetime["month"], datetime["day"],
				datetime["hour"], datetime["minute"], datetime["second"]]
		print('%s - Battle planning phase, %s vs %s' % [
				datetime_str,
				PlayerData.army.get_total_goblins().to_aa(),
				PlayerData.get_dungeon_army().get_total_goblins().to_aa()])
	
	if _battle_state == null:
		_battle_state = BattleState.new(PlayerData.army, PlayerData.get_dungeon_army())
		
		# calculate enemy orders
		var enemy_orders: Array[Gobs.Type] = []
		var army_summary: ArmySummary = PlayerData.get_dungeon_army().get_summary()
		for type: Gobs.Type in Gobs.Type.values():
			if army_summary.goblins_by_type[type].is_gt(0):
				enemy_orders.append(type)
		enemy_orders.shuffle()
		_battle_state.update_enemy_orders(enemy_orders)
	
	%PickPanel.show_plan(_battle_state)


func show_results_panel(battle_result: Events.BattleResult) -> void:
	if _battle_state:
		# unfrag before applying morale
		_battle_state.unfrag()
	PlayerData.home_base_data.heal_data.reroll_wound_severity(%WatchPanel.gob_battle_status)
	MoraleBattleResolver.update_gob_battle_morale(%WatchPanel.gob_battle_status)
	
	_show_panel(%ResultsPanel)
	%ResultsPanel.show_result(battle_result)
	
	var dead_gob_ids: Dictionary[int, bool] = {}
	for gob_id: int in %WatchPanel.gob_battle_status.get_gob_ids():
		if %WatchPanel.gob_battle_status.has_action(gob_id, GobBattleStatus.KILLED):
			dead_gob_ids[gob_id] = true
	MoraleRelationshipResolver.apply_death_morale(dead_gob_ids)
	MoraleRelationshipResolver.create_random_relationships(0.08, 0.04)


func _show_panel(panel: Control) -> void:
	for other_panel: Control in _panels:
		other_panel.hide()
	panel.show()


func _show_retreat() -> void:
	show_results_panel(Events.BattleResult.DEFEAT if PlayerData.army.is_empty() else Events.BattleResult.RETREAT)


func _on_pick_panel_fight_pressed() -> void:
	_show_panel(%WatchPanel)
	_battle_state.update_player_orders(%PickPanel.orders)
	%WatchPanel.play(_battle_state)


func _on_watch_panel_finished() -> void:
	var battle_result: Events.BattleResult
	if PlayerData.army.is_empty() and PlayerData.get_dungeon_army().is_empty():
		battle_result = Events.BattleResult.MUTUAL_DEFEAT
	elif PlayerData.army.is_empty():
		battle_result = Events.BattleResult.DEFEAT
	elif PlayerData.get_dungeon_army().is_empty():
		battle_result = Events.BattleResult.VICTORY
	else:
		# should never reach here; watch panel should only finish if the enemy army is empty
		battle_result = Events.BattleResult.RETREAT
	show_results_panel(battle_result)


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
