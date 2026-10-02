extends Control

const RECRUIT_COUNT: int = 3
const RECRUIT_ROW_SCENE: PackedScene = preload("res://src/main/home_base/home_base_recruit_row.tscn")
const DUNGEON_SUMMARY_SCENE: PackedScene = preload("res://src/main/home_base/dungeon_summary.tscn")

const MAX_MULTIPLIER: float = 1.0e267

func _ready() -> void:
	%CommandPalette.command_entered.connect(_on_command_palette_command_entered)
	
	%MultiplyButton.pressed.connect(_adjust_multiplier.bind(10.0))
	%DivideButton.pressed.connect(_adjust_multiplier.bind(1/10.0))
	%TutorialButton.pressed.connect(%TutorialPanel.open)
	
	%NewDayPanel.ok_pressed.connect(_on_new_day_panel_ok_pressed)
	
	reset()


func reset() -> void:
	for child: Node in %Recruits.get_children():
		%Recruits.remove_child(child)
		child.queue_free()
	
	_refresh_recruits()
	_refresh_summary()
	_refresh_dungeons()
	
	var hide_multiply_buttons: bool = PlayerData.home_base_multiplier.is_eq(1) and PlayerData.gold.is_lt(80)
	%MultiplyButton.visible = not hide_multiply_buttons
	%DivideButton.visible = not hide_multiply_buttons
	
	%TutorialPanel.hide()
	%NewDayPanel.hide()
	
	if not PlayerData.finished_tutorials.has(PlayerData.HOME_BASE_TUTORIAL):
		%TutorialPanel.open()
		PlayerData.finished_tutorials[PlayerData.HOME_BASE_TUTORIAL] = true
	elif not PlayerData.food_record.shown:
		%NewDayPanel.play()
	
	if not %NewDayPanel.visible and _is_being_raided():
		_start_raid()


func _refresh_dungeons() -> void:
	for child: Node in %Dungeons.get_children():
		%Dungeons.remove_child(child)
		child.queue_free()
	
	for dungeon: Dungeon in PlayerData.dungeons:
		dungeon.perform_recon()
	
	for dungeon: Dungeon in PlayerData.dungeons:
		var dungeon_row: Control = DUNGEON_SUMMARY_SCENE.instantiate()
		dungeon_row.dungeon = dungeon
		dungeon_row.max_army_bar_width = 440
		%Dungeons.add_child(dungeon_row)


func _input(event: InputEvent) -> void:
	if %CommandPalette.has_focus():
		return
	
	match Utils.key_press(event):
		KEY_SLASH:
			%CommandPalette.open()
			get_viewport().set_input_as_handled()


func _refresh_summary() -> void:
	%ArmyLabel.text = ""
	%ArmyLabel.text = "Your army:\n"
	%ArmyLabel.text += Gobs.army_bbcode(PlayerData.army)
	%ArmyLabel.text += "\n\n"
	%ArmyLabel.text += "[i]%s[/i]\n" % [PlayerData.home_base_data.get_morale_message()]


func _refresh_recruits() -> void:
	while %Recruits.get_child_count() < RECRUIT_COUNT:
		_add_recruit_row()
	
	%MultiplyButton.disabled = PlayerData.gold.is_lt(Big.mul(PlayerData.home_base_multiplier, 80)) \
			or PlayerData.home_base_multiplier.is_gt(MAX_MULTIPLIER)
	%DivideButton.disabled = PlayerData.home_base_multiplier.is_lte(1)


func _add_recruit_row() -> HomeBaseRecruitRow:
	var recruit_row: HomeBaseRecruitRow = RECRUIT_ROW_SCENE.instantiate()
	recruit_row.recruit_pressed.connect(_recruit.bind(recruit_row))
	recruit_row.skip_pressed.connect(_skip.bind(recruit_row))
	recruit_row.top_margin = 0.0 if %Recruits.get_child_count() == 0 else 4.0
	%Recruits.add_child(recruit_row)
	recruit_row.refresh()
	return recruit_row


