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

var cost: Big = Big.ZERO

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)
	GoldBar.find_instance(self).connect_button_signals(%Button, get.bind("cost"))
	_refresh()


func _refresh() -> void:
	# recalculate cost
	var total_cost: float = 0.0
	for gob: Gob in gobs:
		if not gob.is_hurt():
			continue
		total_cost += HomeBaseData.heal_data.get_gob_heal_cost(gob)
	cost = Big.new(total_cost)
	
	%CostDisplay.amount = CostDisplay.amount_from_cost(cost)
	
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
			goblin_name = "all %s %s goblins" % [emoji_string, Big.float_to_aa(total_hurt_count)]
		else:
			goblin_name = "%s %s" % [Gobs.emoji_from_type(gobs.front().type), gobs.front().name]
			if total_hurt_count > 1.0:
				goblin_name += " + %s others" % [Big.float_to_aa(total_hurt_count - 1)]
		%Label.text = "Bribe %s, +⚔%s" % [goblin_name, Big.float_to_aa(total_penalty)]
	else:
		%Label.text = ""
	
	%Button.disabled = not PlayerData.can_spend(cost) or total_hurt_count == 0.0
	%CostDisplay.disabled = %Button.disabled
