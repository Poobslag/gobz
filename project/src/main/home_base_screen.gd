extends Control

const RECRUIT_COUNT: int = 3
const RECRUIT_ROW_SCENE: PackedScene = preload("res://src/main/home_base_recruit_row.tscn")

const MAX_MULTIPLIER: int = 1_000_000_000_000_000

func _ready() -> void:
	for child: Node in %Recruits.get_children():
		%Recruits.remove_child(child)
		child.queue_free()
	
	_refresh_recruits()
	_refresh_summary()
	
	%FightButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/main/dungeon_select_screen.tscn"))
	
	%CommandPalette.command_entered.connect(_on_command_palette_command_entered)
	
	if PlayerData.home_base_multiplier == 1 and PlayerData.gold < 80:
		%MultiplyButton.visible = false
		%DivideButton.visible = false
	
	%MultiplyButton.pressed.connect(_adjust_multiplier.bind(10.0))
	%DivideButton.pressed.connect(_adjust_multiplier.bind(1/10.0))


func _input(event: InputEvent) -> void:
	if %CommandPalette.has_focus():
		return
	
	match Utils.key_press(event):
		KEY_SLASH:
			%CommandPalette.open()
			get_viewport().set_input_as_handled()


func _refresh_summary() -> void:
	%RichTextLabel.text = ""
	%RichTextLabel.text = "Your army:\n"
	%RichTextLabel.text += Goblins.army_bbcode(PlayerData.army) + "\n\n"
	%RichTextLabel.text += "💰%s" % [Utils.abbr_num(PlayerData.gold)]


func _refresh_recruits() -> void:
	while %Recruits.get_child_count() < RECRUIT_COUNT:
		var recruit_row: HomeBaseRecruitRow = RECRUIT_ROW_SCENE.instantiate()
		recruit_row.recruit_pressed.connect(_recruit.bind(recruit_row))
		recruit_row.skip_pressed.connect(_skip.bind(recruit_row))
		%Recruits.add_child(recruit_row)
	for recruit_row: HomeBaseRecruitRow in %Recruits.get_children():
		recruit_row.refresh()
	%MultiplyButton.disabled = (PlayerData.gold < Utils.big_mult(80, PlayerData.home_base_multiplier \
			or PlayerData.home_base_multiplier >= MAX_MULTIPLIER))
	%DivideButton.disabled = (PlayerData.home_base_multiplier <= 1)


func _recruit(recruit_row: HomeBaseRecruitRow) -> void:
	if PlayerData.gold < recruit_row.get_cost():
		return
	
	PlayerData.gold -= recruit_row.get_cost()
	PlayerData.army.add_item(recruit_row.item)
	
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
	PlayerData.home_base_multiplier = clampi(PlayerData.home_base_multiplier * factor, 1, MAX_MULTIPLIER)
	for recruit_row: HomeBaseRecruitRow in %Recruits.get_children():
		%Recruits.remove_child(recruit_row)
		recruit_row.queue_free()
		_refresh_recruits()


func _on_command_palette_command_entered(command: String) -> void:
	match command.substr(0, 1):
		"g":
			if not command.substr(1).is_valid_int():
				push_warning("Invalid parameter: %s" % [command.substr(1)])
				return
			var factor: float = float(command.substr(1))
			PlayerData.scale_army_units(factor)
			_refresh_recruits()
			_refresh_summary()
		"h":
			if not command.substr(1).is_valid_int():
				push_warning("Invalid parameter: %s" % [command.substr(1)])
				return
			var factor: float = 1.0 / float(command.substr(1))
			PlayerData.scale_army_units(factor)
			_refresh_recruits()
			_refresh_summary()
