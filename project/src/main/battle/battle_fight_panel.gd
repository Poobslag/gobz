extends ColorRect

signal finished
signal plan_pressed
signal retreat_pressed
signal tutorial_pressed

const MORALE_MESSAGE_FREQUENCY: float = 0.2
const MORALE_GOOD_PATH: String = "res://assets/main/battle/battle_morale_good.csv"
const MORALE_BAD_PATH: String = "res://assets/main/battle/battle_morale_bad.csv"

const EFFECTIVE_MESSAGE_THRESHOLD: float = 2.0
const INEFFECTIVE_MESSAGE_THRESHOLD: float = 0.66667

var _flavor_budget: float = randf()
var _battle_state: BattleState

var consecutive_retreat_presses: int = 0
var gob_battle_status: GobBattleStatus = GobBattleStatus.new()

func _ready() -> void:
	%Retreat.pressed.connect(_on_retreat_button_pressed)
	%Plan.pressed.connect(_on_plan_button_pressed)
	%NextButton.pressed.connect(_on_next_button_pressed)
	%TutorialButton.pressed.connect(_on_tutorial_pressed)


func play(new_battle_state: BattleState) -> void:
	consecutive_retreat_presses = 0
	_battle_state = new_battle_state
	_play_next()


func _deployments_label(deployments: Array[BattleState.Deployment]) -> String:
	return Gobs.count_label(deployments, func(deployment: BattleState.Deployment, tally: Gobs.TypeTally) -> void:
		tally.add(deployment.gob.type, deployment.count))


func _gobs_label(gobs: Array[Gob]) -> String:
	return Gobs.count_label(gobs, func(gob: Gob, tally: Gobs.TypeTally) -> void:
		tally.add(gob.type, gob.get_count()))


func _killed_targets_label(kills: Array[BattleResolver.Kill]) -> String:
	return Gobs.count_label(kills, func(kill: BattleResolver.Kill, tally: Gobs.TypeTally) -> void:
		if kill.kill_count.is_gt(0):
			tally.add(kill.target.type, kill.kill_count))


func _wounded_targets_label(kills: Array[BattleResolver.Kill]) -> String:
	return Gobs.count_label(kills, func(kill: BattleResolver.Kill, tally: Gobs.TypeTally) -> void:
		if kill.wounded_count.is_gt(0):
			tally.add(kill.target.type, kill.wounded_count))


func _play_next() -> void:
	%SplashArt.flip_h = not %SplashArt.flip_h
	
	var player_side_report: SideReport = SideReport.new()
	player_side_report.player = true
	var enemy_side_report: SideReport = SideReport.new()
	enemy_side_report.player = false
	
	var deploy_result: BattleState.DeployResult = _battle_state.deploy_next()
	player_side_report.deployments = deploy_result.player_deployments
	enemy_side_report.deployments = deploy_result.enemy_deployments
	player_side_report.active_gobs_label = _gobs_label(_battle_state.player_side.active_gobs)
	enemy_side_report.active_gobs_label = _gobs_label(_battle_state.enemy_side.active_gobs)
	
	# show the goblins after new goblins join in, but before any casualties
	%YourGoblins.text = ""
	%YourGoblins.text += "Your side:\n"
	%YourGoblins.text += _battle_side_bbcode(_battle_state.player_side)
	
	%EnemyGoblins.text = ""
	%EnemyGoblins.text += "Their side:\n"
	%EnemyGoblins.text += _battle_side_bbcode(_battle_state.enemy_side)
	
	player_side_report.attacks = BattleResolver.plan_player_attacks(_battle_state)
	enemy_side_report.attacks = BattleResolver.plan_enemy_attacks(_battle_state)
	player_side_report.kills = BattleResolver.resolve_player_attacks(_battle_state, player_side_report.attacks)
	enemy_side_report.kills = BattleResolver.resolve_enemy_attacks(_battle_state, enemy_side_report.attacks)
	player_side_report.level_ups = BattleResolver.resolve_player_level_ups(_battle_state)
	enemy_side_report.level_ups = BattleResolver.resolve_enemy_level_ups(_battle_state)
	player_side_report.wiped_out = _battle_state.player_side.is_empty()
	enemy_side_report.wiped_out = _battle_state.enemy_side.is_empty()
	
	%YourAttack.text = _format_side_report(player_side_report)
	%EnemyAttack.text = _format_side_report(enemy_side_report)
	
	# update gob_battle_status
	for level_up: BattleResolver.LevelUp in player_side_report.level_ups:
		var level_up_id: int = _battle_state.player_side.get_frag_root_id(level_up.gob)
		gob_battle_status.record_action(level_up_id, GobBattleStatus.LEVELED_UP)
	for kill: BattleResolver.Kill in enemy_side_report.kills:
		var target_id: int = _battle_state.player_side.get_frag_root_id(kill.target)
		gob_battle_status.record_action(target_id, GobBattleStatus.HIT)
		if kill.wounded_count.is_gt(0):
			gob_battle_status.record_action(target_id, GobBattleStatus.WOUNDED)
		if kill.kill_count.is_gt(0):
			gob_battle_status.record_action(target_id, GobBattleStatus.KILLED)
	for kill: BattleResolver.Kill in player_side_report.kills:
		var source_id: int = _battle_state.player_side.get_frag_root_id(kill.source)
		gob_battle_status.record_action(source_id, GobBattleStatus.ENEMY_HIT)
		if kill.wounded_count.is_gt(0):
			gob_battle_status.record_action(source_id, GobBattleStatus.ENEMY_WOUNDED)
		if kill.kill_count.is_gt(0):
			gob_battle_status.record_action(source_id, GobBattleStatus.ENEMY_KILLED)
			gob_battle_status.enemies_killed = Big.add(gob_battle_status.enemies_killed, kill.kill_count)
	
	# update stats
	for kill: BattleResolver.Kill in player_side_report.kills:
		if kill.kill_count.is_gt(0):
			match kill.target.type:
				Gobs.Type.DEVIL:
					PlayerData.increment_stat(PlayerData.ENEMY_DEVIL_GOBLINS_KILLED, kill.kill_count)
	
	# handle random morale messages
	_flavor_budget += MORALE_MESSAGE_FREQUENCY
	if not player_side_report.wiped_out and %YourAttack.get_line_count() <= 6 and randf() < _flavor_budget:
		_show_random_morale_message(player_side_report.kills)
	
	_refresh_buttons()


