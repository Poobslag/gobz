extends Node

func get_collectibles() -> Array[Collectible]:
	var result: Array[Collectible] = []
	result.assign(get_tree().get_nodes_in_group("collectibles").filter(is_ancestor_of))
	return result
