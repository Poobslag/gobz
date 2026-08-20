extends ColorRect

signal kitchen_exited

func _ready() -> void:
	%HealNavigator.navigate_left_pressed.connect(kitchen_exited.emit)
	%HealNavigator.navigate_center_pressed.connect(kitchen_exited.emit)
	%HealNavigator.navigate_right_pressed.connect(kitchen_exited.emit)


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()
