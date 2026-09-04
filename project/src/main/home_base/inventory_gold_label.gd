class_name InventoryGoldLabel
extends Label

func _ready() -> void:
	refresh()
	PlayerData.gold_changed.connect(refresh)


func refresh() -> void:
	text = "💰%s" % [PlayerData.gold.to_aa()]
