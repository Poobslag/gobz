extends Node
## [b]Keys:[/b][br]
## 	[kbd][A,S,D][/kbd]: Change state to exists/file_not_found/error.[br]

func _ready() -> void:
	%SaveSlotRow.desc = "Day 3: 3.7t goblins, 4.1t⚔"
	%SaveSlotRow.state = SaveSlotRow.State.EXISTS


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_A:
			%SaveSlotRow.state = SaveSlotRow.State.EXISTS
		KEY_S:
			%SaveSlotRow.state = SaveSlotRow.State.NOT_FOUND
		KEY_D:
			%SaveSlotRow.state = SaveSlotRow.State.ERROR
