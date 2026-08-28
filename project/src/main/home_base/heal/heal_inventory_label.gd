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
	
	%InventoryLabel.text += "💰 %s - %s %s - %s %s\n" % [
			PlayerData.gold.to_aa(),
			Items.emoji_from_type(Items.WEAK_MEDICINE),
			PlayerData.inventory.get_count(Items.WEAK_MEDICINE).to_aa(),
			Items.emoji_from_type(Items.STRONG_MEDICINE),
			PlayerData.inventory.get_count(Items.STRONG_MEDICINE).to_aa(),]
	
	%InventoryLabel.text += "%s %s - %s %s - %s %s" % [
			Items.emoji_from_type(Items.HERB_1),
			PlayerData.inventory.get_count(Items.HERB_1).to_aa(),
			Items.emoji_from_type(Items.HERB_2),
			PlayerData.inventory.get_count(Items.HERB_2).to_aa(),
			Items.emoji_from_type(Items.HERB_3),
			PlayerData.inventory.get_count(Items.HERB_3).to_aa(),]
