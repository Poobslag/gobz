class_name HealPanel
extends ColorRect

signal kitchen_entered

const HEAL_HELLO_PATH: String = "res://assets/main/home_base/heal_hello.csv"
const HEAL_GOODBYE_CHAT_PATH: String = "res://assets/main/home_base/heal_goodbye_chat.csv"
const HEAL_GOODBYE_GOLD_PATH: String = "res://assets/main/home_base/heal_goodbye_gold.csv"
const HEAL_GOODBYE_MEDICINE_PATH: String = "res://assets/main/home_base/heal_goodbye_medicine.csv"

var _heal_chat_lines: Array[HealChatLines.HealChatLine]

var _ui_state_per_heal_group: Dictionary[HealData.HealGroup, Dictionary] = {}

func _ready() -> void:
	%HealNavigator.move_kitchen.connect(kitchen_entered.emit)
	%HealNavigator.before_move.connect(_on_heal_navigator_before_move)
	%HealNavigator.move_left.connect(_on_heal_navigator_move)
	%HealNavigator.move_right.connect(_on_heal_navigator_move)
	%ChatPicker.option_picked.connect(_on_chat_picker_option_picked)
	%ChatShower.all_messages_shown.connect(_on_chat_shower_all_messages_shown)
	%HealWithGoldRow.pressed.connect(_on_heal_with_gold_row_pressed)


func initialize() -> void:
	%ChatShower.clear()
	%ChatShower.append_neutral_response("\"%s\"" % [LinePool.get_random_line(HEAL_HELLO_PATH)])
	_generate_chat_picker_options()
	refresh()


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()
	
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if center_group == null or center_group.hurt_count.is_eq(0):
		%HealWithGoldRow.visible = false
	else:
		%HealWithGoldRow.visible = true
		%HealWithGoldRow.gobs = center_group.gobs


func inject_chat_line(line: HealChatLines.HealChatLine) -> void:
	if _heal_chat_lines.size() >= 1:
		_heal_chat_lines[0] = line
		_refresh_chat_picker()


func _generate_chat_picker_options() -> void:
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if center_group == null:
		return
	
	_heal_chat_lines = HealChatLines.get_random_lines(center_group.option_count)
	_refresh_chat_picker()


func _refresh_chat_picker() -> void:
	var new_chat_picker_options: Array[String] = []
	for chat_line: HealChatLines.HealChatLine in _heal_chat_lines:
		new_chat_picker_options.append(chat_line.prompt_abbr_1 if randf() < 0.5 else chat_line.prompt_abbr_2)
	%ChatPicker.options = new_chat_picker_options


func _on_chat_picker_option_picked(option_index: int) -> void:
	%ChatPicker.set_option_buttons_disabled(true)
	%ChatShower.append_prompt("\"%s\"" % [_heal_chat_lines[option_index].prompt])
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	var max_value: int = 0
	for chat_line: HealChatLines.HealChatLine in _heal_chat_lines:
		max_value = maxi(max_value, chat_line.value)
	if _heal_chat_lines[option_index].value == max_value:
		# heal the goblin
		var append_goodbye: bool = (center_group.chats_remaining == 1)
		center_group.decrement_chats_remaining()
		if center_group.chats_remaining == 0:
			for gob: Gob in center_group.gobs:
				HealData.full_heal(gob)
			center_group.hurt_count = Big.ZERO
			%ChatShower.append_great_response("\"%s\"" % [_heal_chat_lines[option_index].response_good])
			if append_goodbye:
				%ChatShower.append_great_response("\"%s\"" % [LinePool.get_random_line(HEAL_GOODBYE_CHAT_PATH)])
			refresh()
		else:
			%ChatShower.append_good_response("\"%s\"" % [_heal_chat_lines[option_index].response_good])
	else:
		center_group.increment_chats_remaining()
		%ChatShower.append_bad_response("\"%s\"" % [_heal_chat_lines[option_index].response_bad])
	
	if center_group.chats_remaining > 0:
		_generate_chat_picker_options()
	else:
		%ChatPicker.options = [] as Array[String]


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
		%ChatShower.append_neutral_response("\"%s\"" % [LinePool.get_random_line(HEAL_HELLO_PATH)])
	_generate_chat_picker_options()
	%ChatPicker.set_option_buttons_disabled(false)


func _on_chat_shower_all_messages_shown() -> void:
	%ChatPicker.set_option_buttons_disabled(false)


func _on_heal_with_gold_row_pressed() -> void:
	if PlayerData.gold.is_lt(%HealWithGoldRow.cost):
		return
	
	# Goblins are vaguely reimbursed when you heal them. If you pay $10, the goblin will pocket about $5. Stochastic
	# rounding is applied for the case where 5 billion goblins have to split 2 billion gold.
	var remaining_gob_income: float = %HealWithGoldRow.cost.to_float()
	remaining_gob_income *= HealData.HEAL_GOLD_RETENTION_RATE
	var remaining_hurt_count: float = 0.0
	for gob: Gob in %HealWithGoldRow.gobs:
		remaining_hurt_count += gob.get_hurt_count().to_float()
	PlayerData.gold = Big.sub(PlayerData.gold, %HealWithGoldRow.cost)
	for gob: Gob in %HealWithGoldRow.gobs:
		var gold_per_hurt: float = remaining_gob_income / remaining_hurt_count
		var gold_for_this_gob: float = gob.get_hurt_count().to_float() * gold_per_hurt
		var gold_per_gob: int = Utils.stochastic_roundi(gold_for_this_gob / gob.get_count().to_float())
		gob.gold += gold_per_gob
		remaining_gob_income -= gold_per_gob * gob.get_count().to_float()
		remaining_hurt_count -= gob.get_hurt_count().to_float()
	
	for gob: Gob in %HealWithGoldRow.gobs:
		HealData.full_heal(gob)
	
	%ChatShower.append_great_response("\"%s\"" % [LinePool.get_random_line(HEAL_GOODBYE_GOLD_PATH)])
	HomeBaseData.heal_data.get_center_group().refresh()
	refresh()
