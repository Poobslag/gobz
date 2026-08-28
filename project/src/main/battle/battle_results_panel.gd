extends ColorRect

signal finished

@onready var splash_showers: Array[Control] = [
	%VictoryShower, %DefeatShower, %RetreatShower
]

func _ready() -> void:
	%DoneButton.pressed.connect(finished.emit)


func refresh() -> void:
	%YourGoblins.text = ""
	%YourGoblins.text += "You:\n"
	%YourGoblins.text += Gobs.army_bbcode(PlayerData.army)
	
	%EnemyGoblins.text = ""
	if PlayerData.has_current_dungeon():
		%EnemyGoblins.text += "Bad guys:\n"
		%EnemyGoblins.text += Gobs.army_bbcode(PlayerData.get_dungeon_army())


func victory() -> void:
	refresh()
	_show_splash(%VictoryShower)
	
	var looted_gold: Big = Big.add(PlayerData.army.gold, PlayerData.get_dungeon_army().gold)
	PlayerData.gold = Big.add(PlayerData.gold, looted_gold)
	PlayerData.army.gold = Big.ZERO
	PlayerData.get_dungeon_army().gold = Big.ZERO
	color = Color("458a61")
	%Message.text = ""
	%Message.text += "Victory!\n\n"
	%Message.text += "You loot 💰%s from your fallen allies and enemies." % [looted_gold.to_aa()]
	
	_end_battle()


func defeat() -> void:
	refresh()
	_show_splash(%DefeatShower)
	
	color = Color("8d8381")
	PlayerData.army.gold = Big.ZERO
	PlayerData.gold = Big.add(PlayerData.gold, Big.new(PlayerData.get_dungeon_army().gold.to_float() * 0.1))
	PlayerData.initialize_starting_army()
	%Message.text = ""
	%Message.text += "Defeat...\n\n"
	
	var goblin: Gob = PlayerData.army.gobs.back()
	%Message.text += "%s %s is inspired by the bravery of the fallen goblins!\n" % [
		Gobs.emoji_from_type(goblin.type), goblin.name
	]
	%Message.text += "They give what gold they have and prepare for battle."
	
	_end_battle()


func mutual_defeat() -> void:
	refresh()
	_show_splash(%DefeatShower)
	
	color = Color("8d8381")
	var looted_gold: Big = Big.new(
			Big.add(PlayerData.army.gold, PlayerData.get_dungeon_army().gold).to_float() * 0.5)
	PlayerData.gold = Big.add(PlayerData.gold, looted_gold)
	PlayerData.initialize_starting_army()

	PlayerData.get_dungeon_army().gold = Big.ZERO
	color = Color("458a61")
	%Message.text = ""
	%Message.text += "Mutual defeat...\n\n"
	
	var goblin: Gob = PlayerData.army.gobs.back()
	%Message.text += "%s %s is inspired by the bravery of the fallen goblins!\n" % [
		Gobs.emoji_from_type(goblin.type), goblin.name
	]
	%Message.text += "They loot 💰%s from the battlefield and prepare for battle."
	
	_end_battle()


func retreat() -> void:
	refresh()
	_show_splash(%RetreatShower)
	
	var looted_gold: Big = PlayerData.army.gold
	PlayerData.gold = Big.add(PlayerData.gold, looted_gold)
	PlayerData.army.gold = Big.ZERO
	PlayerData.get_dungeon_army().gold = Big.ZERO
	color = Color("8d8381")
	%Message.text = ""
	%Message.text += "Retreat!\n\n"
	if looted_gold.is_gt(0):
		%Message.text += "You scurry home with 💰%s in your pockets." % [looted_gold.to_aa()]
	else:
		%Message.text += "You scurry home empty-handed." % [looted_gold.to_aa()]
	
	_end_battle()


func _end_battle() -> void:
	PlayerData.day += 1
	PlayerData.cycle_dungeons()
	HomeBaseData.heal_data.mark_groups_dirty()
	PlayerData.market.mark_costs_dirty()


func _show_splash(shower: Node) -> void:
	for next_shower: Node in splash_showers:
		next_shower.hide()
	shower.visible = true
