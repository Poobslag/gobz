class_name HealScreen
extends Control

func _ready() -> void:
	%KitchenPanel.kitchen_exited.connect(show_heal_panel)
	%HealPanel.kitchen_entered.connect(show_kitchen_panel)
	
	show_heal_panel()


func get_heal_panel() -> HealPanel:
	return %HealPanel


func show_heal_panel() -> void:
	%KitchenPanel.hide()
	%HealPanel.show()
	%HealPanel.initialize()


func show_kitchen_panel() -> void:
	%HealPanel.hide()
	%KitchenPanel.show()
	%KitchenPanel.refresh()
