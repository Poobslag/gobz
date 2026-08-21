extends ColorRect

signal kitchen_entered

const HEAL_HELLO_PATH: String = "res://assets/main/home_base/heal_hello.csv"
const HEAL_GOODBYE_PATH: String = "res://assets/main/home_base/heal_goodbye_chat.csv"

var _chat_option_values: Array[int]
var _heal_chat_lines: Array[HealChatLines.HealChatLine]

var _ui_state_per_heal_group: Dictionary[HealData.HealGroup, Dictionary] = {}

func _ready() -> void:
	%HealNavigator.move_kitchen.connect(kitchen_entered.emit)
	%HealNavigator.before_move.connect(_on_heal_navigator_before_move)
	%HealNavigator.move_left.connect(_on_heal_navigator_move)
	%HealNavigator.move_right.connect(_on_heal_navigator_move)
	%ChatPicker.option_picked.connect(_on_chat_picker_option_picked)
	%ChatShower.all_messages_shown.connect(_on_chat_shower_all_messages_shown)


func initialize() -> void:
	%ChatShower.clear()
	%ChatShower.append_neutral_response(LinePool.get_random_line(HEAL_HELLO_PATH))
	_generate_chat_picker_options()
	refresh()


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()


func _generate_chat_picker_options() -> void:
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if center_group == null:
		return
	
	_heal_chat_lines = HealChatLines.get_random_lines(center_group.option_count)
	var new_chat_option_values: Array[int] = []
	var new_chat_picker_options: Array[String] = []
	for chat_line: HealChatLines.HealChatLine in _heal_chat_lines:
		new_chat_option_values.append(chat_line.value)
		new_chat_picker_options.append(chat_line.prompt_abbr_1 if randf() < 0.5 else chat_line.prompt_abbr_2)
	
	_chat_option_values = new_chat_option_values
	%ChatPicker.options = new_chat_picker_options


func _on_chat_picker_option_picked(option_index: int) -> void:
	%ChatPicker.set_option_buttons_disabled(true)
	%ChatShower.append_prompt("\"%s\"" % [_heal_chat_lines[option_index].prompt])
	if _chat_option_values[option_index] == _chat_option_values.max():
		# heal the goblin
		var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
		var append_goodbye: bool = (center_group.chats_remaining == 1)
		center_group.decrement_chats_remaining()
		if center_group.chats_remaining == 0:
			for gob: Gob in center_group.gobs:
				gob.back_wounded = Big.ZERO
				gob.front_hp = gob.hp_max
			center_group.hurt_count = Big.ZERO
			%ChatShower.append_great_response("\"%s\"" % [_heal_chat_lines[option_index].response_good])
			if append_goodbye:
				%ChatShower.append_great_response("\"%s\"" % [LinePool.get_random_line(HEAL_GOODBYE_PATH)])
			refresh()
		else:
			%ChatShower.append_good_response("\"%s\"" % [_heal_chat_lines[option_index].response_good])
	else:
		var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
		center_group.increment_chats_remaining()
		%ChatShower.append_bad_response("\"%s\"" % [_heal_chat_lines[option_index].response_bad])
	
	_generate_chat_picker_options()


func _on_heal_navigator_before_move() -> void:
	%ChatShower.flush_pending_lines()
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	_ui_state_per_heal_group[center_group] = {
		"lines": %ChatShower.get_shown_lines(),
		"options": %ChatPicker.options,
	}


func _on_heal_navigator_move() -> void:
	# remove any healed goblins...
	var groups: Array[HealData.HealGroup] = HomeBaseData.heal_data.get_groups()
	for i in range(groups.size() - 1, -1, -1):
		# ignore groups which are still nearby
		var dist: int = abs(HomeBaseData.heal_data.group_index - i)
		dist = mini(dist, groups.size() - dist)
		if dist >= 2 and groups[i].hurt_count.is_lte(0):
			HomeBaseData.heal_data.remove_group_at(i)
	refresh()
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if _ui_state_per_heal_group.has(center_group):
		%ChatShower.set_shown_lines(_ui_state_per_heal_group[center_group]["lines"])
		%ChatPicker.options = _ui_state_per_heal_group[center_group]["options"]
	else:
		%ChatShower.clear()
		%ChatShower.append_neutral_response(LinePool.get_random_line(HEAL_HELLO_PATH))
	_generate_chat_picker_options()
	%ChatPicker.set_option_buttons_disabled(false)


func _on_chat_shower_all_messages_shown() -> void:
	%ChatPicker.set_option_buttons_disabled(false)
