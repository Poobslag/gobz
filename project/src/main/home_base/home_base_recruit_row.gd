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
	
	# adjust back count based on multiplier
	var same_type_gobs: Array[Gob] = PlayerData.army.gobs.filter(func(other_gob: Gob) -> bool:
		return other_gob.type == gob.type)
	var same_type_gob: Gob
	if not same_type_gobs.is_empty():
		same_type_gob = same_type_gobs.pick_random()
	var gob_count: Big = PlayerData.home_base_multiplier
	if same_type_gob != null and gob_count.is_gt(1) and randf() < 0.5:
		_apply_morale_bonus(same_type_gob.morale.value)
	
	# ensure new recruits don't randomly swing morale
	if same_type_gob != null:
		gob.morale.value = same_type_gob.morale.value
	
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


func _apply_morale_bonus(morale_value: float) -> void:
	var factor: float = 1.0
	if morale_value > 95:
		factor = 1.5
	elif morale_value > 80:
		factor = 1.2
	elif morale_value > 65:
		factor = 1.1
	elif morale_value < 5:
		factor = 0.5
	elif morale_value < 20:
		factor = 0.8
	elif morale_value < 35:
		factor = 0.9
	
	if factor != 1.0:
		if factor > 1.0:
			# show the morale bonus and divide the discount among the goblins
			%MoraleBonus.visible = true
			%MoraleBonus.modulate = Color.WHITE
			%MoraleBonus.text = "+%d%% morale bonus" % [factor * 100 - 100]
			gob.gold = maxi(1, floor(gob.gold / factor))
		elif factor < 1.0:
			# show the morale bonus and multiply the surcharge among the goblins
			%MoraleBonus.visible = true
			%MoraleBonus.modulate = Color("b34947")
			%MoraleBonus.text = "%d%% morale bonus" % [factor * 100 - 100]
			gob.gold = maxi(1, ceil(gob.gold / factor))
		
		var new_count: Big = Big.new(gob.get_count().to_float() * factor)
		gob.back_count = Big.sub(new_count, 1)
