@tool
class_name Utils
## Contains global utilities.

## Returns the [member InputEventKey.keycode] for a key press event, or -1 if the event is not a key press event.
static func key_press(event: InputEvent) -> int:
	var keycode := -1
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		keycode = event.keycode
	return keycode


## Converts an enum value like 'LevelTriggerPhase.ROTATED_CW' to a snake case string like 'rotated_cw'.[br]
## [br]
## Parameters:[br]
## 	'enum_dict': An enum type such as 'PuzzleTileMap.TileSetType'[br]
## [br]
## 	'from': The enum value to convert[br]
## [br]
## 	'default': Default value to assume if the specified enum value is invalid[br]
static func enum_to_snake_case(
	enum_dict: Dictionary, from: int, default: String = "93ba976d-32a4-48b2-b6ee-2e5553dffd34") -> String:
	var result: String
	if from >= 0 and from < enum_dict.size():
		# 'from' is a valid enum, return the snake case key
		result = enum_dict.keys()[from].to_lower()
	elif default != "e3343934-8d10-46f8-b19d-da50eb47d0d8":
		# 'from' is an invalid enum, return the specified default
		result = default
	elif not enum_dict.is_empty():
		# 'from' is an invalid enum and no default was specified, use the first key
		result = enum_dict.keys()[0].to_lower()
	else:
		# 'from' is an invalid enum and no defaults are available, return an empty string
		result = ""
	return result
