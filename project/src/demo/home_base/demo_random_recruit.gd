extends Control
## [b]Keys:[/b][br]
## 	[kbd][1,2,3,4,5][/kbd]: Set day to 1, 3, 6, 10, 20

func _ready() -> void:
	_generate_recruit_histogram()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_1:
			PlayerData.day = 1
			_generate_recruit_histogram()
		KEY_2:
			PlayerData.day = 3
			_generate_recruit_histogram()
		KEY_3:
			PlayerData.day = 6
			_generate_recruit_histogram()
		KEY_4:
			PlayerData.day = 10
			_generate_recruit_histogram()
		KEY_5:
			PlayerData.day = 20
			_generate_recruit_histogram()


func _generate_recruit_histogram() -> void:
	%RichTextLabel.text = ""
	_show_line("Day %s" % [PlayerData.day])
	var count_by_attack: Dictionary[int, int] = {}
	var max_attack: int = 0
	for _i in 100:
		var gob: Gob = PlayerData.army.generate_random_recruit({
			"count": PlayerData.home_base_multiplier,
			"max_level": DungeonDirector.get_recruit_max_level(PlayerData.day),
			"type_weights": DungeonDirector.get_recruit_type_weights(PlayerData.day),
		})
		if not count_by_attack.has(gob.attack):
			count_by_attack[gob.attack] = 0
		count_by_attack[gob.attack] += 1
		max_attack = maxi(gob.attack, max_attack)
	
	for attack: int in range(0, max_attack + 1, 3):
		_show_line("⚔%s=%s ⚔%s=%s ⚔%s=%s" % [
			attack, count_by_attack.get(attack, 0),
			attack + 1, count_by_attack.get(attack + 1, 0),
			attack + 2, count_by_attack.get(attack + 2, 0),
		])


func _show_line(line: String) -> void:
	if not %RichTextLabel.text.is_empty():
		%RichTextLabel.text += "\n"
	%RichTextLabel.text += line
