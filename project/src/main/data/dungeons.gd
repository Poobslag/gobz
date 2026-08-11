class_name Dungeons

static func get_dungeon_select_info(dungeon: Dungeon) -> Dictionary[String, String]:
	var reward_text: String = "+💰%s" % [dungeon.recon_army.get_total_gold().to_aa()]
	
	var attack_by_type: Dictionary[Goblins.GoblinType, Big]
	for type: Goblins.GoblinType in Goblins.GoblinType.values():
		attack_by_type[type] = Big.ZERO
	for item: Army.ArmyItem in dungeon.recon_army.items:
		attack_by_type[item.type] = Big.add(attack_by_type[item.type], Big.mul(item.attack, item.count))
	var type_summaries: Array[Dictionary] = []
	for type: Goblins.GoblinType in Goblins.GoblinType.values():
		type_summaries.append({
			"emoji": Goblins.emoji_from_type(type),
			"attack": attack_by_type[type],
		} as Dictionary[String, Variant])
	type_summaries.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
		return a["attack"].is_gt(b["attack"])
		)
	
	var emoji_string: String = ""
	if type_summaries.size() == 0:
		emoji_string = "-"
	if type_summaries.size() >= 1:
		emoji_string = type_summaries[0]["emoji"]
	if type_summaries.size() >= 2:
		if type_summaries[1]["attack"].is_gt(Big.mul(type_summaries[0]["attack"], 0.2)):
			emoji_string += type_summaries[1]["emoji"]
		else:
			emoji_string = type_summaries[0]["emoji"] + emoji_string
	if type_summaries.size() >= 3:
		if type_summaries[2]["attack"].is_gt(Big.mul(type_summaries[0]["attack"], 0.2)):
			emoji_string +=  type_summaries[2]["emoji"]
		else:
			emoji_string = type_summaries[0]["emoji"] + emoji_string
	
	var attack_string: String = "%s⚔" % [dungeon.recon_army.get_total_attack().to_aa()]
	
	return {
		"name": dungeon.name,
		"reward_text": reward_text,
		"emoji_string": emoji_string,
		"attack_string": attack_string,
	}
