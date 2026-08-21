extends HBoxContainer

const MOOD_INTERVAL = 2.0

signal all_messages_shown

var pending_lines: Array[Array] = []

var _tween: Tween
var _face_tween: Tween

var _shown_lines: Array[String] = []


func _process(_delta: float) -> void:
	if (_tween == null or not _tween.is_running()) and not pending_lines.is_empty():
		_tween = Utils.recreate_tween(self, _tween)
		if %RichTextLabel.get_line_count() >= 3:
			%RichTextLabel.text = StringUtils.substring_after(%RichTextLabel.text, "\n")
		var visible_characters: int = %RichTextLabel.text.length()
		var pending_line: Array = pending_lines.pop_front()
		%RichTextLabel.visible_characters = %RichTextLabel.get_total_character_count()
		if pending_line[0] == 0:
			%RichTextLabel.text += "[left]%s[/left]\n" % [pending_line[1]]
		else:
			%RichTextLabel.text += "[right]%s[/right]" % [pending_line[1]]
		var tween_duration: float = Speech.CHARACTER_DELAY * \
				(%RichTextLabel.get_total_character_count() - %RichTextLabel.visible_characters)
		match pending_line[0]:
			1:
				_tween.tween_callback(_frown)
			2:
				_tween.tween_callback(_smile)
			3:
				_tween.tween_callback(_smile_forever)
		_tween.tween_property(%RichTextLabel, "visible_characters", \
				%RichTextLabel.get_total_character_count(), tween_duration)
		_tween.tween_callback(_check_all_messages_shown)
		if not pending_lines.is_empty():
			_tween.tween_interval(Speech.DEFAULT_DELAY)


func append_prompt(prompt: String) -> void:
	pending_lines.append([0, prompt] as Array[Variant])


func append_bad_response(response: String) -> void:
	pending_lines.append([1, response] as Array[Variant])


func append_good_response(response: String) -> void:
	pending_lines.append([2, response] as Array[Variant])


func append_great_response(response: String) -> void:
	pending_lines.append([3, response] as Array[Variant])


func reset_mood() -> void:
	%Face.text = "😐"


func _frown() -> void:
	_face_tween = Utils.recreate_tween(self, _face_tween)
	%Face.text = "😢"
	_face_tween.tween_interval(MOOD_INTERVAL)
	_face_tween.tween_callback(%Face.set.bind("text", "🙁"))


func _smile() -> void:
	_face_tween = Utils.recreate_tween(self, _face_tween)
	%Face.text = "😀"
	_face_tween.tween_interval(MOOD_INTERVAL)
	_face_tween.tween_callback(%Face.set.bind("text", "🙂"))


func _smile_forever() -> void:
	_face_tween = Utils.kill_tween(_face_tween)
	%Face.text = "😀"


func _check_all_messages_shown() -> void:
	if pending_lines.is_empty():
		all_messages_shown.emit()
