extends ColorRect

signal finished

## Player's goblins which were hit and need their wound severity rerolled.
var player_hit_gobs: Dictionary[Gob, bool] = {}

var _initial_enemy_orders: Array[Gobs.Type] = []
var _initial_player_orders: Array[Gobs.Type] = []
var _player_orders: Array[Gobs.Type] = []
var _enemy_orders: Array[Gobs.Type] = []

func _ready() -> void:
	%NextButton.pressed.connect(_on_next_button_pressed)
	refresh()


func play(new_player_orders: Array[Gobs.Type], new_enemy_orders: Array[Gobs.Type]) -> void:
	if Global.verbose_stdout_mode and PlayerData.has_current_dungeon():
		print('----------')
		var datetime: Dictionary = Time.get_datetime_dict_from_system(true)
		var datetime_str: String = "%04d-%02d-%02d %02d:%02d:%02d" % [
				datetime["year"], datetime["month"], datetime["day"],
				datetime["hour"], datetime["minute"], datetime["second"]]
		print('%s - Start battle, %s vs %s' % [
				datetime_str,
				PlayerData.army.get_total_goblins().to_aa(),
				PlayerData.get_dungeon_army().get_total_goblins().to_aa()])
	
	_initial_enemy_orders = new_enemy_orders.duplicate()
	_initial_player_orders = new_player_orders.duplicate()
	_player_orders = new_player_orders
	_enemy_orders = new_enemy_orders
	
	_erase_invalid_orders(_player_orders, PlayerData.army)
	_erase_invalid_orders(_enemy_orders, PlayerData.get_dungeon_army())
	
	_play_next()


func refresh() -> void:
	%YourGoblins.text = ""
	%YourGoblins.text += "You:\n"
	%YourGoblins.text += Gobs.army_bbcode(PlayerData.army)
	
	%EnemyGoblins.text = ""
	if PlayerData.has_current_dungeon():
		%EnemyGoblins.text += "Bad guys:\n"
		%EnemyGoblins.text += Gobs.army_bbcode(PlayerData.get_dungeon_army())
	
	var next_button_text: String = "Next"
	if PlayerData.army.is_empty() \
			or PlayerData.get_dungeon_army().is_empty() \
			or (_player_orders.is_empty() and _enemy_orders.is_empty()):
		next_button_text = "Done"
	%NextButton.text = next_button_text


func get_kill_report(source_type: Gobs.Type, kills: Array[BattleResolver.Kill]) -> Array[Dictionary]:
	var kills_by_type: Dictionary[Gobs.Type, Big] = {}
	for kill: BattleResolver.Kill in kills:
		if not kills_by_type.has(kill.target.type):
			kills_by_type[kill.target.type] = Big.ZERO
		kills_by_type[kill.target.type] = Big.add(kills_by_type[kill.target.type], kill.kill_count)
	
	var result: Array[Dictionary] = []
	for type: Gobs.Type in kills_by_type.keys():
		result.append({
			"type": type,
			"kill_count": kills_by_type[type],
			"effectiveness": BattleResolver.effectiveness(source_type, type),
		})
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a["kill_count"].is_gt(b["kill_count"]))
	return result


func _get_wave_count() -> int:
	return maxi(_player_orders.size(), _enemy_orders.size())


