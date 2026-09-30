extends Control

const TROPHY_ROW_SCENE: PackedScene = preload("res://src/main/home_base/trophy_row.tscn")

func _ready() -> void:
	refresh()


func refresh() -> void:
	for child: Node in %TrophyRows.get_children():
		%TrophyRows.remove_child(child)
		child.queue_free()
	
	for collectible: Collectible in Collectibles.get_collectibles():
		_add_trophy_row(collectible)


func _add_trophy_row(collectible: Collectible) -> void:
	var trophy_row: TrophyRow = TROPHY_ROW_SCENE.instantiate()
	trophy_row.collectible = collectible
	%TrophyRows.add_child(trophy_row)
