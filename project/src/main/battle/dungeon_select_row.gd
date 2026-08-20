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

@export var button_text: String

func _ready() -> void:
	_refresh()
	%Button.pressed.connect(pressed.emit)


func _refresh() -> void:
	%Button.text = button_text
	%Desc.text = desc
