extends ColorRect

signal finished

var _player_orders: Array[Goblins.GoblinType] = []
var _enemy_orders: Array[Goblins.GoblinType] = []
var _player_order_index: int = 0
var _enemy_order_index: int = 0
var current_wave: int = 0
var wave_count: int = 0

func _ready() -> void:
	%NextButton.pressed.connect(_on_next_button_pressed)
	refresh()


func play(new_player_orders: Array[Goblins.GoblinType], new_enemy_orders: Array[Goblins.GoblinType]) -> void:
	_player_orders = new_player_orders
	_enemy_orders = new_enemy_orders
	_player_order_index = 0
	_enemy_order_index = 0
	current_wave = 0
	wave_count = maxi(new_player_orders.size(), new_enemy_orders.size())
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
	if PlayerData.army.is_empty() or PlayerData.get_dungeon_army().is_empty() or current_wave >= wave_count - 1:
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


func _play_next() -> void:
	%YourAttack.text = ""
	%EnemyAttack.text = ""
	%WaveLabel.text = "Wave %s of %s" % [current_wave + 1, wave_count]
	if PlayerData.has_current_dungeon():
		var player_army: Army = PlayerData.army
		var player_army_summary: Army.ArmySummary = player_army.get_summary()
		var player_type: Goblins.GoblinType
		var enemy_army: Army = PlayerData.get_dungeon_army()
		var enemy_army_summary: Army.ArmySummary = enemy_army.get_summary()
		var enemy_type: Goblins.GoblinType
		var player_attacks: Array[BattleResolver.Attack] = []
		var enemy_attacks: Array[BattleResolver.Attack] = []
		if _player_order_index < _player_orders.size():
			player_type = _player_orders[_player_order_index]
			while player_army_summary.goblins_by_type[player_type] == 0:
				_player_order_index += 1
				if _player_order_index >= _player_orders.size():
					break
				player_type = _player_orders[_player_order_index]
			player_attacks = BattleResolver.plan_attacks( \
					player_army, enemy_army, player_type)
		if _enemy_order_index < _enemy_orders.size():
			enemy_type = _enemy_orders[_enemy_order_index]
			while enemy_army_summary.goblins_by_type[enemy_type] == 0:
				_enemy_order_index += 1
				if _enemy_order_index >= _enemy_orders.size():
					break
				enemy_type = _enemy_orders[_enemy_order_index]
			enemy_attacks = BattleResolver.plan_attacks( \
					enemy_army, player_army, enemy_type)
		var player_kills: Array[BattleResolver.Kill] \
				= BattleResolver.resolve_attacks(player_army, enemy_army, player_attacks)
		var enemy_kills: Array[BattleResolver.Kill] \
				= BattleResolver.resolve_attacks(enemy_army, player_army, enemy_attacks)
		var player_level_ups: Array[BattleResolver.LevelUp] = BattleResolver.resolve_level_ups(player_army)
		var enemy_level_ups: Array[BattleResolver.LevelUp] = BattleResolver.resolve_level_ups(enemy_army)
		
		if player_attacks.is_empty() and enemy_attacks.is_empty():
			%YourAttack.text += "No goblins are left!"
			%EnemyAttack.text += "No goblins are left!"
			current_wave = wave_count - 1
		
		if not player_attacks.is_empty():
			if player_army_summary.goblins_by_type.get(player_type) != 0:
				%YourAttack.text += "%s Your %s goblins attack:\n" % \
						[Goblins.emoji_from_type(player_type),
							player_army_summary.goblins_by_type.get(player_type)]
			
			var kill_report: Array[Dictionary] = get_kill_report(player_type, player_kills)
			for kill_report_item: Dictionary in kill_report:
				var kill_strings: Array[String] = []
				if kill_report_item["kill_count"] > 0:
					kill_strings.append("%s×%s killed" %
							[kill_report_item["kill_count"], Goblins.emoji_from_type(kill_report_item["type"])])
				if kill_report_item["wounded_count"] > 0:
					kill_strings.append("%s×%s wounded" %
							[kill_report_item["wounded_count"], Goblins.emoji_from_type(kill_report_item["type"])])
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
							enemy_army_summary.goblins_by_type.get(enemy_type)]
			
			var kill_report: Array[Dictionary] = get_kill_report(enemy_type, enemy_kills)
			for kill_report_item: Dictionary in kill_report:
				var kill_strings: Array[String] = []
				if kill_report_item["kill_count"] > 0:
					kill_strings.append("%s×%s killed" %
							[kill_report_item["kill_count"], Goblins.emoji_from_type(kill_report_item["type"])])
				if kill_report_item["wounded_count"] > 0:
					kill_strings.append("%s×%s wounded" %
							[kill_report_item["wounded_count"], Goblins.emoji_from_type(kill_report_item["type"])])
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
	
	refresh()


func _on_next_button_pressed() -> void:
	if PlayerData.army.is_empty() or PlayerData.get_dungeon_army().is_empty() or current_wave >= wave_count - 1:
		finished.emit()
	else:
		current_wave += 1
		_player_order_index += 1
		_enemy_order_index += 1
		_play_next()