func _format_side_report(side_report: SideReport) -> String:
	var result: String = ""
	if not side_report.deployments.is_empty() or not side_report.attacks.is_empty():
		# Join message: '8×💧 goblins join the fight!'
		if not side_report.deployments.is_empty():
			var join_message: String = "%s goblins join the fight!\n" % [_deployments_label(side_report.deployments)]
			if join_message.begins_with("1×"):
				join_message = join_message.replace("goblins join", "goblin joins")
			result += join_message
		
		# Attack message: '24×🔥💧 goblins attack:'
		if not side_report.active_gobs_label.is_empty():
			var attack_message: String = "%s goblins attack:\n" % [side_report.active_gobs_label]
			if attack_message.begins_with("1×"):
				attack_message = attack_message.replace("goblins attack", "goblin attacks")
			result += attack_message
		
		# Kill message: '4×😈 killed, 1x🌳 wounded. Not very effective...'
		var kill_message: String = ""
		if not side_report.kills.is_empty():
			var killed_targets_label: String = _killed_targets_label(side_report.kills)
			var kill_strings: Array[String] = []
			if not killed_targets_label.is_empty():
				kill_strings.append("%s killed" % [killed_targets_label])
			var wounded_targets_label: String = _wounded_targets_label(side_report.kills)
			if not wounded_targets_label.is_empty():
				kill_strings.append("%s wounded" % [wounded_targets_label])
			if not kill_strings.is_empty():
				var effectiveness_string: String = ""
				var average_effectiveness: float = BattleResolver.average_effectiveness(side_report.kills)
				if average_effectiveness > EFFECTIVE_MESSAGE_THRESHOLD:
					effectiveness_string = "Very effective!" if side_report.player else "A terrible blow!"
				if average_effectiveness < INEFFECTIVE_MESSAGE_THRESHOLD:
					effectiveness_string = "Not very effective..."
				kill_message = "%s. %s\n" % [", ".join(kill_strings), effectiveness_string]
		if kill_message.is_empty():
			kill_message = "They're trying their best...\n"
		result += kill_message
		
		if side_report.wiped_out:
			result = _append_wiped_out_announcement(result, side_report)
		
		# Level up message: '🔥 Kleex grew to level 4!'
		if not side_report.wiped_out and not side_report.level_ups.is_empty():
			result = _append_level_up_announcements(result, side_report.level_ups)
	return result.strip_edges()


static func _battle_side_bbcode(battle_side: BattleState.BattleSide) -> String:
	var active_summary: ArmySummary = battle_side.get_active_summary()
	var result: String = ""
	result += "[b]%s of %s goblins fighting[/b]\n" % \
			[active_summary.total_goblins.to_aa(), battle_side.get_total_goblins().to_aa()]
	for goblin_type: Gobs.Type in Gobs.Type.values():
		if active_summary.goblins_by_type[goblin_type].is_gte(1):
			var type_attack_rating: String = Gobs.attack_rating(
					active_summary.attack_by_type[goblin_type].to_float() \
							/ active_summary.goblins_by_type[goblin_type].to_float())
			var wounded_string: String = ""
			if active_summary.wounded_by_type[goblin_type].is_gte(1):
				var wounded_percent: float = 100 * active_summary.wounded_by_type[goblin_type].to_float() \
						/ active_summary.goblins_by_type[goblin_type].to_float()
				wounded_percent = max(wounded_percent, 1)
				wounded_string = "(%d%% 🩹) " % [wounded_percent]
			result += "%s: %s goblins %s%s\n" % [
					Gobs.EMOJIS_BY_GOBLIN_TYPE[goblin_type],
					active_summary.goblins_by_type[goblin_type].to_aa(),
					wounded_string,
					type_attack_rating]
	
	return result.strip_edges()


