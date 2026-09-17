class_name HomeBaseRecruitRow
extends HBoxContainer

signal recruit_pressed
signal skip_pressed

var gob: Gob

func _ready() -> void:
	gob = PlayerData.army.generate_random_recruit({
		"count": PlayerData.home_base_multiplier,
		"max_level": DungeonDirector.get_recruit_max_level(PlayerData.day),
		"type_weights": DungeonDirector.get_recruit_type_weights(PlayerData.day),
		})
	
	%CostDisplay.amount = CostDisplay.amount_from_cost(get_cost())
	var goblin_name: String = gob.name
	if gob.get_count().is_gt(1):
		goblin_name += " + %s others" % [Big.sub(gob.get_count(), 1).to_aa()]
	
	var attack_rating: String = Gobs.attack_rating(gob.attack)
	if not attack_rating.is_empty():
		attack_rating = " " + attack_rating
	%Description.text = "%s%s %s" % [
			Gobs.emoji_from_type(gob.type), attack_rating, goblin_name]
	
	%RecruitButton.pressed.connect(recruit_pressed.emit)
	%SkipButton.pressed.connect(skip_pressed.emit)
	GoldBar.find_instance(self).connect_button_signals(%RecruitButton, get_cost)
	
	refresh()


func refresh() -> void:
	%RecruitButton.disabled = not PlayerData.can_spend(get_cost())
	%CostDisplay.disabled = %RecruitButton.disabled


func get_cost() -> Big:
	return Big.mul(gob.gold, gob.get_count())
