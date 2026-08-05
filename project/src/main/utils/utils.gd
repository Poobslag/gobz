@tool
class_name Utils
## Contains global utilities.

const MAX_ARMY_VALUE: int = 999_999_999_999_999_999

## Returns the [member InputEventKey.keycode] for a key press event, or -1 if the event is not a key press event.
static func key_press(event: InputEvent) -> int:
	var keycode := -1
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		keycode = event.keycode
	return keycode


## Converts a potentially large number like 123,456,789 to a compact string like '123,456k'.
static func abbr_num(score_int: int) -> String:
	if score_int > 999_999_999_999_999_999:
		return "@!#,%&!"
	
	var suffix := ""
	var divisor := 1
	
	if score_int > 999_999_999_999_999:
		suffix = "t"
		divisor = 1_000_000_000_000
	elif score_int > 999_999_999_999:
		suffix = "b"
		divisor = 1_000_000_000
	elif score_int > 999_999_999:
		suffix = "m"
		divisor = 1_000_000
	elif score_int > 999_999:
		suffix = "k"
		divisor = 1_000
	
	@warning_ignore("integer_division")
	return "%s%s" % [StringUtils.comma_sep(score_int / divisor), suffix]


static func big_add(a: int, b: int) -> int:
	if a > MAX_ARMY_VALUE - b:
		return MAX_ARMY_VALUE
	return a + b


static func big_mult(a: int, b: int) -> int:
	@warning_ignore("integer_division")
	if b != 0 and a > MAX_ARMY_VALUE / b:
		return MAX_ARMY_VALUE
	return a * b