func _show_random_morale_message(player_kills: Array[BattleResolver.Kill]) -> void:
	if player_kills.is_empty():
		return
	
	_flavor_budget -= 1.0
	var random_gob: Gob = player_kills.pick_random().source
	var random_line: String
	if randf_range(0.0, 100.0) < random_gob.morale.value:
		random_line = LinePool.get_random_line(MORALE_GOOD_PATH)
	else:
		random_line = LinePool.get_random_line(MORALE_BAD_PATH)
	var random_kill_name: String = random_gob.name
	%YourAttack.text += "\n"
	%YourAttack.text += "[i]%s[/i]\n" % [random_line.format([["name", random_kill_name]])]


func _append_level_up_announcements(str_in: String, level_ups: Array[BattleResolver.LevelUp]) -> String:
	var str_out: String = str_in
	var announcement_count: int = 0
	var other_goblin_count: Big = Big.ZERO
	for level_up: BattleResolver.LevelUp in level_ups:
		if announcement_count < 2:
			if level_up.gob.get_count().is_eq(1):
				str_out += "%s %s grew to level %s!\n" % \
						[Gobs.emoji_from_type(level_up.gob.type), level_up.gob.name, \
						level_up.gob.level]
			elif level_up.gob.get_count().is_eq(2):
				str_out += "%s %s + 1 other grew to level %s!\n" % \
						[Gobs.emoji_from_type(level_up.gob.type), level_up.gob.name, \
						level_up.gob.level]
			else:
				str_out += "%s %s + %s others grew to level %s!\n" % \
						[Gobs.emoji_from_type(level_up.gob.type), level_up.gob.name, \
						Big.sub(level_up.gob.get_count(), 1).to_aa(), level_up.gob.level]
			announcement_count += 1
		else:
			other_goblin_count = Big.add(other_goblin_count, level_up.gob.get_count())
	if other_goblin_count.is_gte(1):
		if other_goblin_count.is_eq(1):
			str_out += "1 other goblin leveled up!\n"
		else:
			str_out += "%s other goblins leveled up!\n" % \
					[other_goblin_count.to_aa()]
	return str_out


func _append_wiped_out_announcement(str_in: String, side_report: SideReport) -> String:
	var str_out: String = str_in
	if side_report.player:
		str_out += "[b]Your goblins were wiped out![/b]\n"
	else:
		str_out += "[b]The enemy was wiped out![/b]"
	return str_out


func _refresh_buttons() -> void:
	# refresh query label
	%QueryLabel.text = "Really retreat?" if consecutive_retreat_presses >= 1 else ""
	
	# refresh retreat button
	%Retreat.text = "Retreat"
	%Retreat.disabled = false
	if _battle_state.enemy_side.is_empty():
		# victory; can't retreat
		pass
	elif PlayerData.army.is_empty():
		%Retreat.text = "Defeat"
	elif PlayerData.has_current_dungeon() and PlayerData.get_dungeon().is_raiding():
		%Retreat.text = "No escape!"
		%Retreat.disabled = true
	
	# refresh plan button
	%Plan.disabled = false
	if _battle_state.enemy_side.is_empty():
		# victory; can't plan
		pass
	elif _battle_state.player_side.active_gobs.size() == PlayerData.army.gobs.size():
		%Plan.disabled = true
	
	# refresh next button
	%NextButton.text = "Next"
	%NextButton.disabled = false
	if _battle_state.enemy_side.is_empty():
		%NextButton.text = "Done"
	elif _battle_state.player_side.is_empty():
		%NextButton.disabled = true


func _on_next_button_pressed() -> void:
	consecutive_retreat_presses = 0
	if _battle_state.player_side.is_empty() or _battle_state.enemy_side.is_empty():
		finished.emit()
	else:
		_play_next()


func _on_tutorial_pressed() -> void:
	consecutive_retreat_presses = 0
	tutorial_pressed.emit()
	_refresh_buttons()


func _on_retreat_button_pressed() -> void:
	consecutive_retreat_presses += 1
	if consecutive_retreat_presses >= 2 or PlayerData.army.is_empty():
		retreat_pressed.emit()
	_refresh_buttons()


func _on_plan_button_pressed() -> void:
	consecutive_retreat_presses = 0
	plan_pressed.emit()
	_refresh_buttons()


class SideReport:
	var player: bool = false
	var deployments: Array[BattleState.Deployment]
	var attacks: Array[BattleResolver.Attack]
	var active_gobs_label: String
	var kills: Array[BattleResolver.Kill]
	var level_ups: Array[BattleResolver.LevelUp]
	var wiped_out: bool = false
