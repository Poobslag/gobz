class_name HealPanel
extends ColorRect

signal kitchen_entered

enum HealType {
	NONE,
	CHAT,
	MEDICINE,
	MONEY,
}

const MAX_MULTIPLIER = 100.0

const HEAL_HELLO_PATH: String = "res://assets/main/home_base/heal/heal_hello.csv"
const HEAL_GOODBYE_CHAT_PATH: String = "res://assets/main/home_base/heal/heal_goodbye_chat.csv"
const HEAL_GOODBYE_GOLD_PATH: String = "res://assets/main/home_base/heal/heal_goodbye_gold.csv"
const HEAL_GOODBYE_MEDICINE_PATH: String = "res://assets/main/home_base/heal/heal_goodbye_medicine.csv"

var _heal_chat_lines: Array[HealChatLines.HealChatLine]

var _ui_state_per_heal_group: Dictionary[HealData.HealGroup, Dictionary] = {}
var _heal_type_by_gob: Dictionary[Gob, HealType] = {}

@onready var splash_shower: SplashShower = %SplashShower

func _ready() -> void:
	%HealNavigator.move_kitchen.connect(kitchen_entered.emit)
	%HealNavigator.before_move.connect(_on_heal_navigator_before_move)
	%HealNavigator.move_left.connect(_on_heal_navigator_move)
	%HealNavigator.move_right.connect(_on_heal_navigator_move)
	%ChatPicker.option_picked.connect(_on_chat_picker_option_picked)
	%ChatShower.all_messages_shown.connect(_on_chat_shower_all_messages_shown)
	%HealWithGoldRow.pressed.connect(_on_heal_with_gold_row_pressed)
	%HealWithMedicineRow.pressed.connect(_on_heal_with_medicine_row_pressed)
	%MultiplyButton.pressed.connect(_adjust_multiplier.bind(10.0))
	%DivideButton.pressed.connect(_adjust_multiplier.bind(0.1))
	%HomeNav.before_scene_change.connect(_purge_healed_groups)


func initialize() -> void:
	%ChatShower.clear()
	if HomeBaseData.heal_data.groups.is_empty():
		%ChatShower.append_prompt("(There's nobody to heal.)")
		%ChatShower.hide_face()
	else:
		_append_chat_shower_hello()
	_generate_chat_picker_options()
	refresh()


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()
	
	%ChatPicker.visible = true
	%HealWithMedicineRow.visible = true
	%HealWithGoldRow.visible = true
	%HealWithMedicineRow.heal_all = false
	%HealWithGoldRow.heal_all = false
	%ChatPicker.set_disabled(false)
	
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if center_group == null:
		%ChatPicker.visible = false
	else:
		if center_group.hurt_count.is_eq(0):
			%ChatPicker.set_disabled(true)
	
	if PlayerData.heal_multiplier.is_lt(10):
		# heal all gobs in the current group
		if center_group == null:
			%HealWithMedicineRow.gobs = [] as Array[Gob]
			%HealWithGoldRow.gobs = [] as Array[Gob]
		else:
			%HealWithMedicineRow.gobs = center_group.gobs
			%HealWithGoldRow.gobs = center_group.gobs
	elif PlayerData.heal_multiplier.is_lt(100):
		# heal all hurt gobs of the current group's type
		%HealWithMedicineRow.heal_all = true
		%HealWithGoldRow.heal_all = true
		var hurt_gobs: Array[Gob] = []
		for heal_group: HealData.HealGroup in HomeBaseData.heal_data.get_groups():
			if heal_group.is_hurt() and heal_group.get_type() == center_group.get_type():
				hurt_gobs.append_array(heal_group.gobs)
		%HealWithMedicineRow.gobs = hurt_gobs
		%HealWithGoldRow.gobs = hurt_gobs
	else:
		# heal all hurt gobs
		%HealWithMedicineRow.heal_all = true
		%HealWithGoldRow.heal_all = true
		var hurt_gobs: Array[Gob] = []
		for heal_group: HealData.HealGroup in HomeBaseData.heal_data.get_groups():
			if heal_group.is_hurt():
				hurt_gobs.append_array(heal_group.gobs)
		%HealWithMedicineRow.gobs = hurt_gobs
		%HealWithGoldRow.gobs = hurt_gobs
	
	%MultiplyButton.disabled = PlayerData.heal_multiplier.is_gte(100)
	%DivideButton.disabled = PlayerData.heal_multiplier.is_lte(1)


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


