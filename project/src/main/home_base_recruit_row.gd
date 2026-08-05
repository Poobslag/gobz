class_name HomeBaseRecruitRow
extends HBoxContainer

signal recruit_pressed
signal skip_pressed

var item: Army.ArmyItem

func _ready() -> void:
	item = PlayerData.army.generate_random_recruit({"count": PlayerData.home_base_multiplier})
	
	%RecruitButton.text = "-💰%s" % [Utils.abbr_num(get_cost())]
	var goblin_name: String = item.name
	if item.count > 1:
		goblin_name += " + %s others" % [Utils.abbr_num(item.count - 1)]
	%Description.text = "%s %s,  %s⚔" % [
			Goblins.emoji_from_type(item.type), goblin_name, Utils.abbr_num(item.attack * item.count)]
	
	%RecruitButton.pressed.connect(recruit_pressed.emit)
	%SkipButton.pressed.connect(skip_pressed.emit)
	
	refresh()


func refresh() -> void:
	%RecruitButton.disabled = (get_cost() > PlayerData.gold)


func get_cost() -> int:
	return Utils.big_mult(item.gold, item.count)
