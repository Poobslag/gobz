class_name HealState

var groups: Array[Array]:
	get():
		return get_groups()
var group_index: int

var _groups_cache: Array[Array]
var _groups_dirty: bool = true

func mark_groups_dirty() -> void:
	_groups_dirty = true


func get_groups() -> Array[Array]:
	if _groups_dirty:
		_groups_dirty = false
		_groups_cache = _calculate_groups()
	return _groups_cache


func get_center_group() -> Array[Gob]:
	var result: Array[Gob] = groups[group_index] if group_index < groups.size() else ([] as Array[Gob])
	return result


func get_group_at(i: int) -> Array[Gob]:
	var result: Array[Gob] = groups[i] if i < groups.size() else ([] as Array[Gob])
	return result


func get_left_group() -> Array[Gob]:
	return get_group_at(get_left_index())


func get_right_group() -> Array[Gob]:
	return get_group_at(get_right_index())


func navigate_left() -> void:
	group_index = get_left_index()


func navigate_right() -> void:
	group_index = get_right_index()


func get_left_index() -> int:
	return wrapi(group_index - 1, 0, groups.size() - 1)


func get_right_index() -> int:
	return wrapi(group_index + 1, 0, groups.size() - 1)


func _calculate_groups() -> Array[Array]:
	var result: Array[Array] = []
	var wounded_gobs_by_type: Dictionary[Gobs.Type, Array] = {}
	for type: Gobs.Type in Gobs.Type.values():
		wounded_gobs_by_type[type] = [] as Array[Gob]
	for gob: Gob in PlayerData.army.gobs:
		if gob.get_wounded_count().is_gt(Big.ZERO):
			wounded_gobs_by_type[gob.type].append(gob)
	for heal_group: Array[Gob] in wounded_gobs_by_type.values():
		if not heal_group.is_empty():
			result.append(heal_group)
	result.shuffle()
	return result
