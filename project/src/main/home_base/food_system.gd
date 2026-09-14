class_name FoodSystem

const FOOD_BREAD: Items.Type = Items.FOOD_BREAD
const FOOD_CHICKEN: Items.Type = Items.FOOD_CHICKEN
const FOOD_PIZZA: Items.Type = Items.FOOD_PIZZA
const FOOD_RAM: Items.Type = Items.FOOD_RAM
const FOOD_UNKNOWN: Items.Type = Items.FOOD_UNKNOWN

const EVENTS_BY_FOOD: Dictionary[Items.Type, MoraleEvent.MoraleEventType] = {
	Items.FOOD_BREAD: MoraleEvent.ATE_BREAD,
	Items.FOOD_CHICKEN: MoraleEvent.ATE_CHICKEN,
	Items.FOOD_PIZZA: MoraleEvent.ATE_PIZZA,
	Items.FOOD_RAM: MoraleEvent.ATE_RAM,
	Items.FOOD_UNKNOWN: MoraleEvent.ATE_UNKNOWN,
}

const PREFERENCES_BY_TYPE: Dictionary[Gobs.Type, Array] = {
	Gobs.Type.FIRE: [[FOOD_RAM, FOOD_CHICKEN], [FOOD_PIZZA, FOOD_BREAD], [FOOD_UNKNOWN]],
	Gobs.Type.WATER: [[FOOD_RAM, FOOD_PIZZA], [FOOD_BREAD, FOOD_CHICKEN], [FOOD_UNKNOWN]],
	Gobs.Type.GRASS: [[FOOD_RAM, FOOD_BREAD], [FOOD_CHICKEN, FOOD_PIZZA], [FOOD_UNKNOWN]],
	Gobs.Type.ANGEL: [[FOOD_RAM, FOOD_UNKNOWN], [FOOD_BREAD, FOOD_CHICKEN, FOOD_PIZZA], []],
	Gobs.Type.DEVIL: [[FOOD_RAM, FOOD_CHICKEN], [FOOD_BREAD, FOOD_PIZZA], [FOOD_UNKNOWN]],
}

static func feed_goblins() -> void:
	PlayerData.food_record.starved = false
	PlayerData.food_record.shown = false
	PlayerData.food_record.food_yesterday = _get_food_inventory()
	PlayerData.food_record.morale_yesterday = PlayerData.army.get_average_morale()
	
	var gobs: Array[Gob] = PlayerData.army.gobs.duplicate()
	gobs.shuffle()
	for gob: Gob in gobs:
		if gob.get_count().is_lt(3) and randf_range(0, 3) > gob.get_count().to_float():
			continue
		
		var food_needed: Big = Big.new(max(1, roundf(gob.get_count().to_float() / 3)))
		var available_foods: Array[Items.Type] = []
		
		# Event delta is small, but this is just for starving for one day. Thematically a meal here or there doesn't
		# matter unless the goblin starves for an entire week, then it adds up.
		var event_delta: float = -8
		var event_type: MoraleEvent.MoraleEventType = MoraleEvent.STARVED
		if available_foods.is_empty():
			for food: Items.Type in PREFERENCES_BY_TYPE[gob.type][0]:
				if PlayerData.inventory.has_item(food, Big.ONE):
					available_foods.append(food)
					event_delta = 4
		if available_foods.is_empty():
			for food: Items.Type in PREFERENCES_BY_TYPE[gob.type][1]:
				if PlayerData.inventory.has_item(food, Big.ONE):
					available_foods.append(food)
					event_delta = 2
		if available_foods.is_empty():
			for food: Items.Type in PREFERENCES_BY_TYPE[gob.type][2]:
				if PlayerData.inventory.has_item(food, Big.ONE):
					available_foods.append(food)
					event_delta = -4
		
		if not available_foods.is_empty():
			var food: Items.Type = available_foods.pick_random()
			PlayerData.inventory.take_item(food, food_needed)
			event_type = EVENTS_BY_FOOD[food]
		else:
			PlayerData.food_record.starved = true
		
		if randf() < 0.5 \
				and (gob.morale.events.is_empty() or gob.morale.get_last_event().day <= PlayerData.day - 2):
			# add an actual event
			gob.morale.add_event(MoraleEvent.new_randomized_event(event_type, event_delta))
		else:
			# just tweak the goblin's morale
			gob.morale.adjust_value(event_delta)
	
	# cap excess food
	for food: Items.Type in [Items.FOOD_BREAD, Items.FOOD_CHICKEN, Items.FOOD_PIZZA, Items.FOOD_RAM]:
		var food_count: float = PlayerData.inventory.get_count(food).to_float()
		var max_count: float = 4 * PlayerData.army.get_total_goblins().to_float()
		if food_count > max_count:
			# max stack size is 4x goblin count; lose 25% of the excess
			food_count = floor(food_count - 0.25 * (food_count - max_count))
			PlayerData.inventory.set_count(food, Big.new(food_count))
	
	# special cap for unknown food; only angel goblins can carry it
	var max_unknown_food: float = 0.0
	for gob: Gob in PlayerData.army.gobs:
		if gob.type == Gobs.ANGEL:
			max_unknown_food += gob.get_count().to_float()
	if PlayerData.inventory.get_count(Items.FOOD_UNKNOWN).to_float() > max_unknown_food:
		PlayerData.inventory.set_count(Items.FOOD_UNKNOWN, Big.new(max_unknown_food))
	
	PlayerData.food_record.food_today = _get_food_inventory()
	PlayerData.food_record.morale_today = PlayerData.army.get_average_morale()


static func _get_food_inventory() -> Dictionary[Items.Type, Big]:
	var result: Dictionary[Items.Type, Big] = {}
	for type: Items.Type in [FOOD_BREAD, FOOD_CHICKEN, FOOD_PIZZA, FOOD_RAM, FOOD_UNKNOWN]:
		result[type] = PlayerData.inventory.get_count(type)
	return result
