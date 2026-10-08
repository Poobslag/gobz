class_name HomeBaseRecruitRow
extends Control

signal recruit_pressed
signal skip_pressed

const PLAY_DURATION: float = 0.12

static var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

@export var top_margin: float = 0.0:
	set(value):
		top_margin = value
		if is_node_ready():
			refresh()

var gob: Gob

var _tween: Tween

func _ready() -> void:
	if randf() < 0.6 and PlayerData.prev_dungeon != null and not PlayerData.prev_dungeon.composition.is_empty():
		# generate a recruit based on the previous dungeon's composition
		var composition: Dictionary[String, Variant] = PlayerData.prev_dungeon.composition
		var type: Gobs.Type = composition["types"][_rng.rand_weighted(composition["weights"])]
		gob = PlayerData.army.generate_random_recruit({
			"count": PlayerData.home_base_multiplier,
			"max_level": DungeonDirector.get_recruit_max_level(PlayerData.day),
			"type": type
			})
	else:
		# generate a recruit based on the player's progression through the game
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


func play_recruit_animation() -> void:
	for button: Button in [%RecruitButton, %SkipButton]:
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	%SkipButton.text = "Yes"
	%HBoxContainer.pivot_offset = %HBoxContainer.size * 0.5
	
	_tween = Utils.recreate_tween(self, _tween)
	_tween.parallel().tween_property(%HBoxContainer, "modulate:a", 0.0, PLAY_DURATION) \
			.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CIRC)
	_tween.parallel().tween_property(%HBoxContainer, "scale", Vector2(2.0, 2.0), PLAY_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CIRC)
	_tween.parallel().tween_property(self, "custom_minimum_size:y", 0.0, PLAY_DURATION)
	_tween.tween_callback(queue_free).set_delay(PLAY_DURATION)


func tween_top_margin_to_zero() -> void:
	_tween = Utils.recreate_tween(self, _tween)
	_tween.parallel().tween_property(self, "top_margin", 0.0, PLAY_DURATION)


func play_appear_animation() -> void:
	%HBoxContainer.pivot_offset = %HBoxContainer.size * 1.0
	%HBoxContainer.scale.y = 0.0
	custom_minimum_size.y = 0.0
	_tween = Utils.recreate_tween(self, _tween)
	_tween.tween_property(%HBoxContainer, "scale:y", 1.0, PLAY_DURATION)
	_tween.parallel().tween_method(_set_animated_height, custom_minimum_size.y, 31.0 + top_margin, PLAY_DURATION)


func play_skip_animation() -> void:
	for button: Button in [%RecruitButton, %SkipButton]:
		button.disabled = true
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	_tween = Utils.recreate_tween(self, _tween)
	_tween.tween_property(%HBoxContainer, "modulate:a", 0.0, PLAY_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.parallel().tween_property(%HBoxContainer, "position:x", 400, PLAY_DURATION) \
			.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.parallel().tween_property(self, "custom_minimum_size:y", 0.0, PLAY_DURATION)
	_tween.tween_callback(queue_free).set_delay(PLAY_DURATION)


func refresh() -> void:
	custom_minimum_size.y = 31.0 + top_margin
	size.y = 31.0 + top_margin
	
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
			%MoraleBonus.text = "%d%% morale penalty" % [factor * 100 - 100]
			gob.gold = maxi(1, ceil(gob.gold / factor))
		
		var new_count: Big = Big.new(gob.get_count().to_float() * factor)
		gob.back_count = Big.sub(new_count, 1)


## Sets this row's height, rounded down to a whole pixel.[br]
## [br]
## Used to tween the height of rows that are growing. Rows that are shrinking at the same time are tweened directly,
## and both tweens add up to a constant total height. If both use fractional heights, the container rounds each one
## up (e.g. 15.4 + 15.6 would take 16+16 = 32px instead of 31px) causing the UI to jitter.[br]
## [br]
## Rounding the growing row down keeps the combined height intact.
func _set_animated_height(value: float) -> void:
	custom_minimum_size.y = floor(value)
