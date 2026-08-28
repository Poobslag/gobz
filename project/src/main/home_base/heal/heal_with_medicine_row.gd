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

var weak_medicine_needed: Big = Big.ZERO
var strong_medicine_needed: Big = Big.ZERO

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)
	_refresh()


func has_enough_medicine() -> bool:
	return PlayerData.inventory.get_count(Items.WEAK_MEDICINE).is_gte(weak_medicine_needed) \
			and PlayerData.inventory.get_count(Items.STRONG_MEDICINE).is_gte(strong_medicine_needed)


func _refresh() -> void:
	# recalculate weak_medicine_needed, strong_medicine_needed
	var total_weak_medicine_needed: float = 0.0
	var total_strong_medicine_needed: float = 0.0
	for gob: Gob in gobs:
		if HomeBaseData.heal_data.gob_needs_strong_medicine(gob):
			total_strong_medicine_needed += gob.get_hurt_count().to_float()
		else:
			total_weak_medicine_needed += gob.get_hurt_count().to_float()
	weak_medicine_needed = Big.new(total_weak_medicine_needed)
	strong_medicine_needed = Big.new(total_strong_medicine_needed)
	
	var button_text: String
	if strong_medicine_needed.is_eq(0):
		button_text = "-%s %s" % [
				Items.emoji_from_type(Items.WEAK_MEDICINE),
				weak_medicine_needed.to_aa()]
	elif weak_medicine_needed.is_eq(0):
		button_text = "-%s %s" % [
				Items.emoji_from_type(Items.STRONG_MEDICINE),
				strong_medicine_needed.to_aa()]
	else:
		var input_emojis: String = "%s%s" % [
				Items.emoji_from_type(Items.WEAK_MEDICINE),
				Items.emoji_from_type(Items.STRONG_MEDICINE)]
		var input_count: Big = Big.add(weak_medicine_needed, strong_medicine_needed)
		button_text = "-%s (%s)" % [input_emojis, input_count.to_aa()]
	%Button.text = button_text
	
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
		%Label.text = "Heal %s, +⚔%s" % [goblin_name, Big.new(total_penalty).to_aa()]
	else:
		%Label.text = ""
	
	%Button.disabled = not has_enough_medicine() or total_hurt_count == 0.0
