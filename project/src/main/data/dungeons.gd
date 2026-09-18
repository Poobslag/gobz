class_name Dungeons

static func get_dungeon_select_info(dungeon: Dungeon) -> Dictionary[String, Variant]:
	var goblins_by_type: Dictionary[Gobs.Type, Big]
	for type: Gobs.Type in Gobs.Type.values():
		goblins_by_type[type] = Big.ZERO
	for gob: Gob in dungeon.recon_army.gobs:
		goblins_by_type[gob.type] = Big.add(goblins_by_type[gob.type], gob.get_count())
	var type_summaries: Array[Dictionary] = []
	for type: Gobs.Type in Gobs.Type.values():
		if goblins_by_type[type] == Big.ZERO:
			continue
		type_summaries.append({
			"type": type,
			"goblins": goblins_by_type[type],
		} as Dictionary[String, Variant])
	type_summaries.sort_custom(func(a: Dictionary[String, Variant], b: Dictionary[String, Variant]) -> bool:
		return a["goblins"].is_gt(b["goblins"])
		)
	
	var attack_rating: String = Gobs.attack_rating(
			dungeon.recon_army.get_total_attack().to_float() / dungeon.recon_army.get_total_goblins().to_float())
	
	var goblins_text: String = dungeon.recon_army.get_total_goblins().to_aa() + " " + attack_rating
	
	return {
		"goblins_text": goblins_text,
		"type_summaries": type_summaries,
	}
