class_name Market

var _costs: Dictionary[Items.Type, float] = {}
var _costs_dirty: bool = true

func get_costs() -> Dictionary[Items.Type, float]:
	if _costs_dirty:
		_costs_dirty = false
		_calculate_costs()
	return _costs


func reset() -> void:
	_costs.clear()
	_costs_dirty = true


func mark_costs_dirty() -> void:
	_costs_dirty = true


func get_cost(type: Items.Type, count: Big = Big.ONE) -> Big:
	var cost: float = ceil(get_costs().get(type, 0.01) * count.to_float())
	cost = round_to_sig_figs(cost, 2)
	return Big.new(cost)


func to_json_dict() -> Dictionary[String, Variant]:
	var result: Dictionary[String, Variant] = {}
	var cost_by_item_json: Dictionary[String, Variant] = {}
	for type: Items.Type in get_costs():
		cost_by_item_json[Utils.enum_to_snake_case(Items.Type, type)] = _costs[type]
	result["cost_by_item"] = cost_by_item_json
	return result


func from_json_dict(json: Dictionary[String, Variant]) -> void:
	reset()
	if json.has("cost_by_item"):
		for type_str: String in json["cost_by_item"]:
			_costs[Items.Type.get(type_str.to_upper())] = json["cost_by_item"][type_str]
		_costs_dirty = false


func _calculate_costs() -> void:
	var weak_medicine_base_cost: float = HealData.HEAL_COST_FACTOR * pow(0.25, HealData.HEAL_COST_EXP)
	var strong_medicine_base_cost: float = HealData.HEAL_COST_FACTOR * pow(0.75, HealData.HEAL_COST_EXP)
	_costs = {
		Items.HERB_1: weak_medicine_base_cost * 0.30,
		Items.HERB_2: weak_medicine_base_cost * 0.45,
		Items.HERB_3: weak_medicine_base_cost * 0.75,
		Items.WEAK_MEDICINE: weak_medicine_base_cost,
		Items.STRONG_MEDICINE: strong_medicine_base_cost,
		
		Items.FOOD_BREAD: 0.3,
		Items.FOOD_CHICKEN: 0.5,
		Items.FOOD_PIZZA: 0.4,
		Items.FOOD_RAM: 0.6,
	}
	for type: Items.Type in _costs:
		var adjusted_cost: float = _costs[type]
		adjusted_cost *= randf_range(0.6, 1.4)
		adjusted_cost = Utils.apply_market_whim(adjusted_cost)
		_costs[type] = adjusted_cost


static func round_to_sig_figs(x: float, n: int) -> float:
	if x == 0:
		return 0.0
	var exponent: int = floor(log(abs(x))/log(10)) - (n - 1)
	return round(x / pow(10, exponent)) * pow(10, exponent)
