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
	var looted_gold: Big = Big.add(PlayerData.army.gold, PlayerData.get_dungeon_army().gold)
	PlayerData.gold = Big.add(PlayerData.gold, looted_gold)
	PlayerData.army.gold = Big.ZERO
	PlayerData.get_dungeon_army().gold = Big.ZERO
	color = Color("458a61")
	%Message.text = ""
	%Message.text += "Victory!\n\n"
	%Message.text += "You loot 💰%s from your fallen allies and enemies." % [looted_gold.to_aa()]


func defeat() -> void:
	refresh()
	color = Color("8d8381")
	
	PlayerData.army.gold = Big.ZERO
	PlayerData.gold = Big.add(PlayerData.gold, Big.new(PlayerData.get_dungeon_army().gold.to_float() * 0.1))
	PlayerData.initialize_starting_army()
	%Message.text = ""
	%Message.text += "Defeat...\n\n"
	
	var goblin: Horde = PlayerData.army.hordes.back()
	%Message.text += "%s %s is inspired by the bravery of the fallen goblins!\n" % [
		Goblins.emoji_from_type(goblin.type), goblin.name
	]
	%Message.text += "They give what money they have and prepare for battle."


func retreat() -> void:
	refresh()
	var looted_gold: Big = PlayerData.army.gold
	PlayerData.gold = Big.add(PlayerData.gold, looted_gold)
	PlayerData.army.gold = Big.ZERO
	PlayerData.get_dungeon_army().gold = Big.ZERO
	color = Color("8d8381")
	%Message.text = ""
	%Message.text += "Retreat!\n\n"
	%Message.text += "You scurry home with 💰%s in your pockets." % [looted_gold.to_aa()]
