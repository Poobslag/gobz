class_name HealData

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

func mark_groups_dirty() -> void:
	_groups_dirty = true


func get_groups() -> Array[HealGroup]:
	if _groups_dirty:
		_groups_dirty = false
		_groups_cache = _calculate_groups()
	return _groups_cache


func get_center_group() -> HealGroup:
	return get_group_at(group_index)


func get_group_at(i: int) -> HealGroup:
	return groups[i] if i < groups.size() else null


func get_left_group() -> HealGroup:
	return get_group_at(get_left_index())


func get_right_group() -> HealGroup:
	return get_group_at(get_right_index())


func navigate_left() -> void:
	group_index = get_left_index()


func navigate_right() -> void:
	group_index = get_right_index()


func get_left_index() -> int:
	return wrapi(group_index - 1, 0, groups.size() - 1)


func get_right_index() -> int:
	return wrapi(group_index + 1, 0, groups.size() - 1)


func _calculate_groups() -> Array[HealGroup]:
	var result: Array[HealGroup] = []
	var wounded_gobs_by_type: Dictionary[Gobs.Type, Array] = {}
	var wounded_gob_count_by_type: Dictionary[Gobs.Type, Big] = {}
	for type: Gobs.Type in Gobs.Type.values():
		wounded_gobs_by_type[type] = [] as Array[Gob]
		wounded_gob_count_by_type[type] = Big.ZERO
	for gob: Gob in PlayerData.army.gobs:
		if gob.get_wounded_count().is_gt(Big.ZERO):
			wounded_gobs_by_type[gob.type].append(gob)
			wounded_gob_count_by_type[gob.type] = \
					Big.add(wounded_gob_count_by_type[gob.type], gob.get_wounded_count())
	for type: Gobs.Type in wounded_gobs_by_type:
		var gobs_of_type: Array[Gob] = wounded_gobs_by_type[type]
		if gobs_of_type.is_empty():
			continue
		var heal_threshold: HealThreshold = \
				get_heal_threshold(wounded_gob_count_by_type[gobs_of_type.front().type])
		
		# split goblins from gobs_of_type into heal groups
		var gob_groups: Array[Array] = []
		for i in mini(gobs_of_type.size(), heal_threshold.groups):
			gob_groups.append([] as Array[Gob])
		for i in gobs_of_type.size():
			gob_groups[i % gob_groups.size()].append(gobs_of_type[i])
		for group: Array[Gob] in gob_groups:
			result.append(HealGroup.new(group, heal_threshold))
	
	result.shuffle()
	return result


static func get_heal_threshold(wounded_count: Big) -> HealThreshold:
	# calculate the two possible heal thresholds based on wounded_count
	var wounded_exponent: float = log(wounded_count.to_float()) / log(10)
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
	var wounded_count: Big = Big.ZERO
	
	func _init(init_gobs: Array[Gob], heal_threshold: HealThreshold) -> void:
		gobs = init_gobs
		
		# calculate count, wounded count
		for gob: Gob in gobs:
			count = Big.add(count, gob.get_count())
			wounded_count = Big.add(wounded_count, gob.get_wounded_count())
		
		# initialize chats
		max_chats_remaining = heal_threshold.chats
		chats_remaining = heal_threshold.chats
		option_count = heal_threshold.options
	
	func front() -> Gob:
		return gobs.front()
	
	
	func increment_chats_remaining() -> void:
		chats_remaining = clampi(chats_remaining + 1, 0, max_chats_remaining)
	
	
	func decrement_chats_remaining() -> void:
		chats_remaining = clampi(chats_remaining - 1, 0, max_chats_remaining)
