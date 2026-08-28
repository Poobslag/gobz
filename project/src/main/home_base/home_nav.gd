@tool
extends VBoxContainer

signal before_scene_change

@export
var location_index: int = 0:
	set(value):
		location_index = value
		if not is_node_ready():
			return
		_refresh()

func _ready() -> void:
	_refresh()
	%Home.pressed.connect(change_scene.bind("res://src/main/home_base/home_base_screen.tscn"))
	%Heal.pressed.connect(change_scene.bind("res://src/main/home_base/heal/heal_screen.tscn"))


func change_scene(path: String) -> void:
	before_scene_change.emit()
	get_tree().change_scene_to_file(path)


func _refresh() -> void:
	var nav_buttons: Array[Node] = get_tree().get_nodes_in_group("nav_buttons").filter(is_ancestor_of)
	if location_index >= nav_buttons.size():
		push_error("location_index out of bounds: %s >= %s" % [location_index, nav_buttons.size()])
		return
	
	for i in nav_buttons.size():
		var nav_button: Button = nav_buttons[i]
		nav_button.disabled = false
	nav_buttons[location_index].disabled = true
