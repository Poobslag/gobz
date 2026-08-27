extends GridContainer

signal option_picked(index: int)

@export var options: Array[String] = []:
	set(value):
		options = value
		_refresh()

var _placeholder_button_pressed: bool = false

@onready var option_buttons: Array[Button] = [%Button1, %Button2, %Button3, %Button4, %Button5, %Button6]

func _ready() -> void:
	%PlaceholderButton.pressed.connect(_on_placeholder_button_pressed)
	for i in option_buttons.size():
		option_buttons[i].pressed.connect(option_picked.emit.bind(i))


func set_disabled(new_disabled: bool) -> void:
	for button: Button in option_buttons:
		button.disabled = new_disabled
	%PlaceholderButton.disabled = new_disabled


func set_option_buttons_disabled(new_disabled: bool) -> void:
	for button: Button in option_buttons:
		button.disabled = new_disabled


func _refresh() -> void:
	%PlaceholderButton.hide()
	for option_button: Button in option_buttons:
		option_button.hide()
	
	if not _placeholder_button_pressed:
		%PlaceholderButton.show()
	else:
		for i in options.size():
			var option_button: Button = option_buttons[i]
			option_button.text = options[i]
			option_button.show()


func _on_placeholder_button_pressed() -> void:
	_placeholder_button_pressed = true
	_refresh()
