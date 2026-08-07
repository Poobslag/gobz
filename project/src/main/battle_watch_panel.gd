extends ColorRect

signal finished

var _player_orders: Array[Goblins.GoblinType] = []
var _enemy_orders: Array[Goblins.GoblinType] = []

func _ready() -> void:
	%NextButton.pressed.connect(_on_next_button_pressed)
	refresh()


func play(new_player_orders: Array[Goblins.GoblinType], new_enemy_orders: Array[Goblins.GoblinType]) -> void:
	_player_orders = new_player_orders
	_enemy_orders = new_enemy_orders
	
	_erase_invalid_orders(_player_orders, PlayerData.army)
	_erase_invalid_orders(_enemy_orders, PlayerData.get_dungeon_army())
	
	_play_next()


func refresh() -> void:
	%YourGoblins.text = ""
	%YourGoblins.text += "You:\n"
	%YourGoblins.text += Goblins.army_bbcode(PlayerData.army)
	
	%EnemyGoblins.text = ""
	if PlayerData.has_current_dungeon():
		%EnemyGoblins.text += "Bad guys:\n"
		%EnemyGoblins.text += Goblins.army_bbcode(PlayerData.get_dungeon_army())
	
	var next_button_text: String = "Next"
	if PlayerData.army.is_empty() \
			or PlayerData.get_dungeon_army().is_empty() \
			or (_player_orders.is_empty() and _enemy_orders.is_empty()):
		next_button_text = "Done"
	%NextButton.text = next_button_text


