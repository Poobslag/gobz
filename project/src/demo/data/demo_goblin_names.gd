extends Node

func _ready() -> void:
	%Button.pressed.connect(regenerate_names)
	regenerate_names()


func regenerate_names() -> void:
	%RichTextLabel.text = ""
	for _i in 15:
		if not %RichTextLabel.text.is_empty():
			%RichTextLabel.text += "\n"
		var gender: GoblinNames.Gender = [GoblinNames.MALE, GoblinNames.FEMALE].pick_random()
		var goblin_name: String = GoblinNames.random_name(gender)
		var gender_icon: String = "♂️" if gender == GoblinNames.MALE else "♀️"
		%RichTextLabel.text += "%s %s" % [gender_icon, goblin_name]
