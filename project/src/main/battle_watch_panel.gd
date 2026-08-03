extends ColorRect

signal finished

func _ready() -> void:
	%DoneButton.pressed.connect(finished.emit)
