extends Control

func show_heal_panel() -> void:
	%KitchenPanel.hide()
	%HealPanel.show()
	%HealPanel.refresh()


func show_kitchen_panel() -> void:
	%HealPanel.hide()
	%KitchenPanel.show()
	%KitchenPanel.refresh()