func _play_next() -> void:
	%SplashArt.flip_h = not %SplashArt.flip_h
	
	%YourAttack.text = ""
	%EnemyAttack.text = ""
	
	var player_order_emojis: Array[String] = []
	for order: Gobs.Type in _player_orders:
		player_order_emojis.append(Gobs.emoji_from_type(order))
	if player_order_emojis:
		%WaveLabel.text = "Orders: %s" % ["→".join(player_order_emojis)]
	else:
		%WaveLabel.text = ""
	
	if PlayerData.has_current_dungeon() and Global.verbose_stdout_mode:
		print('----------')
		print('player_orders = %s' % [_verbose_order_string(_player_orders)])
		print('player_army.from_glob(%s)' % [_verbose_army_string(PlayerData.army)])
		print('enemy_orders = %s' % [_verbose_order_string(_enemy_orders)])
		print('enemy_army.from_glob(%s)' % [_verbose_army_string(PlayerData.get_dungeon_army())])
	
	if PlayerData.has_current_dungeon():
		var player_army: Army = PlayerData.army
		var player_army_summary: Army.ArmySummary = player_army.get_summary()
		var player_type: Gobs.Type
		var enemy_army: Army = PlayerData.get_dungeon_army()
		var enemy_army_summary: Army.ArmySummary = enemy_army.get_summary()
		var enemy_type: Gobs.Type
		var player_attacks: Array[BattleResolver.Attack] = []
		var enemy_attacks: Array[BattleResolver.Attack] = []
		if not _player_orders.is_empty():
			player_type = _player_orders.pop_front()
			player_attacks = BattleResolver.plan_attacks(player_army, player_type)
		if not _enemy_orders.is_empty():
			enemy_type = _enemy_orders.pop_front()
			enemy_attacks = BattleResolver.plan_attacks(enemy_army, enemy_type)
		var player_kills: Array[BattleResolver.Kill] \
				= BattleResolver.resolve_attacks(player_army, enemy_army, player_attacks, _initial_enemy_orders)
		var enemy_kills: Array[BattleResolver.Kill] \
				= BattleResolver.resolve_attacks(enemy_army, player_army, enemy_attacks, _initial_player_orders)
		var player_level_ups: Array[BattleResolver.LevelUp] = BattleResolver.resolve_level_ups(player_army)
		var enemy_level_ups: Array[BattleResolver.LevelUp] = BattleResolver.resolve_level_ups(enemy_army)
		
		if not player_attacks.is_empty():
			if player_army_summary.goblins_by_type.get(player_type).is_gt(0):
				%YourAttack.text += "%s Your %s goblins attack:\n" % \
						[Gobs.emoji_from_type(player_type),
							player_army_summary.goblins_by_type.get(player_type).to_aa()]
			
			var kill_report: Array[Dictionary] = get_kill_report(player_type, player_kills)
			for kill_report_gob: Dictionary in kill_report:
				var kill_strings: Array[String] = []
				if kill_report_gob["kill_count"].is_gt(0):
					kill_strings.append("%s×%s killed" %
							[kill_report_gob["kill_count"].to_aa(),
									Gobs.emoji_from_type(kill_report_gob["type"])])
				
				var new_enemy_army_summary: Army.ArmySummary = enemy_army.get_summary()
				var wounded_count: Big = Big.sub(new_enemy_army_summary.wounded_by_type.get(kill_report_gob["type"]), 
						enemy_army_summary.wounded_by_type.get(kill_report_gob["type"]))
				if wounded_count.is_gt(0):
					kill_strings.append("%s×%s wounded" %
							[wounded_count.to_aa(),
									Gobs.emoji_from_type(kill_report_gob["type"])])
				
				var effectiveness_string: String = ""
				if kill_report_gob["effectiveness"] > 1.0:
					effectiveness_string = "Very effective!"
				elif kill_report_gob["effectiveness"] < 1.0:
					effectiveness_string = "Not very effective..."
				%YourAttack.text += "%s. %s\n" % [", ".join(kill_strings), effectiveness_string]
		
		if not player_level_ups.is_empty():
			_append_level_up_announcements(%YourAttack, player_level_ups)
		
		if not enemy_attacks.is_empty():
			if enemy_army_summary.goblins_by_type.get(enemy_type).is_gt(0):
				%EnemyAttack.text += "%s %s enemy goblins attack:\n" \
						% [Gobs.emoji_from_type(enemy_type),
							enemy_army_summary.goblins_by_type.get(enemy_type).to_aa()]
			
			var kill_report: Array[Dictionary] = get_kill_report(enemy_type, enemy_kills)
			for kill_report_gob: Dictionary in kill_report:
				var kill_strings: Array[String] = []
				if kill_report_gob["kill_count"].is_gt(0):
					kill_strings.append("%s×%s killed" %
							[kill_report_gob["kill_count"].to_aa(),
									Gobs.emoji_from_type(kill_report_gob["type"])])
				
				var new_player_army_summary: Army.ArmySummary = player_army.get_summary()
				var wounded_count: Big = Big.sub(new_player_army_summary.wounded_by_type.get(kill_report_gob["type"]), 
						player_army_summary.wounded_by_type.get(kill_report_gob["type"]))
				if wounded_count.is_gt(0):
					kill_strings.append("%s×%s wounded" %
							[wounded_count.to_aa(),
									Gobs.emoji_from_type(kill_report_gob["type"])])
				
				var effectiveness_string: String = ""
				if kill_report_gob["effectiveness"] > 1.0:
					effectiveness_string = "A terrible blow!"
				elif kill_report_gob["effectiveness"] < 1.0:
					effectiveness_string = "Not very effective..."
				%EnemyAttack.text += "%s. %s\n" % [", ".join(kill_strings), effectiveness_string]
			
		if not enemy_level_ups.is_empty():
			_append_level_up_announcements(%EnemyAttack, enemy_level_ups)
		
		for enemy_kill: BattleResolver.Kill in enemy_kills:
			player_hit_gobs[enemy_kill.target] = true
	
	%YourAttack.text = %YourAttack.text.strip_edges()
	%EnemyAttack.text = %EnemyAttack.text.strip_edges()
	
	_erase_invalid_orders(_player_orders, PlayerData.army)
	_erase_invalid_orders(_enemy_orders, PlayerData.get_dungeon_army())
	
	refresh()
	PlayerData.mark_ripoff_factor_dirty()


