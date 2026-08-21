extends ColorRect

signal kitchen_entered

func _ready() -> void:
	%HealNavigator.navigate_kitchen_pressed.connect(kitchen_entered.emit)
	%HealNavigator.navigate_left_pressed.connect(refresh)
	%HealNavigator.navigate_right_pressed.connect(refresh)


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()
