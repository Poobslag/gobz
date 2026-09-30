extends Control
## [b]Keys:[/b][br]
## 	[kbd]A[/kbd]: Add raiders
## 	[kbd]D[/kbd]: Disable demo input
## 	[kbd]R[/kbd]: Reset gobs and gold

var _input_disabled: bool = false

func _ready() -> void:
	reset()


func _input(event: InputEvent) -> void:
	if _input_disabled:
		return
	
	match Utils.key_press(event):
		KEY_A:
			PlayerData.raid_chance = 1.0
			DungeonDirector.cycle_dungeons()
			PlayerData.food_record.shown = false
			%HomeBaseScreen.reset()
		KEY_D:
			_input_disabled = true
		KEY_R:
			reset()


func reset() -> void:
	PlayerDataTestUtils.prepare_demo()
	for _i in 10:
		var gob: Gob = PlayerData.army.generate_random_recruit({"count": Big.new(5)})
		PlayerData.army.add_gob(gob)
	PlayerDataTestUtils.set_gold(Big.new(5000))
	
	%HomeBaseScreen.reset()
