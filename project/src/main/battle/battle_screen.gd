extends Control

func _ready() -> void:
	%PickPanel.finished.connect(_on_pick_panel_finished)
	%WatchPanel.finished.connect(_on_watch_panel_finished)
	%ResultsPanel.finished.connect(_on_results_panel_finished)
	%PickPanel.tutorial_pressed.connect(%TutorialPanel.open)
	%WatchPanel.tutorial_pressed.connect(%TutorialPanel.open)
	
	show_pick_panel()
	
	if not PlayerData.finished_tutorials.has(PlayerData.BATTLE_TUTORIAL):
		%TutorialPanel.open()
		PlayerData.finished_tutorials[PlayerData.BATTLE_TUTORIAL] = true


func hide_tutorial_panel() -> void:
	%TutorialPanel.hide()


func show_pick_panel() -> void:
	%WatchPanel.hide()
	%ResultsPanel.hide()
	%PickPanel.show()
	%PickPanel.clear_orders()
	%PickPanel.refresh()


func show_results_panel() -> void:
	%PickPanel.hide()
	%WatchPanel.hide()
	%ResultsPanel.show()
	
	HomeBaseData.heal_data.reroll_wound_severity(%WatchPanel.gob_battle_status)
	MoraleBattleResolver.update_gob_battle_morale(%WatchPanel.gob_battle_status)
	
	var dead_gob_ids: Dictionary[int, bool] = {}
	for gob: Gob in %WatchPanel.gob_battle_status.get_gobs():
		if %WatchPanel.gob_battle_status.has_action(gob, GobBattleStatus.KILLED):
			dead_gob_ids[gob.id] = true
	MoraleRelationshipResolver.apply_death_morale(dead_gob_ids)
	MoraleRelationshipResolver.create_random_relationships(0.08, 0.04)


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
		show_results_panel()
		%ResultsPanel.retreat()
	else:
		%PickPanel.hide()
		%ResultsPanel.hide()
		%WatchPanel.show()
		%WatchPanel.play(player_orders, enemy_orders)


func _on_watch_panel_finished() -> void:
	if PlayerData.army.is_empty() \
			or not PlayerData.has_current_dungeon() \
			or PlayerData.get_dungeon_army().is_empty():
		show_results_panel()
		if PlayerData.army.is_empty() and PlayerData.get_dungeon_army().is_empty():
			%ResultsPanel.mutual_defeat()
		elif PlayerData.army.is_empty():
			%ResultsPanel.defeat()
		else:
			%ResultsPanel.victory()
	else:
		show_pick_panel()


func _on_results_panel_finished() -> void:
	PlayerSave.save_data()
	get_tree().change_scene_to_file("res://src/main/home_base/home_base_screen.tscn")