func get_kill_report(source_type: Goblins.GoblinType, kills: Array[BattleResolver.Kill]) -> Array[Dictionary]:
	var kills_by_type: Dictionary[Goblins.GoblinType, int] = {}
	var wounded_set: Dictionary[Army.ArmyItem, bool] = {}
	var wounded_by_type: Dictionary[Goblins.GoblinType, int] = {}
	for kill: BattleResolver.Kill in kills:
		if not kills_by_type.has(kill.target.type):
			kills_by_type[kill.target.type] = 0
			wounded_by_type[kill.target.type] = 0
		kills_by_type[kill.target.type] += kill.kill_count
		if not wounded_set.has(kill.target):
			wounded_by_type[kill.target.type] += kill.wounded_count
			wounded_set[kill.target] = true
	
	var result: Array[Dictionary] = []
	for type: Goblins.GoblinType in kills_by_type.keys():
		result.append({
			"type": type,
			"kill_count": kills_by_type[type],
			"wounded_count": wounded_by_type[type],
			"effectiveness": BattleResolver.effectiveness(source_type, type),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["kill_count"] > b["kill_count"])
	return result


func _get_wave_count() -> int:
	return maxi(_player_orders.size(), _enemy_orders.size())


func _play_next() -> void:
	%YourAttack.text = ""
	%EnemyAttack.text = ""
	
	var player_order_emojis: Array[String] = []
	for order: Goblins.GoblinType in _player_orders:
		player_order_emojis.append(Goblins.emoji_from_type(order))
	if player_order_emojis:
		%WaveLabel.text = "Orders: %s" % ["→".join(player_order_emojis)]
	else:
		%WaveLabel.text = ""
	
	if PlayerData.has_current_dungeon():
		var player_army: Army = PlayerData.army
		var player_army_summary: Army.ArmySummary = player_army.get_summary()
		var player_type: Goblins.GoblinType
		var enemy_army: Army = PlayerData.get_dungeon_army()
		var enemy_army_summary: Army.ArmySummary = enemy_army.get_summary()
		var enemy_type: Goblins.GoblinType
		var player_attacks: Array[BattleResolver.Attack] = []
		var enemy_attacks: Array[BattleResolver.Attack] = []
		if not _player_orders.is_empty():
			player_type = _player_orders.pop_front()
			player_attacks = BattleResolver.plan_attacks( \
					player_army, enemy_army, player_type, _enemy_orders)
		if not _enemy_orders.is_empty():
			enemy_type = _enemy_orders.pop_front()
			enemy_attacks = BattleResolver.plan_attacks( \
					enemy_army, player_army, enemy_type, _player_orders)
		var player_kills: Array[BattleResolver.Kill] \
				= BattleResolver.resolve_attacks(player_army, enemy_army, player_attacks)
		var enemy_kills: Array[BattleResolver.Kill] \
				= BattleResolver.resolve_attacks(enemy_army, player_army, enemy_attacks)
		var player_level_ups: Array[BattleResolver.LevelUp] = BattleResolver.resolve_level_ups(player_army)
		var enemy_level_ups: Array[BattleResolver.LevelUp] = BattleResolver.resolve_level_ups(enemy_army)
		
		if not player_attacks.is_empty():
			if player_army_summary.goblins_by_type.get(player_type) != 0:
				%YourAttack.text += "%s Your %s goblins attack:\n" % \
						[Goblins.emoji_from_type(player_type),
							Utils.abbr_num(player_army_summary.goblins_by_type.get(player_type))]
			
			var kill_report: Array[Dictionary] = get_kill_report(player_type, player_kills)
			for kill_report_item: Dictionary in kill_report:
				var kill_strings: Array[String] = []
				if kill_report_item["kill_count"] > 0:
					kill_strings.append("%s×%s killed" %
							[Utils.abbr_num(kill_report_item["kill_count"]),
									Goblins.emoji_from_type(kill_report_item["type"])])
				if kill_report_item["wounded_count"] > 0:
					kill_strings.append("%s×%s wounded" %
							[Utils.abbr_num(kill_report_item["wounded_count"]),
									Goblins.emoji_from_type(kill_report_item["type"])])
				var effectiveness_string: String = ""
				if kill_report_item["effectiveness"] > 1.0:
					effectiveness_string = "Very effective!"
				elif kill_report_item["effectiveness"] < 1.0:
					effectiveness_string = "Not very effective..."
				%YourAttack.text += "%s. %s\n" % [", ".join(kill_strings), effectiveness_string]
		
		if not player_level_ups.is_empty():
			for level_up: BattleResolver.LevelUp in player_level_ups:
				%YourAttack.text += "%s %s grew to level %s!\n" % \
						[Goblins.emoji_from_type(level_up.item.type), level_up.item.name, level_up.item.level]
		
		if not enemy_attacks.is_empty():
			if enemy_army_summary.goblins_by_type.get(enemy_type) != 0:
				%EnemyAttack.text += "%s %s enemy goblins attack:\n" \
						% [Goblins.emoji_from_type(enemy_type),
							Utils.abbr_num(enemy_army_summary.goblins_by_type.get(enemy_type))]
			
			var kill_report: Array[Dictionary] = get_kill_report(enemy_type, enemy_kills)
			for kill_report_item: Dictionary in kill_report:
				var kill_strings: Array[String] = []
				if kill_report_item["kill_count"] > 0:
					kill_strings.append("%s×%s killed" %
							[Utils.abbr_num(kill_report_item["kill_count"]),
									Goblins.emoji_from_type(kill_report_item["type"])])
				if kill_report_item["wounded_count"] > 0:
					kill_strings.append("%s×%s wounded" %
							[Utils.abbr_num(kill_report_item["wounded_count"]),
									Goblins.emoji_from_type(kill_report_item["type"])])
				var effectiveness_string: String = ""
				if kill_report_item["effectiveness"] > 1.0:
					effectiveness_string = "A terrible blow!"
				elif kill_report_item["effectiveness"] < 1.0:
					effectiveness_string = "Not very effective..."
				%EnemyAttack.text += "%s. %s\n" % [", ".join(kill_strings), effectiveness_string]
			
		if not enemy_level_ups.is_empty():
			for level_up: BattleResolver.LevelUp in enemy_level_ups:
				%EnemyAttack.text += "%s %s grew to level %s.\n" % \
						[Goblins.emoji_from_type(level_up.item.type), level_up.item.name, level_up.item.level]
	
	%YourAttack.text = %YourAttack.text.strip_edges()
	%EnemyAttack.text = %EnemyAttack.text.strip_edges()
	
	_erase_invalid_orders(_player_orders, PlayerData.army)
	_erase_invalid_orders(_enemy_orders, PlayerData.get_dungeon_army())
	
	refresh()


func _erase_invalid_orders(orders: Array[Goblins.GoblinType], army: Army) -> void:
	var summary: Army.ArmySummary = army.get_summary()
	
	for order_index: int in range(orders.size() - 1, -1, -1):
		if summary.goblins_by_type[orders[order_index]] == 0:
			orders.remove_at(order_index)


func _on_next_button_pressed() -> void:
	if PlayerData.army.is_empty() \
			or PlayerData.get_dungeon_army().is_empty() \
			or (_player_orders.is_empty() and _enemy_orders.is_empty()):
		finished.emit()
	else:
		_play_next()
