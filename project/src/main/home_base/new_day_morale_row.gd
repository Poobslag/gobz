extends VBoxContainer

var _emoji: String = ""
var _morale_text: String = ""
var _tween: Tween

func prepare(from_value: float) -> void:
	_set_morale_text(from_value)
	_refresh_morale(from_value)


func play(from_value: float, to_value: float, duration: float) -> void:
	_tween = Utils.recreate_tween(self, _tween)
	_set_morale_text(from_value)
	_refresh_morale(from_value)
	_tween.tween_method(_refresh_morale, from_value, to_value, duration)
	_tween.tween_callback(_set_morale_text.bind(to_value))
	_tween.tween_callback(_refresh_morale.bind(to_value))


func _set_morale_text(value: float) -> void:
	var threshold_index: int = Gobs.MORALE_THRESHOLDS.size() - 1
	for i in Gobs.MORALE_THRESHOLDS.size() - 2:
		if value <= Gobs.MORALE_THRESHOLDS[i][0]:
			threshold_index = i
			break
	_emoji = Gobs.MORALE_THRESHOLDS[threshold_index][1]
	_morale_text = Gobs.MORALE_THRESHOLDS[threshold_index][2]


func _refresh_morale(value: float) -> void:
	%ProgressBar.value = value
	
	var percent: String = "%s%%" % [roundi(clampf(value, 0.0, 100.0))]
	%RichTextLabel.text = "%s %s (%s)" % [_emoji, _morale_text, percent]
