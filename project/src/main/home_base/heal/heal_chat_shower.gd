extends HBoxContainer

const MOOD_INTERVAL = 2.0

const EMOJI_BIG_SMILE: String = "😀"
const EMOJI_SMILE: String = "🙂"
const EMOJI_BIG_FROWN: String = "😢"
const EMOJI_FROWN: String = "🙁"
const EMOJI_NEUTRAL: String = "😐"

enum LineType {
	PROMPT,
	BAD_RESPONSE,
	NEUTRAL_RESPONSE,
	GOOD_RESPONSE,
	GREAT_RESPONSE,
}

signal all_messages_shown

var _pending_lines: Array[Array] = []
var _shown_lines: Array[Array] = []
var _tween: Tween
var _face_tween: Tween

func _process(_delta: float) -> void:
	if (_tween == null or not _tween.is_running()) and not _pending_lines.is_empty():
		_tween = Utils.recreate_tween(self, _tween)
		var pending_line: Array[Variant] = _pending_lines.pop_front()
		_shown_lines.append(pending_line)
		if _shown_lines.size() > 3:
			_shown_lines.pop_front()
		var visible_characters: int = %RichTextLabel.text.length()
		
		%RichTextLabel.text = ""
		for i in _shown_lines.size() - 1:
			_write_line_to_label(_shown_lines[i])
		
		%RichTextLabel.visible_characters = %RichTextLabel.get_total_character_count()
		_write_line_to_label(_shown_lines.back())
		var tween_duration: float = Speech.CHARACTER_DELAY * \
				(%RichTextLabel.get_total_character_count() - %RichTextLabel.visible_characters)
		match pending_line[0]:
			LineType.BAD_RESPONSE: _tween.tween_callback(_frown)
			LineType.NEUTRAL_RESPONSE: _tween.tween_callback(_neutral)
			LineType.GOOD_RESPONSE: _tween.tween_callback(_smile)
			LineType.GREAT_RESPONSE: _tween.tween_callback(_smile_forever)
		_tween.tween_property(%RichTextLabel, "visible_characters", \
				%RichTextLabel.get_total_character_count(), tween_duration)
		_tween.tween_callback(_check_all_messages_shown)
		if not _pending_lines.is_empty():
			_tween.tween_interval(Speech.DEFAULT_DELAY)


func flush_pending_lines() -> void:
	_tween = Utils.kill_tween(_tween)
	_face_tween = Utils.kill_tween(_face_tween)
	
	while not _pending_lines.is_empty():
		var pending_line: Array[Variant] = _pending_lines.pop_front()
		_shown_lines.append(pending_line)
	while _shown_lines.size() > 3:
		_shown_lines.pop_front()
	
	# update text label
	%RichTextLabel.text = ""
	var final_face_text: String = ""
	for i in _shown_lines.size():
		_write_line_to_label(_shown_lines[i])
	%RichTextLabel.visible_characters = -1
	
	# update face
	for i in _shown_lines.size():
		match _shown_lines[i][0]:
			LineType.BAD_RESPONSE: final_face_text = EMOJI_FROWN
			LineType.NEUTRAL_RESPONSE: final_face_text = EMOJI_NEUTRAL
			LineType.GOOD_RESPONSE: final_face_text = EMOJI_SMILE
			LineType.GREAT_RESPONSE: final_face_text = EMOJI_BIG_SMILE
	%Face.text = final_face_text


func clear() -> void:
	_tween = Utils.kill_tween(_tween)
	_face_tween = Utils.kill_tween(_face_tween)
	_pending_lines.clear()
	_shown_lines.clear()
	%RichTextLabel.text = ""
	%Face.text = EMOJI_NEUTRAL


func set_shown_lines(new_shown_lines: Array[Array]) -> void:
	_shown_lines = new_shown_lines
	flush_pending_lines()


func get_shown_lines() -> Array[Array]:
	return _shown_lines.duplicate(true)


func append_prompt(prompt: String) -> void:
	_pending_lines.append([LineType.PROMPT, prompt] as Array[Variant])


func append_bad_response(response: String) -> void:
	_pending_lines.append([LineType.BAD_RESPONSE, response] as Array[Variant])


func append_neutral_response(response: String) -> void:
	_pending_lines.append([LineType.NEUTRAL_RESPONSE, response] as Array[Variant])


func append_good_response(response: String) -> void:
	_pending_lines.append([LineType.GOOD_RESPONSE, response] as Array[Variant])


func append_great_response(response: String) -> void:
	_pending_lines.append([LineType.GREAT_RESPONSE, response] as Array[Variant])


func reset_mood() -> void:
	%Face.text = EMOJI_NEUTRAL


func hide_face() -> void:
	%Face.text = ""


func _frown() -> void:
	_face_tween = Utils.recreate_tween(self, _face_tween)
	%Face.text = EMOJI_BIG_FROWN
	_face_tween.tween_interval(MOOD_INTERVAL)
	_face_tween.tween_callback(%Face.set.bind("text", EMOJI_FROWN))


func _neutral() -> void:
	%Face.text = EMOJI_NEUTRAL


func _smile() -> void:
	_face_tween = Utils.recreate_tween(self, _face_tween)
	%Face.text = EMOJI_BIG_SMILE
	_face_tween.tween_interval(MOOD_INTERVAL)
	_face_tween.tween_callback(%Face.set.bind("text", EMOJI_SMILE))


func _smile_forever() -> void:
	_face_tween = Utils.kill_tween(_face_tween)
	%Face.text = EMOJI_BIG_SMILE


func _check_all_messages_shown() -> void:
	if _pending_lines.is_empty():
		all_messages_shown.emit()


func _write_line_to_label(line: Array[Variant]) -> void:
	if not %RichTextLabel.text.is_empty():
		%RichTextLabel.text += "\n"
	if line[0] == LineType.PROMPT:
		%RichTextLabel.text += "[left]%s[/left]" % [line[1]]
	else:
		%RichTextLabel.text += "[right]%s[/right]" % [line[1]]
