extends Node

func _ready() -> void:
	PlayerData.reset()
	for _i in 50:
		var gob: Gob = PlayerData.army.generate_random_recruit({"count": Big.new(10)})
		if randf() < 0.5:
			gob.back_wounded = Big.new(randf_range(2, 8))
		if randf() < 0.5:
			gob.front_hp = randi_range(1, gob.front_hp - 1)
		PlayerData.army.add_gob(gob)
	HomeBaseData.heal_data.mark_groups_dirty()
	
	PlayerData.gold = Big.new(5000)
	PlayerData.inventory.add_item(Items.HERB_1, Big.new(5000))
	PlayerData.inventory.add_item(Items.HERB_2, Big.new(5000))
	PlayerData.inventory.add_item(Items.HERB_3, Big.new(5000))
	PlayerData.inventory.add_item(Items.WEAK_MEDICINE, Big.new(5000))
	PlayerData.inventory.add_item(Items.STRONG_MEDICINE, Big.new(5000))
	%HealScreen.show_heal_panel()
