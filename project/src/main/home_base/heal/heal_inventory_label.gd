extends RichTextLabel

func refresh() -> void:
	%InventoryLabel.text = ""
	
	var heal_group: HealData.HealGroup = HomeBaseData.heal_data.get_center_group()
	if heal_group:
		var summary: Army.ArmySummary = PlayerData.army.get_summary()
		var goblin_type: Gobs.Type = heal_group.get_type()
		if summary.goblins_by_type[goblin_type].is_gte(1):
			var wounded_string: String = ""
			if summary.wounded_by_type[goblin_type].is_gte(1):
				var wounded_percent: float = 100 * summary.wounded_by_type[goblin_type].to_float() \
						/ summary.goblins_by_type[goblin_type].to_float()
				wounded_percent = max(wounded_percent, 1)
				wounded_string = "(%d%% 🩹) " % [wounded_percent]
			%InventoryLabel.text += "%s: %s goblins, %s⚔️%s\n" % [
					Gobs.emoji_from_type(goblin_type),
					summary.goblins_by_type[goblin_type].to_aa(),
					wounded_string,
					summary.attack_by_type[goblin_type].to_aa()]
