extends Control
## [b]Keys:[/b][br]
## 	[kbd]C[/kbd]: Cycle dungeons

func _ready() -> void:
	PlayerDataTestUtils.prepare_demo()
	for dungeon: Dungeon in PlayerData.dungeons:
		dungeon.perform_recon()
	%DungeonSelect.refresh()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_C:
			DungeonDirector.cycle_dungeons()
			for dungeon: Dungeon in PlayerData.dungeons:
				dungeon.perform_recon()
			%DungeonSelect.refresh()
