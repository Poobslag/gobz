extends Control
## [b]Keys:[/b][br]
## 	[kbd]B[/kbd]: Increment bosses_defeated.

func _ready() -> void:
	PlayerDataTestUtils.prepare_demo()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_B:
			PlayerData.bosses_defeated += 1
			refresh()


func refresh() -> void:
	for collectible: Collectible in Collectibles.get_collectibles():
		collectible.refresh_collectible()
	%TrophyScreen.refresh()
