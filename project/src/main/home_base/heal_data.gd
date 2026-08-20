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


func _calculate_groups() -> Array[Array]:
	var result: Array[Array] = []
	var wounded_gobs_by_type: Dictionary[Gobs.Type, Array] = {}
	for type: Gobs.Type in Gobs.Type.values():
		wounded_gobs_by_type[type] = [] as Array[Gob]
	for gob: Gob in PlayerData.army.gobs:
		if gob.get_wounded_count().is_gt(Big.ZERO):
			wounded_gobs_by_type[gob.type].append(gob)
	return result
