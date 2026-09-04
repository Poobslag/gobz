@tool
class_name DungeonSelectRow
extends HBoxContainer

signal pressed

@export var desc: String:
	set(value):
		desc = value
		if is_node_ready():
			_refresh()

@export var button_text: String

func _ready() -> void:
	_refresh()
	%Button.pressed.connect(pressed.emit)


func _refresh() -> void:
	%Button.text = button_text
	%Desc.text = desc
