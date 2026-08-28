class_name HealData

## How bumpy the healing curve is. [br]
## 2.0 = Some wounds cost about 4x as much to heal.
## 4.0 = Some wounds cost about 16x as much to heal.
const HEAL_COST_EXP: float = 2.0
const HEAL_COST_FACTOR: float = 25.0

## It's more expensive to heal with gold, but you get about half of it back eventually.
const HEAL_GOLD_COST_FACTOR: float = 50.0
const HEAL_GOLD_RETENTION_RATE: float = 0.5

static var HEAL_THRESHOLDS: Array[HealThreshold] = [
	HealThreshold.new( 1.0,  2, 1, 2),
	HealThreshold.new( 2.0,  3, 2, 3),
	HealThreshold.new( 3.0,  3, 3, 3),
	HealThreshold.new( 6.0,  4, 3, 4),
	HealThreshold.new(10.0,  4, 4, 4),
	HealThreshold.new(15.0,  5, 4, 5),
	HealThreshold.new(21.0,  5, 5, 5),
	HealThreshold.new(28.0,  6, 5, 6),
	HealThreshold.new(36.0,  6, 6, 6),
	HealThreshold.new(45.0,  7, 6, 6),
	HealThreshold.new(55.0,  8, 6, 6),
	HealThreshold.new(65.0,  9, 6, 6),
	HealThreshold.new(75.0, 10, 6, 6),
	HealThreshold.new(85.0, 11, 6, 6),
	HealThreshold.new(95.0, 12, 6, 6),
]

var groups: Array[HealGroup]:
	get():
		return get_groups()
var group_index: int

var _groups_cache: Array[HealGroup]
var _groups_dirty: bool = true

var _greed_factor_by_gob: Dictionary[Gob, float]

func get_greed_factor(gob: Gob) -> float:
	return _greed_factor_by_gob.get(gob, 1.0)


func mark_groups_dirty() -> void:
	_groups_dirty = true


func remove_group_at(i: int) -> void:
	groups.remove_at(i)
	if i < group_index or group_index >= _groups_cache.size():
		group_index -= 1


func get_groups() -> Array[HealGroup]:
	if _groups_dirty:
		_groups_dirty = false
		_groups_cache = _calculate_groups()
	return _groups_cache


func get_center_group() -> HealGroup:
	return get_group_at(group_index)


func get_group_at(i: int) -> HealGroup:
	return groups[i] if i >= 0 and i < groups.size() else null


func get_left_group() -> HealGroup:
	return get_group_at(get_left_index())


func get_right_group() -> HealGroup:
	return get_group_at(get_right_index())


func move_left() -> void:
	group_index = get_left_index()


func move_right() -> void:
	group_index = get_right_index()


func get_left_index() -> int:
	return wrapi(group_index - 1, 0, groups.size())


func get_right_index() -> int:
	return wrapi(group_index + 1, 0, groups.size())


func get_gob_heal_cost(gob: Gob) -> float:
	var cost_per_goblin: float = maxf(1.0, HEAL_GOLD_COST_FACTOR \
		* pow(gob.wound_severity, HEAL_COST_EXP) \
		* get_greed_factor(gob))
	return cost_per_goblin * gob.get_hurt_count().to_float()


func gob_needs_strong_medicine(gob: Gob) -> bool:
	return gob.wound_severity >= 0.5


func reroll_wound_severity(wounded: Dictionary[Gob, bool]) -> void:
	for gob: Gob in PlayerData.army.gobs:
		if gob in wounded:
			gob.increase_wound_severity()
		else:
			gob.decrease_wound_severity()


func _calculate_groups() -> Array[HealGroup]:
	_recalculate_greed_factor()
	
	var result: Array[HealGroup] = []
	var hurt_gobs_by_type: Dictionary[Gobs.Type, Array] = {}
	var hurt_gob_count_by_type: Dictionary[Gobs.Type, Big] = {}
	for type: Gobs.Type in Gobs.Type.values():
		hurt_gobs_by_type[type] = [] as Array[Gob]
		hurt_gob_count_by_type[type] = Big.ZERO
	
	# group by wound severity
	var sorted_by_wound_severity: Array[Gob] = PlayerData.army.gobs.duplicate()
	sorted_by_wound_severity.sort_custom(func(a: Gob, b: Gob) -> bool:
		return a.wound_severity < b.wound_severity)
	for gob: Gob in PlayerData.army.gobs:
		if gob.is_hurt():
			hurt_gobs_by_type[gob.type].append(gob)
			hurt_gob_count_by_type[gob.type] = \
					Big.add(hurt_gob_count_by_type[gob.type], gob.get_hurt_count())
	
	for type: Gobs.Type in hurt_gobs_by_type:
		var gobs_of_type: Array[Gob] = hurt_gobs_by_type[type]
		if gobs_of_type.is_empty():
			continue
		var heal_threshold: HealThreshold = \
				get_heal_threshold(hurt_gob_count_by_type[gobs_of_type.front().type])
		
		# split goblins from gobs_of_type into heal groups
		var gob_groups: Array[Array] = []
		for i in mini(gobs_of_type.size(), heal_threshold.groups):
			gob_groups.append([] as Array[Gob])
		for i in gobs_of_type.size():
			@warning_ignore("integer_division")
			var target_group_index: int = i * gob_groups.size() / gobs_of_type.size()
			gob_groups[target_group_index].append(gobs_of_type[i])
		for group: Array[Gob] in gob_groups:
			result.append(HealGroup.new(group, heal_threshold))
	
	result.shuffle()
	return result


