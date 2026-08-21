extends ColorRect

signal kitchen_entered

var _chat_option_values: Array[int]

func _ready() -> void:
	%HealNavigator.navigate_kitchen_pressed.connect(kitchen_entered.emit)
	%HealNavigator.navigate_left_pressed.connect(refresh)
	%HealNavigator.navigate_right_pressed.connect(refresh)
	
	var heal_chat_lines: Array[HealChatLines.HealChatLine] = HealChatLines.get_random_lines(4)
	var new_chat_option_values: Array[int] = []
	var new_chat_picker_options: Array[String] = []
	for chat_line: HealChatLines.HealChatLine in heal_chat_lines:
		new_chat_option_values.append(chat_line.value)
		new_chat_picker_options.append(chat_line.prompt_abbr_1 if randf() < 0.5 else chat_line.prompt_abbr_2)
	
	_chat_option_values = new_chat_option_values
	%ChatPicker.options = new_chat_picker_options
	%ChatPicker.option_picked.connect(_on_chat_picker_option_picked)


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()


func _on_chat_picker_option_picked(option_index: int) -> void:
	if _chat_option_values[option_index] == _chat_option_values.max():
		# heal the goblin
		# update the text
		pass
