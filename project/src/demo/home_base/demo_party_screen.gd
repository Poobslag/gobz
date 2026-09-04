extends Node
## [b]Keys:[/b][br]
## 	[kbd]R[/kbd]: Reset gobs and gold

func _ready() -> void:
	reset()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_R:
			reset()


func reset() -> void:
	PlayerData.reset()
	HomeBaseData.reset()
	for _i in 10:
		var gob: Gob = PlayerData.army.generate_random_recruit({"count": Big.new(5)})
		PlayerData.army.add_gob(gob)
	PlayerData.gold = Big.new(5000)
	PlayerData.inventory.add_item(Items.STRONG_MEDICINE, Big.new(5000))
	
	%PartyScreen.reset()
