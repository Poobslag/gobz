class_name HomeBaseRecruitRow
extends HBoxContainer

signal recruit_pressed
signal skip_pressed

var item: Army.ArmyItem

func _ready() -> void:
	item = PlayerData.army.generate_random_recruit()
	
	%RecruitButton.text = "-💰%s" % [StringUtils.comma_sep(item.gold)]
	%Description.text = "%s %s,  %s⚔" % [
			Goblins.emoji_from_type(item.type), item.name, StringUtils.comma_sep(item.attack)]
	
	%RecruitButton.pressed.connect(recruit_pressed.emit)
	%SkipButton.pressed.connect(skip_pressed.emit)
	
	refresh()


func refresh() -> void:
	%RecruitButton.disabled = (item.gold > PlayerData.gold)
