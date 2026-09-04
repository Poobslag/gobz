@tool
extends ColorRect

const INVENTORY_HEADER_LABEL_SCENE: PackedScene = preload("res://src/main/home_base/inventory_header_label.tscn")

@export var inventory_items: Array[Items.Type] = []:
	set(value):
		inventory_items = value
		if is_node_ready():
			_refresh()

func _ready() -> void:
	_refresh()


func _refresh() -> void:
	var inventory_header_labels: Array[Node] = get_tree().get_nodes_in_group("inventory_header_labels") \
			.filter(is_ancestor_of)
	for label: Node in inventory_header_labels:
		label.queue_free()
	for item_type in inventory_items:
		var label: InventoryHeaderLabel = INVENTORY_HEADER_LABEL_SCENE.instantiate()
		label.type = item_type
		%HBoxContainer.add_child(label)
		if Engine.is_editor_hint():
			label.owner = get_tree().edited_scene_root
