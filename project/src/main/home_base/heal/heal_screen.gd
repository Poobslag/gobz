class_name HealScreen
extends Control

func _ready() -> void:
	%KitchenPanel.kitchen_exited.connect(show_heal_panel)
	%HealPanel.kitchen_entered.connect(show_kitchen_panel)
	
	show_heal_panel(true)


func get_heal_panel() -> HealPanel:
	return %HealPanel


func show_heal_panel(initialize: bool = false) -> void:
	%KitchenPanel.hide()
	%HealPanel.show()
	if initialize:
		%HealPanel.initialize()
	else:
		%HealPanel.refresh()


func show_kitchen_panel() -> void:
	%HealPanel.hide()
	%KitchenPanel.show()
	%KitchenPanel.refresh()
