extends Node
## [b]Keys:[/b][br]
## 	[kbd]L[/kbd]: Inject a long heal prompt.
## 	[kbd]E[/kbd]: Heal all gobs and refresh the heal screen.
## 	[kbd]W[/kbd]: Wound all gobs and refresh the heal screen.
## 	[kbd]M[/kbd]: Randomize market costs.

func _ready() -> void:
	PlayerData.reset()
	for _i in 50:
		var gob: Gob = PlayerData.army.generate_random_recruit({"count": Big.new(10)})
		PlayerData.army.add_gob(gob)
	hurt_all_gobs()
	HomeBaseData.heal_data.mark_groups_dirty()
	
	PlayerData.gold = Big.new(5000)
	PlayerData.inventory.add_item(Items.HERB_1, Big.new(5000))
	PlayerData.inventory.add_item(Items.HERB_2, Big.new(5000))
	PlayerData.inventory.add_item(Items.HERB_3, Big.new(5000))
	PlayerData.inventory.add_item(Items.WEAK_MEDICINE, Big.new(5000))
	PlayerData.inventory.add_item(Items.STRONG_MEDICINE, Big.new(5000))
	%HealScreen.show_heal_panel(true)


func hurt_all_gobs() -> void:
	for gob: Gob in PlayerData.army.gobs:
		if randf() < 0.5:
			gob.back_wounded = Big.new(randf_range(2, 8))
		if randf() < 0.5:
			gob.front_hp = randi_range(1, gob.front_hp - 1)
		if gob.is_hurt():
			gob.increase_wound_severity()


func heal_all_gobs() -> void:
	for gob: Gob in PlayerData.army.gobs:
		HealData.full_heal(gob)


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_L:
			%HealScreen.get_heal_panel().inject_chat_line(get_long_heal_chat_line())
		KEY_E:
			heal_all_gobs()
			HomeBaseData.heal_data.mark_groups_dirty()
			%HealScreen.show_heal_panel(true)
		KEY_W:
			hurt_all_gobs()
			HomeBaseData.heal_data.mark_groups_dirty()
			%HealScreen.show_heal_panel(true)
		KEY_M:
			PlayerData.market.mark_costs_dirty()
			%HealScreen.show_kitchen_panel()


func get_long_heal_chat_line() -> HealChatLines.HealChatLine:
	var chat_line: HealChatLines.HealChatLine = HealChatLines.HealChatLine.new()
	for line: HealChatLines.HealChatLine in HealChatLines.get_cached_lines():
		if line.prompt.length() > chat_line.prompt.length():
			chat_line.prompt = line.prompt
		if line.prompt_abbr_1.length() > chat_line.prompt_abbr_1.length():
			chat_line.prompt_abbr_1 = line.prompt_abbr_1
		if line.prompt_abbr_2.length() > chat_line.prompt_abbr_1.length():
			chat_line.prompt_abbr_1 = line.prompt_abbr_2
		if line.response_bad.length() > chat_line.response_bad.length():
			chat_line.response_bad = line.response_bad
		if line.response_good.length() > chat_line.response_bad.length():
			chat_line.response_bad = line.response_good
	chat_line.response_good = chat_line.response_bad
	chat_line.prompt_abbr_2 = chat_line.prompt_abbr_1
	return chat_line