func _purge_healed_groups() -> void:
	for i in range(HomeBaseData.heal_data.groups.size() - 1, -1, -1):
		if not HomeBaseData.heal_data.get_group_at(i).is_hurt():
			HomeBaseData.heal_data.remove_group_at(i)


func _refresh_chat_picker() -> void:
	var new_chat_picker_options: Array[String] = []
	for chat_line: HealChatLines.HealChatLine in _heal_chat_lines:
		new_chat_picker_options.append(chat_line.prompt_abbr_1 if randf() < 0.5 else chat_line.prompt_abbr_2)
	%ChatPicker.options = new_chat_picker_options


func _append_chat_shower_hello() -> void:
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if _ui_state_per_heal_group.has(center_group):
		%ChatShower.set_shown_lines(_ui_state_per_heal_group[center_group]["lines"])
		%ChatPicker.options = _ui_state_per_heal_group[center_group]["options"]
	elif not center_group.is_hurt():
		%ChatShower.clear()
		match _heal_type_by_gob.get(center_group.front()):
			HealType.MEDICINE:
				%ChatShower.append_great_response("\"%s\"" % [LinePool.get_random_line(HEAL_GOODBYE_MEDICINE_PATH)])
			HealType.MONEY:
				%ChatShower.append_great_response("\"%s\"" % [LinePool.get_random_line(HEAL_GOODBYE_GOLD_PATH)])
			_:
				%ChatShower.append_great_response("\"%s\"" % [LinePool.get_random_line(HEAL_GOODBYE_CHAT_PATH)])
	else:
		%ChatShower.append_neutral_response("\"%s\"" % [LinePool.get_random_line(HEAL_HELLO_PATH)])


func _adjust_multiplier(factor: float) -> void:
	PlayerData.heal_multiplier = Big.clamp(PlayerData.heal_multiplier.to_float() * factor, 1, MAX_MULTIPLIER)
	refresh()


func _on_chat_picker_option_picked(option_index: int) -> void:
	%ChatPicker.set_disabled(true)
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
				_heal_type_by_gob[gob] = HealType.CHAT
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
	_append_chat_shower_hello()
	_generate_chat_picker_options()
	
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if center_group != null and center_group.is_hurt():
		%ChatPicker.set_disabled(false)


func _on_chat_shower_all_messages_shown() -> void:
	var center_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if center_group != null and center_group.is_hurt():
		%ChatPicker.set_disabled(false)


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
	PlayerData.take_gold(%HealWithGoldRow.cost)
	for gob: Gob in %HealWithGoldRow.gobs:
		var gold_per_hurt: float = remaining_gob_income / remaining_hurt_count
		var gold_for_this_gob: float = gob.get_hurt_count().to_float() * gold_per_hurt
		var gold_per_gob: int = Utils.stochastic_roundi(gold_for_this_gob / gob.get_count().to_float())
		gob.gold += gold_per_gob
		remaining_gob_income -= gold_per_gob * gob.get_count().to_float()
		remaining_hurt_count -= gob.get_hurt_count().to_float()
	
	for gob: Gob in %HealWithGoldRow.gobs:
		HealData.full_heal(gob)
		_heal_type_by_gob[gob] = HealType.MONEY
	
	%ChatShower.append_great_response("\"%s\"" % [LinePool.get_random_line(HEAL_GOODBYE_GOLD_PATH)])
	if PlayerData.heal_multiplier.is_gt(1):
		_ui_state_per_heal_group.clear()
	for group: HealData.HealGroup in HomeBaseData.heal_data.groups:
		group.refresh()
	refresh()


func _on_heal_with_medicine_row_pressed() -> void:
	if not %HealWithMedicineRow.has_enough_medicine():
		return
	
	PlayerData.inventory.take_item(Items.WEAK_MEDICINE, %HealWithMedicineRow.weak_medicine_needed)
	PlayerData.inventory.take_item(Items.STRONG_MEDICINE, %HealWithMedicineRow.strong_medicine_needed)
	for gob: Gob in %HealWithMedicineRow.gobs:
		HealData.full_heal(gob)
		_heal_type_by_gob[gob] = HealType.MEDICINE
	
	%ChatShower.append_great_response("\"%s\"" % [LinePool.get_random_line(HEAL_GOODBYE_MEDICINE_PATH)])
	if PlayerData.heal_multiplier.is_gt(1):
		_ui_state_per_heal_group.clear()
	for group: HealData.HealGroup in HomeBaseData.heal_data.groups:
		group.refresh()
	refresh()
