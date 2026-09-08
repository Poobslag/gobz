class_name HealWithMedicineRow
extends HBoxContainer

signal pressed

var gobs: Array[Gob]:
	set(value):
		gobs = value
		if is_node_ready():
			_refresh()

var heal_all: bool = false:
	set(value):
		heal_all = value
		if is_node_ready():
			_refresh()

var costs: Array[HealCost] = []

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)
	_refresh()


func has_enough_medicine() -> bool:
	var result: bool = true
	for cost: HealCost in costs:
		if not PlayerData.inventory.has_item(cost.type, cost.count):
			result = false
			break
	return result


func _refresh() -> void:
	# recalculate weak_medicine_needed, strong_medicine_needed
	costs.clear()
	var total_strong_medicine_needed: float = 0.0
	var total_weak_medicine_needed: float = 0.0
	for gob: Gob in gobs:
		if HomeBaseData.heal_data.gob_needs_strong_medicine(gob):
			total_strong_medicine_needed += gob.get_hurt_count().to_float()
		else:
			total_weak_medicine_needed += gob.get_hurt_count().to_float()
	if total_weak_medicine_needed > 0.0:
		costs.append(HealCost.new(Items.Type.WEAK_MEDICINE, Big.new(total_weak_medicine_needed)))
	if total_strong_medicine_needed > 0.0:
		costs.append(HealCost.new(Items.Type.STRONG_MEDICINE, Big.new(total_strong_medicine_needed)))
	
	var button_text: String = ""
	if costs.is_empty():
		button_text = "-🍰🍺"
	else:
		button_text = "-"
		for cost: HealCost in costs:
			button_text += Items.emoji_from_type(cost.type)
	%Button.text = button_text
	
	var bottom_text: String = ""
	for cost: HealCost in costs:
		if bottom_text:
			bottom_text += "   "
		var inventory_count: Big = PlayerData.inventory.get_count(cost.type)
		var cost_count: Big = cost.count
		var has_ingredient: bool = inventory_count.is_gte(cost_count)
		bottom_text += "%s%s%s%s" % [
			Items.emoji_from_type(cost.type),
			"" if has_ingredient else "[color=b34947]",
			cost_count.to_aa(),
			"" if has_ingredient else "[/color]",
			]
	%BottomLabel.text = bottom_text
	
	var heal_stats: Dictionary[String, Variant] = HealData.get_heal_stats(gobs)
	var total_hurt_count: float = heal_stats["hurt_count"]
	var total_penalty: float = heal_stats["penalty"]
	if gobs:
		var goblin_name: String
		if heal_all:
			var types: Dictionary[Gobs.Type, bool] = {}
			for gob: Gob in gobs:
				if gob.is_hurt():
					types[gob.type] = true
			var emoji_string: String = ""
			for type: Gobs.Type in Gobs.Type.values():
				if types.has(type):
					emoji_string += Gobs.emoji_from_type(type)
			goblin_name = "all %s %s goblins" % [emoji_string, Big.new(total_hurt_count).to_aa()]
		else:
			goblin_name = "%s %s" % [Gobs.emoji_from_type(gobs.front().type), gobs.front().name]
			if total_hurt_count > 1.0:
				goblin_name += " + %s others" % [Big.sub(total_hurt_count, 1).to_aa()]
		%TopLabel.text = "Heal %s, +⚔%s" % [goblin_name, Big.new(total_penalty).to_aa()]
	else:
		%TopLabel.text = ""
	
	%Button.disabled = not has_enough_medicine() or total_hurt_count == 0.0


class HealCost extends Resource:
	var type: Items.Type
	var count: Big
	
	func _init(init_type: Items.Type, init_count: Big) -> void:
		type = init_type
		count = init_count
