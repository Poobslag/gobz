@tool
class_name DungeonSelectRow
extends HBoxContainer

signal pressed

@export var desc: String

@export var button_text: String

@export var reward_icons: String = "":
	set(value):
		%Button.reward_icons = value

@export var boss: bool = false:
	set(value):
		%Button.boss = value

func _ready() -> void:
	%Desc.text = desc
	%Button.pressed.connect(pressed.emit)