func _recruit(recruit_row: HomeBaseRecruitRow) -> void:
	if not PlayerData.can_spend(recruit_row.get_cost()):
		return
	
	PlayerData.take_gold(recruit_row.get_cost())
	PlayerData.army.add_gob(recruit_row.gob)
	for other_recruit_row: HomeBaseRecruitRow in %Recruits.get_children():
		other_recruit_row.refresh()
	
	match recruit_row.gob.type:
		Gobs.ANGEL:
			PlayerData.increment_stat(PlayerData.ANGEL_GOBLINS_RECRUITED, recruit_row.gob.get_count())
	
	recruit_row.play_recruit_animation()
	_replace_recruit_row(recruit_row)
	_refresh_summary()


func _skip(recruit_row: HomeBaseRecruitRow) -> void:
	recruit_row.play_skip_animation()
	_replace_recruit_row(recruit_row)


## Smoothly animate in a replacement recruit row for a recruit row which is being animated away.[br]
## [br]
## To smoothly animate the spacing in the Recruits VBoxContainer, we manually assign margins instead of relying on the
## separation property.
func _replace_recruit_row(recruit_row: HomeBaseRecruitRow) -> void:
	if recruit_row.get_index() == 0:
		%Recruits.get_child(1).tween_top_margin_to_zero()
	var replacement_row: HomeBaseRecruitRow = _add_recruit_row()
	replacement_row.play_appear_animation()


func _adjust_multiplier(factor: float) -> void:
	@warning_ignore("narrowing_conversion")
	PlayerData.home_base_multiplier = Big.clamp(PlayerData.home_base_multiplier.to_float() * factor, 1, MAX_MULTIPLIER)
	for recruit_row: HomeBaseRecruitRow in %Recruits.get_children():
		%Recruits.remove_child(recruit_row)
		recruit_row.queue_free()
		_refresh_recruits()


func _is_being_raided() -> bool:
	var raid_dungeon_index: int = DungeonDirector.find_raid_dungeon_index()
	return raid_dungeon_index >= 0 and PlayerData.dungeons[raid_dungeon_index].is_raiding()


func _start_raid() -> void:
	PlayerData.dungeon_index = DungeonDirector.find_raid_dungeon_index()
	get_tree().change_scene_to_file("res://src/main/battle/battle_screen.tscn")


func _on_new_day_panel_ok_pressed() -> void:
	if _is_being_raided():
		_start_raid()


func _on_command_palette_command_entered(command: String) -> void:
	var command_words: PackedStringArray = command.split(" ")
	match command_words[0]:
		"army":
			print("----------")
			print("Army: %s goblins, %s attack" \
					% [PlayerData.army.get_total_goblins().to_aa(), PlayerData.army.get_total_attack().to_aa()])
			var army_json: Dictionary[String, Variant] = PlayerData.army.to_json_dict()
			print(JSON.stringify(army_json, "  "))
		"less":
			if command_words.size() < 2 or float(command_words[1]) <= 0:
				push_warning("Invalid command: %s" % [command])
				return
			var factor: float = 1.0 / float(command_words[1])
			PlayerData.scale_army_units(factor)
			_refresh_recruits()
			_refresh_summary()
			for dungeon: Dungeon in PlayerData.dungeons:
				dungeon.perform_recon()
		"more":
			if command_words.size() < 2 or float(command_words[1]) <= 0:
				push_warning("Invalid command: %s" % [command])
				return
			var factor: float = float(command.substr(1))
			PlayerData.scale_army_units(factor)
			_refresh_recruits()
			_refresh_summary()
			for dungeon: Dungeon in PlayerData.dungeons:
				dungeon.perform_recon()
			
			if PlayerData.gold.is_gte(80):
				%MultiplyButton.visible = true
				%DivideButton.visible = true
		"raid":
			if command_words.size() < 2 or int(command_words[1]) <= -1:
				push_warning("Invalid command: %s" % [command])
				return
			var raid_dungeon_index: int = DungeonDirector.find_raid_dungeon_index()
			if raid_dungeon_index == -1:
				# if there is no raiding dungeon, add a raiding dungeon
				PlayerData.raid_chance = 1.0
				DungeonDirector.cycle_dungeons()
				PlayerData.food_record.shown = false
				raid_dungeon_index = DungeonDirector.find_raid_dungeon_index()
			# set the raiding dungeon's days
			PlayerData.dungeons[raid_dungeon_index].raid_days = int(command_words[1])
			# show the notification and reset
			PlayerData.food_record.shown = false
			reset()
