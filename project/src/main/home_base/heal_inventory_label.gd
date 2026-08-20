extends RichTextLabel

func refresh() -> void:
	%InventoryLabel.text = ""
	
	var heal_group: Array[Gob] = HomeBaseData.heal_state.get_center_group()
	if heal_group:
		var summary: Army.ArmySummary = PlayerData.army.get_summary()
		var goblin_type: Gobs.Type = heal_group.front().type
		if summary.goblins_by_type[goblin_type].is_gte(1):
			var wounded_string: String = ""
			if summary.wounded_by_type[goblin_type].is_gte(1):
				var wounded_percent: float = 100 * summary.wounded_by_type[goblin_type].to_float() \
						/ summary.goblins_by_type[goblin_type].to_float()
				wounded_percent = max(wounded_percent, 1)
				wounded_string = "(%d%% 🩹) " % [wounded_percent]
			%InventoryLabel.text += "%s: %s goblins, %s⚔️%s\n" % [
					Gobs.EMOJIS_BY_GOBLIN_TYPE[goblin_type],
					summary.goblins_by_type[goblin_type].to_aa(),
					wounded_string,
					summary.attack_by_type[goblin_type].to_aa()]
	
	%InventoryLabel.text += "💰 %s - 🍰 %s - 🍺 %s\n" % [
			PlayerData.gold.to_aa(),
			PlayerData.inventory.get_count(Items.WEAK_MEDICINE).to_aa(),
			PlayerData.inventory.get_count(Items.STRONG_MEDICINE).to_aa(),]
	
	%InventoryLabel.text += "🌿 %s - 🍄 %s - 🍞 %s" % [
			PlayerData.inventory.get_count(Items.HERB_1).to_aa(),
			PlayerData.inventory.get_count(Items.HERB_2).to_aa(),
			PlayerData.inventory.get_count(Items.HERB_3).to_aa(),]
