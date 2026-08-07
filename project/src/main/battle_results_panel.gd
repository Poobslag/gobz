extends ColorRect

signal finished

func _ready() -> void:
	%DoneButton.pressed.connect(finished.emit)


func refresh() -> void:
	%YourGoblins.text = ""
	%YourGoblins.text += "You:\n"
	%YourGoblins.text += Goblins.army_bbcode(PlayerData.army)
	
	%EnemyGoblins.text = ""
	if PlayerData.has_current_dungeon():
		%EnemyGoblins.text += "Bad guys:\n"
		%EnemyGoblins.text += Goblins.army_bbcode(PlayerData.get_dungeon_army())


func victory() -> void:
	refresh()
	var looted_gold: int = PlayerData.army.gold + PlayerData.get_dungeon_army().gold
	PlayerData.gold += looted_gold
	PlayerData.army.gold = 0
	PlayerData.get_dungeon_army().gold = 0
	color = Color("458a61")
	%Message.text = ""
	%Message.text += "Victory!\n\n"
	%Message.text += "You loot 💰%s from your fallen allies and enemies." % [Utils.abbr_num(looted_gold)]


func defeat() -> void:
	refresh()
	color = Color("8d8381")
	
	PlayerData.army.gold = 0
	PlayerData.gold += int(PlayerData.get_dungeon_army().gold * 0.1)
	PlayerData.initialize_starting_army()
	%Message.text = ""
	%Message.text += "Defeat...\n\n"
	
	var goblin: Army.ArmyItem = PlayerData.army.items.back()
	%Message.text += "%s %s is inspired by the bravery of the fallen goblins!\n" % [
		Goblins.emoji_from_type(goblin.type), goblin.name
	]
	%Message.text += "They give what money they have and prepare for battle."


func retreat() -> void:
	refresh()
	var looted_gold: int = PlayerData.army.gold
	PlayerData.gold += looted_gold
	PlayerData.army.gold = 0
	PlayerData.get_dungeon_army().gold = 0
	color = Color("8d8381")
	%Message.text = ""
	%Message.text += "Retreat!\n\n"
	%Message.text += "You scurry home with 💰%s in your pockets." % [Utils.abbr_num(looted_gold)]
