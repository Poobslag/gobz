extends Control

func _ready() -> void:
	%PickPanel.finished.connect(_on_pick_panel_finished)
	%WatchPanel.finished.connect(_on_watch_panel_finished)
	
	show_pick_panel()


func show_pick_panel() -> void:
	%PickPanel.show()
	%PickPanel.clear_orders()
	%PickPanel.refresh()
	%WatchPanel.hide()


func _on_pick_panel_finished() -> void:
	%PickPanel.hide()
	%WatchPanel.show()
	
	var player_orders: Array[Goblins.GoblinType] = %PickPanel.orders
	# calculate enemy orders
	var enemy_orders: Array[Goblins.GoblinType] = []
	if PlayerData.has_current_dungeon():
		enemy_orders = []
		var army_summary: Army.ArmySummary = PlayerData.get_dungeon_army().get_summary()
		for type: Goblins.GoblinType in Goblins.GoblinType.values():
			if army_summary.goblins_by_type[type] > 0:
				enemy_orders.append(type)
		enemy_orders.shuffle()
	
	%WatchPanel.play(player_orders, enemy_orders)


func _on_watch_panel_finished() -> void:
	if PlayerData.army.is_empty() \
			or not PlayerData.has_current_dungeon() \
			or PlayerData.get_dungeon_army().is_empty():
		get_tree().change_scene_to_file("res://src/main/home_base_screen.tscn")
	else:
		show_pick_panel()
