class_name Market

var _cost_by_item: Dictionary[Items.Type, float] = {}
var _costs_dirty: bool = true

func mark_costs_dirty() -> void:
	_costs_dirty = true


func get_cost(type: Items.Type, count: Big = Big.ONE) -> Big:
	if _costs_dirty:
		var weak_medicine_base_cost: float = HealData.HEAL_COST_FACTOR * pow(0.25, HealData.HEAL_COST_EXP)
		var strong_medicine_base_cost: float = HealData.HEAL_COST_FACTOR * pow(0.75, HealData.HEAL_COST_EXP)
		_cost_by_item = {
			Items.HERB_1: weak_medicine_base_cost * 0.30,
			Items.HERB_2: weak_medicine_base_cost * 0.45,
			Items.HERB_3: weak_medicine_base_cost * 0.75,
			Items.WEAK_MEDICINE: weak_medicine_base_cost,
			Items.STRONG_MEDICINE: strong_medicine_base_cost,
		}
		_costs_dirty = false
	
	return Big.new(ceil(_cost_by_item.get(type, 0.01) * count.to_float()))
