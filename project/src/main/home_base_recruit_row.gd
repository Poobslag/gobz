class_name HomeBaseRecruitRow
extends HBoxContainer

signal recruit_pressed
signal skip_pressed

var item: Army.ArmyItem

func _ready() -> void:
	item = PlayerData.army.generate_random_recruit({"count": PlayerData.home_base_multiplier})
	
	%RecruitButton.text = "-💰%s" % [get_cost().to_aa()]
	var goblin_name: String = item.name
	if item.count.is_gt(1):
		goblin_name += " + %s others" % [item.count.to_aa()]
	%Description.text = "%s %s,  %s⚔" % [
			Goblins.emoji_from_type(item.type), goblin_name, Big.mul(item.attack, item.count).to_aa()]
	
	%RecruitButton.pressed.connect(recruit_pressed.emit)
	%SkipButton.pressed.connect(skip_pressed.emit)
	
	refresh()


func refresh() -> void:
	%RecruitButton.disabled = get_cost().is_gt(PlayerData.gold)


func get_cost() -> Big:
	return Big.mul(item.gold, item.count)
