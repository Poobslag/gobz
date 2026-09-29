extends ColorRect

signal surrender_pressed
signal fight_pressed
signal tutorial_pressed

var _items_stacks: Array[Array] = []

func _ready() -> void:
	_refresh()
	
	%Surrender.pressed.connect(surrender_pressed.emit)
	%Fight.pressed.connect(fight_pressed.emit)
	%TutorialButton.pressed.connect(tutorial_pressed.emit)


func _refresh() -> void:
	_populate_items_stacks()
	
	%YourGoblins.text = ""
	%YourGoblins.text += "You:\n"
	%YourGoblins.text += Gobs.army_bbcode(PlayerData.army)
	
	%EnemyGoblins.text = ""
	if PlayerData.has_current_dungeon():
		%EnemyGoblins.text += "Bad guys:\n"
		%EnemyGoblins.text += Gobs.army_bbcode(PlayerData.get_dungeon_army())
	
	%QueryLabel.text = ""
	%QueryLabel.text += "We're being raided by goblins from %s!" % [PlayerData.get_dungeon().name]
	%QueryLabel.text += " The raiders will accept surrender if we give them half our gold and supplies.\n"
	%QueryLabel.text += "\n"
	
	# build button_item_emojis, a text list of the items we'll surrender for the button
	var button_item_emojis: String = ""
	for items_entry: Array[Variant] in _items_stacks:
		button_item_emojis += Items.emoji_from_type(items_entry[0])
	button_item_emojis = button_item_emojis.left(10)
	%Surrender.text = "-%s\nSurrender..." % [button_item_emojis]
	
	# build query_item_parts, a text list of the items we'll surrender for the text box
	var query_item_parts: String = ""
	var query_item_list: Array[String] = []
	if PlayerData.gold.is_gt(0):
		query_item_list.append("💰%s" % [Big.float_to_aa(ceil(PlayerData.gold.to_float() * 0.5))])
	for items_entry: Array[Variant] in _items_stacks:
		query_item_list.append("%s%s" % [Items.emoji_from_type(items_entry[0]), Big.float_to_aa(items_entry[1])])
	for i in query_item_list.size():
		if i == 0:
			pass
		elif i < query_item_list.size() - 1:
			query_item_parts += ", "
		else:
			query_item_parts += " and "
		query_item_parts += query_item_list[i]
	
	if query_item_parts == "":
		%QueryLabel.text += "But actually, we don't have anything! ...Should we try to surrender?"
	else:
		%QueryLabel.text += "Should we give up %s and surrender?" % [query_item_parts]


func _populate_items_stacks() -> void:
	_items_stacks = []
	for item_type: Items.Type in PlayerData.inventory.items:
		if PlayerData.inventory.has_item(item_type, Big.ONE):
			_items_stacks.append([item_type, ceil(PlayerData.inventory.get_count(item_type).to_float() * 0.5)]
					as Array[Variant])
	_items_stacks.sort_custom(func(a: Array[Variant], b: Array[Variant]) -> bool:
		return a[1] > b[1])
