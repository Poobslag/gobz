@tool
class_name InventoryHeaderLabel
extends Label

@export var type: Items.Type:
	set(value):
		type = value
		refresh()

func _ready() -> void:
	refresh()
	if Engine.is_editor_hint():
		return
	PlayerData.inventory.inventory_item_changed.connect(func(changed_type: Items.Type) -> void:
		if changed_type != type:
			return
		refresh())


func refresh() -> void:
	var count: Big
	if Engine.is_editor_hint():
		count = Big.new(9_999)
	else:
		count = PlayerData.inventory.get_count(type)
	text = "%s%s" % [Items.emoji_from_type(type), count.to_aa()]
