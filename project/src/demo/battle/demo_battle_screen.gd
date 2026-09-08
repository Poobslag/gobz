extends Control

func _ready() -> void:
	PlayerDataTestUtils.prepare_demo()
	PlayerData.dungeon_index = 1
	%BattleScreen.show_pick_panel()
	%BattleScreen.hide_tutorial_panel()