func _recalculate_greed_factor() -> void:
	for gob: Gob in PlayerData.army.gobs:
		var greed_factor: float = [0.6, 0.8, 1.0, 1.0, 1.0, 1.2, 1.4].pick_random()
		greed_factor = Utils.apply_market_whim(greed_factor)
		_greed_factor_by_gob[gob] = greed_factor


static func get_heal_threshold(hurt_count: Big) -> HealThreshold:
	# calculate the two possible heal thresholds based on hurt_count
	var wounded_exponent: float = log(hurt_count.to_float()) / log(10)
	var lo_index: int = HEAL_THRESHOLDS.size() - 1
	var hi_index: int = HEAL_THRESHOLDS.size() - 1
	for i: int in HEAL_THRESHOLDS.size() - 1:
		if wounded_exponent <= HEAL_THRESHOLDS[i].exponent:
			hi_index = i
			lo_index = maxi(0, i - 1)
			break
	
	# randomly interpolate between the two possible heal thresholds
	var result: HealThreshold = HEAL_THRESHOLDS[lo_index].duplicate()
	if lo_index != hi_index:
		var factor: float = inverse_lerp(
				HEAL_THRESHOLDS[lo_index].exponent, HEAL_THRESHOLDS[hi_index].exponent, wounded_exponent)
		if randf() < factor - floor(factor):
			result.groups = HEAL_THRESHOLDS[hi_index].groups
		if randf() < factor - floor(factor):
			result.chats = HEAL_THRESHOLDS[hi_index].chats
		if randf() < factor - floor(factor):
			result.options = HEAL_THRESHOLDS[hi_index].options
	
	return result


static func full_heal(gob: Gob) -> void:
	gob.back_wounded = Big.ZERO
	gob.front_hp = gob.hp_max


static func get_heal_stats(gobs: Array[Gob]) -> Dictionary[String, Variant]:
	var total_hurt_count: float = 0.0
	var total_penalty: float = 0.0
	for gob: Gob in gobs:
		total_hurt_count += gob.get_hurt_count().to_float()
		total_penalty += gob.get_wounded_count().to_float() \
				* roundi(gob.attack * (1.0 - Gobs.WOUNDED_ATTACK_FACTOR))
	return {
		"hurt_count": total_hurt_count,
		"penalty": total_penalty,
	}


class HealThreshold:
	var exponent: float
	var groups: int
	var chats: int
	var options: int
	
	func _init(init_exponent: float, init_groups: int, init_chats: int, init_options: int) -> void:
		exponent = init_exponent
		groups = init_groups
		chats = init_chats
		options = init_options
	
	
	func duplicate() -> HealThreshold:
		return HealThreshold.new(exponent, groups, chats, options)


class HealGroup:
	var gobs: Array[Gob]
	var max_chats_remaining: int = 5
	var chats_remaining: int = 5
	var option_count: int = 5
	var count: Big = Big.ZERO
	
	## A goblin may be hurt without being wounded. A goblin with 7/8 hp is hurt, and can be healed.
	var hurt_count: Big = Big.ZERO
	
	func _init(init_gobs: Array[Gob], heal_threshold: HealThreshold) -> void:
		gobs = init_gobs
		
		refresh()
		
		# initialize chats
		max_chats_remaining = heal_threshold.chats
		chats_remaining = heal_threshold.chats
		option_count = heal_threshold.options
	
	func is_hurt() -> bool:
		return hurt_count.is_gt(0)
	
	
	## Calculate count, hurt count
	func refresh() -> void:
		count = Big.ZERO
		hurt_count = Big.ZERO
		
		for gob: Gob in gobs:
			count = Big.add(count, gob.get_count())
			hurt_count = Big.add(hurt_count, gob.get_hurt_count())
	
	
	func front() -> Gob:
		return gobs.front()
	
	
	func get_type() -> Gobs.Type:
		return front().type
	
	
	func increment_chats_remaining() -> void:
		chats_remaining = clampi(chats_remaining + 1, 0, max_chats_remaining)
	
	
	func decrement_chats_remaining() -> void:
		chats_remaining = clampi(chats_remaining - 1, 0, max_chats_remaining)
