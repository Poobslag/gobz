class_name Inventory

var items: Dictionary[Items.Type, Big] = {}

func reset() -> void:
	items.clear()


func add_item(type: Items.Type, count: Big) -> void:
	if not items.has(type):
		items[type] = count
	else:
		items[type] = Big.add(items[type], count)


func get_count(type: Items.Type) -> Big:
	return items.get(type, Big.ZERO)


func has_item(type: Items.Type, count: Big) -> bool:
	return get_count(type).is_gte(count)


func take_item(type: Items.Type, count: Big) -> void:
	if items.has(type):
		items[type] = Big.new(max(0, items[type].to_float() - count.to_float()))


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	items.clear()
	for key_string: String in json.keys():
		items[Items.Type.get(key_string.to_upper())] = Big.new(json[key_string])


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	for type: Items.Type in items:
		result[Utils.enum_to_snake_case(Items.Type, type)] = items[type].to_float()
	return result
