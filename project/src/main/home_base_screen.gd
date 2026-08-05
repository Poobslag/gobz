extends Control

const RECRUIT_COUNT: int = 3
const RECRUIT_ROW_SCENE: PackedScene = preload("res://src/main/home_base_recruit_row.tscn")

func _ready() -> void:
	for child: Node in %Recruits.get_children():
		%Recruits.remove_child(child)
		child.queue_free()
	
	_refresh_recruits()
	_refresh_summary()
	
	%FightButton.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://src/main/dungeon_select_screen.tscn"))
	
	%CommandPalette.command_entered.connect(_on_command_palette_command_entered)


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
	%RichTextLabel.text += "💰%s" % [PlayerData.gold]


func _refresh_recruits() -> void:
	while %Recruits.get_child_count() < RECRUIT_COUNT:
		var recruit_row: HomeBaseRecruitRow = RECRUIT_ROW_SCENE.instantiate()
		recruit_row.recruit_pressed.connect(_recruit.bind(recruit_row))
		recruit_row.skip_pressed.connect(_skip.bind(recruit_row))
		%Recruits.add_child(recruit_row)
	for recruit_row: HomeBaseRecruitRow in %Recruits.get_children():
		recruit_row.refresh()


func _recruit(recruit_row: HomeBaseRecruitRow) -> void:
	if PlayerData.gold < recruit_row.item.gold:
		return
	
	PlayerData.gold -= recruit_row.item.gold
	PlayerData.army.add_item(recruit_row.item)
	
	%Recruits.remove_child(recruit_row)
	recruit_row.queue_free()
	_refresh_recruits()
	_refresh_summary()


func _skip(recruit_row: HomeBaseRecruitRow) -> void:
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
