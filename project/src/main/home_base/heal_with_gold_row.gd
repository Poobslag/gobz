extends HBoxContainer

signal pressed

var gobs: Array[Gob]:
	set(value):
		gobs = value
		if is_node_ready():
			_refresh()

var cost: Big = Big.ZERO

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)
	_refresh()


func _refresh() -> void:
	if not gobs:
		return
	
	var total_hurt_count: float = 0.0
	var total_cost: float = 0.0
	var total_penalty: float = 0.0
	for gob: Gob in gobs:
		total_hurt_count += gob.get_hurt_count().to_float()
		
		total_penalty += gob.get_wounded_count().to_float() \
				* roundi(gob.attack * (1.0 - Gobs.WOUNDED_ATTACK_FACTOR))
		
		var cost_per_goblin: float = maxf(1.0, \
				HealData.HEAL_COST_FACTOR * pow(gob.wound_severity, HealData.HEAL_COST_EXP))
		total_cost += cost_per_goblin * gob.get_hurt_count().to_float()
	total_cost *= HomeBaseData.heal_data.get_greed_factor(gobs.front())
	cost = Big.max(total_cost, 1.0)
	%Button.text = "-💰 %s" % [cost.to_aa()]
	var goblin_name: String = "%s %s" % [Gobs.emoji_from_type(gobs.front().type), gobs.front().name]
	if total_hurt_count > 1.0:
		goblin_name += " + %s others" % [Big.sub(total_hurt_count, 1).to_aa()]
	%Label.text = "Treat %s, %s ⚔" % [goblin_name, Big.new(total_penalty).to_aa()]
	%Button.disabled = cost.is_gt(PlayerData.gold)
