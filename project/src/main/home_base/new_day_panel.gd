extends ColorRect

signal ok_pressed

const PAUSE_DURATION: float = 0.3
const FOOD_DURATION: float = 0.6
const MORALE_DURATION: float = 0.6

const MESSAGES_NO_FOOD: Array[String] = [
	"The goblins will do anything for a bite to eat.",
	"The goblins are nothing but skin and bones.",
	"The goblins scavenge for anything resembling food.",
	"The goblins are desperate for some food.",
	"The goblins are starving.",
	"The goblins are absolutely famished.",
	"The goblins are extremely hungry.",
	"The goblins are hungry.",
	"The goblins have run out of food.",
	"The goblins need something to eat.",
	"The goblins want a little something to eat.",
	"The goblins are feeling a little hungry.",
]

const MESSAGES_FOOD: Array[String] = [
	"The goblins hate everything and want to die.",
	"The goblins wonder what they did to deserve this.",
	"The goblins are fomenting insurrection.",
	"The goblins are just in the worst mood.",
	"The goblins demand answers.",
	"The goblins can't take this much longer.",
	"The goblins are restless.",
	"The goblins are getting upset.",
	"The goblins need a break.",
	"The goblins could be doing worse.",
	"The goblins are feeling okay.",
	"The goblins feel satisfied.",
	"The goblins are comfortable.",
	"The goblins have a nice setup here.",
	"The goblins have got things figured out.",
	"The goblins are doing well for themselves.",
	"The goblins are having a great time.",
	"The goblins couldn't be happier.",
	"The goblins are at peace with the world.",
	"The goblins are thrilled with the leadership.",
	"The goblins are living their best life.",
	"The goblins have amazing camaraderie.",
	"The goblins trust each other completely.",
	"The goblins can't remember ever being this happy.",
	"The goblins never knew it could be this good.",
]

var _tween: Tween

func _ready() -> void:
	%Button.pressed.connect(func() -> void:
		hide()
		ok_pressed.emit())


func play() -> void:
	show()
	PlayerData.food_record.shown = true
	
	_tween = Utils.recreate_tween(self, _tween)
	
	# reset to initial state
	var food_rows: Array[Node] = get_tree().get_nodes_in_group("new_day_food_rows").filter(is_ancestor_of)
	for food_row: NewDayFoodRow in food_rows:
		food_row.prepare(PlayerData.food_record.food_yesterday.get(food_row.item_type, Big.ZERO))
	%Button.disabled = true
	%MoraleRow.prepare(PlayerData.food_record.morale_yesterday)
	%MoraleSummary.text = ""
	
	_tween.tween_interval(PAUSE_DURATION)
	
	# animate food rows, then wait...
	var max_food_eaten_pct: float = 0.0
	for food_row: NewDayFoodRow in food_rows:
		var food_yesterday: float = PlayerData.food_record.food_yesterday.get(food_row.item_type, Big.ZERO).to_float()
		var food_today: float = PlayerData.food_record.food_today.get(food_row.item_type, Big.ZERO).to_float()
		var food_eaten_pct: float = abs(food_yesterday - food_today) / max(food_yesterday, food_today, 1)
		max_food_eaten_pct = max(max_food_eaten_pct, food_eaten_pct)
	var food_duration: float = remap(max_food_eaten_pct, 0, 0.1, 0, FOOD_DURATION)
	food_duration = clamp(food_duration, 0.0, FOOD_DURATION)
	_tween.tween_callback(func() -> void:
		for food_row: NewDayFoodRow in food_rows:
			food_row.play( \
					PlayerData.food_record.food_yesterday.get(food_row.item_type, Big.ZERO),
					PlayerData.food_record.food_today.get(food_row.item_type, Big.ZERO),
					food_duration)
		)
	_tween.tween_interval(food_duration + PAUSE_DURATION)
	
	# animate morale row, then wait...
	var morale_delta: float = abs(PlayerData.food_record.morale_yesterday - PlayerData.food_record.morale_today)
	var morale_duration: float = remap(morale_delta, 0, 10, 0, MORALE_DURATION)
	morale_duration = clamp(morale_duration, 0.0, MORALE_DURATION)
	_tween.tween_callback(func() -> void:
		%MoraleRow.play( \
				PlayerData.food_record.morale_yesterday,
				PlayerData.food_record.morale_today,
				morale_duration)
		)
	if morale_duration > 0.1:
		_tween.tween_interval(morale_duration)
	
	# finish animating the panel
	_tween.tween_callback(_refresh_morale_summary)
	_tween.tween_callback(func() -> void:
		%Button.disabled = false)


func _refresh_morale_summary() -> void:
	var has_food: bool = false
	for item: Items.Type in [Items.FOOD_BREAD, Items.FOOD_CHICKEN, Items.FOOD_PIZZA, Items.FOOD_RAM]:
		if PlayerData.food_record.food_today.get(item, Big.ZERO).is_gt(0):
			has_food = true
			break
	
	var messages: Array[String] = MESSAGES_FOOD if has_food else MESSAGES_NO_FOOD
	
	var index: float = remap(PlayerData.food_record.morale_today, 0.0, 100.0, 0, messages.size() - 1)
	index += randf_range(-1.5, 1.5)
	%MoraleSummary.text = messages[clampi(roundi(index), 0, messages.size() - 1)]
