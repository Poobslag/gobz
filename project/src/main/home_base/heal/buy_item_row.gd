class_name BuyItemRow
extends HBoxContainer

signal pressed

@export var type: Items.Type:
	set(value):
		type = value
		if is_node_ready():
			refresh()

func _ready() -> void:
	%Button.pressed.connect(pressed.emit)
	GoldBar.find_instance(self).connect_button_signals(%Button, get_cost)
	refresh()


func get_cost() -> Big:
	return PlayerData.market.get_cost(type, PlayerData.supplies_multiplier)


func refresh() -> void:
	%Emoji.text = Items.emoji_from_type(type)
	%Count.text = PlayerData.inventory.get_count(type).to_aa()
	%Button.disabled = not PlayerData.can_spend(get_cost())
	%Button.text = "+%s" % [PlayerData.supplies_multiplier.to_aa()]
	%Cost.text = "💰%s" % [get_cost().to_aa()]
