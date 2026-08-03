extends ColorRect

signal finished

func _ready() -> void:
	%Done.pressed.connect(finished.emit)
