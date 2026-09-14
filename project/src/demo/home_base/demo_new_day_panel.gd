extends Control
## [b]Keys:[/b][br]
## 	[kbd]S[/kbd]: Show the panel for a normal scenario.
## 	[kbd]T[/kbd]: Show the panel for a scenario with no change.
## 	[kbd]F[/kbd]: Show the panel for a scenario with no food.


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_S:
			PlayerData.food_record.morale_today = randf_range(0, 100)
			PlayerData.food_record.morale_yesterday = randf_range(0, 100)
			for type: Items.Type in [
					Items.FOOD_BREAD, Items.FOOD_CHICKEN,
					Items.FOOD_PIZZA, Items.FOOD_RAM, Items.FOOD_UNKNOWN]:
				PlayerData.food_record.food_today[type] = Big.new(randf_range(10, 100))
				PlayerData.food_record.food_yesterday[type] = Big.new(randf_range(10, 100))
			%NewDayPanel.play()
		KEY_T:
			PlayerData.food_record.morale_today = randf_range(0, 100)
			PlayerData.food_record.morale_yesterday = PlayerData.food_record.morale_today
			for type: Items.Type in [
					Items.FOOD_BREAD, Items.FOOD_CHICKEN,
					Items.FOOD_PIZZA, Items.FOOD_RAM, Items.FOOD_UNKNOWN]:
				PlayerData.food_record.food_today[type] = Big.new(randf_range(10, 100))
				PlayerData.food_record.food_yesterday[type] = PlayerData.food_record.food_today[type]
			%NewDayPanel.play()
		KEY_F:
			PlayerData.food_record.morale_today = randf_range(0, 100)
			PlayerData.food_record.morale_yesterday = randf_range(PlayerData.food_record.morale_today, 100)
			for type: Items.Type in [
					Items.FOOD_BREAD, Items.FOOD_CHICKEN,
					Items.FOOD_PIZZA, Items.FOOD_RAM, Items.FOOD_UNKNOWN]:
				PlayerData.food_record.food_today[type] = Big.ZERO
				PlayerData.food_record.food_yesterday[type] = Big.new(randf_range(10, 100))
			%NewDayPanel.play()
