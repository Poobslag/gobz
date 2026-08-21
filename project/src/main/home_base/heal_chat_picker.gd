extends GridContainer

signal option_picked(index: int)

@export var options: Array[String] = []

@onready var option_buttons: Array[Button] = [%Button1, %Button2, %Button3, %Button4, %Button5, %Button6]

func _ready() -> void:
	%PlaceholderButton.pressed.connect(_on_placeholder_button_pressed)
	for i in option_buttons.size():
		option_buttons[i].pressed.connect(option_picked.emit.bind(i))


func _on_placeholder_button_pressed() -> void:
	%PlaceholderButton.hide()
	for i in options.size():
		option_buttons[i].text = options[i]
		option_buttons[i].show()
