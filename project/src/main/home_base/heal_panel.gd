extends ColorRect

signal kitchen_entered

var _chat_option_values: Array[int]

func _ready() -> void:
	%HealNavigator.navigate_kitchen_pressed.connect(kitchen_entered.emit)
	%HealNavigator.navigate_left_pressed.connect(refresh)
	%HealNavigator.navigate_right_pressed.connect(refresh)
	
	_chat_option_values = [3, 1, 1, 2]
	%ChatPicker.options = ["I hope you feel better", "You're stupid", "I hope you feel worse", "You're such a wimp"] as Array[String]
	%ChatPicker.option_picked.connect(_on_chat_picker_option_picked)


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()


func _on_chat_picker_option_picked(option_index: int) -> void:
	if _chat_option_values[option_index] == _chat_option_values.max():
		# heal the goblin
		# update the text
		pass


class Asdf:
	var player_message_1: String
	var player_message_2: String
	var good_response_message: String
	var bad_response_message: String
	var value: int
