@tool
class_name DungeonSelectRow
extends HBoxContainer

signal pressed

@export var desc: String:
	set(value):
		desc = value
		if not is_node_ready():
			return
		_refresh()

@export var index: int:
	set(value):
		index = value
		if not is_node_ready():
			return
		_refresh()

func _ready() -> void:
	_refresh()
	%Button.pressed.connect(pressed.emit)


func _refresh() -> void:
	%Button.text = "Dungeon %s" % [index + 1]
	%Desc.text = desc
