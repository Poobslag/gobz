class_name Market

var _cost_by_item: Dictionary[Items.Type, float] = {}
var _costs_dirty: bool = true

func mark_costs_dirty() -> void:
	_costs_dirty = true


func get_cost(type: Items.Type, count: Big = Big.ONE) -> Big:
	if _costs_dirty:
		_costs_dirty = false
		_calculate_costs()
	var cost: float = ceil(_cost_by_item.get(type, 0.01) * count.to_float())
	cost = round_to_sig_figs(cost, 2)
	return Big.new(cost)


func _calculate_costs() -> void:
	var weak_medicine_base_cost: float = HealData.HEAL_COST_FACTOR * pow(0.25, HealData.HEAL_COST_EXP)
	var strong_medicine_base_cost: float = HealData.HEAL_COST_FACTOR * pow(0.75, HealData.HEAL_COST_EXP)
	_cost_by_item = {
		Items.HERB_1: weak_medicine_base_cost * 0.30,
		Items.HERB_2: weak_medicine_base_cost * 0.45,
		Items.HERB_3: weak_medicine_base_cost * 0.75,
		Items.WEAK_MEDICINE: weak_medicine_base_cost,
		Items.STRONG_MEDICINE: strong_medicine_base_cost,
	}
	for type: Items.Type in _cost_by_item:
		var adjusted_cost: float = _cost_by_item[type]
		adjusted_cost *= randf_range(0.6, 1.4)
		adjusted_cost = Utils.apply_market_whim(adjusted_cost)
		_cost_by_item[type] = adjusted_cost


static func round_to_sig_figs(x: float, n: int) -> float:
	if x == 0:
		return 0.0
	var exponent: int = floor(log(abs(x))/log(10)) - (n - 1)
	return round(x / pow(10, exponent)) * pow(10, exponent)
