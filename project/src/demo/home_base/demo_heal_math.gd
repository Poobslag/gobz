extends Control
## Demonstrates the math around healing goblins with money, medicine or herbs.[br]
## [br]
## Herbs are the most work, so they should usually be the most efficient. Goblins pocket half the money you spend, so
## healing with gold should require about twice as much gold as healing with medicine. That way the player breaks even
## when the goblin dies.[br]
## [br]
## [b]Keys:[/b][br]
## 	[kbd]R[/kbd]: Rerandomize the results.

func _ready() -> void:
	rerandomize()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_R:
			rerandomize()


func hurt_all_gobs() -> void:
	for gob: Gob in PlayerData.army.gobs:
		if randf() < 0.5:
			gob.back_wounded = Big.new(randf_range(0.2, 0.8) * gob.get_count().to_float())
		if randf() < 0.5:
			gob.front_hp = randi_range(1, gob.front_hp - 1)
		if gob.is_hurt():
			gob.increase_wound_severity()


func rerandomize() -> void:
	PlayerData.reset()
	for _i in 50:
		var gob: Gob = PlayerData.army.generate_random_recruit({"count": Big.new(100)})
		PlayerData.army.add_gob(gob)
	hurt_all_gobs()
	HomeBaseData.heal_data.mark_groups_dirty()
	PlayerData.market.mark_costs_dirty()
	
	%RichTextLabel.text = ""
	var total_gold_cost: float = 0.0
	var total_medicine_cost: float = 0.0
	var total_herb_cost: float = 0.0
	for group: HealData.HealGroup in HomeBaseData.heal_data.groups:
		var group_gold_cost: float = 0.0
		var group_medicine_cost: float = 0.0
		var group_herb_cost: float = 0.0
		for gob: Gob in group.gobs:
			group_gold_cost += HomeBaseData.heal_data.get_gob_heal_cost(gob)
			if HomeBaseData.heal_data.gob_needs_strong_medicine(gob):
				group_medicine_cost += PlayerData.market.get_cost(
						Items.STRONG_MEDICINE, gob.get_hurt_count()).to_float()
				group_herb_cost += (
						PlayerData.market.get_cost(Items.HERB_1, Big.mul(2, gob.get_hurt_count())).to_float()
						+ PlayerData.market.get_cost(Items.HERB_2, Big.mul(3, gob.get_hurt_count())).to_float()
						+ PlayerData.market.get_cost(Items.HERB_3, Big.mul(5, gob.get_hurt_count())).to_float()
					)
			else:
				group_medicine_cost += PlayerData.market.get_cost(Items.WEAK_MEDICINE, gob.get_hurt_count()).to_float()
				var cheapest_herb_cost_per_goblin: float = min(
					PlayerData.market.get_cost(Items.HERB_1, Big.mul(2, gob.get_hurt_count())).to_float(),
					PlayerData.market.get_cost(Items.HERB_2, Big.mul(2, gob.get_hurt_count())).to_float(),
					PlayerData.market.get_cost(Items.HERB_3, Big.mul(2, gob.get_hurt_count())).to_float(),
				)
				group_herb_cost += cheapest_herb_cost_per_goblin
		group_gold_cost = ceil(group_gold_cost)
		group_medicine_cost = ceil(group_medicine_cost)
		group_herb_cost = ceil(group_herb_cost)
		var best_group_cost: float = min(group_gold_cost, group_medicine_cost, group_herb_cost)
		var group_gold_indicator: String = "*" if best_group_cost == group_gold_cost else ""
		var group_medicine_indicator: String = "*" if best_group_cost == group_medicine_cost else ""
		var group_herb_indicator: String = "*" if best_group_cost == group_herb_cost else ""
		show_line("%s - Gold cost: %s%s Medicine cost: %s%s Herb cost: %s%s" % [
				group.front().name,
				group_gold_indicator, Big.new(group_gold_cost).to_aa(),
				group_medicine_indicator, Big.new(group_medicine_cost).to_aa(),
				group_herb_indicator, Big.new(group_herb_cost).to_aa(),
			])
		total_gold_cost += group_gold_cost
		total_medicine_cost += group_medicine_cost
		total_herb_cost += group_herb_cost
	var best_total_cost: float = min(total_gold_cost, total_medicine_cost, total_herb_cost)
	var total_gold_indicator: String = "*" if best_total_cost == total_gold_cost else ""
	var total_medicine_indicator: String = "*" if best_total_cost == total_medicine_cost else ""
	var total_herb_indicator: String = "*" if best_total_cost == total_herb_cost else ""
	show_line("Total: Gold cost: %s%s Medicine cost: %s%s Herb cost: %s%s" % [
			total_gold_indicator, total_gold_cost,
			total_medicine_indicator, total_medicine_cost,
			total_herb_indicator, total_herb_cost])


func show_line(line: String) -> void:
	if %RichTextLabel.text:
		%RichTextLabel.text += "\n"
	%RichTextLabel.text += line
