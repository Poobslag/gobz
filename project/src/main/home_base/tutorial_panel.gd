extends ColorRect

func _ready() -> void:
	%Button.pressed.connect(hide)


func open() -> void:
	show()
	%Button.grab_focus()