func _append_level_up_announcements(text_area: RichTextLabel, level_ups: Array[BattleResolver.LevelUp]) -> void:
	var announcement_count: int = 0
	var other_goblin_count: Big = Big.ZERO
	for level_up: BattleResolver.LevelUp in level_ups:
		if announcement_count < 2:
			if level_up.gob.get_count().is_eq(1):
				text_area.text += "%s %s grew to level %s!\n" % \
						[Gobs.emoji_from_type(level_up.gob.type), level_up.gob.name, \
						level_up.gob.level]
			elif level_up.gob.get_count().is_eq(2):
				text_area.text += "%s %s + 1 other grew to level %s!\n" % \
						[Gobs.emoji_from_type(level_up.gob.type), level_up.gob.name, \
						level_up.gob.level]
			else:
				text_area.text += "%s %s + %s others grew to level %s!\n" % \
						[Gobs.emoji_from_type(level_up.gob.type), level_up.gob.name, \
						Big.sub(level_up.gob.get_count(), 1).to_aa(), level_up.gob.level]
			announcement_count += 1
		else:
			other_goblin_count = Big.add(other_goblin_count, level_up.gob.get_count())
	if other_goblin_count.is_gte(1):
		if other_goblin_count.is_eq(1):
			text_area.text += "1 other goblin leveled up!\n"
		else:
			text_area.text += "%s other goblins leveled up!\n" % \
					[other_goblin_count.to_aa()]


func _erase_invalid_orders(orders: Array[Gobs.Type], army: Army) -> void:
	var summary: Army.ArmySummary = army.get_summary()
	
	for order_index: int in range(orders.size() - 1, -1, -1):
		if summary.goblins_by_type[orders[order_index]].is_eq(0):
			orders.remove_at(order_index)


func _on_next_button_pressed() -> void:
	if PlayerData.army.is_empty() \
			or PlayerData.get_dungeon_army().is_empty() \
			or (_player_orders.is_empty() and _enemy_orders.is_empty()):
		finished.emit()
	else:
		_play_next()


static func _verbose_army_string(army: Army) -> String:
	var glob: String = army.to_glob()
	var glob_split: Array[String] = []
	for i in range(0, glob.length(), 80):
		glob_split.append(glob.substr(i, 80))
	return '"%s"' % ['"\n\t\t+ "'.join(glob_split)]


static func _verbose_order_string(orders: Array[Gobs.Type]) -> String:
	var order_strings: Array[String] = []
	for order: Gobs.Type in orders:
		order_strings.append("Gobs.%s" % [Utils.enum_to_snake_case(Gobs.Type, order).to_upper()])
	return "[%s]" % [", ".join(order_strings)]
