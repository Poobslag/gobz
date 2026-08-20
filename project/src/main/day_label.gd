extends RichTextLabel

func _ready() -> void:
	%DayLabel.text = "Day %s" % [StringUtils.comma_sep(PlayerData.day)]
