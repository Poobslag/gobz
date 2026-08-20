extends ColorRect

func refresh() -> void:
	var heal_groups: Array[Array] = PlayerData.get_heal_groups()
	
	%InventoryLabel.text = ""
	%InventoryLabel.text = ""
	
	#🔥: 11.2m goblins, (4% 🩹) ⚔76.1m
	#💰 1.6m - 🍰 1.2m - 🍺 2.1m
	#🌿 300k - 🍄 2.5m - 🍞 6.7k
	
	pass
