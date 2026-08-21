extends ColorRect

signal kitchen_exited

func _ready() -> void:
	%HealNavigator.move_left.connect(kitchen_exited.emit)
	%HealNavigator.move_center.connect(kitchen_exited.emit)
	%HealNavigator.move_right.connect(kitchen_exited.emit)


func refresh() -> void:
	%InventoryLabel.refresh()
	%HealNavigator.refresh()
