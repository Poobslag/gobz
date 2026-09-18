class_name Dungeons

static func get_dungeon_select_info(dungeon: Dungeon) -> Dictionary[String, Variant]:
	var type_summaries: Array[Dictionary] = get_type_summaries(dungeon.recon_army)
	var goblins_text: String = get_goblins_text(dungeon.recon_army)
	return {
		"goblins_text": goblins_text,
		"type_summaries": type_summaries,
	}


static func get_goblins_text(army: Army) -> String:
	var attack_rating: String = Gobs.attack_rating(
			army.get_total_attack().to_float() / army.get_total_goblins().to_float())
	return army.get_total_goblins().to_aa() + " " + attack_rating


static func get_type_summaries(army: Army) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var goblins_by_type: Dictionary[Gobs.Type, Big]
	for type: Gobs.Type in Gobs.Type.values():
		goblins_by_type[type] = Big.ZERO
	for gob: Gob in army.gobs:
		goblins_by_type[gob.type] = Big.add(goblins_by_type[gob.type], gob.get_count())
	
	for type: Gobs.Type in Gobs.Type.values():
		if goblins_by_type[type] == Big.ZERO:
			continue
		result.append({
			"type": type,
			"goblins": goblins_by_type[type],
		} as Dictionary[String, Variant])
	result.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
		return a["goblins"].is_gt(b["goblins"])
		)
	return result
