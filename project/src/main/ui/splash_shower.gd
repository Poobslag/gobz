extends Control

func _ready() -> void:
	var splash_arts: Array[Node] = get_tree().get_nodes_in_group("splash_art").filter(is_ancestor_of)
	if splash_arts.is_empty():
		return
	for splash_art: Node in splash_arts:
		splash_art.visible = false
	splash_arts.pick_random().visible = true
