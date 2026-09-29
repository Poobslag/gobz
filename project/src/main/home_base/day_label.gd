extends RichTextLabel

func _ready() -> void:
	text = "[b]Day %s[/b]" % [StringUtils.comma_sep(PlayerData.day)]
