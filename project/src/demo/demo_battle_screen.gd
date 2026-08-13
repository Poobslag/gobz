extends Control

func _ready() -> void:
	PlayerData.start_new_game()
	%BattleScreen.show_pick_panel()
