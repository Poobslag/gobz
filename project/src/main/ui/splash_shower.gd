class_name SplashShower
extends Control

func _ready() -> void:
	var splash_arts: Array[Node] = get_tree().get_nodes_in_group("splash_art").filter(is_ancestor_of)
	if splash_arts.is_empty():
		return
	for splash_art: Node in splash_arts:
		splash_art.visible = false
	splash_arts.pick_random().visible = true


func sync(other_shower: SplashShower) -> void:
	var splash_arts: Array[Node] = get_tree().get_nodes_in_group("splash_art").filter(is_ancestor_of)
	var other_splash_arts: Array[Node] \
			= get_tree().get_nodes_in_group("splash_art").filter(other_shower.is_ancestor_of)
	for splash_art: Node in splash_arts:
		splash_art.visible = false
	for i in other_splash_arts.size():
		if other_splash_arts[i].visible and i < splash_arts.size():
			splash_arts[i].visible = true
