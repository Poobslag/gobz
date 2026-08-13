class_name HomeBaseRecruitRow
extends HBoxContainer

signal recruit_pressed
signal skip_pressed

var horde: Horde

func _ready() -> void:
	horde = PlayerData.army.generate_random_recruit({"count": PlayerData.home_base_multiplier})
	
	%RecruitButton.text = "-💰%s" % [get_cost().to_aa()]
	var goblin_name: String = horde.name
	if horde.count.is_gt(1):
		goblin_name += " + %s others" % [Big.sub(horde.count, 1).to_aa()]
	%Description.text = "%s %s,  %s⚔" % [
			Goblins.emoji_from_type(horde.type), goblin_name, Big.mul(horde.attack, horde.count).to_aa()]
	
	%RecruitButton.pressed.connect(recruit_pressed.emit)
	%SkipButton.pressed.connect(skip_pressed.emit)
	
	refresh()


func refresh() -> void:
	%RecruitButton.disabled = get_cost().is_gt(PlayerData.gold)


func get_cost() -> Big:
	return Big.mul(horde.gold, horde.count)
