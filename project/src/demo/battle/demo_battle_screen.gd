extends Control

func _ready() -> void:
	PlayerDataTestUtils.prepare_demo()
	%BattleScreen.show_pick_panel()
