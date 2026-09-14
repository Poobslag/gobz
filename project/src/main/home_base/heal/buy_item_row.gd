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
	refresh()


func get_cost() -> Big:
	return PlayerData.market.get_cost(type, PlayerData.supplies_multiplier)


func refresh() -> void:
	%Emoji.text = Items.emoji_from_type(type)
	%Count.text = PlayerData.inventory.get_count(type).to_aa()
	%Button.disabled = get_cost().is_gt(PlayerData.gold)
	%Button.text = "+%s" % [PlayerData.supplies_multiplier.to_aa()]
	%Cost.text = "💰%s" % [get_cost().to_aa()]
