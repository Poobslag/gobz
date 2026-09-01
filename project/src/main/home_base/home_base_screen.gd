extends Control

const RECRUIT_COUNT: int = 3
const RECRUIT_ROW_SCENE: PackedScene = preload("res://src/main/home_base/home_base_recruit_row.tscn")
const DUNGEON_ROW_SCENE: PackedScene = preload("res://src/main/home_base/dungeon_preview_row.tscn")

const MAX_MULTIPLIER: float = 1.0e267

func _ready() -> void:
	for child: Node in %Recruits.get_children():
		%Recruits.remove_child(child)
		child.queue_free()
	
	_refresh_recruits()
	_refresh_summary()
	_refresh_dungeons()
	
	%FightButton.pressed.connect(func() -> void:
		PlayerSave.save_data()
		get_tree().change_scene_to_file("res://src/main/battle/dungeon_select_screen.tscn"))
	
	%CommandPalette.command_entered.connect(_on_command_palette_command_entered)
	
	if PlayerData.home_base_multiplier.is_eq(1) and PlayerData.gold.is_lt(80):
		%MultiplyButton.visible = false
		%DivideButton.visible = false
	
	%MultiplyButton.pressed.connect(_adjust_multiplier.bind(10.0))
	%DivideButton.pressed.connect(_adjust_multiplier.bind(1/10.0))
	%TutorialButton.pressed.connect(%TutorialPanel.open)
	
	if not PlayerData.finished_tutorials.has(PlayerData.HOME_BASE_TUTORIAL):
		%TutorialPanel.open()
		PlayerData.finished_tutorials[PlayerData.HOME_BASE_TUTORIAL] = true


func _refresh_dungeons() -> void:
	for child: Node in %Dungeons.get_children():
		%Dungeons.remove_child(child)
		child.queue_free()
	
	for dungeon: Dungeon in PlayerData.dungeons:
		dungeon.perform_recon()
	
	for dungeon: Dungeon in PlayerData.dungeons:
		var dungeon_select_info: Dictionary[String, String] = Dungeons.get_dungeon_select_info(dungeon)
		var dungeon_row: Label = DUNGEON_ROW_SCENE.instantiate()
		dungeon_row.text = "%s %s, %s" % [
				dungeon_select_info["emoji_string"],
				dungeon_select_info["name"], dungeon_select_info["attack_string"]
		]
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
	%ArmyLabel.text += Gobs.army_bbcode(PlayerData.army) + "\n\n"
	%ArmyLabel.text += "💰%s" % [PlayerData.gold.to_aa()]


func _refresh_recruits() -> void:
	while %Recruits.get_child_count() < RECRUIT_COUNT:
		var recruit_row: HomeBaseRecruitRow = RECRUIT_ROW_SCENE.instantiate()
		recruit_row.recruit_pressed.connect(_recruit.bind(recruit_row))
		recruit_row.skip_pressed.connect(_skip.bind(recruit_row))
		%Recruits.add_child(recruit_row)
	for recruit_row: HomeBaseRecruitRow in %Recruits.get_children():
		recruit_row.refresh()
	
	%MultiplyButton.disabled = PlayerData.gold.is_lt(Big.mul(PlayerData.home_base_multiplier, 80)) \
			or PlayerData.home_base_multiplier.is_gt(MAX_MULTIPLIER)
	%DivideButton.disabled = PlayerData.home_base_multiplier.is_lte(1)


func _recruit(recruit_row: HomeBaseRecruitRow) -> void:
	if PlayerData.gold.is_lt(recruit_row.get_cost()):
		return
	
	PlayerData.take_gold(recruit_row.get_cost())
	PlayerData.army.add_gob(recruit_row.gob)
	
	%Recruits.remove_child(recruit_row)
	recruit_row.queue_free()
	_refresh_recruits()
	_refresh_summary()


func _skip(recruit_row: HomeBaseRecruitRow) -> void:
	%Recruits.remove_child(recruit_row)
	recruit_row.queue_free()
	_refresh_recruits()


func _adjust_multiplier(factor: float) -> void:
	@warning_ignore("narrowing_conversion")
	PlayerData.home_base_multiplier = Big.clamp(PlayerData.home_base_multiplier.to_float() * factor, 1, MAX_MULTIPLIER)
	for recruit_row: HomeBaseRecruitRow in %Recruits.get_children():
		%Recruits.remove_child(recruit_row)
		recruit_row.queue_free()
		_refresh_recruits()


func _on_command_palette_command_entered(command: String) -> void:
	match command:
		"army":
			print("----------")
			print("Army: %s goblins, %s attack" \
					% [PlayerData.army.get_total_goblins().to_aa(), PlayerData.army.get_total_attack().to_aa()])
			var army_json: Dictionary[String, Variant] = PlayerData.army.to_json_dict()
			print(JSON.stringify(army_json, "  "))
	match command.substr(0, 1):
		"g":
			if not command.substr(1).is_valid_int():
				push_warning("Invalid parameter: %s" % [command.substr(1)])
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
		"h":
			if not command.substr(1).is_valid_int():
				push_warning("Invalid parameter: %s" % [command.substr(1)])
				return
			var factor: float = 1.0 / float(command.substr(1))
			PlayerData.scale_army_units(factor)
			_refresh_recruits()
			_refresh_summary()
			for dungeon: Dungeon in PlayerData.dungeons:
				dungeon.perform_recon()
