@tool
class_name SaveSlotRow
extends HBoxContainer

signal play_pressed
signal delete_confirmed

enum State {
	EXISTS,
	NOT_FOUND,
	ERROR,
	DELETE_WARNING,
	DELETE_ARMED,
}

const FONT_COLOR_PROPERTIES: Array[String] = [
	"font_color",
	"font_focus_color",
	"font_pressed_color",
	"font_hover_color",
	"font_hover_pressed_color",
	"font_disabled_color",
]

@export var desc: String:
	set(value):
		desc = value
		if is_node_ready():
			_refresh()

@export var state: State = State.EXISTS:
	set(value):
		state = value
		if is_node_ready():
			_refresh()

func _ready() -> void:
	%PlayButton.pressed.connect(play_pressed.emit)
	%DeleteButton.pressed.connect(_on_delete_pressed)
	%WarningTimer.timeout.connect(_on_warning_timer_timeout)


func _refresh() -> void:
	# default state; continue/delete, both enabled, white text, description
	for property: String in FONT_COLOR_PROPERTIES:
		%DeleteButton.remove_theme_color_override(property)
	%PlayButton.text = "Continue"
	%PlayButton.disabled = false
	%DeleteButton.text = "Delete"
	%DeleteButton.disabled = false
	%Desc.text = desc
	
	match state:
		State.EXISTS:
			pass
		State.NOT_FOUND:
			%PlayButton.text = "New"
			%DeleteButton.disabled = true
			%Desc.text = ""
		State.ERROR:
			%PlayButton.disabled = true
			%Desc.text = "Error loading file."
		State.DELETE_WARNING:
			%DeleteButton.text = "Confirm?"
			%DeleteButton.disabled = true
			for property: String in FONT_COLOR_PROPERTIES:
				%DeleteButton.add_theme_color_override(property, Color.RED)
		State.DELETE_ARMED:
			%DeleteButton.text = "Confirm?"
			%DeleteButton.add_theme_color_override("font_color", Color.RED)


func _on_delete_pressed() -> void:
	if state == State.DELETE_ARMED:
		delete_confirmed.emit()
	else:
		state = State.DELETE_WARNING
		%WarningTimer.start()


func _on_warning_timer_timeout() -> void:
	if state == State.DELETE_WARNING:
		state = State.DELETE_ARMED
