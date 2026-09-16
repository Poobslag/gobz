extends Control
## [b]Keys:[/b][br]
## 	[kbd][A,S,D,F][/kbd]: Set the player's gold to a small/medium/large amount
## 	[kbd][Z,X,C,V][/kbd]: Preview a small/medium/large purchase

func _ready() -> void:
	reset()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_A: PlayerData.gold = Big.new(0)
		KEY_S: PlayerData.gold = Big.new(1)
		KEY_D: PlayerData.gold = Big.new(500)
		KEY_F: PlayerData.gold = Big.new(1000)
		
		KEY_Z: %GoldBar.start_cost_preview(self, Big.new(5))
		KEY_X: %GoldBar.start_cost_preview(self, Big.new(50))
		KEY_C: %GoldBar.start_cost_preview(self, Big.new(500))
		KEY_V: %GoldBar.start_cost_preview(self, Big.new(5000))
	
	match Utils.key_release(event):
		KEY_Z, KEY_X, KEY_C, KEY_V:
			%GoldBar.stop_cost_preview(self)


func reset() -> void:
	PlayerData.reset()
	PlayerData.gold = Big.new(1000)
