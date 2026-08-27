class_name BuyItemRow
extends HBoxContainer

signal pressed

@export var type: Items.Type:
	set(value):
		type = value
		if is_node_ready():
			refresh()

@export var count: Big = Big.ONE:
	set(value):
		count = value
		if is_node_ready():
			refresh()

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)
	refresh()


func get_cost() -> Big:
	return PlayerData.market.get_cost(type, count)


func refresh() -> void:
	%Button.disabled = get_cost().is_gt(PlayerData.gold)
	%Button.text = "-💰 %s" % [get_cost().to_aa()]
	%Label.text = "Buy %s×%s" % [Items.emoji_from_type(type), count.to_aa()]
