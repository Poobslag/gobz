@tool
class_name Utils
## Contains global utilities.


## Returns the [member InputEventKey.keycode] for a key press event, or -1 if the event is not a key press event.
static func key_press(event: InputEvent) -> int:
	var keycode := -1
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		keycode = event.keycode
	return keycode
