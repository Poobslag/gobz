extends RichTextLabel

func _ready() -> void:
	%DayLabel.text = "[b]Day %s[/b]" % [StringUtils.comma_sep(PlayerData.day)]
