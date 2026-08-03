class_name HomeBaseRecruitRow
extends HBoxContainer

signal recruit_pressed
signal skip_pressed

var item: Army.ArmyItem
var cost: int

func _ready() -> void:
	var recruit: Dictionary[String, Variant] = PlayerData.army.generate_random_recruit()
	item = recruit["item"]
	cost = recruit["cost"]
	
	%RecruitButton.text = "💰%s" % [StringUtils.comma_sep(cost)]
	%Description.text = "%s %s,  %s⚔" % [
			Goblins.EMOJIS_BY_GOBLIN_TYPE[item.type], item.name, StringUtils.comma_sep(item.attack)]
	
	%RecruitButton.pressed.connect(recruit_pressed.emit)
	%SkipButton.pressed.connect(skip_pressed.emit)
	
	refresh()


func refresh() -> void:
	%RecruitButton.disabled = (cost >= PlayerData.gold)
