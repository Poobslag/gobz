extends PanelContainer

var _tween: Tween

func play_message(message: String) -> void:
	%RichTextLabel.text = message
	_tween = Utils.recreate_tween(self, _tween)
	var tween_duration: float = Speech.CHARACTER_DELAY * \
			(%RichTextLabel.get_total_character_count() - %RichTextLabel.visible_characters)
	_tween.tween_property(%RichTextLabel, "visible_characters", \
			%RichTextLabel.get_total_character_count(), tween_duration)


func set_message(message: String) -> void:
	%RichTextLabel.text = message
	_tween = Utils.kill_tween(_tween)
	%RichTextLabel.visible_characters = -1
