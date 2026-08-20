extends VBoxContainer

func _ready() -> void:
	_refresh()


func _refresh() -> void:
	HomeBaseData.heal_state.get_heal_groups()
	pass
