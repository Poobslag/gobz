extends Control
## [b]Keys:[/b][br]
## 	[kbd]M[/kbd]: Randomize market costs.

func _ready() -> void:
	PlayerData.gold = Big.new(50_000)
	for type: Items.Type in Items.Type.values():
		PlayerData.inventory.add_item(type, Big.new(5000))
	%SuppliesScreen.refresh()


func _input(event: InputEvent) -> void:
	match Utils.key_press(event):
		KEY_M:
			PlayerData.market.mark_costs_dirty()
			%SuppliesScreen.refresh()
